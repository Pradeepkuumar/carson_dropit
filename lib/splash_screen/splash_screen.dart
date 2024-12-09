import 'package:carson_zyppy/pages/auth/login_screen.dart';
import 'package:carson_zyppy/pages/orders/orders_tab_container.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_pages/app_pages.dart';
import '../global/global.dart';
import '../pages/auth/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreesState createState() => _SplashScreesState();
}

class _SplashScreesState extends State<SplashScreen> {
  bool showLoadingScreen = true;
  final AuthController controller = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    getUser();
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        showLoadingScreen = false;
      });
    });
  }

  void getUser() async {
    // var value = await _userRepository.getUser();
    //  if (value != null) {
    //   // user = value;
    //  } else {}
  }

  @override
  Widget build(BuildContext context) {
    if (showLoadingScreen) {
      return Container(
        height: Get.height,
        decoration: utils.boxDacorationGradient(),
        child: Center(
          child: Stack(children: [
            Image.asset(
              "assets/images/bg_login.jpg",
              height: Get.height,
              width: Get.width,
              fit: BoxFit.fill,
            ),
            Center(
              child: utils.iosProgressIndicator(AppColors.white),
            ),
          ]),
        ),
      );
    } else {
      if (controller.userId == 0) {
        return LoginScreen();
      } else if (controller.userId == 1) {
        return OrdersTabContainer();
      }else{
        return SplashScreen();
      }
    }
  }
}
