import 'dart:ffi';
import 'dart:io';
import 'dart:ui';
import 'package:carson_zyppy/utils/text_style_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global/consts.dart';
import '../global/global.dart';
import 'colors.dart';


typedef OnDropdownItemSelected = void Function(String);

class Utils extends GetxController {
  late BuildContext context;

  // final RoundedLoadingButtonController _btnController = RoundedLoadingButtonController();

  // success snackBar this requires title and message in return
  successSnackBar(String title, String message) {
    return Get.snackbar(title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        colorText: Colors.white);
  }



   bool _isSnackbarActive = false;

   void errorSnackBar(String title, String message) {
    if (!_isSnackbarActive) {
      _isSnackbarActive = true;
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        colorText: Colors.white,
        snackbarStatus: (value){
          if(value == SnackbarStatus.CLOSED){
            _isSnackbarActive = false;
          }
      }
      );
    }
  }

  // // Animated  rounded Button
  // animatedRoundedButton(String? title, void Function() doSomething,
  //     RoundedLoadingButtonController) {
  //   return RoundedLoadingButton(
  //     child: Text(title!,
  //         style: TextStyle(
  //           color: Colors.white,
  //         )),
  //     color: AppColors.black,
  //     controller: RoundedLoadingButtonController,
  //     successColor: AppColors.green,
  //     onPressed: doSomething,
  //     errorColor: AppColors.red,
  //   );
  // }

  mainButton(String? title, void Function() onClick, Color color) {
    return Container(
      height: 40,
      width: Get.width,
      child: ElevatedButton(
        child: Text(
          title!, style: TextStyle(color: AppColors.white, fontSize: 18,),),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          textStyle: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.normal,
              color: AppColors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onClick,
      ),
    );
  }

  // Icon Button With Border
  Widget iconButton(String? title, void Function() onClick, IconData? icon,
      Color btnColor, Color textAndIconColor) {
    return InkWell(
      child: Container(
        width: null,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: btnColor,
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 18.0,
                  color: textAndIconColor,
                ),
                SizedBox(width: 5),
                Text(
                  title.toString(),
                  style: TextStyle(fontSize: 10, color: textAndIconColor),
                )
              ],
            ),
          ),
        ),
      ),
      onTap: onClick,
      splashColor: AppColors.white,
    );
  }

  // Icon Button Without Border
  iconButtonWithoutBorder(String? title, void Function() onClick,
      IconData? icon, Color? color) {
    return InkWell(
        child: Padding(
          padding: EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 18.0,
                color: Get.isDarkMode ? AppColors.white : color,
              ),
              SizedBox(width: 5),
              Text(
                title.toString(),
                style: TextStyle(
                    fontSize: 10,
                    color: Get.isDarkMode ? AppColors.white : color),
              )
            ],
          ),
        ),
        onTap: onClick,
        splashColor: Get.isDarkMode ? AppColors.white : color);
  }

  iconButtonWithoutBorderVertical(String? title, void Function() onClick,
      IconData? icon, Color? color) {
    return InkWell(
        child: Padding(
          padding: EdgeInsets.all(0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 30.0,
                color: Get.isDarkMode ? AppColors.white : color,
              ),
              SizedBox(height: 5),
              Text(
                title.toString(),
                style: TextStyle(
                    fontSize: 10,
                    color: Get.isDarkMode ? AppColors.white : color),
              )
            ],
          ),
        ),
        onTap: onClick,
        splashColor: Get.isDarkMode ? AppColors.white : color);
  }

  // Icon Button with Border
  iconButtonWithRoundedBorder(String? title,double height, void Function() onClick,
      IconData? icon, Color borderColor, IconData? startIcon,double borderSize, Color iconsColor) {
    return InkWell(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: borderColor, // Border color
            width: borderSize, // Border width (1px)
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                startIcon,
                size: 20.0,
                color: iconsColor,
              ),
              SizedBox(width: 1),
              SizedBox(
                width: 150.0,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(
                        color: iconsColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0),
                  ),
                ),
              ),
              SizedBox(width: 5),
              Icon(
                icon,
                size: 20.0,
                color: iconsColor,
              ),
            ],
          ),
        ),
      ),
      onTap: onClick,
      splashColor: AppColors.primaryThemeColor,
    );
  }

  dialogSuccess(String? title, void Function() clickListener) {
    return Get.defaultDialog(
      title: "Success",
      content: Container(
        decoration: utils.roundedBorder(AppColors.green, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              child: Lottie.asset(ANIM_SUCCESS),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: utils.tvLarge(title, AppColors.black),
              ),
            )
          ],
        ),
      ),
      onConfirm: clickListener,
      buttonColor: AppColors.primaryThemeColor,
    );
  }
  nonCancellableDialog(String? title) {
    return Get.defaultDialog(
      title: "Error !",
      titleStyle: TextStyle(color: AppColors.red),
      backgroundColor: AppColors.white,
      content: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              child: Lottie.asset(ANIM_ERROR),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(5),
                child: utils.tvCustom(title, AppColors.red, 15),
              ),
            )
          ],
        ),
      ),
      buttonColor: AppColors.primaryThemeColor,
      barrierDismissible: false
    );
  }

  errorDialog(String? title) {
    return Get.defaultDialog(
      title: "Error !",
      titleStyle: TextStyle(color: AppColors.red),
      backgroundColor: AppColors.white,
      content: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              child: Lottie.asset(ANIM_ERROR),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(5),
                child: utils.tvCustom(title, AppColors.red, 15),
              ),
            )
          ],
        ),
      ),
      buttonColor: AppColors.primaryThemeColor,
    );
    // return AlertDialog(content: Text(title!), actions: [
    //   SizedBox(
    //     width: 100,
    //     child: ElevatedButton(
    //       style: ElevatedButton.styleFrom(
    //         backgroundColor: Colors.pink,
    //         shape:
    //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    //       ),
    //       onPressed: clickListener,
    //       child: const Center(
    //         child: Text(
    //           "Ok",
    //         ),
    //       ),
    //     ),
    //   ),
    // ]);
  }

  elevatedContainer(double height, double width,Color bgColor,
  String name,String count,void Function() onClick) {
   return InkWell(
      onTap: (){
        onClick();
      },
     child: Container(
        height: height,
        width: width,
        decoration: utils.boxDecorationCustomColor(bgColor),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaY: 1, sigmaX: 1),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    utils.tvCustom(name, AppColors.white, 20),
                    utils.tvCustom(count, AppColors.white, 15),
                  ],
                ),
              )),
        ),
      ),
   );
  }

  noDataFoundWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 250,
        width: 250,
        child: Card(
          elevation: 2,
          color: AppColors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  child: Lottie.asset(ANIM_ERROR),
                ),
                utils.tvCustom("No Data Found !", AppColors.red, 15),
                SizedBox(height: 25,),
                utils.iconButton("Go Back", (){
                  Get.back();
                }, Icons.arrow_back_ios_new_outlined, AppColors.primaryThemeColor, AppColors.white)
              ],
            ),
          ),
        ),
      ),
    );
  }


  void showLoadingDialog(String? message) {
     if(Get.isDialogOpen == false) {
       Get.dialog(
         Center(
           child: Container(
             height: Get.height,
             width: Get.width,
             color: AppColors.transparent,
             child: Center(
               child: Container(
                 height: 100,
                 width: 100,
                 alignment: Alignment.center,
                 decoration: utils.boxDecorationWhite(),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   crossAxisAlignment: CrossAxisAlignment.center,
                   children: [
                     Padding(
                       padding: const EdgeInsets.all(10.0),
                       child: Container(
                         height: 50,
                         width: 50,
                         // child: Lottie.asset(ImageConstants.ANIM_LOADING_DOTS),
                         child: utils.iosProgressIndicator(AppColors.primaryThemeColor),
                         // GetPlatform.isAndroid
                         //     ? CircularProgressIndicator(
                         //   color: AppColors.primaryThemeColor,
                         // )
                         //     : utils.iosProgressIndicator(AppColors.white),
                       ),
                     ),
                     utils.tvCustom(
                       message ?? "Loading...", AppColors.black,10)
                   ],
                 ),
               ),
             ),
           ),
         ),
         name: 'loadingDialog',
       );
     }
  }
    void closeLoadingDialog() {
    if (Get.isDialogOpen == true) {
      if (Navigator.of(Get.context!).canPop()) {
        Navigator.of(Get.context!).pop();
      }
    }

  }

  searchBox({required Null Function(dynamic value) onChanged}) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
          labelText: "Search",
          hintText: "Search",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0)))),
    );
  }

  backButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: EdgeInsets.all(10),
        child: Icon(
          Icons.arrow_back,
          color: Colors.black,
          size: 24,
        ),
      ),
    );
  }

  imageView(String imageString, int height, int width) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Image.asset(
        imageString,
        height: height.h,
        width: width.w,
        alignment: Alignment.topCenter,
        fit: BoxFit.fill
      ),
    );
  }

  clickableImageVertical(String name,Color textColor,Color iconColor,String imageString,double height, double width,void Function() onClick){
    return InkWell(
       onTap: (){
         onClick();
       },
       child: Column(
         children: [
           Image.asset(
               imageString,
               height: height,
               width: width,
               alignment: Alignment.topCenter,
               fit: BoxFit.fill
           ),
           tvRegular(name, textColor)
         ],
       ),
     );
  }

  boxDacorationGradient() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      // color: AppColors.mainColorTwo,
      gradient: LinearGradient(
        begin: FractionalOffset(0.0, 0.0),
        end: FractionalOffset(0.0, 1.0),
        colors: [
          AppColors.primaryThemeColor,
          AppColors.primaryThemeColor,
          AppColors.secondryThemeColor, // White
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(156, 0, 0, 0),
          blurRadius: 3,
          offset: Offset(1, 1),
        )
      ],
    );
  }

  boxDecorationWhite() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      backgroundBlendMode: BlendMode.screen,
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(103, 0, 0, 0),
          blurRadius: 3,
          offset: Offset(1, 1),
        )
      ],
    );
  }
  boxDecorationCustomColor(Color color) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: color,
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(103, 0, 0, 0),
          blurRadius: 3,
          offset: Offset(1, 2),
        )
      ],
    );
  }

  boxDecorationTransparent() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      color: Colors.white.withOpacity(0.5),
    );
  }

  boxDecorationBlack() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      color: Colors.black,
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(156, 0, 0, 0),
          blurRadius: 3,
          offset: Offset(1, 1),
        )
      ],
    );
  }

  roundedBorder(Color borderColor, double borderRadius) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: 1.0,
      ),
    );
  }

  boxDacorationVerticalGradient() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: FractionalOffset(4.0, 1.0),
        end: FractionalOffset(1.0, 2.0),
        colors: [
          AppColors.primaryThemeColor,
          AppColors.primaryThemeColor,
          AppColors.yellow,
        ],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(156, 0, 0, 0),
          blurRadius: 3,
          offset: Offset(1, 1),
        )
      ],
    );
  }

  mainBorder() {
    return BoxDecoration(
      border: Border.all(
        width: 2,
        color: AppColors.primaryThemeColor,
      ),
      borderRadius: BorderRadius.all(Radius.circular(5)),
    );
  }



  textFieldBorder() {
    return OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.sp),
        borderSide: BorderSide(color: AppColors.primaryThemeColor, width: 1));
  }

  mainButtonBackground() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      color: AppColors.primaryThemeColor,
      boxShadow: const [
        BoxShadow(
          color: Colors.grey,
          blurRadius: 1,
          offset: Offset(1, 2),
        )
      ],
    );
  }

  baseContainer(String iconData, String title, String count) {
    return Expanded(
      child: Container(
          decoration: BoxDecoration(boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 4,
              offset: Offset(1, 2),
            )
          ], borderRadius: BorderRadius.circular(10), color: AppColors.white
            // gradient: const LinearGradient(
            //   begin: FractionalOffset(-2.0, 1.0),
            //   end: FractionalOffset(1.0, 2.0),
            //   colors: [
            //     AppColors.mainColor,
            //     AppColors.mainColorTwo,
            //   ],
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                child: SizedBox(
                  height: 60,
                  child: Image.asset(iconData),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Text(
                  title,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  count,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
              )
            ],
          )),
    );
  }


  openDialPad(String phoneNumber) async {
    Uri url = Uri(scheme: "tel", path: phoneNumber);

      await launchUrl(url);

  }

  openWhtsApp(String Number) {
    launchUrl(Uri.parse('https://wa.me/$Number'),
        mode: LaunchMode.externalApplication);
  }

  openEmailApp() {
    launchUrl(Uri.parse('https://mail.google.com/mail/u/0/#inbox'),
        mode: LaunchMode.externalApplication);
  }

