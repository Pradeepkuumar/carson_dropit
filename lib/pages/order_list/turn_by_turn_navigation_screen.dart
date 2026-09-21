import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    hide Marker;
import '../../global/global.dart';
import '../../utils/colors.dart';
import 'turn_by_turn_navigation_controller.dart';

// Full-screen embedded turn-by-turn guidance. Google's Navigation SDK draws
// its own chrome (route line, turn banner, ETA card, recenter button) - this
// screen only adds a back button, since that view has no app-level way to
// exit on its own.
class TurnByTurnNavigationScreen
    extends GetView<TurnByTurnNavigationController> {
  const TurnByTurnNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.errorMessage.value != null) {
            return _errorState(controller.errorMessage.value!);
          }
          return Stack(
            children: [
              if (!controller.isInitializing.value)
                GoogleMapsNavigationView(
                  onViewCreated: controller.onViewCreated,
                  gestureRecognizers: {
                    Factory<EagerGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),

              if (controller.isInitializing.value)
                Container(
                  color: AppColors.backgroundColorMain,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 14.h),
                      utils.tvCustom(
                        "Starting navigation to ${controller.destinationTitle}...",
                        Colors.white,
                        13,
                      ),
                    ],
                  ),
                ),
              Positioned(
                top: 12.h,
                left: 12.w,
                child: InkWell(
                  onTap: controller.exitNavigation,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _errorState(String message) {
    return Container(
      color: AppColors.backgroundColorMain,
      alignment: Alignment.center,
      padding: EdgeInsets.all(28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white.withOpacity(0.7),
            size: 34.sp,
          ),
          SizedBox(height: 14.h),
          utils.tvCustom(message, Colors.white, 14),
          SizedBox(height: 20.h),
          InkWell(
            borderRadius: BorderRadius.circular(24.r),
            onTap: () => Get.back(result: false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
              decoration: BoxDecoration(
                color: AppColors.primaryThemeColor,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: utils.tvCustom("Go back", Colors.white, 14),
            ),
          ),
        ],
      ),
    );
  }
}
