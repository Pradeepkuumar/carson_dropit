import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../models/driver_data.dart';

class AttendanceProgressBar extends StatelessWidget {
  final Attendance? attendance;

  const AttendanceProgressBar({Key? key, required this.attendance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: context.isPhone?30:60,
        height: context.isPhone?50:60,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            FractionallySizedBox(
              heightFactor: double.parse(attendance?.workingHours.toString() ?? "0.0").clamp(0.0, 12.0) / 12.0,
              child: Container(
                decoration: BoxDecoration(
                  color:
                      double.parse(attendance?.workingHours.toString() ?? "0.0") < 5 ? AppColors.red : AppColors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: utils.tvCustom("${attendance?.workingHours.toString()}\nHrs", AppColors.black, 8),
                )),
            Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      utils.tvCustom("${attendance!.date!.day}", AppColors.black, 15),
                      utils.tvCustom(changeMonthToStr(attendance!.date!.month), AppColors.black, 10)
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String changeMonthToStr(int month) {
    switch (month) {
      case 1:
        return "Jan";
      case 2:
        return "Feb";
      case 3:
        return "Mar";
      case 4:
        return "Apr";
      case 5:
        return "May";
      case 6:
        return "Jun";
      case 7:
        return "Jul";
      case 8:
        return "Aug";
      case 9:
        return "Sep";
      case 10:
        return "Oct";
      case 11:
        return "Nov";
      case 12:
        return "Dec";
      default:
        return "Invalid month";
    }
  }
}
