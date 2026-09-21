import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/dashboard/controller/rider_dashboard_controller.dart';
import '../utils/colors.dart';

// Shared avatar rendering (locally-picked file > remote URL > fallback
// initial) - used in the dashboard header, the Account screen and the
// update-profile dialog so all three stay in sync.
Widget buildRiderAvatar({
  required RiderDashboardController controller,
  required double radius,
  required Color backgroundColor,
  required Widget fallback,
}) {
  return Obx(() {
    if (controller.avatar.value != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: FileImage(controller.avatar.value!),
      );
    }
    final avatarUrl = controller.userData.avatar;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: fallback,
      );
    }
    final size = radius * 2;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: (size * 2).round(),
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: backgroundColor,
          alignment: Alignment.center,
          child: SizedBox(
            width: radius * 0.7,
            height: radius * 0.7,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryThemeColor,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: backgroundColor,
          alignment: Alignment.center,
          child: fallback,
        ),
      ),
    );
  });
}
