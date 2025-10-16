import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'colors.dart';

DateTime parseUtcTime(String utcTime) {
  return DateTime.parse(utcTime).toLocal();
}

int getSecondsDifference(DateTime createdAt) {
  DateTime now = DateTime.now();
  return now.difference(createdAt).inSeconds;
}

Column slaTimer(double height,double width,String createdAt, int slaHours,double textSize) {
  DateTime createdDate = parseUtcTime(createdAt);
  int duration = slaHours * 3600;
  int elapsedSeconds = getSecondsDifference(createdDate);
  int initialDuration = (elapsedSeconds < duration) ? elapsedSeconds : duration;
  bool isOrderTimeOver = elapsedSeconds >= duration;


  return Column(
    children: [
      CircularCountDownTimer(
        duration: duration,
        initialDuration: initialDuration,
        controller: CountDownController(),
        width: width,
        height: height,
        ringColor:isOrderTimeOver? AppColors.red :Colors.grey[300]!,
        fillColor:AppColors.green
        ,
        backgroundColor: Get.isDarkMode ? AppColors.greyColor10 :Colors.white,
        isReverseAnimation: true,
        isReverse: true,
        autoStart: true,
        strokeWidth: 5.0,
        textAlign: TextAlign.center,
        textStyle:  TextStyle(fontSize: textSize, color:Get.isDarkMode ? AppColors.white : Colors.black),
        timeFormatterFunction: (defaultFormatterFunction, duration) {
          if (duration.inSeconds == 0) {
            return "00:00";
          } else {
            return Function.apply(defaultFormatterFunction, [duration]);
          }
        },
      ),
      const SizedBox(height: 2,),
      Text("Remaining Time",style: TextStyle(
        color: Get.isDarkMode ? AppColors.white : Colors.black,fontSize: Get.context!.isPhone ? 6.sp:13.sp
      ),
      textAlign: TextAlign.center,)
    ],
  );
}