// Instagram
  openInstagram(String username) {
    launchUrl(Uri.parse('https://instagram.com/$username'),
        mode: LaunchMode.externalApplication);
  }

// Facebook
  openFacebook(String username) {
    launchUrl(Uri.parse('https://facebook.com/$username'),
        mode: LaunchMode.externalApplication);
  }

// Twitter
  openTwitter(String username) {
    launchUrl(Uri.parse('https://twitter.com/$username'),
        mode: LaunchMode.externalApplication);
  }

// LinkedIn
  openLinkedIn(String username) {
    launchUrl(Uri.parse('https://linkedin.com/in/$username'),
        mode: LaunchMode.externalApplication);
  }

  openMaps(String Address) {
    launchUrl(Uri.parse('google.navigation:q=$Address'),
        mode: LaunchMode.externalApplication);
  }

  getTodayDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd-MM-yyyy');
    final String formatted = formatter.format(now);
    return formatted;
  }

  Future<String?> showFutureDateTimePicker(BuildContext context,
      String dateFormat) async {
    // Pick the date first
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryThemeColor,
              onPrimary: AppColors.white,
              onSurface: AppColors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryThemeColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Pick the time after picking the date
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryThemeColor,
                onPrimary: AppColors.white,
                onSurface: AppColors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        String formattedDateTime = DateFormat(dateFormat).format(finalDateTime);
        return formattedDateTime;
      }
    }
    return null;
  }


  // Future<String?> showFutureDateTimePicker(
  //     BuildContext context, String dateFormat) async {
  //   DateTime? pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime.now(),
  //     lastDate: DateTime(2100),
  //     builder: (context, child) {
  //       return Theme(
  //         data: Theme.of(context).copyWith(
  //           colorScheme: ColorScheme.light(
  //             primary: AppColors.primaryThemeColor,
  //             onPrimary: AppColors.white,
  //             onSurface: AppColors.black,
  //           ),
  //           textButtonTheme: TextButtonThemeData(
  //             style: TextButton.styleFrom(
  //               foregroundColor:
  //                   AppColors.primaryThemeColor, // button text color
  //             ),
  //           ),
  //         ),
  //         child: child!,
  //       );
  //     },
  //   );
  //
  //   if (pickedDate != null) {
  //     String formattedDate = DateFormat(dateFormat).format(pickedDate);
  //     return formattedDate;
  //   } else {
  //     return null;
  //   }
  // }

  //Dialog
  simpleDialog(String title, String middleText, void Function() clickListener,
      void Function() clickListenerCancelButton) {
    return Get.defaultDialog(
      title: title,
      middleText: middleText,
      buttonColor: AppColors.primaryThemeColor,
      onConfirm: clickListener,
      onCancel: clickListenerCancelButton,
      barrierDismissible: false,
    );
  }

  //Radio Button
  simpleRadioButtonHorizontal(String title,
      String value,
      String selectedOption,
      void Function() clickListener,) {
    return Row(
      children: <Widget>[
        Radio(
          value: value,
          groupValue: selectedOption,
          activeColor: AppColors.green,
          onChanged: (value) {
            clickListener();
          },
        ),
        Text(
          title,
          style: TextStyle(color: AppColors.primaryThemeColor),
        ),
      ],
    );
  }

  simpleRadioButtonVertical(String title,
      String value,
      String selectedOption,
      void Function() clickListener,) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Radio(
          value: value,
          groupValue: selectedOption,
          activeColor: AppColors.green,
          onChanged: (value) {
            clickListener();
          },
        ),
        Text(
          title,
          style: TextStyle(color: AppColors.primaryThemeColor),
        ),
      ],
    );
  }

  // dialog(String title, List<dynamic> list) {
  //   return Get.defaultDialog(
  //     title: title,
  //     content: SizedBox(
  //       height: 300,
  //       width: Get.width,
  //       child: ListView.builder(
  //         itemCount: list.length,
  //         itemBuilder: (BuildContext context, int index) {
  //           return reasonsItem(list[index]);
  //         },
  //       ),
  //     ),
  //   );
  // }

  void popUpWindow(String title, List<dynamic> list,
      Function(dynamic) onItemSelected) {
    Get.defaultDialog(
      title: title,
      content: SizedBox(
        height: 300,
        width: Get.width,
        child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (BuildContext context, int index) {
            final item = list[index];
            return ListTile(
              title: Text(item.toString()),
              onTap: () {
                onItemSelected(item);
                Get.back();
              },
            );
          },
        ),
      ),
    );
  }

  dropDown() {
    return DropdownButton<dynamic>(
      items: <String>['A', 'B', 'C', 'D'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (_) {},
    );
  }

  whiteDivider() {
    return Divider(
      thickness: 1,
      height: 5,
      color: AppColors.white,
    );
  }

  divider(double height) {
    return Divider(height: height, thickness: 1);
  }

  dividerBlack() {
    return Divider(
      height: 2,
      thickness: 1,
      color: Colors.black,
    );
  }

  dottedIcon(Color? color, double? height) {
    return Image.asset(
      'assets/images/ic_dot.png',
      color: color,
      height: height,
    );
  }

  //ios circularProgressIndicator
  iosProgressIndicator(Color? color) {
    return CupertinoActivityIndicator(
        radius: 20.0, color: color ?? AppColors.white );
  }

  tvMandatoryField(String? text, double fontSize, Color fontColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 2),
      child: Row(
        children: [
          Text(text!,
              softWrap: true,
              style: AppTextStyle.textPoppins14(AppColors.primaryThemeColor)),
          Align(
            alignment: Alignment.topLeft,
            child: Text("*",
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 10,
                )),
          )
        ],
      ),
    );
  }

  tvCombinedField(String? text, String tralingText, double fontSize,
      Color fontColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, bottom: 2),
      child: Container(
        height: 22.sp,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(text!,
                softWrap: true,
                style: AppTextStyle.textPoppins18()),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(tralingText,
                  style: TextStyle(
                    color: fontColor,
                    fontSize: 6,
                  )),
            )
          ],
        ),
      ),
    );
  }

  tvRegular(String? text, Color textColor) {
    return Text(
      text!.tr,
      softWrap: true,
      style: AppTextStyle.tsRegular(textColor),
    );
  }

  tvCustom(String? text, Color textColor, double fontSize) {
    return Text(
      text ?? "",
      softWrap: true,
      style: AppTextStyle.tsCustom(textColor, fontSize),
      textAlign: TextAlign.center,
    );
  }

  tvMedium(String? text) {
    return Text(text!.tr,
        softWrap: true,
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
        ));
  }

  tvLarge(String? text, Color color) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        text!.tr,
        softWrap: true,
        style: AppTextStyle.tsBoldLarge(color),
      ),
    );
  }

  tvHeading(String? text, Color color) {
    return Text(
      text!.tr,
      softWrap: true,
      style: AppTextStyle.tsHeading(color),
    );
  }

  Future<XFile?> pickImageFromGallery() async {
    // Pick an Image From Memory.
    final XFile? image =
    await imagePicker.pickImage(source: ImageSource.gallery);
    return image;
  }

  // Future<XFile?> pickImageFromGallery() async {
  //   final ImagePicker picker = ImagePicker();
  //   final LostDataResponse response = await picker.retrieveLostData();
  //   if (!response.isEmpty) {
  //     final XFile? image =
  //         await imagePicker.pickImage(source: ImageSource.gallery);
  //     //final List<XFile>? files = response.files;
  //     if (image != null) {
  //       return image;
  //     } else {
  //       utils.errorSnackBar(response.exception!.message.toString(), "");
  //     }
  //   }
  //   return null;
  // }

  Future<File?> pickImage(ImageSource imageSource) async {
    // Capture Image From Camera.
    //final pickedFile = await imagePicker.getImage(source: imageSource);
    final pickedFile = await imagePicker.pickImage(source: imageSource);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }

    return null;
  }



  // Future<XFile?> captureImageByCamera() async {
  //   // Capture Image From Camera.
  //   final XFile? image =
  //       await imagePicker.pickImage(source: ImageSource.camera);
  //   return image;
  // }

  //Image Compression
  // Future<File?> compressAndGetFile(File file) async {
  //   var result = await FlutterImageCompress.compressAndGetFile(
  //     file.absolute.path,
  //     "",
  //     quality: 50,
  //   );
  //    File convertedImage = File(result!.path);
  //   return convertedImage;
  // }

  //order Status Row with status
  // orderStatusRow(Rx<OrderDetailsData>? orderDetailsData) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     mainAxisAlignment: MainAxisAlignment.start,
  //     children: [
  //       Row(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Icon(
  //             Icons.check_circle_outline_outlined,
  //             color: AppColors.green,
  //           ),
  //           Column(
  //             children: [
  //               utils.tvMedium("Placed Time"),
  //               utils.tvRegular(
  //                   orderDetailsData?.value.placedTime ?? "", AppColors.black)
  //             ],
  //           )
  //         ],
  //       ),
  //       Padding(
  //         padding: EdgeInsets.only(left: 10),
  //         child: utils.dottedIcon(AppColors.green, 40),
  //       ),
  //       Row(
  //         children: [
  //           Icon(
  //             orderDetailsData!.value.assignedTime == null
  //                 ? Icons.cancel
  //                 : Icons.check_circle_outline_outlined,
  //             color: orderDetailsData.value.assignedTime == null
  //                 ? AppColors.greyColor4
  //                 : AppColors.green,
  //           ),
  //           Column(
  //             children: [
  //               utils.tvMedium("Assigned Time"),
  //               utils.tvRegular(
  //                   orderDetailsData.value.assignedTime ?? "", AppColors.black)
  //             ],
  //           )
  //         ],
  //       ),
  //       Padding(
  //         padding: EdgeInsets.only(left: 10),
  //         child: utils.dottedIcon(
  //             orderDetailsData.value.assignedTime == null
  //                 ? AppColors.greyColor4
  //                 : AppColors.green,
  //             40),
  //       ),
  //       Row(
  //         children: [
  //           Icon(
  //             orderDetailsData.value.pickedTime == null
  //                 ? Icons.cancel
  //                 : Icons.check_circle_outline_outlined,
  //             color: orderDetailsData.value.pickedTime == null
  //                 ? AppColors.greyColor4
  //                 : AppColors.green,
  //           ),
  //           Column(
  //             children: [
  //               utils.tvMedium("Picked Time"),
  //               utils.tvRegular(
  //                   orderDetailsData.value.pickedTime ?? "", AppColors.black)
  //             ],
  //           )
  //         ],
  //       ),
  //       Padding(
  //         padding: EdgeInsets.only(left: 10),
  //         child: utils.dottedIcon(
  //             orderDetailsData.value.pickedTime == null
  //                 ? AppColors.greyColor4
  //                 : AppColors.green,
  //             40),
  //       ),
  //       Row(
  //         children: [
  //           Icon(
  //             orderDetailsData.value.deliveredTime == null
  //                 ? Icons.cancel
  //                 : Icons.check_circle_outline_outlined,
  //             color: orderDetailsData.value.deliveredTime == null
  //                 ? AppColors.greyColor4
  //                 : AppColors.green,
  //           ),
  //           Column(
  //             children: [
  //               utils.tvMedium("Delivered Time"),
  //               utils.tvRegular(
  //                   orderDetailsData.value.deliveredTime ?? "", AppColors.black)
  //             ],
  //           )
  //         ],
  //       ),
  //     ],
  //   );
  // }
  //
  // progressIndicator() {
  //   return Container(
  //     height: 45.h,
  //     width: 45.w,
  //     child: CircularPercentIndicator(
  //       radius: 22.sp,
  //       lineWidth: 5.sp,
  //       startAngle: 0.0,
  //       animation: true,
  //       progressColor: AppColors.primaryThemeColor,
  //       arcBackgroundColor: AppColors.greyColor1,
  //       arcType: ArcType.values[2],
  //       percent: .90,
  //       center: Text(
  //         "91%",
  //         style: AppTextStyle.textManrope12(color: Colors.black),
  //       ),
  //     ),
  //   );
  // }

  Widget reasonDropdown(List<Map<String, dynamic>> reasons,
      String selectedItemId,
      void Function(String?)? onChanged,) {
    return DropdownButton<String>(
      value: selectedItemId,
      hint: Text('Select a reason'),
      onChanged: onChanged,
      items: reasons.map<DropdownMenuItem<String>>((reason) {
        return DropdownMenuItem<String>(
          value: reason["_id"],
          child: Text(reason["reason"]),
        );
      }).toList(),
    );
  }

