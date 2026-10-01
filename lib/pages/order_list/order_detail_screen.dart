import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    hide Marker;
import 'package:signature/signature.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: AppColors.backgroundColorMain),
      child: Scaffold(
        backgroundColor: Get.isDarkMode ? AppColors.black : AppColors.greyColor1,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // header - extends up behind the status bar (SafeArea top: false)
              // so the status bar strip is navy on edge-to-edge Android.
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  (isTablet ? 32 : 16).w,
                  MediaQuery.paddingOf(context).top + 14.h,
                  (isTablet ? 32 : 16).w,
                  14.h,
                ),
                color: AppColors.backgroundColorMain,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    Flexible(
                      child:utils.tvCustom(
                        order.awbNo ?? order.orderRefNumber ?? '-',
                        Colors.white,
                        maxLines: 2,
                        isTablet ? 22 : 19,
                        textAlignment: TextAlign.left,
                      ) ,
                    )

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
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (controller.isAvailable)
                            _pill(
                              "Available order",
                              AppColors.greenLight,
                              dotColor: AppColors.greenLight,
                            )
                          else
                            _pill(
                              order.status ?? "-",
                              _statusColor(order.status ?? ""),
                            ),
                          if ((order.serviceType ?? "").isNotEmpty)
                            _typeBadge(order.serviceType!),
                          if (order.isPriorityOrder) _priorityTag(),
                          if ((order.sla_in_hours ?? "").isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Get.isDarkMode ?AppColors.white :AppColors.black,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                utils.tvCustom(
                                  "${order.sla_in_hours}h SLA",
                                  Get.isDarkMode ?AppColors.white :AppColors.black,
                                  12.5,
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // map
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: SizedBox(
                          height: 160.h,
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
                                    () => EagerGestureRecognizer(),
                                  ),
                                },
                              ),
                              if ((order.distance ?? "").isNotEmpty)
                                Positioned(
                                  left: 10.w,
                                  bottom: 10.h,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(8.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.social_distance,
                                          color: AppColors.greyColor5,
                                          size: 13.sp,
                                        ),
                                        SizedBox(width: 5.w),
                                        utils.tvCustom(
                                          order.distance!,
                                          AppColors.black,
                                          12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      if (controller.isAvailable) ...[
                        // Container(
                        //   padding: EdgeInsets.symmetric(
                        //     horizontal: 14.w,
                        //     vertical: 12.h,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: Get.isDarkMode
                        //         ? AppColors.greyColor10
                        //         : const Color(0xFFECEFF1),
                        //     borderRadius: BorderRadius.circular(12.r),
                        //   ),
                        //   child: Row(
                        //     children: [
                        //       Icon(
                        //         Icons.info_outline,
                        //         color: AppColors.greyColor5,
                        //         size: 16.sp,
                        //       ),
                        //       SizedBox(width: 8.w),
                        //       Expanded(
                        //         child: utils.tvCustom(
                        //           "Accepting assigns this order to you.",
                        //           AppColors.greyColor5,
                        //           10,
                        //           textAlignment: TextAlign.left,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _confirmDecline,
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  side: const BorderSide(
                                    color: AppColors.primaryThemeColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: utils.tvCustom(
                                  "Decline",
                                  AppColors.primaryThemeColor,
                                  12.5,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _confirmAccept,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  backgroundColor: AppColors.primaryThemeColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: utils.tvCustom(
                                  "Accept order",
                                  Colors.white,
                                  12.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                      ] else if (order.status == UNDELIVERED) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openDropbackSheet(context),
                            icon: Icon(
                              Icons.warehouse_outlined,
                              size: 16.sp,
                              color: AppColors.primaryThemeColor,
                            ),
                            label: utils.tvCustom(
                              "Back to warehouse",
                              AppColors.primaryThemeColor,
                              12.5,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
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
                       SizedBox(height: 10.h),
                      _routeTimelineCard(
                        order: order,
                        cardBg: cardBg,
                        onCallPickup: (order.pickupPhoneNo ?? "").isNotEmpty
                            ? controller.callPickup
                            : null,
                        onCallConsignee:
                            (order.consigneeMobileNo ?? "").isNotEmpty
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


                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
    );
  }

  void _confirmAccept() {
    utils.simpleDialog(
      "Accept Order",
      "Do you want to accept this order?",
      () => controller.accept(),
      () => Get.back(),
    );
  }

  void _confirmDecline() {
    utils.simpleDialog(
      "Decline Order",
      "Do you want to decline this order?",
      () => controller.decline(),
      () => Get.back(),
    );
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
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
          ],
          utils.tvCustom(label, color, 12.5),
        ],
      ),
    );
  }

  static const Map<String, Color> _typeAccents = {
    "b2c": AppColors.primaryThemeColor,
    "c2c": AppColors.blue,
    "whatsapp": Color(0xFF0BA30B),
  };
  static const Map<String, String> _typeLabels = {
    "b2c": "B2C",
    "c2c": "C2C",
    "whatsapp": "WhatsApp",
  };

  Widget _typeBadge(String serviceType) {
    final key = serviceType.toLowerCase();
    final color = _typeAccents[key] ?? AppColors.primaryThemeColor;
    final label = _typeLabels[key] ?? serviceType.toUpperCase();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: utils.tvCustom(label, color, 11.5),
    );
  }

  Widget _priorityTag() {
    final iconColor = Get.isDarkMode ? AppColors.white : AppColors.black;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.secondryThemeColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: iconColor, size: 13.sp),
          SizedBox(width: 4.w),
          utils.tvCustom("PRIORITY", AppColors.black, 11.5),
        ],
      ),
    );
  }

  // Same dot -> line -> pin route connector OrderCardWidget already uses
  // for pickup/drop-off, so this screen's route reads the same way the
  // order list's cards do.
  Widget _routeTimelineCard({
    required dynamic order,
    required Color cardBg,
    VoidCallback? onCallPickup,
    VoidCallback? onCallConsignee,
  }) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 16.w,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Container(
                      width: 9.w,
                      height: 9.w,
                      decoration: const BoxDecoration(
                        color: AppColors.greenLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Container(
                        width: 1.5,
                        color: const Color(0xFFE0E0E0),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.location_on,
                    color: AppColors.primaryThemeColor,
                    size: 15.sp,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _routeLeg(
                    label: "PICKUP",
                    title: order.merchantName ?? "-",
                    subtitle:
                        order.pickupLocationName ??
                        order.pickupAddress ??
                        "-",
                    onCall: onCallPickup,
                  ),
                  SizedBox(height: 16.h),
                  _routeLeg(
                    label: "DELIVER TO",
                    title: order.consigneeName ?? "-",
                    subtitle: order.consigneeAddress ?? "-",
                    onCall: onCallConsignee,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeLeg({
    required String label,
    required String title,
    required String subtitle,
    VoidCallback? onCall,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              utils.tvCustom(
                label,
                AppColors.greyColor4,
                10.5,
                textAlignment: TextAlign.left,
              ),
              utils.tvCustom(
                title,
                AppColors.black,
                12,
                textAlignment: TextAlign.left,
                maxLines: 1,
              ),
              utils.tvCustomRegular(
                subtitle,
                AppColors.greyColor5,
                9.5,
                textAlignment: TextAlign.left,
                maxLines: 2,
              ),
            ],
          ),
        ),
        if (onCall != null) ...[SizedBox(width: 8.w), _callButton(onCall)],
      ],
    );
  }

  Widget _callButton(VoidCallback onCall) {
    return InkWell(
      onTap: onCall,
      borderRadius: BorderRadius.circular(9.r),
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(Get.isDarkMode ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(9.r),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.call_outlined, color: AppColors.blue, size: 14.sp),
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
                  offset: const Offset(0, 4),
                ),
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
                utils.tvCustom(
                  label,
                  AppColors.greyColor4,
                  11.5,
                  textAlignment: TextAlign.left,
                ),
                utils.tvCustom(
                  value,
                  AppColors.black,
                  10.5,
                  textAlignment: TextAlign.left,
                  maxLines: 2,
                ),
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
                  offset: const Offset(0, 4),
                ),
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
            child: utils.tvCustom(
              "Customer payment",
              AppColors.greyColor4,
              10.5,
              textAlignment: TextAlign.left,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: color.withOpacity(Get.isDarkMode ? 0.22 : 0.14),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: utils.tvCustom(label, color, 10),
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
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _statLine(
              Icons.social_distance,
              "Distance",
              (order.distance ?? "-").toString(),
            ),
          ),
          Container(width: 1, height: 30.h, color: const Color(0xFFF0F0F0)),
          SizedBox(width: 12.w),
          Expanded(
            child: _statLine(
              Icons.access_time,
              "Estimated travel",
              (order.duration ?? "-").toString(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Back to warehouse (dropback) sheet - shown for an undelivered order
  // ---------------------------------------------------------------------

  void _openDropbackSheet(BuildContext context) {
    final order = controller.order;
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
              "Return to warehouse",
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
            utils.tvCustom(
              "Warehouse proof photo (required)",
              AppColors.black,
              13,
              textAlignment: TextAlign.left,
            ),
            SizedBox(height: 8.h),
            GetBuilder<OrderDetailController>(
              builder: (_) => SizedBox(
                width: 96.w,
                child: _dropbackTile(
                  icon: Icons.camera_alt_outlined,
                  label: "Attempt photo",
                  captured: controller.dropbackPhoto != null,
                  onTap: controller.captureDropbackPhoto,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            utils.tvCustom(
              "Signature (optional)",
              AppColors.black,
              13,
              textAlignment: TextAlign.left,
            ),
            SizedBox(height: 8.h),
            GetBuilder<OrderDetailController>(
              builder: (_) => SizedBox(
                width: 96.w,
                child: _dropbackTile(
                  icon: Icons.edit_outlined,
                  label: "Signature",
                  captured: controller.dropbackSignatureFile != null,
                  onTap: () => _openDropbackSignatureSheet(context),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            GetBuilder<OrderDetailController>(
              builder: (_) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.dropbackPhoto == null
                      ? null
                      : () async {
                          Get.back();
                          await controller.confirmDropback();
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
                    "Drop at warehouse",
                    Colors.white,
                    14.5,
                  ),
                ),
              ),
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

  Widget _statLine(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.greyColor5, size: 16),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              utils.tvCustom(
                label,
                AppColors.greyColor4,
                10.5,
                textAlignment: TextAlign.left,
                maxLines: 1,
              ),
              utils.tvCustom(
                value,
                AppColors.black,
                10.5,
                textAlignment: TextAlign.left,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
