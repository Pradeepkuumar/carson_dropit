import 'package:carson_zyppy/app_pages/app_pages.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:carson_zyppy/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../global/consts.dart';
import '../global/global.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreesState createState() => _SplashScreesState();
}

class _SplashScreesState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await userRepository.getUser();
    if (!mounted) return;
    // Navigate via GetX's named routes (instead of returning a page widget
    // directly from build()) so RiderDashboardBinding actually runs and
    // RiderDashboardController is registered before any dashboard-family
    // screen builds - notably needed for cold starts (killed app opened via
    // a push notification), where AppBottomNav's Obx would otherwise build
    // before the controller exists and throw GetX's "improper use" error.
    Get.offAllNamed(user?.code != null ? Routes.riderDashBord : Routes.auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColorMain,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: GeometricBackgroundPainter()),
          ),
          SafeArea(
            child: Center(
              child: SizedBox(
                height: 110,
                width: 200,
                child: Image.asset(appLogo, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
