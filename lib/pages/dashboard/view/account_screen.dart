import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app_pages/app_pages.dart';
import '../../../global/app_bottom_nav.dart';
import '../../../global/global.dart';
import '../../../global/rider_avatar.dart';
import '../../../global/update_profile_dialog.dart';
import '../../../utils/colors.dart';
import '../controller/rider_dashboard_controller.dart';

class AccountScreen extends GetView<RiderDashboardController> {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = !context.isPhone;
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final cardBg = isDark ? AppColors.greyColor10 : Colors.white;
      return Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.greyColor1,
        bottomNavigationBar: const AppBottomNav(currentIndex: 3),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    horizontal: (isTablet ? 32 : 16).w, vertical: 14.h),
                color: AppColors.backgroundColorMain,
                child: Row(
                  children: [
                    // InkWell(
                    //   onTap: () => Get.back(),
                    //   borderRadius: BorderRadius.circular(8.r),
                    //   child: Padding(
                    //     padding: EdgeInsets.only(right: 10.w),
                    //     child:
                    //         Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
                    //   ),
                    // ),
                    utils.tvCustom("Account", Colors.white, isTablet ? 22 : 16,
                        textAlignment: TextAlign.left),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all((isTablet ? 32 : 16).w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileCard(context, cardBg, isDark),
                      SizedBox(height: 14.h),
                      _settingsCard(context, cardBg, isDark),
                      SizedBox(height: 14.h),
                      _menuRow(
                        cardBg: cardBg,
                        isDark: isDark,
                        icon: Icons.support_agent_outlined,
                        iconColor: AppColors.greenLight,
                        label: "Support",
                        onTap: () {},
                      ),
                      SizedBox(height: 14.h),
                      _menuRow(
                        cardBg: cardBg,
                        isDark: isDark,
                        icon: Icons.logout,
                        iconColor: AppColors.red,
                        labelColor: AppColors.red,
                        label: "Logout",
                        showChevron: false,
                        onTap: () async {
                          bool isLoggedOut = await controller.logout();
                          if (isLoggedOut) {
                            utils.simpleDialog(
                                "Do you want to Logout from app?", "",
                                () async {
                              var loggedOut = await controller.logout();
                              if (loggedOut) {
                                userRepository.deleteUser();
                                Get.offAllNamed(Routes.auth);
                              }
                            }, () {
                              Get.back();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _profileCard(BuildContext context, Color cardBg, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: showUpdateProfileDialog,
              borderRadius: BorderRadius.circular(15.r),
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryThemeColor.withOpacity(isDark ? 0.2 : 0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.edit_outlined,
                    color: AppColors.primaryThemeColor, size: 14.sp),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  buildRiderAvatar(
                    controller: controller,
                    radius: 28.r,
                    backgroundColor: AppColors.primaryThemeColor.withOpacity(0.14),
                    fallback: Obx(() => utils.tvCustom(
                        controller.riderName.value.isNotEmpty
                            ? controller.riderName.value[0].toUpperCase()
                            : "R",
                        AppColors.primaryThemeColor,
                        22)),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        utils.tvCustom(controller.userData.name ?? "",
                            AppColors.black, 16,
                            textAlignment: TextAlign.left, maxLines: 1),
                        SizedBox(height: 3.h),
                        utils.tvCustom(controller.userData.email ?? "",
                            AppColors.greyColor5, 12.5,
                            textAlignment: TextAlign.left, maxLines: 1),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryThemeColor.withOpacity(isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.primaryThemeColor, size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Obx(() => utils.tvCustom(
                          "QAR ${controller.walletAmount.value}",
                          AppColors.primaryThemeColor,
                          13,
                          textAlignment: TextAlign.left)),
                    ),
                    utils.tvCustom("WALLET", AppColors.primaryThemeColor, 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context, Color cardBg, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: AppColors.greyColor4.withOpacity(isDark ? 0.2 : 0.14),
                borderRadius: BorderRadius.circular(9.r),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.settings_outlined,
                  color: isDark ? Colors.white : AppColors.greyColor5,
                  size: 17.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: utils.tvCustom("Theme", AppColors.black, 13.5,
                  textAlignment: TextAlign.left),
            ),
            _themeToggle(isDark),
          ],
        ),
      ),
    );
  }

  Widget _themeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : AppColors.greyColor1,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _themeOption(
            icon: Icons.light_mode_outlined,
            label: "Light",
            selected: !isDark,
            isDark: isDark,
            onTap: () => controller.setThemeMode(false),
          ),
          _themeOption(
            icon: Icons.dark_mode_outlined,
            label: "Dark",
            selected: isDark,
            isDark: isDark,
            onTap: () => controller.setThemeMode(true),
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required IconData icon,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryThemeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(17.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13.sp,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white54 : AppColors.greyColor4)),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white54 : AppColors.greyColor4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuRow({
    required Color cardBg,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    Color labelColor = AppColors.black,
    bool showChevron = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDark ? 0.2 : 0.10),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 17.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: utils.tvCustom(label, labelColor, 13.5,
                    textAlignment: TextAlign.left),
              ),
              if (showChevron)
                Icon(Icons.chevron_right,
                    color: isDark ? AppColors.greyColor4 : const Color(0xFFC7C7C7),
                    size: 18.sp),
            ],
          ),
        ),
      ),
    );
  }
}
