
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../global/global.dart';

class FirebaseMessagingController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  String? fcm_token;
  var onNewNotification = false.obs;
  
  // Notification payload data
  var notificationData = {}.obs;
  var isInitilized = false;

  @override
  void onInit() {
    super.onInit();
   if (!isInitilized) {
      isInitilized = true;
      _initializeFirebaseMessaging();
      initializeLocalNotifications();
    }
  }

  @override
  void onReady() {
    getFirebaseToken();
    super.onReady();
  }


  Future<void> _initializeFirebaseMessaging() async {
    await _firebaseMessaging.requestPermission(
      sound: true,
      badge: false,
      alert: true,
      provisional: false,
    );
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print(message);
    //   onNewNotification.value = true;
    //   _handleNotification(message);
      
    // });
   
   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("🔔 Foreground FCM: ${message.data}");
      print(message.toString());
      onNewNotification.value = true;

      final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      final type = message.data['type'] ?? '';
      final sound = message.data['sound'] ?? (type == 'NearByOrders' ? 'nearby_order' : 'new_order');
      final channelId = type == 'NearByOrders'
          ? 'nearby_orders_channel'
          : 'assigned_new_order_channel';

      await _showNotification(
        title: title,
        body: body,
        soundName: sound,
        channelId: channelId,
      );
    });



    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
     // _handleNotification(message);
    });


    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      // if (message != null) {
      //   _handleNotification(message);
      // }
    });


    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        fcm_token = newToken;
        box.write("fcm_token", newToken);
        print("🔄 FCM Token refreshed: $newToken");
    });

    fcm_token = await _firebaseMessaging.getToken();
    box.write("fcm_token", fcm_token);

  }

  void getFirebaseToken() async{
        fcm_token = await _firebaseMessaging.getToken();
        box.write("fcm_token", fcm_token);
  }


  static Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
    print('🌙 ======== BACKGROUND MESSAGE HANDLER ========');
    
    try {
      
      WidgetsFlutterBinding.ensureInitialized();
      
      // Initialize local notifications
      final FlutterLocalNotificationsPlugin notificationsPlugin = 
          FlutterLocalNotificationsPlugin();
      
      // Initialize with your app icon
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('ic_launcher');
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );
      
      await notificationsPlugin.initialize(settings);
      
      // Extract notification data
      final data = message.data;
      final notification = message.notification;
      
      final title = data['title'] ?? notification?.title ?? 'New Order';
      final body = data['body'] ?? notification?.body ?? 'You have a new order!';
      final type = data['type'] ?? '';
      
      // Determine sound and channel
      final sound = data['sound'] ?? 
          (type == 'NearByOrders' ? 'nearby_order' : 'new_order');
      final channelId = type == 'NearByOrders'
          ? 'nearby_orders_channel'
          : 'assigned_new_order_channel';
      
      print('🌙 Background notification:');
      print('- Title: $title');
      print('- Body: $body');
      print('- Type: $type');
      print('- Sound: $sound');
      print('- Channel: $channelId');
      
      
      await _createNotificationChannelInBackground(
        notificationsPlugin, 
        channelId, 
        type, 
        sound
      );
      
      // Create notification with sound
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channelId,
        type == 'NearByOrders' ? 'Nearby Orders' : 'Assigned Orders',
        channelDescription: 'Notifications for $type orders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(sound),
        enableVibration: true,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        ongoing: false,
      );
      
      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
      if(message.contentAvailable == true){
      await notificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
      );
      }
      print('✅ Background notification displayed with sound');
    } catch (e, stackTrace) {
      print('❌ Error in background message handler: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  // Helper method to create notification channel in background
  static Future<void> _createNotificationChannelInBackground(
    FlutterLocalNotificationsPlugin notificationsPlugin,
    String channelId,
    String type,
    String soundName,
  ) async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          type == 'NearByOrders' ? 'Nearby Orders' : 'Assigned Orders',
          description: 'Notifications for $type orders',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound(soundName),
          enableVibration: true,
        ),
      );
    }
  }



  void _handleNotification(RemoteMessage message) {
    String? title = message.notification?.title;
    String? body = message.notification?.body;
    String? type = message.data['type'];

    switch (type) {
      case "NearByOrders":
        _showNotification(
          title: title,
          body: body,
          soundName: 'nearby_order',
          channelId: 'new_order_channel',
        );
        break;
      case "AssignedOrder":
        _showNotification(
          title: title,
          body: body,
          soundName: 'new_order',
          channelId: 'assigned_new_order_channel',
        );
        break;

      default:
        _showNotification(
          title: title,
          body: body,
          soundName: 'new_order',
          channelId: 'new_order_channel',
        );
    }
  }





  void initializeLocalNotifications() async {
    const initializationSettingsAndroid =
    AndroidInitializationSettings('ic_launcher');
    // final initializationSettingsIOS = IOSInitializationSettings(
    //    requestSoundPermission: false,
    //     requestBadgePermission: false,
    //      requestAlertPermission: false,);
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: initializationSettingsIOS,
    );
    _notificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("🔔 Notification tapped: ${response.payload}");
        // Handle navigation or action when notification is tapped
      },
    );
    await _createNotificationChannels();
  }



  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'nearby_orders_channel',
          'Nearby Orders',
          description: 'Notifications for nearby orders',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('nearby_order'),
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'assigned_new_order_channel',
          'Assigned Orders',
          description: 'Notifications for assigned orders',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('new_order'),
        ),
      );
    }
  }

  Future<void> _showNotification({
    String? title,
    String? body,
    required String soundName,
    required String channelId,
  }) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelId == 'nearby_orders_channel'
      ? 'Nearby Orders'
      : 'Assigned Orders',
      channelDescription: 'Channel for $channelId',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(""),
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      DateTime.now().microsecond,
      title,
      body,
      platformChannelSpecifics,
    );
    print("🔔 notification shown: $title - $body");
  }


}
