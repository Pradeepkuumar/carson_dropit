import 'dart:async';
import 'dart:io';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart'
    hide Marker;
import 'package:signature/signature.dart';
import '../../global/app_bottom_nav.dart';
import '../../global/global.dart';
import '../../global/value_window_strip.dart';
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
    // Back from the browser / share target after sending the payment link.
    if (state == AppLifecycleState.resumed) {
      controller.onAppResumed();
    }
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
                    if (controller.isLoadingNextOrder) {
                      return _loadingNextOrderState();
                    }
                    if (controller.noOrdersAvailable) {
                      return _noActiveOrderState();
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all((isTablet ? 32 : 16).w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _progressCard(context, cardBg),
                                SizedBox(height: 12.h),
                                if (controller.pickupSuggestions.length >
                                    1) ...[
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
                                if (_hasPackageInfo) ...[
                                  _packageCard(cardBg),
                                  SizedBox(height: 14.h),
                                ],
                                if (controller.currentStep == 4) ...[
                                  _evidenceCard(context, cardBg),
                                  SizedBox(height: 14.h),
                                ],
                                _paymentStrip(),


                              ],
                            ),
                          ),
                        ),
                        if (!controller.isTerminal)
                          _primaryActionBar(isTablet, cardBg),
                      ],
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
  // Also shown after the rider finishes their last order ("All done").
  Widget _noActiveOrderState() {
    final allDone = controller.finishedAllOrders;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: (allDone ? AppColors.greenLight : AppColors.greyColor4)
                    .withOpacity(Get.isDarkMode ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                allDone ? Icons.check_rounded : Icons.two_wheeler,
                color: allDone ? AppColors.greenLight : AppColors.greyColor4,
                size: 30.sp,
              ),
            ),
            SizedBox(height: 14.h),
            utils.tvCustom(
              allDone ? "All done for now" : "No active orders right now",
              AppColors.black,
              15,
            ),
            SizedBox(height: 4.h),
            utils.tvCustom(
              "New assignments will show up here.",
              AppColors.greyColor4,
              12,
              maxLines: 2,
            ),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: controller.refreshAssignedOrders,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                side: const BorderSide(color: AppColors.primaryThemeColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              icon: Icon(
                Icons.refresh,
                color: AppColors.primaryThemeColor,
                size: 16.sp,
              ),
              label: utils.tvCustom(
                "Refresh",
                AppColors.primaryThemeColor,
                12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shown while the assigned-orders list is re-fetched after a finished
  // order's result dialog.
  Widget _loadingNextOrderState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryThemeColor,
          ),
          SizedBox(height: 14.h),
          utils.tvCustom("Loading next order…", AppColors.black, 13),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Bypasses tvCustom: muted white-on-navy label in both themes,
          // which tvCustom's fixed w600 white can't give.
          Text(
            "Active order : ",
            style: AppTextStyle.tsCustom(
              AppColors.whiteFade,
              utils.responsiveFontSize(13.sp),
            ).copyWith(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: utils.tvCustom(
              order.awbNo ?? order.orderRefNumber ?? "-",
              Colors.white,
              16,
              textAlignment: TextAlign.left,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Service type + priority tags - shown at the right end of the "Delivery
  // progress" title row; renders nothing when neither applies.
  Widget _orderTags() {
    final order = controller.order;
    final hasType = (order.serviceType ?? "").isNotEmpty;
    // PRIORITY for priority orders; VALUE for any other WhatsApp order.
    final hasDeliveryTag = order.isPriorityOrder || order.isWhatsAppOrder;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasType) _typeBadge(order.serviceType!),
        if (hasType && hasDeliveryTag) SizedBox(width: 8.w),
        if (order.isPriorityOrder)
          _priorityTag()
        else if (order.isWhatsAppOrder)
          _valueTag(),
      ],
    );
  }

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
  // Payment strip - amount to collect (COD / split) or prepaid, plus its
  // collection status. Replaces the old top banner + bottom status card.
  // ---------------------------------------------------------------------
  Widget _paymentStrip() {
    final isCod = controller.isCod;
    final paidOnline = isCod && controller.isPaymentCompleted;
    final color = isCod && !paidOnline ? _amberOFD : AppColors.greenLight;
    final String label;
    final String value;
    final String status;
    if (paidOnline) {
      label = "Paid via payment link";
      value = "QAR ${controller.codAmountToCollect}";
      status = "Paid";
    } else if (isCod && controller.paymentLinkSent) {
      label = "Payment link sent";
      value = "QAR ${controller.codAmountToCollect}";
      status = controller.isCheckingPayment ? "Checking..." : "Pending";
    } else if (isCod) {
      label = controller.isSplitPayment
          ? "Split · COD · collect from customer"
          : "COD · collect from customer";
      value = "QAR ${controller.codAmountToCollect}";
      status = controller.isDelivered
          ? "Collected"
          : (controller.isFailed ? "Not collected" : "Pending");
    } else {
      label = "Prepaid";
      value = "Paid online";
      status = "Paid";
    }
    final strip = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(Get.isDarkMode ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: color.withOpacity(Get.isDarkMode ? 0.24 : 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isCod && !paidOnline
                  ? Icons.payments_outlined
                  : Icons.check_circle_outline,
              color: color,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                utils.tvCustom(
                  label,
                  color,
                  10,
                  textAlignment: TextAlign.left,
                  maxLines: 1,
                ),
                SizedBox(height: 2.h),
                utils.tvCustom(
                  value,
                  color,
                  16,
                  textAlignment: TextAlign.left,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withOpacity(Get.isDarkMode ? 0.3 : 0.16),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: utils.tvCustom(status, color, 10),
          ),
        ],
      ),
    );
    if (controller.currentStep != 4 || !controller.hasPaymentLink) {
      return strip;
    }
    return Column(
      children: [
        strip,
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _paymentLinkActionButton(
                icon: Icons.link,
                label: "Payment link",
                onPressed: _showCodPaymentSheet,
              ),
            ),
            if (controller.paymentLinkSent) ...[
              SizedBox(width: 10.w),
              Expanded(
                child: _paymentLinkActionButton(
                  icon: Icons.refresh,
                  label: "Refresh status",
                  loading: controller.isCheckingPayment,
                  onPressed: controller.refreshPaymentStatus,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Outlined primary-colour button under the payment strip.
  Widget _paymentLinkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool loading = false,
  }) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        side: const BorderSide(color: AppColors.primaryThemeColor, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
      ),
      icon: loading
          ? SizedBox(
              width: 14.sp,
              height: 14.sp,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryThemeColor,
              ),
            )
          : Icon(icon, color: AppColors.primaryThemeColor, size: 16.sp),
      label: utils.tvCustom(
        loading ? "Checking..." : label,
        AppColors.primaryThemeColor,
        12.5,
        maxLines: 1,
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
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        // Sized to its content (the full AWB) within these bounds, instead
        // of a fixed width that cut the AWB off.
        constraints: BoxConstraints(
          minWidth: context.isPhone ? 138.w : 168.0.sp,
          maxWidth: context.isPhone ? 190.w : 220.0.sp,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.isPhone ? 10.w : 12.0.sp,
          vertical: context.isPhone ? 9.h : 11.0.sp,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
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
              11,
              textAlignment: TextAlign.left,
              maxLines: 1,
            ),
            SizedBox(height: 3.h),
            utils.tvCustom(
              (o.consigneeName?.isNotEmpty ?? false)
                  ? o.consigneeName!
                  : (o.merchantName ?? "-"),
              AppColors.greyColor4,
              9.5,
              textAlignment: TextAlign.left,
              maxLines: 1,
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isCurrent
                    ? AppColors.primaryThemeColor
                    : (Get.isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFEFEFEF)),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCurrent) ...[
                    Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: context.isPhone ? 11.sp : 13.0.sp,
                    ),
                    SizedBox(width: 3.w),
                  ],
                  Flexible(
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.blueLight.withOpacity(
                    Get.isDarkMode ? 0.3 : 0.14,
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: utils.tvCustom(
                  controller.isPickupPhase ? "PICKUP" : "DROP-OFF",
                  AppColors.blueLight,
                  9.5,
                ),
              ),
              SizedBox(width: 8.w),
              utils.tvCustom(
                "Next stop",
                AppColors.greyColor4,
                10.5,
                textAlignment: TextAlign.left,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          utils.tvCustom(
            controller.nextStopName,
            AppColors.black,
            13,
            textAlignment: TextAlign.left,
            maxLines: 1,
          ),
          SizedBox(height: 2.h),
          utils.tvCustom(
            controller.nextStopAddress,
            AppColors.greyColor5,
            10.5,
            textAlignment: TextAlign.left,
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: double.infinity,
              height: context.isPhone ? 160.h : 220.h,
              child: Stack(
                children: [
                  Positioned.fill(
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
                  // Top-left, clear of the map's bottom-right zoom controls.
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: _distanceChip(controller.nextStopDistance),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          if (controller.hasOngoingCall) ...[
            _ongoingCallCard(),
            SizedBox(height: 10.h),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: dest == null ? null : controller.openNavigation,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    backgroundColor: AppColors.blueLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  label: utils.tvCustom("Navigate", Colors.white, 12.5),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(child: _callButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _distanceChip(String distance) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? AppColors.greyColor10 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: AppColors.primaryThemeColor,
            size: 13.sp,
          ),
          SizedBox(width: 4.w),
          utils.tvCustom(distance, AppColors.black, 11),
        ],
      ),
    );
  }

  // Call merchant (pickup phase) / customer (delivery phase). Disabled while
  // a call is already being tracked - the ongoing-call card in the progress
  // card takes over until it's ended and logged.
  Widget _callButton() {
    final callDisabled = controller.hasOngoingCall;
    final color = callDisabled
        ? AppColors.greyColor4
        : AppColors.primaryThemeColor;
    return OutlinedButton.icon(
      onPressed: callDisabled ? null : _startCall,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        side: BorderSide(
          color: callDisabled
              ? AppColors.greyColor2
              : AppColors.primaryThemeColor,
          width: 1.4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      icon: Icon(Icons.call_outlined, color: color, size: 16.sp),
      label: utils.tvCustom(
        callDisabled
            ? "In call"
            : (controller.isPickupPhase ? "Call merchant" : "Call customer"),
        color,
        12.5,
        maxLines: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Package card - what the rider is carrying. Hidden when the order has
  // no item details at all.
  // ---------------------------------------------------------------------
  bool get _hasPackageInfo {
    final o = controller.order;
    return (o.itemName ?? "").isNotEmpty ||
        (o.itemDescription ?? "").isNotEmpty ||
        (o.weight ?? "").isNotEmpty ||
        (o.quantity ?? 0) > 0 ||
        (o.remarks ?? "").isNotEmpty;
  }

  Widget _packageCard(Color cardBg) {
    final o = controller.order;
    final quantity = o.quantity ?? 0;
    final facts = <String>[
      if (quantity > 0) "$quantity item${quantity > 1 ? 's' : ''}",
      if ((o.weight ?? "").isNotEmpty) "${o.weight} kg",
    ];
    final description = o.itemDescription ?? "";
    final remarks = o.remarks ?? "";
    final factBg = Get.isDarkMode
        ? Colors.white.withOpacity(0.08)
        : AppColors.greyColor1;
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryThemeColor.withOpacity(
                    Get.isDarkMode ? 0.22 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryThemeColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    utils.tvCustom(
                      "Package",
                      AppColors.greyColor4,
                      10.5,
                      textAlignment: TextAlign.left,
                    ),
                    SizedBox(height: 2.h),
                    utils.tvCustom(
                      (o.itemName ?? "").isNotEmpty ? o.itemName! : "-",
                      AppColors.black,
                      13,
                      textAlignment: TextAlign.left,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (facts.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final fact in facts)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: factBg,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: utils.tvCustom(fact, AppColors.black, 10.5),
                  ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            SizedBox(height: 10.h),
            utils.tvCustom(
              description,
              AppColors.greyColor5,
              10.5,
              textAlignment: TextAlign.left,
              maxLines: 4,
            ),
          ],
          if (remarks.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Get.isDarkMode
                    ? AppColors.blue.withOpacity(0.3)
                    : AppColors.headerColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Get.isDarkMode ? AppColors.white : AppColors.blue,
                    size: 14.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: utils.tvCustom(
                      remarks,
                      AppColors.blue,
                      10.5,
                      textAlignment: TextAlign.left,
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Pinned primary action - stays above the bottom nav so the next step is
  // always reachable without scrolling.
  // ---------------------------------------------------------------------
  Widget _primaryActionBar(bool isTablet, Color cardBg) {
    // Locked until the payment link is paid (or while it's being checked);
    // green once the customer has paid through the link.
    // Also locked at Confirm pickup on a value order outside its window.
    final locked = controller.isDeliveryLockedForPayment ||
        controller.isCheckingPayment ||
        controller.isPickupLockedForWindow;
    final paidOnline = controller.currentStep == 4 &&
        controller.isCod &&
        controller.isPaymentCompleted;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        (isTablet ? 32 : 20).w, 5.h,
        (isTablet ? 32 : 20).w,
        5.h,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(
            color: Get.isDarkMode
                ? Colors.white.withOpacity(0.12)
                : AppColors.greyColor2.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: locked ? null : _onPrimaryActionPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: paidOnline
                    ? AppColors.greenLight
                    : AppColors.primaryThemeColor,
                disabledBackgroundColor: Get.isDarkMode
                    ? AppColors.greyColor5
                    : AppColors.greyColor2,
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
          // SizedBox(height: 6.h),
          // utils.tvCustom(
          //   "Status updates reach the merchant in real time",
          //   AppColors.greyColor4,
          //   9.5,
          // ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Delivery progress card: stepper + primary/secondary actions
  // ---------------------------------------------------------------------
  Widget _progressCard(BuildContext context, Color cardBg) {
    final step = controller.currentStep;
    final failed = controller.isFailed;

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
          Row(
            children: [
              Expanded(
                child: utils.tvCustom(
                  "Delivery progress",
                  AppColors.black,
                  14,
                  textAlignment: TextAlign.left,
                  maxLines: 1,
                ),
              ),
              _orderTags(),
            ],
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
            // Value orders: pickup only inside the API's time window.
            if (controller.isPickupPhase &&
                controller.order.hasValueWindow) ...[
              ValueWindowStrip(
                order: controller.order,
                action: "Pickup",
                onWindowOpen: controller.refreshValueWindow,
              ),
              SizedBox(height: 10.h),
            ],

            if (controller.currentStep == 4 || controller.currentStep == 2) ...[
              SizedBox(height: 4.h),
              // Outlined red with a light red fill - clearly a button, but
              // quieter than the pinned primary action so it's hard to hit
              // by mistake.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openUndeliveredSheet(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.red.withOpacity(
                      Get.isDarkMode ? 0.16 : 0.06,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: const BorderSide(color: AppColors.red, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.red,
                    size: 16.sp,
                  ),
                  label: utils.tvCustom(
                    controller.currentStep == 2 ?"Report a pickup issue" : "Report a delivery issue",
                    AppColors.red,
                    12.5,
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
    if (controller.currentStep == 4 &&
        controller.isCod &&
        !controller.isPaymentCompleted) {
      // Delivery proof (package photo, delivery photo, signature) comes
      // before collecting payment - with or without a payment link.
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
                  controller.hasPaymentLink
                      ? "Collect QAR ${controller.codAmountToCollect}"
                      : "Confirm payment",
                  AppColors.black,
                  16,
                  textAlignment: TextAlign.left,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            utils.tvCustom(
              controller.hasPaymentLink
                  ? "Ask the customer to scan to pay, or send them the link. Delivery unlocks once they've paid."
                  : "Collect QAR ${controller.codAmountToCollect} from the customer before completing this delivery.",
              AppColors.greyColor5,
              13,
              textAlignment: TextAlign.left,
              maxLines: 3,
            ),
            if (controller.hasPaymentLink) ...[
              SizedBox(height: 14.h),
              _paymentLinkQr(),
              SizedBox(height: 14.h),
              _paymentSheetOption(
                icon: Icons.open_in_new,
                color: AppColors.primaryThemeColor,
                title: "Open payment link",
                subtitle: "Customer pays on your phone",
                onTap: () {
                  Get.back();
                  controller.openPaymentLink();
                },
              ),
              SizedBox(height: 10.h),
              _paymentSheetOption(
                icon: Icons.share_outlined,
                color: Get.isDarkMode ? AppColors.blueLight : AppColors.blue,
                title: "Share payment link",
                subtitle: "WhatsApp, SMS or any app",
                onTap: () {
                  Get.back();
                  controller.sharePaymentLink();
                },
              ),
            ] else ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  controller.confirmPrimaryAction(cashCollected: true);
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
                    "Collect QAR ${controller.codAmountToCollect} from the customer before confirming delivery.",
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
          ],
        ),
      ),
      isScrollControlled: true,
    ).then((_) {
      // The customer may have paid by scanning the QR - same pending /
      // refresh-status state as after opening or sharing the link.
      if (controller.hasPaymentLink) controller.markPaymentLinkShown();
    });
  }

  // Scan-to-pay QR of the payment link. Always black on a white card (dark
  // mode too) so phone cameras can read it - which is also why the caption
  // uses AppTextStyle directly: tvCustom would force it white in dark mode.
  Widget _paymentLinkQr() {
    final qrSize = Get.context!.isPhone ? 160.r : 220.r;
    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(14.r, 14.r, 14.r, 10.r),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.greyColor2.withOpacity(0.6)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: (controller.order.paymentLink ?? "").trim(),
              size: qrSize,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text.rich(
              TextSpan(
                text: "Scan to pay ",
                children: [
                  TextSpan(
                    text: "QAR ${controller.codAmountToCollect}",
                    style: AppTextStyle.tsCustom(
                      AppColors.primaryThemeColor,
                      utils.responsiveFontSize(11.sp),
                    ),
                  ),
                ],
              ),
              style: AppTextStyle.tsCustom(
                AppColors.black,
                utils.responsiveFontSize(11.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // One tappable row in the payment sheet (open / share link).
  Widget _paymentSheetOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Get.isDarkMode
                ? Colors.white.withOpacity(0.12)
                : AppColors.greyColor2.withOpacity(0.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: color.withOpacity(Get.isDarkMode ? 0.24 : 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  utils.tvCustom(
                    title,
                    AppColors.black,
                    13.5,
                    textAlignment: TextAlign.left,
                    maxLines: 1,
                  ),
                  SizedBox(height: 2.h),
                  utils.tvCustom(
                    subtitle,
                    AppColors.greyColor5,
                    11,
                    textAlignment: TextAlign.left,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.greyColor4,
              size: 18.sp,
            ),
          ],
        ),
      ),
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
                // Step 2 = arrived at pickup: this sheet marks NOT_PICKED.
                controller.currentStep == 2
                    ? "Why couldn't you pick up this order?"
                    : "Why couldn't you deliver this order?",
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
                    file: controller.undeliveredPhoto,
                    onCapture: controller.captureUndeliveredPhoto,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              GetBuilder<ActiveDeliveryController>(
                builder: (_) => Obx(() {
                  final missingReason =
                      controller.selectedReasonId.value == null;
                  final missingPhoto = controller.undeliveredPhoto == null;
                  // Names exactly what's still needed while the confirm
                  // button is disabled; hidden once both are in.
                  final hint = missingReason && missingPhoto
                      ? "Select a reason and add an attempt photo to continue"
                      : missingReason
                      ? "Select a reason to continue"
                      : missingPhoto
                      ? "Add an attempt photo to continue"
                      : null;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hint != null) ...[
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
                                  hint,
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
                          onPressed: hint != null
                              ? null
                              : () async {
                                  Get.back();
                                  await controller.confirmUndelivered();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            disabledBackgroundColor: AppColors.red.withOpacity(
                              0.4,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                          ),
                          child: utils.tvCustom(
                            controller.currentStep == 2
                                ? "Confirm - Mark as not picked"
                                : "Confirm - Mark as undelivered",
                            Colors.white,
                            14.5,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
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
      // A failed order stops at its current step - "Delivered" for
      // undelivered, "Collected" for not picked.
      if (i == step - 1) {
        return failed ? _StepState.failed : _StepState.current;
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
                  file: controller.packagePhoto,
                  onCapture: controller.capturePackagePhoto,
                ),
              ),
              SizedBox(width: (context.isPhone ? 10 : 16).w),
              Expanded(
                child: _evidenceTile(
                  icon: Icons.camera_alt_outlined,
                  label: "Delivery photo",
                  file: controller.deliveryPhoto,
                  onCapture: controller.captureDeliveryPhoto,
                ),
              ),
              SizedBox(width: (context.isPhone ? 10 : 16).w),
              Expanded(
                child: _evidenceTile(
                  icon: Icons.edit_outlined,
                  label: "Customer signature",
                  file: controller.signatureFile,
                  onCapture: () => _openSignatureSheet(context),
                ),
              ),
            ],
          ),
          if (controller.packagePhoto != null ||
              controller.deliveryPhoto != null ||
              controller.signatureFile != null) ...[
            SizedBox(height: 8.h),
            Center(
              child: utils.tvCustom(
                "Tap a photo to view or retake it",
                AppColors.greyColor4,
                10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Empty: icon + label, tap captures. Captured: the image fills the tile
  // with a tick badge and a retake button; tapping it opens a preview.
  Widget _evidenceTile({
    required IconData icon,
    required String label,
    required File? file,
    required VoidCallback onCapture,
  }) {
    if (file != null) {
      return _capturedEvidenceTile(
        label: label,
        file: file,
        onRetake: onCapture,
      );
    }
    return InkWell(
      onTap: onCapture,
      borderRadius: BorderRadius.circular(12.r),
      child: AspectRatio(
        aspectRatio: 1 / 1.05,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Get.isDarkMode
                  ? Colors.white.withOpacity(0.25)
                  : AppColors.greyColor2,
              width: 1.4,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.greyColor4, size: 20.sp),
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
      ),
    );
  }

  Widget _capturedEvidenceTile({
    required String label,
    required File file,
    required VoidCallback onRetake,
  }) {
    return GestureDetector(
      onTap: () => _showEvidencePreview(
        label: label,
        file: file,
        onRetake: onRetake,
      ),
      child: AspectRatio(
        aspectRatio: 1 / 1.05,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.greenLight, width: 1.6),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The signature PNG has a white background of its own.
                Image.file(file, fit: BoxFit.cover),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 5.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.black.withOpacity(0),
                          AppColors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                    child: utils.tvCustom(
                      label,
                      AppColors.white,
                      9.5,
                      maxLines: 1,
                    ),
                  ),
                ),
                Positioned(
                  top: 5.r,
                  right: 5.r,
                  child: Container(
                    width: 18.r,
                    height: 18.r,
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                    child: Icon(Icons.check, color: AppColors.white, size: 11.r),
                  ),
                ),
                Positioned(
                  top: 2.r,
                  left: 2.r,
                  // Larger hit area than the visible dot.
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRetake,
                    child: Padding(
                      padding: EdgeInsets.all(3.r),
                      child: Container(
                        width: 20.r,
                        height: 20.r,
                        decoration: BoxDecoration(
                          color: AppColors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: AppColors.white,
                          size: 13.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Full-screen view of a captured evidence image with Retake / Done.
  void _showEvidencePreview({
    required String label,
    required File file,
    required VoidCallback onRetake,
  }) {
    Get.dialog(
      Dialog.fullscreen(
        backgroundColor: AppColors.black.withOpacity(0.92),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all((context.isPhone ? 14 : 28).w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: utils.tvCustom(
                        label,
                        AppColors.white,
                        15,
                        textAlignment: TextAlign.left,
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: AppColors.white, size: 22.sp),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: InteractiveViewer(
                      child: Image.file(file, fit: BoxFit.contain),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.back();
                          onRetake();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          side: const BorderSide(color: AppColors.white, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                        ),
                        icon: Icon(Icons.refresh, color: AppColors.white, size: 18.sp),
                        label: utils.tvCustom("Retake", AppColors.white, 14),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryThemeColor,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                        ),
                        child: utils.tvCustom("Done", AppColors.white, 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                  delivered
                      ? "Delivered"
                      : (controller.isNotPicked
                            ? "Not picked up"
                            : "Delivery unsuccessful"),
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
}

enum _StepState { done, current, pending, failed }
