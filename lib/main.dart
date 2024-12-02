import 'package:carson_zyppy/pages/auth/login_screen.dart';
import 'package:carson_zyppy/pages/orders/orders_tab_container.dart';
import 'package:carson_zyppy/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Carson Zyppy',
      home:  SplashScreen(),
    );
  }
}
