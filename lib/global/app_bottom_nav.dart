import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../app_pages/app_pages.dart';
import '../pages/dashboard/controller/rider_dashboard_controller.dart';
import '../pages/order_list/order_list_controller.dart';
import '../utils/colors.dart';
import 'global.dart';

// Same Home/Order/Active Order/Account bar RiderDashboard shows, reused on
// its sibling screens (Order List, Active Delivery) so it stays visible
// there too instead of disappearing behind the pushed route.
class AppBottomNav extends StatelessWidget {
  final int currentIndex; // 0 Home, 1 Order, 2 Active Order, 3 Account

  const AppBottomNav({super.key, required this.currentIndex});

  RiderDashboardController? get _dashboardController =>
      Get.isRegistered<RiderDashboardController>()
      ? Get.find<RiderDashboardController>()
      : null;

  void _openTab(int index) {
    if (index == currentIndex) return;
    // Pop every screen pushed on top of the dashboard first, so the stack
    // stays [dashboard, target] no matter which tab this bar was tapped
    // from, instead of stacking tabs on top of each other. Matching on
    // route.isFirst (not settings.name == Routes.riderDashBord) because the
    // dashboard isn't always reached via that named route - on an app
    // restart with an existing session, SplashScreen returns RiderDashboard
    // directly as a widget instead of navigating to it, so its route never
    // carries that name; popUntil with a predicate that never matches empties
    // the whole stack instead of stopping at the dashboard.
    Get.until((route) => route.isFirst);
    switch (index) {
      case 0:
        _dashboardController?.getDashBoardData();
        _dashboardController?.getNextDelivery();
        _dashboardController?.fetchAvailableOrders();
        _dashboardController?.fetchWalletAmount();
        break;
      case 1:
        if (Get.isRegistered<OrderListController>()) {
          Get.find<OrderListController>().getDriverConfig();
        }
        Get.toNamed(Routes.orderListScreen);
        break;
      case 2:
        // ActiveDeliveryController fetches its own assigned orders and has
        // a proper empty state (noOrdersAvailable) - unlike allOrdersMapScreen,
        // which has no graceful handling when it finds zero orders and just
        // pops itself. See rider_dashboard.dart's own Active Order tap for
        // the same fix.
        Get.toNamed(Routes.activeDeliveryScreen);
        break;
      case 3:
        _dashboardController?.getUserData();
        _dashboardController?.fetchWalletAmount();
        Get.toNamed(Routes.accountScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = !context.isPhone;
    final controller = _dashboardController;
    Widget buildBar(bool showActiveBadge) {
      final isDark = controller?.isDarkMode.value ?? Get.isDarkMode;
      final navBg = isDark ? AppColors.greyColor10 : Colors.white;
      return Container(
        padding: EdgeInsets.fromLTRB(
          6,
          isTablet ? 16.h : 10.h,
          6,
          isTablet ? 16.h : 14.h,
        ),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isTablet ? 26.r : 20.r),
          ),
          border: isDark
              ? Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))
              : null,
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                context,
                icon: Icons.home_outlined,
                label: "Home",
                selected: currentIndex == 0,
                isDark: isDark,
                onTap: () => _openTab(0),
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.inventory_2_outlined,
                label: "Order",
                selected: currentIndex == 1,
                isDark: isDark,
                onTap: () => _openTab(1),
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.two_wheeler,
                label: "Active Order",
                selected: currentIndex == 2,
                showBadge: showActiveBadge,
                isDark: isDark,
                onTap: () => _openTab(2),
              ),
            ),
            Expanded(
              child: _navItem(
                context,
                icon: Icons.person_outline,
                label: "Account",
                selected: currentIndex == 3,
                isDark: isDark,
                onTap: () => _openTab(3),
              ),
            ),
          ],
        ),
      );
    }

    return controller == null
        ? buildBar(false)
        : Obx(() => buildBar(controller.isAnyActiveOrder.value));
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    final isTablet = !context.isPhone;
    final inactiveColor = isDark ? AppColors.greyColor3 : AppColors.greyColor4;
    final color = selected ? AppColors.primaryThemeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 56.w : 44.w,
              height: isTablet ? 34.h : 28.h,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryThemeColor.withOpacity(
                        isDark ? 0.16 : 0.10,
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: (isTablet ? 26 : 21).sp, color: color),
                  if (showBadge)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.greyColor10
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            utils.tvCustom(label, color, isTablet ? 12.5 : 10.5, maxLines: 1),
          ],
        ),
      ),
    );
  }
}
