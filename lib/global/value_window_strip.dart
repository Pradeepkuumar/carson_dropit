import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'consts.dart';
import 'global.dart';
import '../pages/my_orders/orders/models/orders_model.dart';
import '../utils/colors.dart';

// Accept/pickup time-window strip for value orders, driven by the API's
// is_within_window / next_window_* keys. Shared by OrderCardWidget, the
// dashboard's Upcoming Orders rows and the Active Delivery screen. The
// "opens in" countdown ticks down locally each minute between API refreshes,
// and calls onWindowOpen when it reaches 0 so the screen can re-fetch.
class ValueWindowStrip extends StatefulWidget {
  final OrdersData order;
  // "Accept" or "Pickup".
  final String action;
  // Order already collected - the window no longer applies.
  final bool picked;
  // Pass a method tear-off (e.g. controller.getNextDelivery) - several
  // strips reaching 0 together then trigger one refresh, not one each.
  final void Function()? onWindowOpen;

  const ValueWindowStrip({
    super.key,
    required this.order,
    required this.action,
    this.picked = false,
    this.onWindowOpen,
  });

  // Last refresh per callback, for the de-duplication above.
  static final Map<Function, DateTime> _lastRefresh = {};

  // Next window this close (in minutes) shows the amber strip.
  static const int soonMinutes = 15;

  // Statuses before the parcel is collected, where pickup is window-limited.
  static bool isBeforePickup(String? status) =>
      status == ASSIGNED || status == RE_ASSIGNED || status == REACHED;

  static bool hasNextWindow(OrdersData order) =>
      (order.next_window_label ?? "").trim().isNotEmpty;

  static String durationLabel(int minutes) {
    if (minutes < 60) return "$minutes min";
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? "${hours}h" : "${hours}h ${rest}m";
  }

  // "opens in 1h 35m", or "opens at 10:00" once no minutes are left.
  static String opensPhrase(OrdersData order, {int? minutesLeft}) {
    final minutes = minutesLeft ?? order.nextWindowMinutesLeft;
    if (minutes > 0) return "opens in ${durationLabel(minutes)}";
    final start = (order.next_window_start ?? "").trim();
    return start.isNotEmpty ? "opens at $start" : "opens soon";
  }

  @override
  State<ValueWindowStrip> createState() => _ValueWindowStripState();
}

class _ValueWindowStripState extends State<ValueWindowStrip> {
  Timer? _ticker;
  int _minutesLeft = 0;
  // API values the countdown was started from. Refreshes may update the
  // same OrdersData object in place, so compare against these rather than
  // oldWidget.order.
  OrdersData? _seenOrder;
  String? _seenMinutes;
  bool? _seenWithin;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(ValueWindowStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final order = widget.order;
    if (order != _seenOrder ||
        order.next_window_minutes_left != _seenMinutes ||
        order.is_within_window != _seenWithin) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _ticker?.cancel();
    final order = widget.order;
    _seenOrder = order;
    _seenMinutes = order.next_window_minutes_left;
    _seenWithin = order.is_within_window;
    _minutesLeft = order.nextWindowMinutesLeft;
    if (!order.isOutsideValueWindow || _minutesLeft <= 0) return;
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || _minutesLeft <= 0) return;
      setState(() => _minutesLeft--);
      if (_minutesLeft == 0) _onCountdownDone();
    });
  }

  void _onCountdownDone() {
    _ticker?.cancel();
    // A few seconds' grace so the server's window has opened by the time
    // the screen asks again.
    Future.delayed(const Duration(seconds: 5), () {
      final refresh = widget.onWindowOpen;
      if (!mounted || refresh == null) return;
      final now = DateTime.now();
      final last = ValueWindowStrip._lastRefresh[refresh];
      if (last != null && now.difference(last).inSeconds < 30) return;
      ValueWindowStrip._lastRefresh[refresh] = now;
      refresh();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    if (!order.isValueOrder || (!widget.picked && !order.hasValueWindow)) {
      return const SizedBox.shrink();
    }
    final isTablet = !context.isPhone;
    final isDark = Get.isDarkMode;
    final open = order.is_within_window == true;
    final hasNext = ValueWindowStrip.hasNextWindow(order);
    final soon = !open &&
        hasNext &&
        _minutesLeft > 0 &&
        _minutesLeft <= ValueWindowStrip.soonMinutes;

    final String title;
    String? subtitle;
    IconData icon = Icons.lock_outline;
    Color color = AppColors.greyColor5;
    Color bg = isDark ? Colors.white.withOpacity(0.08) : AppColors.greyColor1;

    if (widget.picked) {
      title = "Picked · deliver any time today";
      icon = Icons.check;
      color = AppColors.black;
    } else if (open) {
      title = "${widget.action} open now";
      if (hasNext) subtitle = order.next_window_label!.trim();
      icon = Icons.access_time;
      color = AppColors.greenLight;
      bg = AppColors.greenLight.withOpacity(isDark ? 0.45 : 0.12);
    } else if (!hasNext) {
      title = "No more ${widget.action.toLowerCase()} windows today";
    } else {
      title =
          "${widget.action} ${ValueWindowStrip.opensPhrase(order, minutesLeft: _minutesLeft)}";
      subtitle = "Next: ${order.next_window_label!.trim()}";
      if (soon) {
        color = AppColors.amber;
        bg = AppColors.amber.withOpacity(isDark ? 0.55 : 0.14);
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (isTablet ? 12 : 10).w,
        vertical: (isTablet ? 9 : 7).h,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Icon(
              icon,
              color: isDark ? AppColors.white : color,
              size: (isTablet ? 15 : 13).sp,
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                utils.tvCustom(
                  title,
                  color,
                  11,
                  textAlignment: TextAlign.left,
                  maxLines: 2,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 1.h),
                  utils.tvCustom(
                    subtitle,
                    color,
                    9.5,
                    textAlignment: TextAlign.left,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}