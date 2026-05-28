import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'dart:io'; 
import '../global/global.dart';


class FirebaseMessagingController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  String? fcm_token;
  bool isInitialized = false;
  var onNewNotification = false.obs;
  var onNewAssignedOrder = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (!isInitialized) {
      isInitialized = true;
      _initializeFirebaseMessaging();
      initializeLocalNotifications();
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Foreground FCM: ${message.data}');
        print(message.toString());
          onNewNotification.value = true;
        final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        final type = message.data['type'] ?? '';
        
        if (type != 'NearByOrders') {
          onNewAssignedOrder.value++;
        }

        final sound = message.data['sound'] ?? (type == 'NearByOrders' ? 'nearby_order' : 'new_order');
        final channelId = type == 'NearByOrders'
            ? 'nearby_orders_channel'
            : 'assigned_new_order_channel';

        _showNotification(
          title: title,
          body: body,
          soundName: sound,
          channelId: channelId,
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from notification: ${message.messageId}');
      });

      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('Initial message received: ${message.messageId}');
        }
      });

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
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
      final initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
    
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
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Channel for nearby orders with custom sound
        const AndroidNotificationChannel nearbyOrdersChannel = AndroidNotificationChannel(
          'nearby_orders_channel',
          'Nearby Orders',
          description: 'Notifications for nearby orders',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('nearby_order'), 
          enableVibration: true,
        );

        // Channel for assigned/new orders with custom sound
        const AndroidNotificationChannel newOrdersChannel = AndroidNotificationChannel(
          'assigned_new_order_channel',
          'New Orders',
          description: 'Notifications for new assigned orders',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('new_order'), 
          enableVibration: true,
        );

        // Default channel
        const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
          'default_channel',
          'Default Notifications',
          description: 'Channel for all other notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        // Create all channels
        await androidImplementation.createNotificationChannel(nearbyOrdersChannel);
        await androidImplementation.createNotificationChannel(newOrdersChannel);
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
      final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
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
      final DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: soundName != null ? '$soundName.aiff' : 'default', // iOS needs extension
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title:  title,
        body:  body,
        notificationDetails: platformChannelSpecifics,
        payload: payload,
      );

      print('✅ Notification shown: $title with sound: $soundName on channel: $notificationChannelId');
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
      default:
        return 'Default Notifications';
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
    // Handle navigation based on notification type
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