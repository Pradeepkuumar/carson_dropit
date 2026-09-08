import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart' hide Marker;
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../utils/colors.dart';
import 'order_detail_controller.dart';

const Color _amberOFD = Color(0xFFA67C00);

class OrderDetailScreen extends GetView<OrderDetailController> {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = !context.isPhone;
    final order = controller.order;
    final cardBg = Get.isDarkMode ? AppColors.greyColor10 : Colors.white;

    return Scaffold(
      backgroundColor: Get.isDarkMode ? AppColors.black : AppColors.greyColor1,
      body: SafeArea(
        child: Column(
          children: [
            // header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: (isTablet ? 32 : 16).w, vertical: 14.h),
              color: AppColors.backgroundColorMain,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.only(right: 10.w),
                      child: Icon(Icons.arrow_back,
                          color: Colors.white, size: 20.sp),
                    ),
                  ),
                  utils.tvCustom(
                      "Order ${order.awbNo ?? order.orderRefNumber ?? '-'}",
                      Colors.white,
                      isTablet ? 22 : 19,
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
                    // status row
                    Row(
                      children: [
                        if (controller.isAvailable)
                          _pill("Available order", AppColors.greenLight,
                              dotColor: AppColors.greenLight)
                        else
                          _pill(order.status ?? "-", _statusColor(order.status ?? "")),
                        SizedBox(width: 10.w),
                        if ((order.sla_in_hours ?? "").isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time,
                                  color: AppColors.greyColor4, size: 14.sp),
                              SizedBox(width: 4.w),
                              utils.tvCustom("${order.sla_in_hours}h SLA",
                                  AppColors.greyColor4, 12.5),
                            ],
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // map
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: SizedBox(
                        height: 220.h,
                        child: Stack(
                          children: [
                            GoogleMapsMapView(
                              onViewCreated: controller.onMapViewCreated,
                              initialMapToolbarEnabled: false,
                              initialZoomControlsEnabled: true,
                              initialZoomGesturesEnabled: true,
                              // Without this, pinch-to-zoom is lost to the
                              // parent SingleChildScrollView's drag
                              // recognizer instead of reaching the map.
                              gestureRecognizers: {
                                Factory<EagerGestureRecognizer>(
                                    () => EagerGestureRecognizer()),
                              },
                            ),
                            if ((order.distance ?? "").isNotEmpty)
                              Positioned(
                                left: 10.w,
                                bottom: 10.h,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(8.r),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.social_distance,
                                          color: AppColors.greyColor5, size: 13.sp),
                                      SizedBox(width: 5.w),
                                      utils.tvCustom(
                                          order.distance!, AppColors.black, 12),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    _infoCard(
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppColors.greenLight,
                      label: "Pickup from",
                      title: order.merchantName ?? "-",
                      subtitle: order.pickupLocationName ?? order.pickupAddress ?? "-",
                      cardBg: cardBg,
                      onCall: (order.pickupPhoneNo ?? "").isNotEmpty
                          ? controller.callPickup
                          : null,
                    ),
                    SizedBox(height: 12.h),

                    _infoCard(
                      icon: Icons.person_outline,
                      iconColor: AppColors.primaryThemeColor,
                      label: "Deliver to",
                      title: order.consigneeName ?? "-",
                      subtitle: order.consigneeAddress ?? "-",
                      cardBg: cardBg,
                      onCall: (order.consigneeMobileNo ?? "").isNotEmpty
                          ? controller.callConsignee
                          : null,
                    ),
                    SizedBox(height: 12.h),

                    _simpleCard(
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.greyColor5,
                      label: "Package",
                      value:
                          "${order.itemName ?? '-'} · ${order.quantity ?? 1} item${(order.quantity ?? 1) > 1 ? 's' : ''}${(order.weight ?? '').isNotEmpty ? ' · ${order.weight} kg' : ''}",
                      cardBg: cardBg,
                    ),
                    SizedBox(height: 12.h),

                    _paymentCard(order, cardBg),
                    SizedBox(height: 12.h),

                    _distanceEtaCard(order, cardBg),
                    SizedBox(height: 16.h),

                    if (controller.isAvailable) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: Get.isDarkMode
                              ? AppColors.greyColor10
                              : const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.greyColor5, size: 16.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: utils.tvCustom(
                                  "Accepting assigns this order to you.",
                                  AppColors.greyColor5,
                                  12,
                                  textAlignment: TextAlign.left),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _confirmDecline,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                side: const BorderSide(
                                    color: AppColors.primaryThemeColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: utils.tvCustom(
                                  "Decline", AppColors.primaryThemeColor, 14.5),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmAccept,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                backgroundColor: AppColors.primaryThemeColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: utils.tvCustom(
                                  "Accept order", Colors.white, 14.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAccept() {
    utils.simpleDialog("Accept Order", "Do you want to accept this order?",
        () => controller.accept(), () => Get.back());
  }

  void _confirmDecline() {
    utils.simpleDialog("Decline Order", "Do you want to decline this order?",
        () => controller.decline(), () => Get.back());
  }

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

  Widget _pill(String label, Color color, {Color? dotColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            SizedBox(width: 6.w),
          ],
          utils.tvCustom(label, color, 12.5),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String title,
    required String subtitle,
    required Color cardBg,
    VoidCallback? onCall,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: Get.isDarkMode
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(Get.isDarkMode ? 0.18 : 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                utils.tvCustom(label, AppColors.greyColor4, 11.5,
                    textAlignment: TextAlign.left),
                utils.tvCustom(title, AppColors.black, 15,
                    textAlignment: TextAlign.left, maxLines: 1),
                utils.tvCustom(subtitle, AppColors.greyColor5, 11.5,
                    textAlignment: TextAlign.left, maxLines: 2),
              ],
            ),
          ),
          if (onCall != null)
            InkWell(
              onTap: onCall,
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                      color: Get.isDarkMode
                          ? Colors.white.withOpacity(0.15)
                          : const Color(0xFFE5E5E5)),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.call_outlined,
                    color: Get.isDarkMode ? Colors.white : AppColors.backgroundColorMain,
                    size: 16.sp),
              ),
            ),
        ],
      ),
    );
  }

  Widget _simpleCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color cardBg,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: Get.isDarkMode
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(Get.isDarkMode ? 0.18 : 0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                utils.tvCustom(label, AppColors.greyColor4, 11.5,
                    textAlignment: TextAlign.left),
                utils.tvCustom(value, AppColors.black, 13.5,
                    textAlignment: TextAlign.left, maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(dynamic order, Color cardBg) {
    final isCod = (order.paymentType ?? "").toString().toLowerCase() == "cod";
    final color = isCod ? _amberOFD : AppColors.greenLight;
    final label = isCod
        ? "COD · QAR ${order.orderAmount ?? '0'}"
        : "${(order.paymentType ?? "").toString().isNotEmpty ? "${order.paymentType} · " : ""}Paid";
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: Get.isDarkMode
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: color.withOpacity(Get.isDarkMode ? 0.18 : 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.payments_outlined, color: color, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: utils.tvCustom("Customer payment", AppColors.greyColor4, 12.5,
                textAlignment: TextAlign.left),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: color.withOpacity(Get.isDarkMode ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: utils.tvCustom(label, color, 12),
          ),
        ],
      ),
    );
  }

  Widget _distanceEtaCard(dynamic order, Color cardBg) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: Get.isDarkMode
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statLine(Icons.social_distance, "Distance",
                (order.distance ?? "-").toString()),
          ),
          Container(width: 1, height: 30.h, color: const Color(0xFFF0F0F0)),
          SizedBox(width: 12.w),
          Expanded(
            child: _statLine(Icons.access_time, "Estimated travel",
                (order.duration ?? "-").toString()),
          ),
        ],
      ),
    );
  }

  Widget _statLine(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.greyColor5, size: 16),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            utils.tvCustom(label, AppColors.greyColor4, 10.5,
                textAlignment: TextAlign.left),
            utils.tvCustom(value, AppColors.black, 13.5,
                textAlignment: TextAlign.left),
          ],
        ),
      ],
    );
  }
}
