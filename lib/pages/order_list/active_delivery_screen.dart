import 'dart:async';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    hide Marker;
import 'package:signature/signature.dart';
import '../../global/app_bottom_nav.dart';
import '../../global/global.dart';
import '../../utils/colors.dart';
import '../../utils/text_style_util.dart';
import '../my_orders/orders/models/orders_model.dart';
import '../my_orders/orders/models/reason_data.dart';
import 'active_delivery_controller.dart';

const Color _amberOFD = Color(0xFFA67C00);

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen>
    with WidgetsBindingObserver {
  final controller = Get.find<ActiveDeliveryController>();

  static const _stepLabels = [
    "Accepted",
    "Arrived at pickup",
    "Collected",
    "Out for delivery",
    "Delivered",
  ];

  // Call tracking - the timer lives here (not on the controller) so the
  // per-second tick only rebuilds this screen, same split AllOrdersMapPage
  // uses with AllOrdersMapController.
  Stopwatch? _callTimer;
  Timer? _callDurationTimer;
  bool _isCallInitiated = false;
  String _currentCallDuration = "00:00";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callDurationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached && _isCallInitiated) {
      _handleAppTermination();
    }
  }

  void _handleAppTermination() async {
    if (_isCallInitiated && _callTimer != null && _callTimer!.isRunning) {
      _callTimer!.stop();
      _callDurationTimer?.cancel();
      final duration = _formatCallDuration(_callTimer!.elapsed.inSeconds);
      _isCallInitiated = false;
      await controller.logCall(status: 'call disconnected', duration: duration);
      controller.endCall();
    }
  }

  String _formatCallDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startCall() {
    if (controller.hasOngoingCall) {
      utils.errorSnackBar(
        "Ongoing Call",
        "Cannot start another call while one is in progress",
      );
      return;
    }
    final type = controller.isPickupPhase ? 'pickup' : 'consignee';
    final phone = controller.isPickupPhase
        ? (controller.order.pickupPhoneNo ?? "")
        : (controller.order.consigneeMobileNo ?? "");
    if (phone.isEmpty) return;

    controller.startCall(type);
    _isCallInitiated = true;
    _currentCallDuration = "00:00";
    _callTimer = Stopwatch()..start();
    utils.openDialPad(phone);

    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callTimer != null && _callTimer!.isRunning) {
        setState(() {
          _currentCallDuration = _formatCallDuration(
            _callTimer!.elapsed.inSeconds,
          );
        });
      }
    });
  }

  void _endCall() {
    if (_callTimer == null || !_callTimer!.isRunning) return;
    _callTimer!.stop();
    _callDurationTimer?.cancel();
    _isCallInitiated = false;
    final duration = _formatCallDuration(_callTimer!.elapsed.inSeconds);
    _showCallOutcomeSheet(duration);
  }

  void _submitCallOutcome(String status, String duration) {
    Get.back();
    controller.logCall(status: status, duration: duration).then((_) {
      controller.endCall();
    });
  }

  void _showCallOutcomeSheet(String duration) {
    final contactNumber = controller.callType == 'pickup'
        ? controller.order.pickupPhoneNo
        : controller.order.consigneeMobileNo;
    Get.bottomSheet(
      PopScope(
        canPop: false,
        child: Container(
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
                "Call ended",
                AppColors.black,
                16,
                textAlignment: TextAlign.left,
              ),
              SizedBox(height: 2.h),
              utils.tvCustom(
                "${controller.order.awbNo ?? '-'} · ${contactNumber ?? '-'}",
                AppColors.greyColor5,
                12,
                textAlignment: TextAlign.left,
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryThemeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14.sp,
                      color: AppColors.primaryThemeColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "Duration: $duration",
                      style: AppTextStyle.tsCustom(
                        AppColors.primaryThemeColor,
                        utils.responsiveFontSize(12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              utils.tvCustom(
                "How was the call? This must be logged to continue.",
                AppColors.greyColor5,
                12,
                textAlignment: TextAlign.left,
              ),
              SizedBox(height: 10.h),
              _callOutcomeOption(
                icon: Icons.person_outline,
                label: "Talked to customer",
                color: AppColors.greenLight,
                onTap: () => _submitCallOutcome("talked to customer", duration),
              ),
              SizedBox(height: 10.h),
              _callOutcomeOption(
                icon: Icons.phone_missed_outlined,
                label: "Customer missed call",
                color: AppColors.red,
                onTap: () =>
                    _submitCallOutcome("customer missed call", duration),
              ),
              SizedBox(height: 10.h),
              _callOutcomeOption(
                icon: Icons.cancel_outlined,
                label: "Call not connected",
                color: AppColors.blue,
                onTap: () => _submitCallOutcome("Not Connected", duration),
              ),
            ],
          ),
        ),
      ),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
    );
  }

  Widget _callOutcomeOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(Get.isDarkMode ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: color.withOpacity(Get.isDarkMode ? 0.28 : 0.16),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.tsCustom(
                  color,
                  utils.responsiveFontSize(14.5),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withOpacity(0.5),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = !context.isPhone;
    final cardBg = Get.isDarkMode ? AppColors.greyColor10 : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.backgroundColorMain,
      ),
      child: Scaffold(
        backgroundColor: Get.isDarkMode
            ? AppColors.black
            : AppColors.greyColor1,
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              GetBuilder<ActiveDeliveryController>(
                builder: (_) => _header(context, isTablet),
              ),
              Expanded(
                child: GetBuilder<ActiveDeliveryController>(
                  builder: (_) {
                    if (controller.isLoadingOrder) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.noOrdersAvailable) {
                      return _noActiveOrderState();
                    }
                    return SingleChildScrollView(
                      padding: EdgeInsets.all((isTablet ? 32 : 16).w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((controller.order.serviceType ?? "").isNotEmpty ||
                              controller.order.isPriorityOrder) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if ((controller.order.serviceType ?? "")
                                    .isNotEmpty)
                                  _typeBadge(controller.order.serviceType!),
                                if ((controller.order.serviceType ?? "")
                                        .isNotEmpty &&
                                    controller.order.isPriorityOrder)
                                  SizedBox(width: 8.w),
                                if (controller.order.isPriorityOrder)
                                  _priorityTag(),
                              ],
                            ),
                            SizedBox(height: 12.h),
                          ],
                          if (!controller.isDelivered) ...[
                            controller.isCod ? _codBanner() : _ppdBanner(),
                            SizedBox(height: 12.h),
                          ],
                          if (controller.pickupSuggestions.length > 1) ...[
                            _pickupSuggestionsCard(cardBg),
                            SizedBox(height: 14.h),
                          ],
                          if (controller.isTerminal) ...[
                            _terminalCard(cardBg),
                            SizedBox(height: 14.h),
                          ] else ...[
                            _nextStopCard(context, cardBg),
                            SizedBox(height: 14.h),
                          ],
                          if (controller.currentStep == 4) ...[
                            _evidenceCard(context, cardBg),
                            SizedBox(height: 14.h),
                          ],
                          _progressCard(context, cardBg),
                          SizedBox(height: 14.h),
                          controller.isCod
                              ? _codStatusCard(cardBg)
                              : _ppdStatusCard(cardBg),
                          SizedBox(height: 14.h),
                          _infoBanner(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shown when this screen is opened without a specific order (the bottom
  // nav's "Active Order" tab no longer passes one - see ActiveDeliveryController)
  // and the rider turns out to have nothing assigned by the time the fetch
  // that picks the first one comes back.
  // ---------------------------------------------------------------------
  Widget _noActiveOrderState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.two_wheeler, color: AppColors.greyColor4, size: 40.sp),
            SizedBox(height: 12.h),
            utils.tvCustom(
              "No active orders right now",
              AppColors.greyColor4,
              14,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------
  Widget _header(BuildContext context, bool isTablet) {
    final order = controller.order;
    return Container(
      width: double.infinity,
      // Extends up behind the status bar (body SafeArea has top: false), so
      // the status bar strip is navy on edge-to-edge Android.
      padding: EdgeInsets.fromLTRB(
        (isTablet ? 32 : 16).w,
        MediaQuery.paddingOf(context).top + 14.h,
        (isTablet ? 32 : 16).w,
        14.h,
      ),
      color: AppColors.backgroundColorMain,
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                utils.tvCustom(
                  "Active :- ",
                  Colors.white,
                  isTablet ? 16 : 14,
                  textAlignment: TextAlign.left,
                ),

                utils.tvCustom(
                  order.awbNo ?? order.orderRefNumber ?? "-",
                  Colors.white,
                  isTablet ? 15 : 14,
                  textAlignment: TextAlign.left,
                ),
              ],
            ),
          ),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.secondryThemeColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: AppColors.black, size: 10.sp),
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

  // ---------------------------------------------------------------------
  // Ongoing call card
  // ---------------------------------------------------------------------
  Widget _ongoingCallCard() {
    final order = controller.order;
    final contactNumber = controller.callType == 'pickup'
        ? order.pickupPhoneNo
        : order.consigneeMobileNo;
    final contactLabel = controller.callType == 'pickup'
        ? "Merchant"
        : "Customer";
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.primaryThemeColor.withOpacity(
          Get.isDarkMode ? 0.16 : 0.08,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryThemeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryThemeColor.withOpacity(
                    Get.isDarkMode ? 0.28 : 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.phone_in_talk_outlined,
                  color: AppColors.primaryThemeColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    utils.tvCustom(
                      "Call in progress · $contactLabel",
                      AppColors.greyColor4,
                      11.5,
                      textAlignment: TextAlign.left,
                    ),
                    SizedBox(height: 2.h),
                    utils.tvCustom(
                      contactNumber ?? "-",
                      AppColors.black,
                      15,
                      textAlignment: TextAlign.left,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.greenLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.greenLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _currentCallDuration,
                      style: AppTextStyle.tsCustom(
                        AppColors.greenLight,
                        utils.responsiveFontSize(12),
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _endCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                padding: EdgeInsets.symmetric(vertical: 11.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
              icon: Icon(Icons.call_end, color: Colors.white, size: 15.sp),
              label: utils.tvCustom("End call & log outcome", Colors.white, 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // COD warning banner
  // ---------------------------------------------------------------------
  Widget _codBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _amberOFD.withOpacity(Get.isDarkMode ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _amberOFD.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _amberOFD, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: utils.tvCustom(
              "COD · Collect QAR ${controller.order.orderAmount ?? '0'} from customer",
              _amberOFD,
              10,
              textAlignment: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PPD (prepaid) info banner - parity with _codBanner for non-COD orders
  // ---------------------------------------------------------------------
  Widget _ppdBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppColors.blue.withOpacity(0.16)
            : AppColors.headerColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.blue.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.blue, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: utils.tvCustom(
              "Prepaid · Paid online, no collection needed",
              AppColors.blue,
              10,
              textAlignment: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Nearby-pickups strip - other assigned orders near (or, if none are
  // nearby, all of) this order's pickup point, so the rider can switch
  // between them without leaving this screen. Only shown when there's more
  // than just the order already on screen.
  // ---------------------------------------------------------------------
  Widget _pickupSuggestionsCard(Color cardBg) {
    final suggestions = controller.pickupSuggestions;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: utils.tvCustom(
              controller.pickupSuggestionsAreNearby
                  ? "${suggestions.length} orders at this pickup"
                  : "Nothing nearby · ${suggestions.length - 1} other assigned orders",
              AppColors.greyColor4,
              11.5,
              textAlignment: TextAlign.left,
            ),
          ),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int index = 0; index < suggestions.length; index++) ...[
                    if (index != 0) SizedBox(width: 8.w),
                    _pickupSuggestionChip(suggestions[index]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickupSuggestionChip(OrdersData o) {
    final isCurrent = controller.pickupSuggestionTag(o) == "Viewing";
    final borderColor = isCurrent
        ? AppColors.primaryThemeColor
        : (Get.isDarkMode
              ? Colors.white.withOpacity(0.15)
              : const Color(0xFFECECEC));
    return InkWell(
      onTap: isCurrent ? null : () => controller.switchToOrder(o),
      borderRadius: BorderRadius.circular(11.r),
      child: Container(
        width: 110.w,
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11.r),
          border: Border.all(color: borderColor, width: 1.6),
          color: isCurrent
              ? AppColors.primaryThemeColor.withOpacity(
                  Get.isDarkMode ? 0.16 : 0.06,
                )
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            utils.tvCustom(
              o.awbNo ?? o.orderRefNumber ?? "-",
              AppColors.black,
              10,
              textAlignment: TextAlign.left,
              maxLines: 1,
            ),
            SizedBox(height: 2.h),
            utils.tvCustom(
              (o.consigneeName?.isNotEmpty ?? false)
                  ? o.consigneeName!
                  : (o.merchantName ?? "-"),
              AppColors.greyColor4,
              9,
              textAlignment: TextAlign.left,
              maxLines: 1,
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primaryThemeColor
                    : (Get.isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFEFEFEF)),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: utils.tvCustom(
                controller.pickupSuggestionTag(o),
                isCurrent ? Colors.white : AppColors.greyColor5,
                8.5,
                textAlignment: TextAlign.left,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Next stop card (address + mini map)
  // ---------------------------------------------------------------------
  Widget _nextStopCard(BuildContext context, Color cardBg) {
    final dest = controller.destLatLng;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          utils.tvCustom(
            "Next stop",
            AppColors.greyColor4,
            11.5,
            textAlignment: TextAlign.left,
          ),
          SizedBox(height: 4.h),
          utils.tvCustom(
            controller.nextStopName,
            AppColors.black,
            12,
            textAlignment: TextAlign.left,
            maxLines: 1,
          ),
          SizedBox(height: 2.h),
          utils.tvCustom(
            controller.nextStopAddress,
            AppColors.greyColor5,
            10,
            textAlignment: TextAlign.left,
            maxLines: 2,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.greyColor5,
                size: 13.sp,
              ),
              SizedBox(width: 5.w),
              utils.tvCustom(
                controller.nextStopDistance,
                AppColors.greyColor5,
                12,
                textAlignment: TextAlign.left,
              ),
              SizedBox(width: 16.w),
              Icon(Icons.access_time, color: AppColors.greyColor4, size: 13.sp),
              SizedBox(width: 5.w),
              utils.tvCustom(
                "ETA ",
                AppColors.greyColor5,
                12,
                textAlignment: TextAlign.left,
              ),
              utils.tvCustom(
                controller.nextStopEta,
                AppColors.primaryThemeColor,
                12,
                textAlignment: TextAlign.left,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: double.infinity,
              height: context.isPhone ? 160.h : 220.h,
              child: dest == null
                  ? Container(
                      color: Get.isDarkMode
                          ? AppColors.backgroundColorLight
                          : AppColors.greyColor1,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.map_outlined,
                        color: AppColors.greyColor4,
                        size: 22.sp,
                      ),
                    )
                  : GoogleMapsMapView(
                      onViewCreated: controller.onMapViewCreated,
                      initialMapToolbarEnabled: false,
                      initialZoomControlsEnabled: true,
                      initialZoomGesturesEnabled: true,
                      gestureRecognizers: {
                        Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                    ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: dest == null ? null : controller.openNavigation,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                backgroundColor: AppColors.blueLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: Icon(Icons.navigation, color: Colors.white, size: 16.sp),
              label: utils.tvCustom("Navigate", Colors.white, 13.5),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Delivery progress card: stepper + primary/secondary actions
  // ---------------------------------------------------------------------
  Widget _progressCard(BuildContext context, Color cardBg) {
    final step = controller.currentStep;
    final failed = controller.isUndelivered;
    final callDisabled = controller.hasOngoingCall;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          utils.tvCustom(
            "Delivery progress",
            AppColors.black,
            14,
            textAlignment: TextAlign.left,
          ),
          SizedBox(height: 6.h),
          _stepTracker(step: step, failed: failed),
          SizedBox(height: 8.h),
          if (!controller.isTerminal) ...[
            SizedBox(height: 6.h),
            if (controller.showPickupBuffer) ...[
              _bufferTimerCard(),
              SizedBox(height: 10.h),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onPrimaryActionPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryThemeColor,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                icon: Icon(
                  controller.primaryActionIcon,
                  color: Colors.white,
                  size: 18.sp,
                ),
                label: utils.tvCustom(
                  controller.primaryActionLabel.toUpperCase(),
                  Colors.white,
                  12,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (controller.hasOngoingCall) ...[
              _ongoingCallCard(),
              SizedBox(height: 14.h),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: callDisabled ? null : _startCall,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  side: BorderSide(
                    color: callDisabled
                        ? AppColors.greyColor2
                        : AppColors.primaryThemeColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                icon: Icon(
                  Icons.call_outlined,
                  color: callDisabled
                      ? AppColors.greyColor4
                      : AppColors.primaryThemeColor,
                  size: 16.sp,
                ),
                label: utils.tvCustom(
                  callDisabled
                      ? "Call in progress"
                      : (controller.isPickupPhase
                                ? "Call merchant"
                                : "Call customer")
                            .toUpperCase(),
                  callDisabled
                      ? AppColors.greyColor4
                      : AppColors.primaryThemeColor,
                  12,
                ),
              ),
            ),
            if (controller.currentStep == 4 || controller.currentStep == 2) ...[
              SizedBox(height: 12.h),
              InkWell(
                onTap: () => _openUndeliveredSheet(context),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.red,
                        size: 15.sp,
                      ),
                      SizedBox(width: 8.w),
                      utils.tvCustom(
                        "Report a delivery issue",
                        AppColors.red,
                        13,
                        textAlignment: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Pickup buffer countdown - shown above the primary action button while
  // the rider waits out the server-given pickup_buffer_time_in_minutes
  // window. The button stays enabled so the rider can confirm early.
  // ---------------------------------------------------------------------
  Widget _bufferTimerCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primaryThemeColor.withOpacity(
          Get.isDarkMode ? 0.16 : 0.08,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primaryThemeColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircularCountDownTimer(
            duration: controller.pickupBufferSeconds,
            initialDuration: 0,
            controller: CountDownController(),
            width: 96.w,
            height: 96.w,
            ringColor: Get.isDarkMode
                ? Colors.white.withOpacity(0.15)
                : AppColors.primaryThemeColor.withOpacity(0.15),
            fillColor: AppColors.primaryThemeColor,
            backgroundColor: Get.isDarkMode
                ? AppColors.greyColor10
                : Colors.white,
            isReverseAnimation: true,
            isReverse: true,
            autoStart: true,
            strokeWidth: 6.0,
            textAlign: TextAlign.center,
            textStyle: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: Get.isDarkMode
                  ? AppColors.white
                  : AppColors.primaryThemeColor,
            ),
            timeFormatterFunction: (defaultFormatterFunction, duration) {
              if (duration.inSeconds == 0) return "00:00";
              return Function.apply(defaultFormatterFunction, [duration]);
            },
            onComplete: controller.onPickupBufferComplete,
          ),
          SizedBox(height: 10.h),
          utils.tvCustom("Pickup buffer time", AppColors.primaryThemeColor, 13),
          SizedBox(height: 4.h),
          utils.tvCustom(
            "You can confirm the pickup once the timer ends",
            AppColors.greyColor5,
            12,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Primary action - gates the final "Confirm delivery" step behind a
  // payment-collected confirmation for COD orders (PPD orders proceed
  // straight through, same as every earlier step).
  // ---------------------------------------------------------------------
  void _onPrimaryActionPressed() {
    if (controller.currentStep == 4 && controller.isCod) {
      if (!controller.evidenceComplete) {
        utils.errorSnackBar(
          "Evidence required",
          "Capture package photo, delivery photo and signature first.",
        );
        return;
      }
      _showCodPaymentSheet();
      return;
    }
    controller.confirmPrimaryAction();
  }

  void _showCodPaymentSheet() {
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
            Row(
              children: [
                Icon(Icons.payments_outlined, color: _amberOFD, size: 20.sp),
                SizedBox(width: 8.w),
                utils.tvCustom(
                  "Confirm payment",
                  AppColors.black,
                  16,
                  textAlignment: TextAlign.left,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            utils.tvCustom(
              "Collect QAR ${controller.order.orderAmount ?? '0'} from the customer before completing this delivery.",
              AppColors.greyColor5,
              13,
              textAlignment: TextAlign.left,
              maxLines: 3,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  controller.confirmPrimaryAction();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenLight,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                icon: Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 18.sp,
                ),
                label: utils.tvCustom("Payment Collected", Colors.white, 15),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Get.back();
                  utils.errorSnackBar(
                    "Payment required",
                    "Collect QAR ${controller.order.orderAmount ?? '0'} from the customer before confirming delivery.",
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                child: utils.tvCustom("Not Collected", AppColors.red, 15),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ---------------------------------------------------------------------
  // Undelivered reason sheet
  // ---------------------------------------------------------------------
  void _openUndeliveredSheet(BuildContext context) {
    controller.ensureReasonsLoaded();
    Get.bottomSheet(
      Container(
        // Cap the sheet so a long reasons list scrolls instead of
        // overflowing past the photo tile and confirm button.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 20.h),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? AppColors.greyColor10 : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
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
                "Why couldn't you deliver this order?",
                AppColors.black,
                14,
                textAlignment: TextAlign.left,
              ),
              SizedBox(height: 6.h),
              Obx(() {
                if (controller.reasonsList.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryThemeColor,
                      ),
                    ),
                  );
                }
                return Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: controller.reasonsList
                          .map((r) => _reasonRow(r))
                          .toList(),
                    ),
                  ),
                );
              }),
              SizedBox(height: 14.h),
              utils.tvCustom(
                "Delivery proof (required)",
                AppColors.black,
                14,
                textAlignment: TextAlign.left,
              ),
              SizedBox(height: 8.h),
              GetBuilder<ActiveDeliveryController>(
                builder: (_) => SizedBox(
                  width: 150.w,
                  child: _evidenceTile(
                    icon: Icons.camera_alt_outlined,
                    label: "Attempt photo",
                    captured: controller.undeliveredPhoto != null,
                    onTap: controller.captureUndeliveredPhoto,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              GetBuilder<ActiveDeliveryController>(
                builder: (_) => Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          controller.selectedReasonId.value == null ||
                              controller.undeliveredPhoto == null
                          ? null
                          : () async {
                              Get.back();
                              await controller.confirmUndelivered();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        disabledBackgroundColor: AppColors.red.withOpacity(0.4),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28.r),
                        ),
                      ),
                      child: utils.tvCustom(
                        "Confirm - Mark as undelivered",
                        Colors.white,
                        14.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _reasonRow(CancelReason reason) {
    return Obx(() {
      final selected = controller.selectedReasonId.value == reason.id;
      return InkWell(
        onTap: () => controller.selectReason(reason),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Get.isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFF0F0F0),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.red : AppColors.greyColor2,
                    width: 2,
                  ),
                  color: selected ? AppColors.red : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: utils.tvCustom(
                  reason.reason,
                  AppColors.black,
                  12,
                  textAlignment: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // Horizontal step tracker: one connected row of dots instead of a tall
  // vertical list, so "Delivery progress" reads at a glance.
  Widget _stepTracker({required int step, required bool failed}) {
    final count = _stepLabels.length;
    final states = List.generate(count, (i) {
      if (i < step - 1) return _StepState.done;
      if (i == step - 1) {
        return failed && i == count - 1
            ? _StepState.failed
            : _StepState.current;
      }
      return _StepState.pending;
    });

    Color segmentColor(int i) => states[i] == _StepState.done
        ? AppColors.greenLight
        : (Get.isDarkMode
              ? Colors.white.withOpacity(0.15)
              : const Color(0xFFE0E0E0));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < count; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == 0
                            ? Colors.transparent
                            : segmentColor(i - 1),
                      ),
                    ),
                    SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: Center(child: _stepDot(states[i])),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == count - 1
                            ? Colors.transparent
                            : segmentColor(i),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Bypasses tvCustom: each step's label needs a distinct
                // per-state color (current/done/failed/pending) that
                // tvCustom's fixed dark-mode-white logic can't express -
                // same precedent as the bottom-nav tab labels in
                // rider_dashboard.dart.
                Text(
                  _stepLabels[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style:
                      AppTextStyle.tsCustom(
                        _stepLabelColor(states[i]),
                        utils.responsiveFontSize(9.5.sp),
                      ).copyWith(
                        fontWeight: states[i] == _StepState.current
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _stepLabelColor(_StepState state) {
    switch (state) {
      case _StepState.current:
        return Get.isDarkMode ? Colors.white : AppColors.black;
      case _StepState.failed:
        return AppColors.red;
      case _StepState.pending:
        return AppColors.greyColor4;
      case _StepState.done:
        return Get.isDarkMode
            ? Colors.white.withOpacity(0.7)
            : AppColors.greyColor5;
    }
  }

  Widget _stepDot(_StepState state) {
    switch (state) {
      case _StepState.done:
        return Container(
          width: 22.w,
          height: 22.w,
          decoration: const BoxDecoration(
            color: AppColors.greenLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.check, color: Colors.white, size: 13.sp),
        );
      case _StepState.current:
        return Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Get.isDarkMode ? AppColors.greyColor10 : Colors.white,
            border: Border.all(color: AppColors.primaryThemeColor, width: 2),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: AppColors.primaryThemeColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      case _StepState.failed:
        return Icon(Icons.cancel, color: AppColors.red, size: 22.sp);
      case _StepState.pending:
        return Container(
          width: 16.w,
          height: 16.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greyColor2, width: 2),
          ),
        );
    }
  }

  // ---------------------------------------------------------------------
  // Delivery evidence card
  // ---------------------------------------------------------------------
  Widget _evidenceCard(BuildContext context, Color cardBg) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          utils.tvCustom(
            "Delivery evidence",
            AppColors.black,
            16,
            textAlignment: TextAlign.left,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _evidenceTile(
                  icon: Icons.camera_alt_outlined,
                  label: "Package photo",
                  captured: controller.packagePhoto != null,
                  onTap: controller.capturePackagePhoto,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _evidenceTile(
                  icon: Icons.camera_alt_outlined,
                  label: "Delivery photo",
                  captured: controller.deliveryPhoto != null,
                  onTap: controller.captureDeliveryPhoto,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _evidenceTile(
                  icon: Icons.edit_outlined,
                  label: "Customer signature",
                  captured: controller.signatureFile != null,
                  onTap: () => _openSignatureSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _evidenceTile({
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

  void _openSignatureSheet(BuildContext context) {
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
            utils.tvCustom("Customer signature", AppColors.black, 16),
            SizedBox(height: 12.h),
            Container(
              height: 220.h,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyColor2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Signature(
                controller: controller.signatureController,
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.clearSignature,
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
                      await controller.captureSignature();
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

  // ---------------------------------------------------------------------
  // COD collection status
  // ---------------------------------------------------------------------
  Widget _codStatusCard(Color cardBg) {
    final collected = controller.isDelivered;
    final statusColor = collected
        ? AppColors.greenLight
        : AppColors.primaryThemeColor;
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                utils.tvCustom(
                  "COD collection status",
                  AppColors.greyColor4,
                  10.5,
                  textAlignment: TextAlign.left,
                ),
                SizedBox(height: 4.h),
                utils.tvCustom(
                  collected ? "Collected" : "Pending",
                  statusColor,
                  14,
                  textAlignment: TextAlign.left,
                ),
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(maxWidth: 170.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _amberOFD.withOpacity(Get.isDarkMode ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payments_outlined, color: _amberOFD, size: 18.sp),
                SizedBox(width: 8.w),
                Flexible(
                  child: utils.tvCustom(
                    "Collect QAR ${controller.order.orderAmount ?? '0'} from customer",
                    _amberOFD,
                    10,
                    textAlignment: TextAlign.left,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PPD (prepaid) payment status - parity with _codStatusCard
  // ---------------------------------------------------------------------
  Widget _ppdStatusCard(Color cardBg) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                utils.tvCustom(
                  "Payment status",
                  AppColors.greyColor4,
                  11.5,
                  textAlignment: TextAlign.left,
                ),
                SizedBox(height: 4.h),
                utils.tvCustom(
                  "Prepaid",
                  AppColors.greenLight,
                  14,
                  textAlignment: TextAlign.left,
                ),
              ],
            ),
          ),
          Container(
            constraints: BoxConstraints(maxWidth: 170.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.greenLight.withOpacity(
                Get.isDarkMode ? 0.16 : 0.10,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.greenLight,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: utils.tvCustom(
                    "Paid online",
                    AppColors.greenLight,
                    11,
                    textAlignment: TextAlign.left,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Terminal state (delivered / undelivered) summary card
  // ---------------------------------------------------------------------
  Widget _terminalCard(Color cardBg) {
    final delivered = controller.isDelivered;
    final color = delivered ? AppColors.greenLight : AppColors.red;
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
            child: Icon(
              delivered ? Icons.check_circle_outline : Icons.error_outline,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                utils.tvCustom(
                  delivered ? "Delivered" : "Delivery unsuccessful",
                  color,
                  15,
                  textAlignment: TextAlign.left,
                ),
                SizedBox(height: 2.h),
                utils.tvCustom(
                  delivered
                      ? (controller.order.consigneeName ?? "-")
                      : (controller.order.reason ?? "-"),
                  AppColors.greyColor5,
                  12,
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

  // ---------------------------------------------------------------------
  // Info banner
  // ---------------------------------------------------------------------
  Widget _infoBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Get.isDarkMode
            ? AppColors.blue.withOpacity(0.18)
            : AppColors.headerColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.blue, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: utils.tvCustom(
              "Status actions update the merchant in real time.",
              AppColors.blue,
              12,
              textAlignment: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepState { done, current, pending, failed }
