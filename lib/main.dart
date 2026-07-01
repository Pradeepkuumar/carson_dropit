import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:carson_zyppy/app_pages/app_pages.dart';
import 'package:carson_zyppy/app_theme/AppTheme.dart';
import 'package:carson_zyppy/firebase_notifications/firebase_notifiction_controller.dart';
import 'package:carson_zyppy/firebase_options.dart';
import 'package:carson_zyppy/local_db/dataBase/database.dart';
import 'package:carson_zyppy/local_db/user_repo.dart';
import 'package:carson_zyppy/local_db/userRepository/db/floor_database.dart';
import 'package:carson_zyppy/splash_screen/splash_screen.dart';
import 'package:upgrader/upgrader.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await FirebaseMessagingController.firebaseMessagingBackgroundHandler(message);
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
          themeMode: ThemeMode.light,
          theme: AppThemes.light,
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
}