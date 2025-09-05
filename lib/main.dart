import 'dart:ui';
import 'package:carson_zyppy/splash_screen/splash_screen.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app_pages/app_pages.dart';
import 'app_theme/AppTheme.dart';
import 'firebase_notifications/firebase_notifiction_controller.dart';
import 'firebase_options.dart';
import 'local_db/dataBase/database.dart';
import 'local_db/userRepository/db/floor_database.dart';
import 'local_db/user_repo.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔥 Background/Killed Notification: ${message.data}");
}
void main() async {
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Get.put(FirebaseMessagingController());
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await Get.putAsync<UserRepository>(permanent: true, () async {
    final db = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
    return FloorUserRepository(db);
  });

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Get.isDarkMode ? AppColors.black : AppColors.white,
      statusBarIconBrightness: Get.isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: Get.isDarkMode ? Brightness.dark : Brightness.light,
    ));

    return ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Carson Drop-it',
            home: const SplashScreen(),
            theme: AppThemes.light,
           themeMode: ThemeMode.light,
           getPages: AppPages.routes,
          );
        });
  }
}
