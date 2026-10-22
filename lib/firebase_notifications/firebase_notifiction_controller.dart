import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../global/global.dart';
import '../pages/dashboard/controller/rider_dashboard_controller.dart';

class FirebaseMessagingController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? fcm_token;
  bool isInitialized = false;
  var onNewNotification = false.obs;
  var onNewAssignedOrder = 0.obs;
  // Data of the latest foreground OrderCancelled push - the active delivery
  // screen watches it to tell the rider when the order they're on is gone.
  var onOrderCancelled = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    if (!isInitialized) {
      isInitialized = true;
      // Tap handlers first, before the (awaited) permission prompt, so a tap
      // that launched/resumed the app is never missed.
      _registerTapHandlers();
      _initializeFirebaseMessaging();
      initializeLocalNotifications();
    }
  }

  void _registerTapHandlers() {
    // Background -> tapped (app was alive, not on screen).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.messageId}');
      // Fires the instant Android resumes the activity, sometimes before
      // Flutter's engine has reattached its surface - navigating right away
      // can render into a frame that isn't on screen yet, showing as a
      // blank/white screen. Deferring to the next frame avoids that.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromNotificationData(message.data);
      });
      // Make sure that next frame actually comes, so the callback isn't
      // left waiting on an idle engine.
      WidgetsBinding.instance.scheduleFrame();
    });

    // Killed -> launched by tapping an FCM (system tray) notification.
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print('Initial message received: ${message.messageId}');
        _navigateFromNotificationData(message.data);
      }
    });
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
            criticalAlert: true,
          );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Foreground FCM: ${message.data}');
        print(message.toString());

        final title =
            message.notification?.title ??
            message.data['title'] ??
            'Notification';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        final type = message.data['type'] ?? '';

        onNewNotification.value = true;
        // A cancellation isn't a new assigned order - only refresh.
        if (type != 'NearByOrders' && type != 'OrderCancelled') {
          onNewAssignedOrder.value++;
        }
        if (type == 'OrderCancelled') {
          onOrderCancelled.value = Map<String, dynamic>.from(message.data);
        }

        final String sound;
        final String channelId;
        switch (type) {
          case 'NearByOrders':
            sound = message.data['sound'] ?? 'nearby_order';
            channelId = 'nearby_orders_channel';
            break;
          case 'OrderCancelled':
            sound = message.data['sound'] ?? 'order_cancelled';
            channelId = 'order_cancellation_channel';
            break;
          default:
            sound = message.data['sound'] ?? 'new_order';
            channelId = 'assigned_new_order_channel';
        }

        _showNotification(
          title: title,
          body: body,
          soundName: sound,
          channelId: channelId,
          payload: jsonEncode(message.data),
        );
      });

      // Foreground messages are shown by _showNotification (custom sounds) -
      // letting iOS also present the FCM banner showed every message twice.
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      await getFCMTokenWithRetry();
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> getFCMTokenWithRetry() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();

        if (apnsToken == null) {
          print('APNS token not available yet, waiting...');
          await Future.delayed(Duration(seconds: 2));
          await getFCMTokenWithRetry();
          return;
        }
        print('APNS token available: $apnsToken');
      }

      fcm_token = await _firebaseMessaging.getToken();
      if (fcm_token != null) {
        box.write(apiKeys.fcmToken, fcm_token);
        print('FCM Token: $fcm_token');
      } else {
        print('FCM token is null, retrying in 3 seconds...');
        await Future.delayed(Duration(seconds: 3));
        await getFCMTokenWithRetry();
      }
    } catch (e) {
      print('Error getting FCM token: $e');
      await Future.delayed(Duration(seconds: 3));
      await getFCMTokenWithRetry();
    }
  }

  void initializeLocalNotifications() async {
    try {
      final initializationSettingsAndroid = AndroidInitializationSettings(
        'ic_notification',
      );

      final initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print("🔔 Notification tapped: ${response.payload}");
          _handleNotificationTap(response);
        },
      );
      // Create multiple notification channels with different sounds
      await _createNotificationChannels();

      // Killed -> launched by tapping one of our own local notifications
      // (shown while in foreground, app killed afterwards) -
      // onDidReceiveNotificationResponse doesn't fire for that case.
      final launchDetails = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final response = launchDetails!.notificationResponse;
        if (response != null) _handleNotificationTap(response);
      }
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        // Channel for nearby orders with custom sound
        const AndroidNotificationChannel nearbyOrdersChannel =
            AndroidNotificationChannel(
              'nearby_orders_channel',
              'Nearby Orders',
              description: 'Notifications for nearby orders',
              importance: Importance.high,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('nearby_order'),
              enableVibration: true,
            );

        // Channel for assigned/new orders with custom sound
        const AndroidNotificationChannel newOrdersChannel =
            AndroidNotificationChannel(
              'assigned_new_order_channel',
              'New Orders',
              description: 'Notifications for new assigned orders',
              importance: Importance.high,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('new_order'),
              enableVibration: true,
            );

        // Channel for cancelled orders ("Order cancelled! Please check your
        // order list.") - max importance, the rider must stop the delivery.
        const AndroidNotificationChannel orderCancelledChannel =
            AndroidNotificationChannel(
              'order_cancellation_channel',
              'Order Cancelled',
              description: 'Notifications for cancelled orders',
              importance: Importance.max,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('order_cancelled'),
              enableVibration: true,
            );

        // Default channel
        const AndroidNotificationChannel defaultChannel =
            AndroidNotificationChannel(
              'default_channel',
              'Default Notifications',
              description: 'Channel for all other notifications',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
            );

        // Create all channels
        await androidImplementation.createNotificationChannel(
          nearbyOrdersChannel,
        );
        await androidImplementation.createNotificationChannel(newOrdersChannel);
        await androidImplementation.createNotificationChannel(
          orderCancelledChannel,
        );
        // Replaced by order_cancellation_channel (the id the backend sends).
        await androidImplementation.deleteNotificationChannel(
          channelId: 'order_cancelled_channel',
        );
        await androidImplementation.createNotificationChannel(defaultChannel);

        print('✅ Notification channels created successfully');
      }
    } catch (e) {
      print('Error creating notification channels: $e');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? soundName,
    String? channelId,
    String? payload,
  }) async {
    try {
      // Use provided channelId or default
      final String notificationChannelId = channelId ?? 'default_channel';
      final String channelName = _getChannelName(notificationChannelId);

      // Android notification details with custom sound
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            notificationChannelId,
            channelName,
            channelDescription: 'Channel for $channelName',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: soundName != null
                ? RawResourceAndroidNotificationSound(soundName)
                : null, // null will use default channel sound
            enableVibration: true,
            styleInformation: BigTextStyleInformation(body),
          );

      // iOS notification details with custom sound
      final DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: soundName != null
                ? '$soundName.aiff'
                : 'default', // iOS needs extension
            interruptionLevel: InterruptionLevel.timeSensitive,
          );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: payload,
      );

      print(
        '✅ Notification shown: $title with sound: $soundName on channel: $notificationChannelId',
      );
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'nearby_orders_channel':
        return 'Nearby Orders';
      case 'assigned_new_order_channel':
        return 'New Orders';
      case 'order_cancellation_channel':
        return 'Order Cancelled';
      default:
        return 'Default Notifications';
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromNotificationData(data);
    } catch (e) {
      print('Error decoding notification payload: $e');
    }
  }

  String? _lastTappedRef;
  DateTime? _lastTappedAt;

  // Shared by all four tap paths (foreground local-notification tap,
  // background onMessageOpenedApp, killed getInitialMessage, killed
  // local-notification launch) so tapping any notification type opens its
  // order detail regardless of app state or platform.
  void _navigateFromNotificationData(Map<String, dynamic> data) {
    final orderRef = (data['awb_number'] ?? '').toString();
    if (orderRef.isEmpty) return;

    // Two paths can report the same tap (e.g. getInitialMessage and the
    // local-notification launch details) - open it only once.
    final now = DateTime.now();
    if (_lastTappedRef == orderRef &&
        _lastTappedAt != null &&
        now.difference(_lastTappedAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastTappedRef = orderRef;
    _lastTappedAt = now;

    // Always stash first; RiderDashboardController opens it once its
    // initial load is done (consumePendingNotificationOrder is a no-op
    // before that). On a cold start the splash screen's Get.offAllNamed
    // would otherwise wipe out a detail screen opened too early.
    RiderDashboardController.pendingFocusOrderRef = orderRef;
    if (Get.isRegistered<RiderDashboardController>()) {
      Get.find<RiderDashboardController>().consumePendingNotificationOrder();
    }
  }

  Future<void> refreshFCMToken() async {
    await getFCMTokenWithRetry();
  }

  void listenForTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      fcm_token = newToken;
      box.write("fcm_token", newToken);
      print('FCM Token refreshed: $newToken');
    });
  }
}
