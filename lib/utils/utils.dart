import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:carson_zyppy/utils/text_style_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart' hide Marker;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../global/consts.dart';
import '../global/global.dart';
import 'colors.dart';


typedef OnDropdownItemSelected = void Function(String);

class Utils extends GetxController {
   BuildContext? context = Get.context;



  // final RoundedLoadingButtonController _btnController = RoundedLoadingButtonController();


   double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

   double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

   bool isMobileScreen(BuildContext context) {
    return getScreenWidth(context) < 600;
  }

   bool isTabletScreen(BuildContext context) {
    return getScreenWidth(context) >= 600 && getScreenWidth(context) < 1024;
  }

   bool isLargeScreen(BuildContext context) {
    return getScreenWidth(context) >= 1024;
  }



  // success snackBar this requires title and message in return
  successSnackBar(String title, String message) {
    return Get.snackbar(title, message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        colorText: Colors.white);
  }

   bool _isSnackbarActive = false;

   void errorSnackBar(String title, String message) {
    if (!_isSnackbarActive) {
      _isSnackbarActive = true;
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
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
    return SizedBox(
      height: 40,
      width: Get.width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          textStyle:  TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.normal,
              color: Get.isDarkMode ?  AppColors.black:AppColors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onClick,
        child: Text(
          title!, style:  TextStyle(color: Get.isDarkMode ?  AppColors.black:AppColors.white, fontSize: 18,),),
      ),
    );
  }

