import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/auth/login_screen.dart';
import 'package:carson_zyppy/pages/dashboard/view/rider_dashboard.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../global/global.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreesState createState() => _SplashScreesState();
}

class _SplashScreesState extends State<SplashScreen> {
  bool showLoadingScreen = true;
  var user = UserData();

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
    var value = await userRepository.getUser();
     if (value != null) {
      user = value;
     } else {

     }
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
              child: utils.iosProgressIndicator(AppColors.white,"Loading data please wait..."),
            ),
          ]),
        ),
      );
    } else {
      if (user.code == null) {
        return const LoginScreen();
      } else if (user.code != null) {
        return const RiderDashboard();
      }else{
        return const SplashScreen();
      }
    }
  }
}
