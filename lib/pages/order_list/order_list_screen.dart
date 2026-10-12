import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: AppColors.backgroundColorMain),
      child: Scaffold(
        backgroundColor: Get.isDarkMode ? AppColors.black : AppColors.greyColor1,
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context),
                  Obx(() => _buildStatusPills(context)),
                  Obx(() => _buildActiveFilterIndicator(context)),
                  Expanded(
                    child: TabBarView(
                      controller: controller.tabController,
                      children: [
                        for (final status in OrderListController.statuses)
                          _buildOrderList(context, status),
                      ],
                    ),
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
        ),
    );
  }

  // One page of the status TabBarView - renders the already-fetched list for
  // [status]; switching tabs never triggers an API call.
  Widget _buildOrderList(BuildContext context, String status) {
    // RefreshIndicator stays mounted across loading/empty/list states - if it
    // were swapped out mid-pull (e.g. for the loading spinner), the pull
    // gesture would be cut off.
    return RefreshIndicator(
      onRefresh: () => controller.refreshTab(status),
      child: Obx(() {
        if (controller.typeTab.value != "b2c") {
          return _emptyState(
            "${controller.typeTab.value == "c2c" ? "C2C" : "WhatsApp"} orders aren't available on this screen yet.",
          );
        }
        final orders = controller.ordersFor(status);
        // Full-page spinner only for the first load; on pull-to-refresh the
        // existing list stays visible under the RefreshIndicator's spinner.
        if (controller.loadingFor(status).value && orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (orders.isEmpty) {
          return _emptyState("No orders here right now.");
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 20.h),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) =>
              _orderCard(context, orders[index], status),
        );
      }),
    );
  }

  // Scrollable (always) and filling the viewport, so an empty tab can still
  // be pulled down to refresh.
  Widget _emptyState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: utils.tvCustom(message, AppColors.greyColor4, 13),
              ),
            ),
          ),
        ],
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
      // Header extends up behind the status bar (body SafeArea has
      // top: false), so the status bar strip is navy on edge-to-edge Android.
      padding: EdgeInsets.fromLTRB(
        (isTablet ? 32 : 16).w,
        MediaQuery.paddingOf(context).top + 12.h,
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
      // TabBar is driven by controller.tabController, which is shared with
      // the TabBarView below - so tapping a label and swiping the list stay
      // in sync, and the indicator follows the swipe.
      child: TabBar(
        controller: controller.tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: accent, width: (isTablet ? 3 : 2.5).h),
          borderRadius: BorderRadius.circular(2.r),
        ),
        tabs: [
          _statusPill(
            context,
            "Assigned",
            "assigned",
            controller.assignedOrders.length,
            accent,
          ),
          _statusPill(
            context,
            "Available",
            "available",
            controller.availableOrders.length,
            accent,
          ),
          _statusPill(context, "Completed", "completed", null, accent),
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: (isTablet ? 14 : 11).h),
      child: Row(
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
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: accent.withOpacity(Get.isDarkMode ? 0.22 : 0.14),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: utils.tvCustom(count.toString(), accent, 10.5),
            ),
          ],
        ],
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
          top: MediaQuery.paddingOf(context).top + (isTablet ? 74.h : 56.h),
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
  Widget _orderCard(BuildContext context, OrdersData order, String status) {
    final available = status == "available";
    final completed = status == "completed";
    final atRisk = controller.isAtRisk(order, status);
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
      // Order status can change in detail (e.g. delivered), moving it to
      // another tab - refresh all cached lists, not just this one.
      )?.then((_) => controller.refreshAllTabs()),
      onAccept: available ? () => _confirmAccept(order) : null,
      onDecline: available ? () => _confirmDecline(order) : null,
      onDropback: (completed && order.status == UNDELIVERED)
          ? () => _openDropbackSheet(context, order)
          : null,
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

  // ---------------------------------------------------------------------
  // Return (dropback) sheet - undelivered orders in Completed tab, returned
  // either to the merchant (DROPBACK_ML) or the warehouse (DROPBACK_CLW)
  // ---------------------------------------------------------------------

  // Section label with a red required "*". The star bypasses tvCustom so it
  // stays red in dark mode, where tvCustom would force it white.
  Widget _requiredLabel(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        utils.tvCustom(label, AppColors.black, 13, textAlignment: TextAlign.left),
        Text(
          " *",
          style: AppTextStyle.tsCustom(
            AppColors.red,
            utils.responsiveFontSize(13.sp),
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _dropbackTargetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const accent = AppColors.primaryThemeColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(Get.isDarkMode ? 0.16 : 0.06)
              : (Get.isDarkMode
                    ? Colors.white.withOpacity(0.06)
                    : AppColors.greyColor1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(Get.isDarkMode ? 0.22 : 0.10),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 16.sp),
                ),
                const Spacer(),
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accent : Colors.transparent,
                    border: Border.all(
                      color: selected ? accent : AppColors.greyColor2,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(height: 6.h),
            utils.tvCustom(
              title,
              AppColors.black,
              12,
              textAlignment: TextAlign.left,
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: 2.h),
              utils.tvCustom(
                subtitle,
                AppColors.greyColor5,
                10,
                textAlignment: TextAlign.left,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDropbackSheet(BuildContext context, OrdersData order) {
    controller.resetDropbackState();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 20.h),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? AppColors.greyColor10 : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.greyColor2,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            utils.tvCustom(
              "Return order",
              AppColors.black,
              16,
              textAlignment: TextAlign.left,
            ),
            SizedBox(height: 2.h),
            utils.tvCustom(
              order.awbNo ?? order.orderRefNumber ?? "-",
              AppColors.greyColor5,
              12,
              textAlignment: TextAlign.left,
            ),
            SizedBox(height: 14.h),
            _requiredLabel("Return to"),
            SizedBox(height: 8.h),
            GetBuilder<OrderListController>(
              builder: (_) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dropbackTargetOption(
                      icon: Icons.storefront_outlined,
                      title: "Merchant",
                      subtitle: [
                        order.merchantName,
                        order.pickupLocationName ?? order.pickupAddress,
                      ].where((s) => (s ?? "").isNotEmpty).join(" · "),
                      selected: controller.isDropbackToMerchant,
                      onTap: () => controller.selectDropbackTarget("merchant"),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _dropbackTargetOption(
                      icon: Icons.warehouse_outlined,
                      title: "Warehouse",
                      subtitle: "Drop at the hub",
                      selected: !controller.isDropbackToMerchant,
                      onTap: () =>
                          controller.selectDropbackTarget("warehouse"),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            GetBuilder<OrderListController>(
              builder: (_) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel("Proof photo"),
                      SizedBox(height: 8.h),
                      SizedBox(
                        width: 120.w,
                        child: _dropbackTile(
                          icon: Icons.camera_alt_outlined,
                          label: controller.isDropbackToMerchant
                              ? "Merchant photo"
                              : "Warehouse photo",
                          captured: controller.dropbackPhoto != null,
                          onTap: controller.captureDropbackPhoto,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 14.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      utils.tvCustom(
                        "Signature (optional)",
                        AppColors.black,
                        13,
                        textAlignment: TextAlign.left,
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        width: 120.w,
                        child: _dropbackTile(
                          icon: Icons.edit_outlined,
                          label: "Signature",
                          captured: controller.dropbackSignatureFile != null,
                          onTap: () => _openDropbackSignatureSheet(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            GetBuilder<OrderListController>(
              builder: (_) {
                final missingPhoto = controller.dropbackPhoto == null;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Says what's still needed while the button is disabled;
                    // the signature is optional, so it's never mentioned.
                    if (missingPhoto) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(
                            Get.isDarkMode ? 0.16 : 0.06,
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.red,
                              size: 14.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: utils.tvCustom(
                                "Add a ${controller.isDropbackToMerchant ? "merchant" : "warehouse"} proof photo to continue",
                                AppColors.red,
                                10.5,
                                textAlignment: TextAlign.left,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: missingPhoto
                            ? null
                            : () async {
                                Get.back();
                                await controller.confirmDropback(order);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryThemeColor,
                          disabledBackgroundColor: AppColors.primaryThemeColor
                              .withOpacity(0.4),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                        ),
                        child: utils.tvCustom(
                          controller.isDropbackToMerchant
                              ? "Return to merchant"
                              : "Drop at warehouse",
                          Colors.white,
                          14.5,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openDropbackSignatureSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? AppColors.greyColor10 : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            utils.tvCustom("Signature", AppColors.black, 16),
            SizedBox(height: 12.h),
            Container(
              height: 220.h,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyColor2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Signature(
                controller: controller.dropbackSignatureController,
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.clearDropbackSignature,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: const BorderSide(
                        color: AppColors.primaryThemeColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    child: utils.tvCustom(
                      "Clear",
                      AppColors.primaryThemeColor,
                      14,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await controller.captureDropbackSignature();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryThemeColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    child: utils.tvCustom("Save", Colors.white, 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _dropbackTile({
    required IconData icon,
    required String label,
    required bool captured,
    required VoidCallback onTap,
  }) {
    final color = captured ? AppColors.greenLight : AppColors.greyColor4;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: captured
                ? AppColors.greenLight.withOpacity(0.5)
                : (Get.isDarkMode
                      ? Colors.white.withOpacity(0.25)
                      : AppColors.greyColor2),
            width: 1.4,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              captured ? Icons.check_circle : icon,
              color: color,
              size: 20.sp,
            ),
            SizedBox(height: 8.h),
            utils.tvCustom(
              label,
              AppColors.greyColor5,
              10.5,
              textAlignment: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
