import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../pages/my_orders/orders/models/orders_model.dart';
import '../utils/colors.dart';
import 'global.dart';

// Confetti-only colors, not app UI tokens - the burst is meant to look
// festive/varied, not to match the brand palette like normal chrome does.
const _kConfettiExtraColors = [Color(0xFFFFC107), Color(0xFF3B82F6), Color(0xFFEC4899)];

void showOrderDeliveredDialog({
  required OrdersData order,
  required bool isCod,
  required VoidCallback onContinue,
}) {
  Get.dialog(
    _OrderDeliveredDialog(order: order, isCod: isCod, onContinue: onContinue),
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.55),
  );
}

class _ConfettiPiece {
  final double leftFraction;
  final double width;
  final double height;
  final bool isCircle;
  final Color color;
  final double dx;
  final double dy;
  final double rotation;
  final double delay;
  final double duration;

  _ConfettiPiece({
    required this.leftFraction,
    required this.width,
    required this.height,
    required this.isCircle,
    required this.color,
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.delay,
    required this.duration,
  });
}

class _OrderDeliveredDialog extends StatefulWidget {
  final OrdersData order;
  final bool isCod;
  final VoidCallback onContinue;

  const _OrderDeliveredDialog({
    required this.order,
    required this.isCod,
    required this.onContinue,
  });

  @override
  State<_OrderDeliveredDialog> createState() => _OrderDeliveredDialogState();
}