  // Icon Button With Border
  Widget iconButton(String? title, void Function() onClick, IconData? icon,
      Color btnColor, Color textAndIconColor) {
    return InkWell(
      onTap: onClick,
      splashColor: AppColors.white,
      child: SizedBox(
        width: null,
        height: Get.context!.isPhone? 30:50,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: btnColor,
              borderRadius: const BorderRadius.all(Radius.circular(5))),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icon,
                  size: 18.0,
                  color: textAndIconColor,
                ),
                const SizedBox(width: 5),
                Text(
                  title.toString(),
                  style: TextStyle(fontSize: Get.context!.isPhone?12:15, color: textAndIconColor),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Icon Button Without Border
  iconButtonWithoutBorder(String? title, void Function() onClick,
      IconData? icon, Color? color) {
    return InkWell(
        onTap: onClick,
        splashColor: Get.isDarkMode ? AppColors.white : color,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 18.0,
                color: Get.isDarkMode ? AppColors.white : color,
              ),
              const SizedBox(width: 5),
              Text(
                title.toString(),
                style: TextStyle(
                    fontSize: 10,
                    color: Get.isDarkMode ? AppColors.white : color),
              )
            ],
          ),
        ));
  }

  iconButtonWithoutBorderVertical(String? title, void Function() onClick,
      IconData? icon, Color? color) {
    return InkWell(
        onTap: onClick,
        splashColor: Get.isDarkMode ? AppColors.white : color,
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 30.0,
                color: Get.isDarkMode ? AppColors.white : color,
              ),
              const SizedBox(height: 5),
              Text(
                title.toString(),
                style: TextStyle(
                    fontSize: 10,
                    color: Get.isDarkMode ? AppColors.white : color),
              )
            ],
          ),
        ));
  }

  // Icon Button with Border
  iconButtonWithRoundedBorder(String? title,double height, void Function() onClick,
      IconData? icon, Color borderColor, IconData? startIcon,double borderSize, Color iconsColor) {
    return InkWell(
      onTap: onClick,
      splashColor: AppColors.primaryThemeColor,
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
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                startIcon,
                size: 20.0,
                color: iconsColor,
              ),
              const SizedBox(width: 1),
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
              const SizedBox(width: 5),
              Icon(
                icon,
                size: 20.0,
                color: iconsColor,
              ),
            ],
          ),
        ),
      ),
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
            SizedBox(
              height: 100,
              width: 100,
              child: Lottie.asset(ANIM_SUCCESS),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(5),
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
      titleStyle: const TextStyle(color: AppColors.red),
      backgroundColor: AppColors.white,
      content: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 80,
              width: 80,
              child: Lottie.asset(ANIM_ERROR),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(5),
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
    closeLoadingDialog();
    return Get.defaultDialog(
      title: "Error !",
      titleStyle: const TextStyle(color: AppColors.red),
      backgroundColor: Get.isDarkMode? AppColors.greyColor10: AppColors.white,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 80,
            width: 80,
            child: Lottie.asset(ANIM_ERROR),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: utils.tvCustom(title, AppColors.red, 15),
            ),
          )
        ],
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

  noDataFoundWidget(String msg) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IntrinsicHeight(
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Image.asset(appLogo,color: Get.isDarkMode ?  AppColors.primaryThemeColor: null,)
                ),
                utils.tvCustom(msg, AppColors.red, 15),
                const SizedBox(height: 25,),
                IntrinsicWidth(
                  child: utils.iconButton("Go Back", (){
                    Navigator.of(Get.context!).pop();
                  }, Icons.arrow_back_ios_new_outlined, AppColors.primaryThemeColor, AppColors.white),
                )
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
           child: Scaffold(
             backgroundColor: AppColors.transparent,
             body: Container(
               height: Get.height,
               width: Get.width,
               color: AppColors.transparent,
               child: Center(
                 child: Container(
                   height: 100,
                   width: 150,
                   alignment: Alignment.center,
                   decoration: utils.boxDecorationWhite(),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     crossAxisAlignment: CrossAxisAlignment.center,
                     children: [
                       Padding(
                         padding: const EdgeInsets.all(10.0),
                         child: SizedBox(
                           height: 50,
                           width: 50,
                           // child: Lottie.asset(ImageConstants.ANIM_LOADING_DOTS),
                           child: utils.iosProgressIndicator(AppColors.primaryThemeColor,"Loading..."),
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
      decoration: const InputDecoration(
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
        Navigator.pop(context!);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.all(10),
        child: const Icon(
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
      gradient: const LinearGradient(
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
      color: Get.isDarkMode ? const Color.fromARGB(255, 107, 105, 105) : Colors.white,
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(103, 0, 0, 0),
          blurRadius: 1,
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
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: FractionalOffset(4.0, 1.0),
        end: FractionalOffset(1.0, 2.0),
        colors: [
          AppColors.primaryThemeColor,
          AppColors.primaryThemeColor,
          AppColors.yellow,
        ],
      ),
      boxShadow: [
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
      borderRadius: const BorderRadius.all(Radius.circular(5)),
    );
  }



  textFieldBorder() {
    return OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.sp),
        borderSide: const BorderSide(color: AppColors.primaryThemeColor, width: 1));
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
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw "Could not open dial pad";
    }

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
  void openMapsFromLatLang(double latitude, double longitude) async {
  final Uri uri = Uri.parse('google.navigation:q=$latitude,$longitude');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch Google Maps';
  }
}

  // Parses a lat/lng string pair off an order model into a LatLng, or null
  // if either is missing/unparseable - shared by every screen that reads
  // pickup/dropoff coordinates off an order.
  LatLng? parseLatLng(String? lat, String? lng) {
    final parsedLat = double.tryParse(lat ?? "");
    final parsedLng = double.tryParse(lng ?? "");
    if (parsedLat == null || parsedLng == null) return null;
    return LatLng(latitude: parsedLat, longitude: parsedLng);
  }

  // A simple colored dot-with-white-ring marker, drawn at runtime so pickup
  // (red) and dropoff (green) markers are visually distinct on the map -
  // the google_navigation_flutter package's default marker icon has no
  // color/hue option. Shared by OrderDetailController and
  // ActiveDeliveryController so both screens render pickup/dropoff
  // identically.
  Future<ImageDescriptor> mapDotMarker(Color color) async {
    const double size = 72;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2 - 4, Paint()..color = Colors.white);
    canvas.drawCircle(center, size / 2 - 10, Paint()..color = color);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return registerBitmapImage(
      bitmap: byteData!,
      imagePixelRatio: 2,
      width: 26,
      height: 26,
    );
  }

  // Draws the actual road-following route via the Directions API (reusing
  // the app's Maps API key, already configured for Android in
  // AndroidManifest.xml). Falls back to a straight connector if the
  // directions request fails so the map never ends up with no line at all.
  Future<void> drawMapRoute(
      GoogleMapViewController controller, LatLng pickup, LatLng dropoff) async {
    List<LatLng> routePoints = [pickup, dropoff];
    try {
      final result = await PolylinePoints().getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(pickup.latitude, pickup.longitude),
          destination: PointLatLng(dropoff.latitude, dropoff.longitude),
          mode: TravelMode.driving,
        ),
        googleApiKey: GOOGLE_MAPS_API_KEY,
      );
      if (result.points.isNotEmpty) {
        routePoints = result.points
            .map((p) => LatLng(latitude: p.latitude, longitude: p.longitude))
            .toList();
      }
    } catch (_) {
      // keep the straight-line fallback
    }

    await controller.addPolylines([
      PolylineOptions(
        points: routePoints,
        strokeColor: AppColors.blue,
        strokeWidth: 4,
      ),
    ]);
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
            colorScheme: const ColorScheme.light(
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
              colorScheme: const ColorScheme.light(
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

  String formatDate(String dateString, String format ) {
     DateTime dateTime = DateTime.parse(dateString).toLocal();
      return DateFormat(format).format(dateTime);

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
    return Get.dialog(
      _SimpleConfirmDialog(
        title: title,
        message: middleText,
        onConfirm: clickListener,
        onCancel: clickListenerCancelButton,
      ),
      barrierDismissible: false,
    );
  }
  simpleDialogContent(String title, String middleText, void Function() clickListener,
      void Function() clickListenerCancelButton,Widget content) {
    return Get.defaultDialog(
      title: title,
      titleStyle: TextStyle(
        fontSize: 15.sp
      ),
      middleText: middleText,
      buttonColor: AppColors.primaryThemeColor,
      onConfirm: clickListener,
      onCancel: clickListenerCancelButton,
      barrierDismissible: false,
      content: content
    );
  }

  // void showCustomDialog({
  //   required String title,
  //   required String middleText,
  //   required List<Widget> buttons,
  // }) {
  //   Get.defaultDialog(
  //     title: title,
  //     middleText: middleText,
  //     barrierDismissible: false,
  //     contentPadding: const EdgeInsets.all(16),
  //     actions: buttons,
  //   );
  // }
  void showCustomDialog({
    required String title,
    required String middleText,
    required List<Widget> buttons,
  }) {
    Get.defaultDialog(
      title: "",
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      radius: 8,
      barrierDismissible: false,
      content: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  middleText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ...buttons,
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 2,
            child: GestureDetector(
              onTap: () => Navigator.of(Get.context!).pop(),
              child: const Icon(Icons.close, color: Colors.red),
            ),
          ),
        ],
      ),
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
          style: const TextStyle(color: AppColors.primaryThemeColor),
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
          style: const TextStyle(color: AppColors.primaryThemeColor),
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
                Navigator.of(Get.context!).pop();
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
    return const Divider(
      thickness: 1,
      height: 5,
      color: AppColors.white,
    );
  }

  divider(double height) {
    return Divider(height: height, thickness: 1);
  }

  dividerBlack() {
    return const Divider(
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
  iosProgressIndicator(Color? color,String? message) {
    return
          CupertinoActivityIndicator(
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
          const Align(
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
      child: SizedBox(
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

  // Scales a base font size up on tablets so the tv* text helpers below
  // stay readable/proportional on larger screens instead of a fixed jump.
  double responsiveFontSize(double size) {
    return context!.isTablet ? size * 1.35 : size;
  }

  tvRegular(String? text, Color textColor, {double? size, int? maxLines}) {
    final baseStyle =
        AppTextStyle.tsRegular(Get.isDarkMode ? AppColors.white : textColor);
    return Text(
      text!.tr,
      softWrap: true,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: baseStyle.copyWith(
          fontSize: responsiveFontSize(size?.sp ?? baseStyle.fontSize?.sp ?? 10.sp)),
    );
  }

  tvCustom(String? text, Color textColor, double fontSize,
      {TextAlign textAlignment = TextAlign.center, int? maxLines}) {
    return Text(
      text ?? "",
      softWrap: true,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: AppTextStyle.tsCustom(
          Get.isDarkMode ? AppColors.white : textColor,
          responsiveFontSize(fontSize.sp)),
      textAlign: textAlignment,
    );
  }
  tvCustomRegular(String? text, Color textColor, double fontSize,
      {TextAlign textAlignment = TextAlign.center, int? maxLines}) {
    return Text(
      text ?? "",
      softWrap: true,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: AppTextStyle.tsCustomRegular(
          Get.isDarkMode ? AppColors.white : textColor,
          responsiveFontSize(fontSize.sp)),
      textAlign: textAlignment,
    );
  }

  tvMedium(String? text, {Color? color, double? size, int? maxLines}) {
    return Text(text!.tr,
        softWrap: true,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        style: TextStyle(
          color: Get.isDarkMode ? AppColors.white : (color ?? Colors.black),
          fontSize: responsiveFontSize(size?.sp?? 10.sp),
        ));
  }

  tvLarge(String? text, Color color, {double? size, int? maxLines}) {
    final baseStyle =
        AppTextStyle.tsBoldLarge(Get.isDarkMode ? AppColors.white : color);
    return Align(
      alignment: Alignment.center,
      child: Text(
        text!.tr,
        softWrap: true,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        style: baseStyle.copyWith(
            fontSize: responsiveFontSize(size ?? baseStyle.fontSize ?? 20)),
      ),
    );
  }

  tvHeading(String? text, Color color, {double? size, int? maxLines}) {
    final baseStyle = AppTextStyle.tsHeading(color);
    return Text(
      text!.tr,
      softWrap: true,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: baseStyle.copyWith(
          fontSize: responsiveFontSize(size ?? baseStyle.fontSize ?? 34)),
    );
  }


  Future<File> saveUiImageToFile(ui.Image image, String fileName) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$fileName.png';
  final file = File(filePath);
  await file.writeAsBytes(buffer);

  return file;
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

    final pickedFile = await imagePicker.pickImage(source: imageSource,maxWidth : 720,maxHeight: 1080,imageQuality: 90 );

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
      hint: const Text('Select a reason'),
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

// Faint scattered isometric-cube wireframes used as the background on
// LoginScreen, SplashScreen, and RiderDashboard's pre-attendance loading
// screen, so all three read as one continuous look instead of each having
// its own copy of the same pattern.
class GeometricBackgroundPainter extends CustomPainter {
  static const _cubes = [
    _GeometricCube(Offset(0.02, 0.14), 100),
    _GeometricCube(Offset(0.30, 0.05), 50),
    _GeometricCube(Offset(-0.04, 0.44), 42),
    _GeometricCube(Offset(0.90, 0.16), 46),
    _GeometricCube(Offset(0.86, 0.80), 78),
    _GeometricCube(Offset(1.06, 0.92), 95),
    _GeometricCube(Offset(0.14, 1.02), 62),
    _GeometricCube(Offset(0.46, 0.98), 34),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final cube in _cubes) {
      _drawCube(
        canvas,
        paint,
        Offset(
          cube.centerFraction.dx * size.width,
          cube.centerFraction.dy * size.height,
        ),
        cube.radius,
      );
    }
  }

  void _drawCube(Canvas canvas, Paint paint, Offset center, double radius) {
    final vertices = List.generate(6, (i) {
      final angle = (math.pi / 180) * (-90 + i * 60);
      return center +
          Offset(math.cos(angle) * radius, math.sin(angle) * radius * 0.86);
    });

    final hexagon = Path()..moveTo(vertices[0].dx, vertices[0].dy);
    for (var i = 1; i < vertices.length; i++) {
      hexagon.lineTo(vertices[i].dx, vertices[i].dy);
    }
    hexagon.close();
    canvas.drawPath(hexagon, paint);

    canvas.drawLine(center, vertices[0], paint);
    canvas.drawLine(center, vertices[2], paint);
    canvas.drawLine(center, vertices[4], paint);
  }

  @override
  bool shouldRepaint(covariant GeometricBackgroundPainter oldDelegate) => false;
}

class _GeometricCube {
  final Offset centerFraction;
  final double radius;
  const _GeometricCube(this.centerFraction, this.radius);
}

class _SimpleConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SimpleConfirmDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    final isTablet = !context.isPhone;
    final cardWidth = isTablet ? 380.0.sp : 320.0.sp;
    final cardBg = isDark ? AppColors.greyColor10 : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.black;
    final subtextColor = isDark ? Colors.white.withOpacity(0.62) : AppColors.greyColor4;
    final iconBg = isDark
        ? AppColors.primaryThemeColor.withOpacity(0.18)
        : AppColors.primaryThemeColor.withOpacity(0.10);
    final outlineColor = isDark ? Colors.white.withOpacity(0.18) : const Color(0xFFE0E0E0);

    // Get.dialog() shows this as a standalone overlay route with no
    // ambient Material/DefaultTextStyle, so Text falls back to Flutter's
    // debug style (yellow with an underline) without this wrapper.
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: cardWidth,
          padding: EdgeInsets.fromLTRB(22.sp, 26.sp, 22.sp, 22.sp),
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
            children: [
              Container(
                width: 56.sp,
                height: 56.sp,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(
                  Icons.help_outline,
                  color: AppColors.primaryThemeColor,
                  size: 26.sp,
                ),
              ),
              SizedBox(height: 16.h),
              utils.tvCustom(title, textColor, 17),
              SizedBox(height: 8.h),
              utils.tvCustom(message, subtextColor, 13.5, maxLines: 4),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                        onCancel();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: outlineColor, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 13.sp),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: utils.tvCustom("Cancel", textColor, 14.5),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryThemeColor,
                        padding: EdgeInsets.symmetric(vertical: 13.sp),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: utils.tvCustom("Ok", Colors.white, 14.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
