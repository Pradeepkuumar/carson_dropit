import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../pages/dashboard/controller/rider_dashboard_controller.dart';
import '../utils/colors.dart';
import 'global.dart';
import 'rider_avatar.dart';

// Runs as a Get.dialog (global overlay) rather than an in-tree Visibility,
// so it works no matter which screen is on top - the Account screen and
// the dashboard's own header both call this the same way.
void showUpdateProfileDialog() {
  final controller = Get.find<RiderDashboardController>();
  Get.dialog(
    _UpdateProfileDialog(initialAvatar: controller.avatar.value),
    barrierDismissible: false,
  );
}

// Photo-only update: phone and address are not editable here, but
// updateProfileDetails() still sends their saved values unchanged.
class _UpdateProfileDialog extends StatelessWidget {
  const _UpdateProfileDialog({required this.initialAvatar});

  // Avatar file as it was when the dialog opened, so Cancel can undo an
  // unsaved pick and Save only enables once a new photo is chosen.
  final File? initialAvatar;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RiderDashboardController>();
    final isDark = Get.isDarkMode;
    final isPhone = context.isPhone;
    final cardBg = isDark ? AppColors.greyColor10 : AppColors.white;

    void cancel() {
      controller.avatar.value = initialAvatar;
      Get.back();
    }

    return Dialog(
      backgroundColor: cardBg,
      surfaceTintColor: AppColors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: isPhone ? double.infinity : 460.w),
        child: SingleChildScrollView(
          padding: EdgeInsets.all((isPhone ? 18 : 24).w),
          child: Form(
            key: controller.profileFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(isDark, cancel),
                SizedBox(height: 18.h),
                _avatarBlock(controller, isDark, isPhone, cardBg),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: _sourceButton(
                        isDark: isDark,
                        icon: Icons.photo_library_outlined,
                        label: "Gallery",
                        onTap: controller.pickAvatar,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _sourceButton(
                        isDark: isDark,
                        icon: Icons.camera_alt_outlined,
                        label: "Camera",
                        onTap: controller.pickAvatarFromCamera,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _actions(controller, isDark, cancel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool isDark, VoidCallback onClose) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              utils.tvCustom("Update Photo", AppColors.black, 17,
                  textAlignment: TextAlign.left),
              SizedBox(height: 3.h),
              utils.tvCustom("Choose a clear photo of your face",
                  AppColors.greyColor5, 11.5,
                  textAlignment: TextAlign.left),
            ],
          ),
        ),
        InkWell(
          onTap: onClose,
          customBorder: const CircleBorder(),
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.white.withOpacity(0.08)
                  : AppColors.greyColor1,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.close,
                size: 15.sp,
                color: isDark ? AppColors.white : AppColors.black),
          ),
        ),
      ],
    );
  }

  Widget _avatarBlock(RiderDashboardController controller, bool isDark,
      bool isPhone, Color cardBg) {
    final radius = (isPhone ? 44 : 56).r;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            buildRiderAvatar(
              controller: controller,
              radius: radius,
              backgroundColor: AppColors.primaryThemeColor.withOpacity(0.14),
              fallback: utils.tvCustom(
                  controller.riderName.value.isNotEmpty
                      ? controller.riderName.value[0].toUpperCase()
                      : "R",
                  AppColors.primaryThemeColor,
                  isPhone ? 30 : 34),
            ),
            Positioned(
              right: -2.w,
              bottom: -2.w,
              child: InkWell(
                onTap: controller.showImageSourceDialog,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryThemeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.camera_alt,
                      color: AppColors.white, size: 13.sp),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        utils.tvCustom(controller.userData.name ?? "", AppColors.black, 15,
            maxLines: 1),
        SizedBox(height: 3.h),
        Obx(() => controller.avatar.value != initialAvatar
            ? utils.tvCustom("New photo selected", AppColors.greenLight, 11.5)
            : utils.tvCustom(
                controller.userData.email ?? "", AppColors.greyColor5, 11.5,
                maxLines: 1)),
      ],
    );
  }

  Widget _sourceButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.white.withOpacity(0.06) : AppColors.greyColor1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
            color: isDark
                ? AppColors.white.withOpacity(0.12)
                : AppColors.greyColor2.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.white.withOpacity(0.08)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon,
                    size: 15.sp, color: AppColors.primaryThemeColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: utils.tvCustom(label, AppColors.black, 13,
                    textAlignment: TextAlign.left, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(
      RiderDashboardController controller, bool isDark, VoidCallback cancel) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r));
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46.h,
            child: OutlinedButton(
              onPressed: cancel,
              style: OutlinedButton.styleFrom(
                shape: shape,
                side: BorderSide(
                    color: isDark
                        ? AppColors.white.withOpacity(0.2)
                        : AppColors.greyColor2),
              ),
              child: utils.tvCustom("Cancel", AppColors.greyColor5, 13.5),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: SizedBox(
            height: 46.h,
            child: Obx(() {
              final hasNewPhoto = controller.avatar.value != initialAvatar;
              return ElevatedButton(
                onPressed: hasNewPhoto
                    ? () async {
                        bool success = await controller.updateProfileDetails();
                        if (success) Get.back();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: shape,
                  backgroundColor: AppColors.primaryThemeColor,
                  disabledBackgroundColor:
                      AppColors.primaryThemeColor.withOpacity(0.4),
                ),
                child: utils.tvCustom("Save photo", AppColors.white, 13.5),
              );
            }),
          ),
        ),
      ],
    );
  }
}