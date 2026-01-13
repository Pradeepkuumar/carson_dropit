import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/auth/login_screen.dart';
import 'package:carson_zyppy/pages/dashboard/view/rider_dashboard.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../global/consts.dart';
import '../global/global.dart';
import '../utils/bio_metric_login/biometric_login.dart';

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
    Future.delayed(const Duration(seconds: 6), () {
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
      return Scaffold(
        body: SafeArea(
          child: SizedBox(
            height: Get.height,
           width: Get.width,
            child: Center(
              child: SizedBox(
                height: 200,
                width: Get.width - 50,
                child: Lottie.asset(ANIM_LOGO),
              ),
            ),
          ),
        ),
      );
    } else {

      if (user.code == null) {
        return const LoginScreen();
      } else if (user.code != null) {
      //  Get.to(()=>  BiometricLockScreen().authenticate(
      //     localizedReason: 'Please authenticate to proceed',
      //     biometricOnly: true,
      //     stickyAuth: false,
      //     sensitiveTransaction: true,
      //     useErrorDialogs: true,
      //   ).then((authenticated) {
      //     if (authenticated) {
            
      //     } else {
      //       utils.errorSnackBar("Authentication Failed", "Unable to authenticate using biometrics.");
      //        return const RiderDashboard();
      //     }
      //   }));
        return const RiderDashboard();
      }else{
        return const SplashScreen();
      }
    }
  }
}
