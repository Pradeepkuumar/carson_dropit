import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/material.dart';

ItemMapNotifications(String notificationText) {
  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: Container(
      decoration: utils.roundedBorder(AppColors.primaryThemeColor, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(
            Icons.notifications_rounded,
            color: AppColors.primaryThemeColor,
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              utils.tvCustom(notificationText, AppColors.black, 12),
            ],
          ),
          const Icon(
            Icons.delete_forever,
            color: AppColors.red,
          ),
        ],
      ),
    ),
  );
}
