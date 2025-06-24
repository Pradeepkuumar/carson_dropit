
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../global/global.dart';

class FirebaseMessagingController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  String? fcm_token;

  @override
  void onInit() {
    super.onInit();
    _initializeFirebaseMessaging();
    initializeLocalNotifications();
  }


  Future<void> _initializeFirebaseMessaging() async {
    await _firebaseMessaging.requestPermission(
      sound: true,
      badge: true,
      alert: true,
      provisional: false,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(message);
      _handleNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotification(message);
    });


    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotification(message);
      }
    });
    fcm_token = await _firebaseMessaging.getToken();
    box.write("fcm_token", fcm_token);
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
    final initializationSettingsAndroid =
    AndroidInitializationSettings('ic_launcher');
    // final initializationSettingsIOS = IOSInitializationSettings(
    //    requestSoundPermission: false,
    //     requestBadgePermission: false,
    //      requestAlertPermission: false,);
    final initializationSettings = InitializationSettings(
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
  }


}
