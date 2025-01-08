import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../global/global.dart';
import 'notification_model/notification.dart';

class FirebaseMessagingController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
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
      // Handle incoming messages when the app is in the foreground
      _showNotification(body: message.notification?.body,title: message.notification?.title );
      addNotification(LocalNotification(body: message.notification?.body,title: message.notification?.title ));
      print('Received message: ${message.notification?.title}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       _showNotification(body: message.notification?.body,title: message.notification?.title );
      // Handle notification taps when the app is in the background or terminated
      print('Opened app from notification: ${message.notification?.title}');
    });
    fcm_token = (await _firebaseMessaging.getToken())!;
    box.write("fcm_token", fcm_token);
  }

  // GetStorage()
  // Send the token to your server or handle it as needed }
  void initializeLocalNotifications() {
    final initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // final initializationSettingsIOS = IOSInitializationSettings(
    //    requestSoundPermission: false,
    //     requestBadgePermission: false,
    //      requestAlertPermission: false, );
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: initializationSettingsIOS,
    );
    _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(
    { String? title,  String? body}) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'coderootz', 'zyppy',
      importance: Importance.high, priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
      playSound: true,
      actions: [

      ]
      //sound: RawResourceAndroidNotificationSound('your_sound'),
    );
//  final iOSPlatformChannelSpecifics = IOSNotificationDetails(
//   //sound: 'your_sound.m4a',
//   );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      //  iOS: iOSPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      DateTime.now().microsecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
