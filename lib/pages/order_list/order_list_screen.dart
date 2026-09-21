import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app_pages/app_pages.dart';
import '../../global/app_bottom_nav.dart';
import '../../global/order_card_widget.dart';
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../utils/colors.dart';
import '../../utils/text_style_util.dart';
import '../my_orders/orders/models/orders_model.dart';
import 'order_list_controller.dart';

class OrderListScreen extends GetView<OrderListController> {
  const OrderListScreen({super.key});

  static const _typeAccents = {
    "b2c": AppColors.primaryThemeColor,
    "c2c": AppColors.blue,
    "whatsapp": Color(0xFF0BA30B),
  };

  Color get _typeAccent => _typeAccents[controller.typeTab.value]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode ? AppColors.black : AppColors.greyColor1,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Obx(() => _buildStatusPills(context)),
                Obx(() => _buildActiveFilterIndicator(context)),
                Expanded(
                  child: Obx(() {
                    if (controller.typeTab.value != "b2c") {
                      return _emptyState(
                        "${controller.typeTab.value == "c2c" ? "C2C" : "WhatsApp"} orders aren't available on this screen yet.",
                      );
                    }
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final orders = controller.currentOrders;
                    if (orders.isEmpty) {
                      return _emptyState("No orders here right now.");
                    }
                    return RefreshIndicator(
                      onRefresh: controller.refreshCurrentTab,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) =>
                            _orderCard(context, orders[index]),
                      ),
                    );
                  }),
                ),
              ],
            ),
            Obx(
              () => controller.filterMenuOpen.value
                  ? _filterMenu(context)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: utils.tvCustom(message, AppColors.greyColor4, 13),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header: title + search/filter buttons + order-type tabs
  // ---------------------------------------------------------------------
  static const _typeLabels = {
    "b2c": "B2C",
    "c2c": "C2C",
    "whatsapp": "WhatsApp",
  };

  Widget _buildHeader(BuildContext context) {
    final isTablet = !context.isPhone;
    // final accent = _typeAccent;
    // final channels = controller.allowedChannels;
    // final tabs = <Widget>[];
    // for (var i = 0; i < channels.length; i++) {
    //   final value = channels[i];
    //   tabs.add(Expanded(
    //       child: _typeTab(
    //           context, _typeLabels[value] ?? value, value, accent)));
    //   if (i != channels.length - 1) tabs.add(SizedBox(width: 2.w));
    // }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        (isTablet ? 32 : 16).w,
        12.h,
        (isTablet ? 32 : 16).w,
        (isTablet ? 20 : 14).h,
      ),
      color: AppColors.backgroundColorMain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => controller.searchOpen.value
                ? _searchBar(context)
                : _titleRow(context, isTablet),
          ),
          SizedBox(height: isTablet ? 18.h : 5.h),
          // Container(
          //   padding: EdgeInsets.all(4.w),
          //   decoration: BoxDecoration(
          //     color: AppColors.backgroundColorLight,
          //     borderRadius: BorderRadius.circular(12.r),
          //   ),
          //   child: Row(children: tabs),
          // ),
        ],
      ),
    );
  }

  Widget _titleRow(BuildContext context, bool isTablet) {
    return Row(
      children: [
        // InkWell(
        //   onTap: () => Get.back(),
        //   borderRadius: BorderRadius.circular(8.r),
        //   child: Padding(
        //     padding: EdgeInsets.only(right: 8.w),
        //     child: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
        //   ),
        // ),
        Expanded(
          child: utils.tvCustom(
            "Orders",
            Colors.white,
            isTablet ? 24 : 16,
            textAlignment: TextAlign.left,
          ),
        ),
        _headerIconButton(context, Icons.search, controller.openSearch),
        SizedBox(width: 10.w),
        _headerIconButton(context, Icons.tune, controller.openFilterMenu),
      ],
    );
  }

  Widget _searchBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: controller.closeSearch,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
          ),
        ),
        Expanded(
          child: Container(
            height: 38.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.centerLeft,
            child: TextField(
              controller: controller.searchController,
              autofocus: true,
              onChanged: controller.updateSearchQuery,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: "Search AWB, merchant, consignee...",
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isTablet = !context.isPhone;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: (isTablet ? 44 : 38).w,
        height: (isTablet ? 44 : 38).w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: (isTablet ? 20 : 18).sp),
      ),
    );
  }

  Widget _typeTab(
    BuildContext context,
    String label,
    String value,
    Color accent,
  ) {
    final isTablet = !context.isPhone;
    final selected = controller.typeTab.value == value;
    final color = selected ? Colors.white : AppColors.whiteFade;
    return InkWell(
      onTap: () => controller.switchType(value),
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: (isTablet ? 11 : 8).h),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.tsCustom(
            color,
            utils.responsiveFontSize(isTablet ? 16 : 14.5),
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Assigned / Available / Completed status pills, with counts
  // ---------------------------------------------------------------------
  Widget _buildStatusPills(BuildContext context) {
    final isTablet = !context.isPhone;
    final accent = _typeAccent;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        (isTablet ? 32 : 16).w,
        14.h,
        (isTablet ? 32 : 16).w,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _statusPill(
              context,
              "Assigned",
              "assigned",
              controller.assignedOrders.length,
              accent,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _statusPill(
              context,
              "Available",
              "available",
              controller.availableOrders.length,
              accent,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _statusPill(context, "Completed", "completed", null, accent),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(
    BuildContext context,
    String label,
    String value,
    int? count,
    Color accent,
  ) {
    final isTablet = !context.isPhone;
    final selected = controller.statusTab.value == value;
    final inactiveColor = Get.isDarkMode
        ? AppColors.greyColor3
        : AppColors.greyColor4;
    final color = selected ? accent : inactiveColor;
    return InkWell(
      onTap: () => controller.switchStatus(value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: (isTablet ? 8 : 6).h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: utils.tvCustom(
                    label,
                    color,
                    isTablet ? 15 : 13,
                    maxLines: 1,
                  ),
                ),
                if (count != null) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(Get.isDarkMode ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: utils.tvCustom(count.toString(), accent, 10.5),
                  ),
                ],
              ],
            ),
            SizedBox(height: (isTablet ? 8 : 6).h),
            Container(
              height: (isTablet ? 3 : 2.5).h,
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Active payment-filter chip (shown below the status pills when a
  // filter other than "All" is applied). Tapping it reopens the menu.
  // ---------------------------------------------------------------------
  static const _filterLabels = {"ppd": "PPD", "cod": "COD", "risk": "At risk"};

  Widget _buildActiveFilterIndicator(BuildContext context) {
    final isTablet = !context.isPhone;
    final typeFilter = controller.serviceTypeFilter.value;
    final paymentFilter = controller.paymentFilter.value;
    if (typeFilter == "all" && paymentFilter == "all") {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        (isTablet ? 32 : 16).w,
        12.h,
        (isTablet ? 32 : 16).w,
        0,
      ),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          if (typeFilter != "all")
            _activeFilterChip(
              _typeLabels[typeFilter] ?? typeFilter,
              _typeAccents[typeFilter] ?? _typeAccent,
              () => controller.switchServiceTypeFilter("all"),
            ),
          if (paymentFilter != "all")
            _activeFilterChip(
              _filterLabels[paymentFilter] ?? "",
              paymentFilter == "risk" ? AppColors.red : _typeAccent,
              () => controller.switchFilter("all"),
            ),
        ],
      ),
    );
  }

  Widget _activeFilterChip(String label, Color accent, VoidCallback onClear) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: accent.withOpacity(Get.isDarkMode ? 0.2 : 0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: controller.openFilterMenu,
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: utils.tvCustom(label, accent, 12),
            ),
          ),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Icon(Icons.close, size: 14.sp, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Filter dropdown, anchored just below the header's filter icon
  // ---------------------------------------------------------------------
  Widget _filterMenu(BuildContext context) {
    final isTablet = !context.isPhone;
    final accent = _typeAccent;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.closeFilterMenu,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: isTablet ? 74.h : 56.h,
          right: isTablet ? 32.w : 16.w,
          child: Container(
            width: isTablet ? 260.w : 228.w,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? AppColors.greyColor10 : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filterSectionLabel("Type"),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _filterChip(
                      "All",
                      controller.serviceTypeFilter.value == "all",
                      AppColors.greyColor5,
                      () => controller.switchServiceTypeFilter("all"),
                    ),
                    for (final type in const ["b2c", "c2c", "whatsapp"])
                      _filterChip(
                        _typeLabels[type]!,
                        controller.serviceTypeFilter.value == type,
                        _typeAccents[type]!,
                        () => controller.switchServiceTypeFilter(type),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                _filterSectionLabel("Payment"),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _filterChip(
                      "All",
                      controller.paymentFilter.value == "all",
                      AppColors.greyColor5,
                      () => controller.switchFilter("all"),
                    ),
                    _filterChip(
                      "PPD",
                      controller.paymentFilter.value == "ppd",
                      accent,
                      () => controller.switchFilter("ppd"),
                    ),
                    _filterChip(
                      "COD",
                      controller.paymentFilter.value == "cod",
                      accent,
                      () => controller.switchFilter("cod"),
                    ),
                    _filterChip(
                      "At risk",
                      controller.paymentFilter.value == "risk",
                      AppColors.red,
                      () => controller.switchFilter("risk"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 6.h),
      child: utils.tvCustom(
        label.toUpperCase(),
        AppColors.greyColor4,
        10,
        textAlignment: TextAlign.left,
      ),
    );
  }

  Widget _filterChip(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected
              ? color
              : color.withOpacity(Get.isDarkMode ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: utils.tvCustom(
          label,
          selected ? Colors.white : color,
          11.5,
          textAlignment: TextAlign.left,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Order card
  // ---------------------------------------------------------------------
  Widget _orderCard(BuildContext context, OrdersData order) {
    final available = controller.statusTab.value == "available";
    final completed = controller.statusTab.value == "completed";
    final atRisk = !completed && controller.isAtRisk(order);
    return OrderCardWidget(
      order: order,
      available: available,
      completed: completed,
      atRisk: atRisk,
      dueInLabel: _dueInLabel(controller.remainingSecondsFor(order)),
      accentColor: _typeAccent,
      isCod: controller.isCod(order),
      onTap: () => Get.toNamed(
        Routes.orderDetailScreen,
        arguments: order,
      )?.then((_) => controller.refreshCurrentTab()),
      onAccept: available ? () => _confirmAccept(order) : null,
      onDecline: available ? () => _confirmDecline(order) : null,
    );
  }

  String _dueInLabel(int remainingSeconds) {
    if (remainingSeconds <= 0) return "Overdue";
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    return hours > 0 ? "${hours}h ${minutes}m left" : "${minutes}m left";
  }

  void _confirmAccept(OrdersData order) {
    utils.simpleDialog(
      "Accept Order",
      "Do you want to accept this order?",
      () {
        controller.acceptRejectOrder(acceptOrder, order.awbNo ?? "");
      },
      () {
        Get.back();
      },
    );
  }

  void _confirmDecline(OrdersData order) {
    utils.simpleDialog(
      "Decline Order",
      "Do you want to decline this order?",
      () {
        controller.acceptRejectOrder(rejectOrder, order.awbNo ?? "");
      },
      () {
        Get.back();
      },
    );
  }
}
