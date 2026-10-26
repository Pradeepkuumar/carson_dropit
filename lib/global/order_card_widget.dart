import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'consts.dart';
import 'global.dart';
import 'value_window_strip.dart';
import '../pages/my_orders/orders/models/orders_model.dart';
import '../utils/colors.dart';

// Shared by OrderListScreen's "available" tab and RiderDashboard's
// "New Requests" section, so the two can never visually drift apart - same
// fields, same badges, same Accept/Decline buttons. Pass `width` to use it
// in a horizontal scroller; leave it null to fill its parent (vertical list).
class OrderCardWidget extends StatelessWidget {
  final OrdersData order;
  final bool available;
  final bool completed;
  final bool atRisk;
  final String dueInLabel;
  final Color accentColor;
  final bool isCod;
  final double? width;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onDropback;
  // Set only for the first card in the order list's Assigned tab - shows
  // the "UP NEXT" label and a footer with a "Go to delivery" button.
  final VoidCallback? onGoToDelivery;
  // Re-fetches the list when a value order's time window opens - pass a
  // method tear-off (see ValueWindowStrip.onWindowOpen).
  final void Function()? onWindowOpen;
  // Condensed layout for the dashboard's "New Requests" carousel: header
  // row (icon/AWB/status/customer/distance + payment badge), no address
  // block, no accent border - see the "Option A" design mockup.
  final bool compact;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.available,
    required this.completed,
    required this.atRisk,
    required this.dueInLabel,
    required this.accentColor,
    required this.isCod,
    this.width,
    required this.onTap,
    this.onAccept,
    this.onDecline,
    this.onDropback,
    this.onGoToDelivery,
    this.onWindowOpen,
    this.compact = false,
  });

  static const Map<String, Color> typeAccents = {
    "b2c": AppColors.primaryThemeColor,
    "c2c": AppColors.blue,
    "whatsapp": Color(0xFF0BA30B),
  };
  static const Map<String, String> typeLabels = {
    "b2c": "B2C",
    "c2c": "C2C",
    "whatsapp": "WhatsApp",
  };
  static const Color _amberOFD = Color(0xFFA67C00);

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
      case NOT_PICKED:
        return AppColors.red;
      case CANCELED:
        return AppColors.greyColor4;
      default:
        return AppColors.primaryThemeColor;
    }
  }

  // Footer label/color on a finished (completed or undelivered) order.
  String get _finishedLabel {
    switch (order.status) {
      case UNDELIVERED:
        return "Undelivered";
      case NOT_PICKED:
        return "Not picked";
      case CANCELED:
        return "Cancelled";
      default:
        return "Delivered";
    }
  }

  Color get _finishedColor =>
      order.status == UNDELIVERED || order.status == NOT_PICKED
          ? AppColors.red
          : AppColors.greyColor4;

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

  Widget _typeBadge(String serviceType) {
    final key = serviceType.toLowerCase();
    final color = typeAccents[key] ?? AppColors.primaryThemeColor;
    final label = typeLabels[key] ?? serviceType.toUpperCase();
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: color.withOpacity(Get.isDarkMode ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: utils.tvCustom(label, color, 10, textAlignment: TextAlign.left),
      ),
    );
  }

  Widget _priorityTag() {
    final iconColor = Get.isDarkMode ? AppColors.white : AppColors.black;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.secondryThemeColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: iconColor, size: 10.sp),
          SizedBox(width: 2.w),
          utils.tvCustom(
            "PRIORITY",
            AppColors.black,
            9,
            textAlignment: TextAlign.left,
          ),
        ],
      ),
    );
  }

  // WhatsApp orders that aren't priority are "value" deliveries.
  Widget _valueTag() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.greyColor5.withOpacity(Get.isDarkMode ? 0.5 : 0.14),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: utils.tvCustom(
        "VALUE",
        AppColors.greyColor5,
        9,
        textAlignment: TextAlign.left,
      ),
    );
  }

  // PRIORITY for priority orders; VALUE for any other WhatsApp order.
  bool get _hasDeliveryTag => order.isPriorityOrder || order.isWhatsAppOrder;

  Widget _deliveryTag() =>
      order.isPriorityOrder ? _priorityTag() : _valueTag();

  // Value-order window strip: Accept on available orders, Pickup before the
  // parcel is collected, and a "deliver any time" note once it's picked.
  Widget? _valueWindowStrip() {
    if (!order.hasValueWindow || completed) return null;
    if (available) {
      return ValueWindowStrip(
        order: order,
        action: "Accept",
        onWindowOpen: onWindowOpen,
      );
    }
    if (ValueWindowStrip.isBeforePickup(order.status)) {
      return ValueWindowStrip(
        order: order,
        action: "Pickup",
        onWindowOpen: onWindowOpen,
      );
    }
    if (order.status == PICKED || order.status == OFD) {
      return ValueWindowStrip(order: order, action: "Pickup", picked: true);
    }
    return null;
  }

  // Accept is locked on a value order outside its time window.
  bool get _acceptLocked => available && order.isOutsideValueWindow;

  Color get _lockedButtonColor =>
      Get.isDarkMode ? AppColors.greyColor5 : AppColors.greyColor2;

  Widget _acceptLabel(String text, double fontSize) {
    if (!_acceptLocked) return utils.tvCustom(text, Colors.white, fontSize);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, color: Colors.white, size: 13.sp),
        SizedBox(width: 4.w),
        utils.tvCustom(text, Colors.white, fontSize),
      ],
    );
  }

  Widget _paymentBadge() {
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

  @override
  Widget build(BuildContext context) {
    final isTablet = !context.isPhone;
    final cardBg = Get.isDarkMode ? AppColors.greyColor10 : Colors.white;
    final windowStrip = _valueWindowStrip();

    final card = InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all((compact ? 12 : (isTablet ? 18 : 14)).w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: (available && !compact)
              ? Border.all(color: accentColor.withOpacity(0.35), width: 1.5)
              : (Get.isDarkMode
                    ? Border.all(color: Colors.white.withOpacity(0.08))
                    : null),
          boxShadow: Get.isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: compact
            ? _buildCompactContent(context, isTablet, windowStrip)
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onGoToDelivery != null) _upNextLabel(isTablet),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: (isTablet ? 46 : 38).w,
                  height: (isTablet ? 46 : 38).w,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(
                      Get.isDarkMode ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: accentColor,
                    size: (isTablet ? 19: 16).sp,
                  ),
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
                              12,
                              textAlignment: TextAlign.left,
                              maxLines: 1,
                            ),
                          ),

                        ],
                      ),
                      SizedBox(height: 1.h),
                      if ((order.status ?? "").isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        _statusBadge(order.status!),
                      ],
                      SizedBox(height: 1.h),
                      utils.tvCustom(
                        (order.consigneeName?.isNotEmpty ?? false)
                            ? order.consigneeName!
                            : (order.merchantName ?? ""),
                        AppColors.greyColor4,
                        11,
                        textAlignment: TextAlign.left,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ((order.serviceType ?? "").isNotEmpty || _hasDeliveryTag) ...[
              SizedBox(height: 8.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((order.serviceType ?? "").isNotEmpty)
                    _typeBadge(order.serviceType!),
                  if ((order.serviceType ?? "").isNotEmpty && _hasDeliveryTag)
                    SizedBox(width: 6.w),
                  if (_hasDeliveryTag) _deliveryTag(),
                ],
              ),
            ],
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
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            child: Container(
                              width: 1.5,
                              color: const Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          color: AppColors.primaryThemeColor,
                          size: 14.sp,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        utils.tvCustomRegular(
                          order.pickupLocationName ??
                              order.pickupAddress ??
                              "-",
                          AppColors.greyColor10,
                          10,
                          textAlignment: TextAlign.left,
                          maxLines: 2,
                        ),
                        SizedBox(height: 10.h),
                        utils.tvCustomRegular(
                          order.consigneeAddress ?? "-",
                          AppColors.greyColor10,
                          10,
                          textAlignment: TextAlign.left,
                          maxLines: 2,
                        ),
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
                    Icon(
                      Icons.social_distance,
                      color: AppColors.greyColor4,
                      size: 13.sp,
                    ),
                    SizedBox(width: 4.w),
                    utils.tvCustom(
                      order.distance ?? "-",
                      AppColors.greyColor4,
                      11,
                    ),
                  ],
                ),
                _paymentBadge(),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: completed
                          ? _finishedColor
                          : (atRisk ? AppColors.red : AppColors.greyColor10),
                      size: 13.sp,
                    ),
                    SizedBox(width: 4.w),
                    utils.tvCustom(
                      completed ? _finishedLabel : dueInLabel,
                      completed
                          ? _finishedColor
                          : (atRisk ? AppColors.red : AppColors.greyColor10),
                      11,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((order.sla_in_hours ?? "").isNotEmpty) ...[
                      utils.tvCustom(
                        "${order.sla_in_hours}h SLA",
                        AppColors.greyColor4,
                        10.5,
                      ),
                      SizedBox(width: 6.w),
                    ],
                    Icon(
                      Icons.chevron_right,
                      color: const Color(0xFFC7C7C7),
                      size: 18.sp,
                    ),
                  ],
                ),
              ],
            ),
            if (windowStrip != null) ...[
              SizedBox(height: 10.h),
              windowStrip,
            ],
            if (available) ...[
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: utils.tvCustom("Decline", AppColors.black, 13),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptLocked ? null : onAccept,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        backgroundColor: AppColors.primaryThemeColor,
                        disabledBackgroundColor: _lockedButtonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: _acceptLabel("Accept order", 13),
                    ),
                  ),
                ],
              ),
            ],
            if (completed && order.requires_return == "1" && onDropback != null) ...[
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDropback,
                  icon: Icon(
                    Icons.warehouse_outlined,
                    size: 16.sp,
                    color: AppColors.primaryThemeColor,
                  ),
                  label: utils.tvCustom(
                    "Drop Back",
                    AppColors.primaryThemeColor,
                    12.5,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    side: const BorderSide(
                      color: AppColors.primaryThemeColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ],
            if (onGoToDelivery != null) _goToDeliveryFooter(isTablet),
          ],
        ),
      ),
    );

    return width != null ? SizedBox(width: width, child: card) : card;
  }

  // "UP NEXT" marker - same as the dashboard's first upcoming order.
  Widget _upNextLabel(bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 12.h : 10.h),
      child: Row(
        children: [
          Container(
            width: isTablet ? 7.w : 6.w,
            height: isTablet ? 7.w : 6.w,
            decoration: const BoxDecoration(
              color: AppColors.primaryThemeColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          utils.tvCustom(
            "UP NEXT",
            AppColors.primaryThemeColor,
            9.5,
            textAlignment: TextAlign.left,
          ),
        ],
      ),
    );
  }

  // Pickup name + "Go to delivery" (opens the Active Order screen) - same
  // as the dashboard's first upcoming order.
  Widget _goToDeliveryFooter(bool isTablet) {
    final pickup = (order.merchantName?.isNotEmpty ?? false)
        ? order.merchantName!
        : (order.pickupLocationName ?? "");
    return Container(
      margin: EdgeInsets.only(top: isTablet ? 14.h : 12.h),
      padding: EdgeInsets.only(top: isTablet ? 12.h : 10.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Get.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: pickup.isEmpty
                ? const SizedBox.shrink()
                : utils.tvCustom(
                    "Pickup · $pickup",
                    AppColors.greyColor4,
                    10.5,
                    textAlignment: TextAlign.left,
                    maxLines: 1,
                  ),
          ),
          SizedBox(width: 10.w),
          InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: onGoToDelivery,
            child: Container(
              height: isTablet ? 40.h : 34.h,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 18.w : 14.w),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  utils.tvCustom("Go to delivery", AppColors.white, 12.5),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.white,
                    size: (isTablet ? 18 : 15).sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // "Option A" condensed layout: header row (icon/AWB/status/customer/
  // distance + payment badge), no address block, small Decline/Accept
  // buttons alongside the countdown instead of a full-width row.
  Widget _buildCompactContent(
    BuildContext context,
    bool isTablet,
    Widget? windowStrip,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: (isTablet ? 40 : 34).w,
              height: (isTablet ? 40 : 34).w,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(Get.isDarkMode ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(9.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.inventory_2_outlined,
                color: accentColor,
                size: (isTablet ? 20 : 17).sp,
              ),
            ),
            SizedBox(width: 10.w),
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
                          13,
                          textAlignment: TextAlign.left,
                          maxLines: 1,
                        ),
                      ),
                      if ((order.serviceType ?? "").isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        _typeBadge(order.serviceType!),
                      ],
                      if (_hasDeliveryTag) ...[
                        SizedBox(width: 6.w),
                        _deliveryTag(),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  if ((order.status ?? "").isNotEmpty) ...[
                    SizedBox(width: 6.w),
                    _statusBadge(order.status!),
                  ],
                  utils.tvCustom(
                    "${(order.consigneeName?.isNotEmpty ?? false) ? order.consigneeName! : (order.merchantName ?? "-")}  ·  ${order.distance ?? "-"}",
                    AppColors.greyColor4,
                    11.5,
                    textAlignment: TextAlign.left,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (available) ...[
          SizedBox(height: 10.h),
          Divider(
            height: 1,
            color: Get.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFEFEFEF),
          ),
          SizedBox(height: 10.h),
          if (windowStrip != null) ...[
            windowStrip,
            SizedBox(height: 10.h),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _paymentBadge(),
                  SizedBox(height: 4.h),
                  utils.tvCustom(
                    completed ? _finishedLabel : dueInLabel,
                    atRisk ? AppColors.red : AppColors.greyColor4,
                    10.5,
                    textAlignment: TextAlign.left,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      // Material's default 48dp minimum tap target would
                      // otherwise balloon past this button's small visual
                      // size and swallow taps meant for the card's own
                      // onTap, on a card this short.
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: utils.tvCustom("Decline", AppColors.black, 11.5),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: _acceptLocked ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 6.h,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.primaryThemeColor,
                      disabledBackgroundColor: _lockedButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _acceptLabel("Accept", 11.5),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}
