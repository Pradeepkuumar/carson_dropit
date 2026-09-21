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
import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/global/global.dart';

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

  // The Account screen's Light/Dark toggle persists an explicit choice here;
  // with none saved yet, fall back to following the OS setting.
  ThemeMode _initialThemeMode() {
    final saved = box.read<String>(THEME_MODE_KEY);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }
}