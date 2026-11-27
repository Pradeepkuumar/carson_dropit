import 'dart:async';
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
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  var onNewNotification = false.obs;
  var notificationRevision = 0.obs;
  var onNewAssignedOrder = 0.obs;
  var onOrderCancelled = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    if (!isInitialized) {
      isInitialized = true;
      fcm_token = box.read(apiKeys.fcmToken);
      debugPrint('[FCM_LIFECYCLE] Controller initialized once');
      // Attach message/token observers before any permission prompt can pause
      // startup. This controller is permanent for the whole app session.
      _registerTapHandlers();
      _registerForegroundMessageListener();
      listenForTokenRefresh();
      _initializeFirebaseMessaging();
      initializeLocalNotifications();
    }
  }

  void _registerTapHandlers() {
    // Background -> tapped (app was alive, not on screen).
    _openedMessageSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[FCM_LIFECYCLE] Notification opened from background: id=${message.messageId}; type=${message.data['type']}',
      );
      _markNotificationEvent(source: 'opened-from-background');
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
        debugPrint(
          '[FCM_LIFECYCLE] Initial notification opened: id=${message.messageId}; type=${message.data['type']}',
        );
        _markNotificationEvent(source: 'initial-message');
        _navigateFromNotificationData(message.data);
      }
    });
  }

  void _registerForegroundMessageListener() {
    if (_foregroundMessageSubscription != null) return;
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        debugPrint(
          '[FCM_LIFECYCLE] Foreground message received: id=${message.messageId}; type=${message.data['type']}',
        );
        _handleIncomingMessage(message, source: 'foreground');
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[FCM_LIFECYCLE] Foreground listener error: $error');
      },
    );
    debugPrint('[FCM_LIFECYCLE] Foreground listener registered');
  }

  void _handleIncomingMessage(
    RemoteMessage message, {
    required String source,
  }) {
    final data = message.data;
    final title =
        message.notification?.title ?? data['title'] ?? 'Notification';
    final body = message.notification?.body ?? data['body'] ?? '';
    final type = data['type'] ?? '';
    debugPrint(
      '[FCM_LIFECYCLE] Message details: source=$source; notificationPayload=${message.notification != null}; dataKeys=${data.keys.toList()}; titlePresent=${title.isNotEmpty}; bodyPresent=${body.isNotEmpty}',
    );

    _markNotificationEvent(source: source, type: type);
    // A cancellation isn't a new assigned order - only refresh.
    if (type != 'NearByOrders' && type != 'OrderCancelled') {
      onNewAssignedOrder.value++;
    }
    if (type == 'OrderCancelled') {
      onOrderCancelled.value = Map<String, dynamic>.from(data);
    }

    final String sound;
    final String channelId;
    switch (type) {
      case 'NearByOrders':
        sound = data['sound'] ?? 'nearby_order';
        channelId = 'nearby_orders_channel';
        break;
      case 'OrderCancelled':
        sound = data['sound'] ?? 'order_cancelled';
        channelId = 'order_cancellation_channel';
        break;
      default:
        sound = data['sound'] ?? 'new_order';
        channelId = 'assigned_new_order_channel';
    }

    _showNotification(
      title: title,
      body: body,
      soundName: sound,
      channelId: channelId,
      payload: jsonEncode(data),
    );
  }

  void _markNotificationEvent({
    required String source,
    String? type,
  }) {
    notificationRevision.value++;
    onNewNotification.value = true;
    debugPrint(
      '[FCM_LIFECYCLE] Notification event raised: source=$source; type=${type ?? 'unknown'}; revision=${notificationRevision.value}',
    );
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );
      debugPrint(
        '[FCM_LIFECYCLE] Permission result: authorizationStatus=${settings.authorizationStatus}',
      );

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
    // Keep startup/login responsive when Firebase or APNS is unavailable.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        if (Platform.isIOS) {
          final apnsToken = await _firebaseMessaging
              .getAPNSToken()
              .timeout(const Duration(seconds: 5));
          if (apnsToken == null) {
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
        }

        final token = await _firebaseMessaging
            .getToken()
            .timeout(const Duration(seconds: 5));
        if (token != null && token.isNotEmpty) {
          fcm_token = token;
          box.write(apiKeys.fcmToken, token);
          debugPrint(
            '[FCM_LIFECYCLE] Token retrieved: fingerprint=${token.hashCode}; local login token marker matches=${box.read('fcm_registered_token') == token}',
          );
          return;
        }
      } catch (e) {
        print('Error getting FCM token (attempt ${attempt + 1}): $e');
      }

      if (attempt < 2) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    fcm_token = null;
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
    if (_tokenRefreshSubscription != null) return;
    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen(
      (String newToken) {
        fcm_token = newToken;
        box.write(apiKeys.fcmToken, newToken);
        final registeredToken = box.read('fcm_registered_token');
        final registrationRequired = registeredToken != newToken;
        if (registrationRequired) {
          box.remove('fcm_registered_token');
        }
        debugPrint(
          '[FCM_LIFECYCLE] Token refreshed: fingerprint=${newToken.hashCode}; authenticated=${(box.read(apiKeys.apiToken) ?? '').toString().isNotEmpty}; backend registration required=$registrationRequired',
        );
        // This client currently has no authenticated token-update endpoint.
        // Do not call login again or persist the driver's password here.
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[FCM_LIFECYCLE] Token refresh listener error: $error');
      },
    );
    debugPrint('[FCM_LIFECYCLE] Token refresh listener registered');
  }
}
