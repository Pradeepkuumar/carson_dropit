import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'consts.dart';
import 'global.dart';
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

    final card = InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all((isTablet ? 18 : 14).w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: available
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
                    color: accentColor.withOpacity(
                      Get.isDarkMode ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: accentColor,
                    size: (isTablet ? 22 : 19).sp,
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
                              13.5,
                              textAlignment: TextAlign.left,
                              maxLines: 1,
                            ),
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
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ((order.serviceType ?? "").isNotEmpty) ...[
              SizedBox(height: 8.h),
              _typeBadge(order.serviceType!),
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
                          11.5,
                          textAlignment: TextAlign.left,
                          maxLines: 2,
                        ),
                        SizedBox(height: 10.h),
                        utils.tvCustomRegular(
                          order.consigneeAddress ?? "-",
                          AppColors.greyColor10,
                          11.5,
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
                          ? AppColors.greyColor4
                          : (atRisk ? AppColors.red : AppColors.greyColor10),
                      size: 13.sp,
                    ),
                    SizedBox(width: 4.w),
                    utils.tvCustom(
                      completed ? "Delivered" : dueInLabel,
                      completed
                          ? AppColors.greyColor4
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
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        backgroundColor: AppColors.primaryThemeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
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

    return width != null ? SizedBox(width: width, child: card) : card;
  }
}
