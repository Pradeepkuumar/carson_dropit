import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app_pages/app_pages.dart';
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../utils/colors.dart';
import '../my_orders/orders/models/orders_model.dart';
import 'order_list_controller.dart';

const Color _amberOFD = Color(0xFFA67C00);

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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Obx(() => _buildHeader(context)),
                Obx(() => _buildStatusPills(context)),
                Obx(() => _buildActiveFilterIndicator(context)),
                Expanded(
                  child: Obx(() {
                    if (controller.typeTab.value != "b2c") {
                      return _emptyState(
                          "${controller.typeTab.value == "c2c" ? "C2C" : "WhatsApp"} orders aren't available on this screen yet.");
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
            Obx(() => controller.filterMenuOpen.value
                ? _filterMenu(context)
                : const SizedBox.shrink()),
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
  Widget _buildHeader(BuildContext context) {
    final isTablet = !context.isPhone;
    final accent = _typeAccent;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB((isTablet ? 32 : 16).w, 12.h,
          (isTablet ? 32 : 16).w, (isTablet ? 20 : 14).h),
      color: AppColors.backgroundColorMain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => controller.searchOpen.value
              ? _searchBar(context)
              : _titleRow(context, isTablet)),
          SizedBox(height: isTablet ? 18.h : 14.h),
          Row(
            children: [
              Expanded(child: _typeTab(context, "B2C", "b2c", accent)),
              SizedBox(width: 8.w),
              Expanded(child: _typeTab(context, "C2C", "c2c", accent)),
              SizedBox(width: 8.w),
              Expanded(
                  child: _typeTab(context, "WhatsApp", "whatsapp", accent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _titleRow(BuildContext context, bool isTablet) {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
          ),
        ),
        Expanded(
          child: utils.tvCustom("Orders", Colors.white, isTablet ? 24 : 20,
              textAlignment: TextAlign.left),
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
      BuildContext context, IconData icon, VoidCallback onTap) {
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

  Widget _typeTab(BuildContext context, String label, String value, Color accent) {
    final isTablet = !context.isPhone;
    final selected = controller.typeTab.value == value;
    return InkWell(
      onTap: () => controller.switchType(value),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: (isTablet ? 12 : 9).h),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: utils.tvCustom(
            label, selected ? Colors.white : AppColors.black, 12.5),
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
          (isTablet ? 32 : 16).w, 14.h, (isTablet ? 32 : 16).w, 0),
      child: Row(
        children: [
          Expanded(
              child: _statusPill(context, "Assigned", "assigned",
                  controller.assignedOrders.length, accent)),
          SizedBox(width: 8.w),
          Expanded(
              child: _statusPill(context, "Available", "available",
                  controller.availableOrders.length, accent)),
          SizedBox(width: 8.w),
          Expanded(
              child:
                  _statusPill(context, "Completed", "completed", null, accent)),
        ],
      ),
    );
  }

  Widget _statusPill(
      BuildContext context, String label, String value, int? count, Color accent) {
    final isTablet = !context.isPhone;
    final selected = controller.statusTab.value == value;
    return InkWell(
      onTap: () => controller.switchStatus(value),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: (isTablet ? 13 : 10).h),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : (Get.isDarkMode ? AppColors.greyColor10 : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            utils.tvCustom(
                label,
                selected
                    ? Colors.white
                    : (Get.isDarkMode ? Colors.white : AppColors.black),
                13),
            if (count != null) ...[
              SizedBox(width: 6.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.25)
                      : accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: utils.tvCustom(
                    count.toString(), selected ? Colors.white : accent, 10.5),
              ),
            ],
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
    final filter = controller.paymentFilter.value;
    if (filter == "all") return const SizedBox.shrink();
    final accent = filter == "risk" ? AppColors.red : _typeAccent;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          (isTablet ? 32 : 16).w, 12.h, (isTablet ? 32 : 16).w, 0),
      child: Container(
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
                child: utils.tvCustom(_filterLabels[filter] ?? "", accent, 12),
              ),
            ),
            InkWell(
              onTap: () => controller.switchFilter("all"),
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(Icons.close, size: 14.sp, color: accent),
              ),
            ),
          ],
        ),
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
            width: 168.w,
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? AppColors.greyColor10 : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _filterMenuRow("All", "all", accent),
                _filterMenuRow("PPD", "ppd", accent),
                _filterMenuRow("COD", "cod", accent),
                _filterMenuRow("At risk", "risk", AppColors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterMenuRow(String label, String value, Color color) {
    final selected = controller.paymentFilter.value == value;
    return InkWell(
      onTap: () => controller.switchFilter(value),
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(Get.isDarkMode ? 0.2 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            utils.tvCustom(label, selected ? color : AppColors.greyColor5, 13),
            if (selected) Icon(Icons.check, color: color, size: 15.sp),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Order card
  // ---------------------------------------------------------------------
  Widget _orderCard(BuildContext context, OrdersData order) {
    final isTablet = !context.isPhone;
    final available = controller.statusTab.value == "available";
    final completed = controller.statusTab.value == "completed";
    final atRisk = !completed && controller.isAtRisk(order);
    final cardBg = Get.isDarkMode ? AppColors.greyColor10 : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Get.toNamed(Routes.orderDetailScreen, arguments: order)
          ?.then((_) => controller.refreshCurrentTab()),
      child: Container(
      padding: EdgeInsets.all((isTablet ? 18 : 14).w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: available
            ? Border.all(color: _typeAccent.withOpacity(0.35), width: 1.5)
            : (Get.isDarkMode
                ? Border.all(color: Colors.white.withOpacity(0.08))
                : null),
        boxShadow: Get.isDarkMode
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: (isTablet ? 46 : 38).w,
                height: (isTablet ? 46 : 38).w,
                decoration: BoxDecoration(
                  color: _typeAccent.withOpacity(Get.isDarkMode ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.inventory_2_outlined,
                    color: _typeAccent, size: (isTablet ? 22 : 19).sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: utils.tvCustom(
                              order.awbNo ?? order.orderRefNumber ?? "-",
                              AppColors.black,
                              13.5,
                              textAlignment: TextAlign.left,
                              maxLines: 1),
                        ),
                        if ((order.status ?? "").isNotEmpty) ...[
                          SizedBox(width: 6.w),
                          _statusBadge(order.status!),
                        ],
                      ],
                    ),
                    SizedBox(height: 1.h),
                    utils.tvCustom(
                        (order.consigneeName?.isNotEmpty ?? false)
                            ? order.consigneeName!
                            : (order.merchantName ?? ""),
                        AppColors.greyColor4,
                        12,
                        textAlignment: TextAlign.left,
                        maxLines: 1),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 16.w,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 3.h),
                        child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                                color: AppColors.greenLight,
                                shape: BoxShape.circle)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          child: Container(
                              width: 1.5, color: const Color(0xFFE0E0E0)),
                        ),
                      ),
                      Icon(Icons.location_on,
                          color: AppColors.primaryThemeColor, size: 14.sp),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      utils.tvCustom(
                          order.pickupLocationName ?? order.pickupAddress ?? "-",
                          AppColors.greyColor10,
                          11.5,
                          textAlignment: TextAlign.left,
                          maxLines: 2),
                      SizedBox(height: 10.h),
                      utils.tvCustom(order.consigneeAddress ?? "-",
                          AppColors.greyColor10, 11.5,
                          textAlignment: TextAlign.left, maxLines: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.social_distance,
                      color: AppColors.greyColor4, size: 13.sp),
                  SizedBox(width: 4.w),
                  utils.tvCustom(order.distance ?? "-", AppColors.greyColor4, 11),
                ],
              ),
              _paymentBadge(order),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time,
                      color: completed
                          ? AppColors.greyColor4
                          : (atRisk ? AppColors.red : AppColors.greyColor10),
                      size: 13.sp),
                  SizedBox(width: 4.w),
                  utils.tvCustom(
                      completed
                          ? "Delivered"
                          : _dueInLabel(controller.remainingSecondsFor(order)),
                      completed
                          ? AppColors.greyColor4
                          : (atRisk ? AppColors.red : AppColors.greyColor10),
                      11),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((order.sla_in_hours ?? "").isNotEmpty) ...[
                    utils.tvCustom(
                        "${order.sla_in_hours}h SLA", AppColors.greyColor4, 10.5),
                    SizedBox(width: 6.w),
                  ],
                  Icon(Icons.chevron_right,
                      color: const Color(0xFFC7C7C7), size: 18.sp),
                ],
              ),
            ],
          ),
          if (available) ...[
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmDecline(order),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: utils.tvCustom("Decline", AppColors.black, 13),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmAccept(order),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      backgroundColor: AppColors.primaryThemeColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: utils.tvCustom("Accept order", Colors.white, 13),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  // Same status -> color mapping already used in orders_item.dart.
  Color _statusColor(String status) {
    switch (status) {
      case ASSIGNED:
      case RE_ASSIGNED:
        return AppColors.linkColor;
      case PICKED:
        return AppColors.blue;
      case OFD:
        return _amberOFD;
      case PLACED:
      case DELIVERED:
        return AppColors.greenLight;
      case UNDELIVERED:
        return AppColors.red;
      default:
        return AppColors.primaryThemeColor;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: utils.tvCustom(status, color, 9, textAlignment: TextAlign.left),
    );
  }

  Widget _paymentBadge(OrdersData order) {
    final isCod = controller.isCod(order);
    final color = isCod ? _amberOFD : AppColors.greenLight;
    final label = isCod
        ? "COD · QAR ${order.orderAmount ?? '0'}"
        : "${(order.paymentType ?? "").isNotEmpty ? "${order.paymentType} · " : ""}Paid";
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: utils.tvCustom(label, color, 10.5, textAlignment: TextAlign.left),
    );
  }

  String _dueInLabel(int remainingSeconds) {
    if (remainingSeconds <= 0) return "Overdue";
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    return hours > 0 ? "${hours}h ${minutes}m left" : "${minutes}m left";
  }

  void _confirmAccept(OrdersData order) {
    utils.simpleDialog("Accept Order", "Do you want to accept this order?",
        () {
      controller.acceptRejectOrder(acceptOrder, order.awbNo ?? "");
    }, () {
      Get.back();
    });
  }

  void _confirmDecline(OrdersData order) {
    utils.simpleDialog("Decline Order", "Do you want to decline this order?",
        () {
      controller.acceptRejectOrder(rejectOrder, order.awbNo ?? "");
    }, () {
      Get.back();
    });
  }
}