// passwordField(String? hintText, TextEditingController textEditingController,
//     bool obscureText, void Function() clickListner) {
//   return Material(
//     color: Colors.transparent,
//     child: InkWell(
//       onTap: clickListner,
//       child: TextFormField(
//         controller: textEditingController,
//         textAlign: TextAlign.start,
//         style: TextStyle(fontSize: 14, color: Colors.white),
//         obscureText: obscureText,
//         minLines: 1,
//         maxLines: 1,
//         keyboardType: TextInputType.visiblePassword,
//         decoration: InputDecoration(
//           labelText: hintText,
//           labelStyle: TextStyle(fontSize: 14, color: Colors.white),
//           contentPadding: EdgeInsets.only(left: 30),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30),
//             borderSide: BorderSide(color: Colors.white),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30),
//             borderSide: BorderSide(color: Colors.white, width: 1),
//           ),
//           suffixIcon: Icon(
//             obscureText ? Icons.visibility : Icons.visibility_off,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     ),
//   );
// }
}

// class SwitchUtils {
//   static Widget buildSwitch({
//     required bool value,
//     required ValueChanged<bool> onChanged,
//     required String label,
//     Color? activeColor,
//     Color? inactiveColor,
//   }) {
//     return Row(
//       children: [
//         Expanded(
//           child: Text(
//             label,
//             style: TextStyle(fontSize: 16),
//           ),
//         ),
//         Switch(
//           value: value,
//           onChanged: onChanged,
//           activeColor: activeColor ?? Colors.green,
//           inactiveTrackColor: inactiveColor ?? Colors.grey,
//         ),
//       ],
//     );
//   }
// }

// child: DropdownButton<String>(
//                                                           items: <String>[
//                                                             'A',
//                                                             'B',
//                                                             'C',
//                                                             'D'
//                                                           ].map((String value) {
//                                                             return DropdownMenuItem<
//                                                                 String>(
//                                                               value: value,
//                                                               child: Text(value),
//                                                             );
//                                                           }).toList(),
//                                                           onChanged: (_) {},
//                                                         // ),
