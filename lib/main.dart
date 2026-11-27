import 'dart:convert';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:carson_zyppy/app_pages/app_pages.dart';
import 'package:carson_zyppy/core/theme/AppTheme.dart';
import 'package:carson_zyppy/firebase_notifications/firebase_notifiction_controller.dart';
import 'package:carson_zyppy/firebase_options.dart';
import 'package:carson_zyppy/local_db/dataBase/database.dart';
import 'package:carson_zyppy/local_db/user_repo.dart';
import 'package:carson_zyppy/local_db/userRepository/db/floor_database.dart';
import 'package:carson_zyppy/splash_screen/splash_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/global/global.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final data = message.data;
  debugPrint(
    '[FCM_LIFECYCLE] Background message received: id=${message.messageId}; type=${data['type']}',
  );

  // Notification payloads are displayed by Android/iOS. Data-only pushes need
  // a local notification while the app is backgrounded or terminated.
  if (message.notification != null) {
    debugPrint('[FCM_LIFECYCLE] Background notification payload handled by OS');
    return;
  }

  final title = (data['title'] ?? 'New order').toString();
  final body = (data['body'] ?? 'A new order is available').toString();
  final notifications = FlutterLocalNotificationsPlugin();
  const channel = AndroidNotificationChannel(
    'default_channel',
    'Notifications',
    description: 'Order and driver notifications',
    importance: Importance.max,
  );
  final android = notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(channel);
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await notifications.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Notifications',
        channelDescription: 'Order and driver notifications',
        importance: Importance.max,
        priority: Priority.max,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(data),
  );
  debugPrint('[FCM_LIFECYCLE] Data-only background notification displayed');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  Get.put(
    FirebaseMessagingController(),
    permanent: true,
  );

  FlutterError.onError = (FlutterErrorDetails errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
    return true;
  };

  await Get.putAsync<UserRepository>(
        () async {
      final db = await $FloorAppDatabase
          .databaseBuilder('app_database.db')
          .build();

      return FloorUserRepository(db);
    },
    permanent: true,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Carson Drop-it',
          themeMode: _initialThemeMode(),
          theme: AppThemes.light,
          darkTheme: AppThemes.dark,
          getPages: AppPages.routes,
          home: UpgradeAlert(
            barrierDismissible: false,
            dialogStyle: UpgradeDialogStyle.material,
            showIgnore: false,
            showLater: false,
            child: const SplashScreen(),
          ),
        );
      },
    );
  }

  ThemeMode _initialThemeMode() {
    final saved = box.read<String>(THEME_MODE_KEY);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }
}