class _OrderDeliveredDialogState extends State<_OrderDeliveredDialog>
    with TickerProviderStateMixin {
  late final AnimationController _cardController;
  late final AnimationController _confettiController;
  late final AnimationController _pulseController;
  late final List<_ConfettiPiece> _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = _buildConfetti();
    _cardController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
          ..forward();
    // Both loop for as long as the dialog stays open, so the celebration
    // keeps going instead of freezing once the one-shot entrance finishes.
    _confettiController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
          ..repeat();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
          ..repeat();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<_ConfettiPiece> _buildConfetti() {
    final colors = [
      AppColors.primaryThemeColor,
      AppColors.green,
      _kConfettiExtraColors[0],
      _kConfettiExtraColors[1],
      _kConfettiExtraColors[2],
      AppColors.greenLight,
    ];
    return List.generate(24, (i) {
      final isCircle = i % 3 == 0;
      return _ConfettiPiece(
        leftFraction: (6 + (i * 37) % 88) / 100.0,
        width: (isCircle ? 7 : 6 + (i % 3) * 2).toDouble(),
        height: (isCircle ? 7 : 12 + (i % 4) * 3).toDouble(),
        isCircle: isCircle,
        color: colors[i % colors.length],
        dx: ((i % 2 == 0 ? 1 : -1) * (30 + (i * 13) % 90)).toDouble(),
        dy: (240 + (i * 29) % 220).toDouble(),
        rotation: (220 + (i * 47) % 360) * math.pi / 180,
        delay: ((i * 7) % 30) / 100.0 / 2.0,
        duration: (0.75 + (i * 11) % 60 / 100.0 / 2.0).clamp(0.2, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final isTablet = !context.isPhone;
    final cardWidth = isTablet ? 380.0.sp : 320.0.sp;

    // Get.dialog() shows this as a standalone overlay route, not nested
    // under the screen behind it, so it has no ambient Material/
    // DefaultTextStyle unless one is provided here - without it, Text
    // falls back to Flutter's debug style (yellow with an underline).
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Center(child: _buildCard(context, isDark, isTablet, cardWidth)),
          Positioned.fill(
            child: IgnorePointer(child: _buildConfettiLayer(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, bool isTablet, double cardWidth) {
    final cardBg = isDark ? AppColors.greyColor10 : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subtextColor = isDark ? Colors.white.withOpacity(0.62) : AppColors.greyColor4;
    final infoBg = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFFAFAFA);
    final divider = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEDEDED);

    return AnimatedBuilder(
      animation: Listenable.merge([_cardController, _pulseController]),
      builder: (context, child) {
        final t = _cardController.value;
        final cardT = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - cardT) * 24),
            child: Container(
              width: cardWidth,
              padding: EdgeInsets.fromLTRB(22.sp, 28.sp, 22.sp, 22.sp),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 48,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildBadge(t, _pulseController.value),
                  SizedBox(height: 18.h),
                  utils.tvCustom("Order Delivered!", textColor, 19),
                  SizedBox(height: 6.h),
                  utils.tvCustom(
                    "Great job — the package was handed over successfully.",
                    subtextColor,
                    13.5,
                    maxLines: 2,
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
                    decoration: BoxDecoration(
                      color: infoBg,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Column(
                      children: [
                        _infoRow("AWB Number", widget.order.awbNo ?? "-", textColor,
                            subtextColor),
                        Divider(height: 20.h, thickness: 1, color: divider),
                        _infoRow("Consignee", widget.order.consigneeName ?? "-", textColor,
                            subtextColor),
                        if (widget.isCod) ...[
                          Divider(height: 20.h, thickness: 1, color: divider),
                          _infoRow(
                            "Cash Collected",
                            "QAR ${widget.order.orderAmount ?? "0"}",
                            AppColors.greenLight,
                            subtextColor,
                            valueBold: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        widget.onContinue();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryThemeColor,
                        padding: EdgeInsets.symmetric(vertical: 14.sp),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: utils.tvCustom("Continue", Colors.white, 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value, Color valueColor, Color labelColor,
      {bool valueBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        utils.tvCustom(label, labelColor, 12.5, textAlignment: TextAlign.left),
        Flexible(
          child: utils.tvCustom(
            value,
            valueColor,
            valueBold ? 14 : 13.5,
            textAlignment: TextAlign.right,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(double t, double pulseT) {
    final popT = Curves.elasticOut.transform(((t - 0.08) / 0.5).clamp(0.0, 1.0));
    final checkT = ((t - 0.42) / 0.35).clamp(0.0, 1.0);
    final isDark = Get.isDarkMode;
    // Second ring half a cycle behind the first, so they pulse staggered
    // instead of in lockstep, for as long as the dialog stays open.
    final ring2T = (pulseT + 0.5) % 1.0;

    return SizedBox(
      width: 88.sp,
      height: 88.sp,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ring(pulseT, maxScale: 1.9, maxOpacity: 0.55, isDark: isDark),
          _ring(ring2T, maxScale: 2.6, maxOpacity: 0.4, isDark: isDark),
          Transform.scale(
            scale: popT,
            child: Container(
              width: 72.sp,
              height: 72.sp,
              decoration:
                  const BoxDecoration(color: AppColors.greenLight, shape: BoxShape.circle),
              child: Center(
                child: CustomPaint(
                  size: Size(34.sp, 34.sp),
                  painter: _CheckmarkPainter(checkT, Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double t, {required double maxScale, required double maxOpacity, required bool isDark}) {
    final scale = 0.4 + (maxScale - 0.4) * t;
    final opacity = (maxOpacity * (1 - t)).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 88.sp,
          height: 88.sp,
          decoration: BoxDecoration(
            color: AppColors.greenLight.withOpacity(isDark ? 0.35 : 0.18),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildConfettiLayer(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final originTop = size.height * 0.38;
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        final overall = _confettiController.value;
        return Stack(
          children: _confetti.map((piece) {
            if (overall < piece.delay) return const SizedBox.shrink();
            final localT = ((overall - piece.delay) / piece.duration).clamp(0.0, 1.0);
            final fallT = Curves.easeIn.transform(localT);
            final opacity = localT < 0.75 ? 1.0 : (1 - (localT - 0.75) / 0.25).clamp(0.0, 1.0);
            return Positioned(
              left: size.width * piece.leftFraction,
              top: originTop,
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(piece.dx.w * fallT, piece.dy.h * fallT),
                  child: Transform.rotate(
                    angle: piece.rotation * fallT,
                    child: Container(
                      width: piece.width.w,
                      height: piece.height.w,
                      decoration: BoxDecoration(
                        color: piece.color,
                        borderRadius:
                            BorderRadius.circular(piece.isCircle ? 100 : 2.r),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.72)
      ..lineTo(size.width * 0.80, size.height * 0.30);
    final metric = path.computeMetrics().first;
    final extracted = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}