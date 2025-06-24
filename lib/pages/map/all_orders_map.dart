import 'dart:async';
import 'dart:math';

import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/map/controller/all_orders_map_controller.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../global/consts.dart';
import '../../utils/calculate_sla.dart';
import 'orderItem/clickedOrderItem.dart';

class AllOrdersMapPage extends GetView<AllOrdersMapController> {
  StreamSubscription<RemainingTimeOrDistanceChangedEvent>?
  remainingTimeOrDistanceChangedSubscription;


  final controller = Get.put(AllOrdersMapController());

  var enableMapLiveCamera = false.obs;
  var enableMapType = false.obs;
  var enableNavigation = false.obs;
  var showNotificationView = false.obs;
  late LatLng pickUpLocation;
  late LatLng deliveryLocation;

  var orderDurationByGoogle = "".obs;
  var orderDistanceByGoogle = "".obs;

  AllOrdersMapPage({super.key});


  void _onViewCreated(GoogleNavigationViewController mapController) async {
    WidgetsFlutterBinding.ensureInitialized();
    WakelockPlus.enable();
    controller.navigationViewController = mapController;
    await mapController.setMyLocationEnabled(true);
    for (var marker in controller.markers) {
      mapController.addMarkers([marker]);
    }
    await controller.googleMapsNavigator.setDestinations(Destinations(
      waypoints: controller.waypoints,
      displayOptions: NavigationDisplayOptions(
        showDestinationMarkers: false,
        showStopSigns: true,
        showTrafficLights: true,
      ),
      routingOptions: RoutingOptions(travelMode: NavigationTravelMode.driving),
    ));
    await controller.navigationViewController?.setNavigationUIEnabled(true);
    await controller.navigationViewController?.setSpeedometerEnabled(true);

    final darkMapStyle = await rootBundle.loadString(
        'assets/map_theme/map_theme_dark.json');
    await mapController.setMapStyle(Get.isDarkMode ? darkMapStyle : null);
//     await controller.navigationViewController?.setMapStyle('''
//    [{
//     "featureType": "administrative",
//     "elementType": "geometry",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "featureType": "poi",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "featureType": "road",
//     "elementType": "labels.icon",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   },
//   {
//     "featureType": "transit",
//     "stylers": [
//       {
//         "visibility": "off"
//       }
//     ]
//   }
// ]
//     ''');
    // await controller.navigationViewController?.settings.setTrafficEnabled(true);
  }

  // void _onRemainingTimeOrDistanceChangedEvent(
  //     RemainingTimeOrDistanceChangedEvent event) {
  //   if (!mounted) {
  //     return;
  //   }
  //   var value = event.remainingDistance.toInt();
  //   if (value <= 50) {
  //     setState(() {
  //       isUpdateCardVisible.value = true;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // backgroundColor: AppColors.primaryThemeColor,
          body: Obx(() =>
          controller.isLoading.value ?
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    height: 150,
                    width: Get.width - 50,
                    child: Image.asset(appLogo, color: Get.isDarkMode
                        ? AppColors.primaryThemeColor
                        : null,)),
                utils.iosProgressIndicator(AppColors.primaryThemeColor,
                    "Loading Maps Please wait..."),
                const SizedBox(
                  height: 20,
                ),
                Obx(() {
                  return utils.tvCustom(controller.currentHintText,
                      AppColors.primaryThemeColor, 15);
                }),

              ],
            ),
          )
              : Container(
            child: controller.ordersList.isEmpty ? Center(
              child: utils.noDataFoundWidget("No Order For Pickup/Delivery"),
            ) : Stack(children: [
              controller.initializeNavigation.value
                  ? GoogleMapsNavigationView(
                key: ValueKey(controller.mapType),
                gestureRecognizers: Set()
                  ..add(Factory<PanGestureRecognizer>(
                          () => PanGestureRecognizer()))..add(
                      Factory<ScaleGestureRecognizer>(
                              () => ScaleGestureRecognizer())),
                onViewCreated: _onViewCreated,
                initialMapType: controller.mapType,
                initialNavigationUIEnabledPreference:
                NavigationUIEnabledPreference.automatic,
                initialCameraPosition: CameraPosition(
                  target: controller.currentLocation!,
                  zoom: 14,
                ),
                onMarkerClicked: (value) async {
                  if (value != "current_location") {
                    controller.selectedOrderAwbId.value = value;
                    await controller.selectedLocationOrders();
                    controller.viewAcceptView.value = true;
                    controller.bottomBarListType.value = 0;
                  } else {
                    if (kDebugMode) {
                      print("Marker not found in map.");
                    }
                  }
                },
              )
                  : Center(
                child: utils.iosProgressIndicator(
                    AppColors.primaryThemeColor,
                    "Loading maps please wait..."),
              ),

              Obx(() {
                return Visibility(
                  visible: controller.currentLocationOrders.isNotEmpty
                      ? controller.currentLocationOrders.first.status ==
                      REACHED || controller
                      .markUnDelivered.value || controller
                      .markDelivered.value : controller.ordersList.first
                      .status == REACHED || controller
                      .markUnDelivered.value || controller
                      .markDelivered.value,
                  child: Positioned(
                      top: 100,
                      left: 10,
                      child: Container(
                          decoration: utils.boxDecorationWhite(),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Obx(() {
                                  return CircularCountDownTimer(
                                    duration: int.tryParse(
                                        controller.currentLocationOrders.isNotEmpty ? controller.currentLocationOrders.first.status == REACHED ? controller.currentLocationOrders.first.pickup_buffer_time_in_minutes! : controller.currentLocationOrders.first.dropoff_buffer_time_in_minutes!
                                            : controller.ordersList.first.status == REACHED ? controller.ordersList.first.pickup_buffer_time_in_minutes! :
                                        controller.ordersList.first.dropoff_buffer_time_in_minutes!)! *
                                        60,
                                    initialDuration: 0,
                                    controller: CountDownController(),
                                    width: 80,
                                    height: 80,
                                    ringColor: Get.isDarkMode
                                        ? AppColors.white
                                        : Colors.grey[300]!,
                                    fillColor: AppColors.green,
                                    backgroundColor: Get.isDarkMode ? AppColors
                                        .greyColor10 : Colors.white,
                                    isReverseAnimation: true,
                                    isReverse: true,
                                    autoStart: true,
                                    strokeWidth: 5.0,
                                    textAlign: TextAlign.center,
                                    textStyle: TextStyle(
                                        fontSize: 15,
                                        color: Get.isDarkMode
                                            ? AppColors.white
                                            : Colors.black),
                                    timeFormatterFunction: (
                                        defaultFormatterFunction, duration) {
                                      if (duration.inSeconds == 0) {
                                        return "00:00";
                                      } else {
                                        return Function.apply(
                                            defaultFormatterFunction,
                                            [duration]);
                                      }
                                    },
                                  );
                                }),
                                const SizedBox(height: 5,),
                                Text("Buffer Time", style: TextStyle(
                                    color: Get.isDarkMode
                                        ? AppColors.white
                                        : Colors.black,
                                    fontSize: Get.context!.isPhone ? 10 : 13
                                ),
                                  textAlign: TextAlign.center,)
                              ],
                            ),
                          )
                      )
                  ),
                );
              }),
              Obx(() {
                return Positioned(
                  top: 100,
                  right: 10,
                  child: Column(
                    children: [
                      Container(
                        decoration: utils.boxDecorationWhite(),
                        height: controller.currentLocationOrders
                            .isNotEmpty
                            ? controller.currentLocationOrders.first
                            .status == PICKED ? 550.sp : 185.sp
                            : controller
                            .ordersList.first.status == PICKED
                            ? 550.sp
                            : 185.sp,
                        width: controller.currentLocationOrders
                            .isNotEmpty
                            ? controller.currentLocationOrders.first
                            .status == PICKED ? 330.sp : 150.sp
                            : controller
                            .ordersList.first.status == PICKED
                            ? 330.sp
                            : 150.sp,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              utils.tvCustom(
                                  "Current Order", AppColors.primaryThemeColor,
                                  14),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "Order No.",
                                        style: TextStyle(
                                          fontSize:
                                          Get.context!.isPhone ? 12 : 15,
                                          color: Get.isDarkMode ? AppColors
                                              .white : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        controller
                                            .currentLocationOrders.isNotEmpty
                                            ? controller
                                            .currentLocationOrders.first.awbNo
                                            .toString()
                                            : controller.ordersList.first.awbNo
                                            .toString(),
                                        style: TextStyle(
                                          fontSize:
                                          Get.context!.isPhone ? 12 : 15,
                                          color: Get.isDarkMode ? AppColors
                                              .white : AppColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  slaTimer(
                                      40.sp,
                                      40.sp,
                                      controller.currentLocationOrders.isNotEmpty ? controller.currentLocationOrders
                                          .first
                                          .createdAt
                                          .toString()
                                          : controller.ordersList.first
                                          .createdAt
                                          .toString(),
                                      int.tryParse(controller
                                          .currentLocationOrders
                                          .isNotEmpty
                                          ? controller.currentLocationOrders
                                          .first.sla_in_hours
                                          .toString()
                                          : controller
                                          .ordersList.first.sla_in_hours
                                          .toString()
                                          .toString()) ??
                                          0,
                                      12),
                                ],
                              ),
                              Column(
                                children: [
                                  customRow("Zone",
                                      controller.currentLocationOrders
                                          .isNotEmpty
                                          ? controller.currentLocationOrders
                                          .first.consigneeZone! : controller
                                          .ordersList.first.consigneeZone!),
                                  customRow("Street",
                                      controller.currentLocationOrders
                                          .isNotEmpty
                                          ? controller.currentLocationOrders
                                          .first.consigneeStreetNumber!
                                          : controller
                                          .ordersList.first
                                          .consigneeStreetNumber!),
                                  customRow("Building",
                                      controller.currentLocationOrders
                                          .isNotEmpty
                                          ? controller.currentLocationOrders
                                          .first.consigneeBuildingNo!
                                          : controller
                                          .ordersList.first
                                          .consigneeBuildingNo!),
                                ],
                              ),
                              Visibility(
                                  visible: controller.currentLocationOrders
                                      .isNotEmpty
                                      ? controller.currentLocationOrders.first
                                      .status == PICKED ? true : false
                                      : controller
                                      .ordersList.first.status == PICKED
                                      ? true
                                      : false,
                                  child:
                                  Column(

                                    children: [
                                      Column(
                                        children: [
                                          customRow("Order SLA", "${controller
                                              .currentLocationOrders.isNotEmpty
                                              ? controller.currentLocationOrders
                                              .first.sla_in_hours : controller
                                              .ordersList.first
                                              .sla_in_hours}(Hrs)"),
                                          customRow("Pickup-Delivery Distance",
                                              controller.currentLocationOrders
                                                  .isNotEmpty
                                                  ? controller
                                                  .currentLocationOrders.first
                                                  .distance! : controller
                                                  .ordersList.first.distance!),
                                          customRow("Approx. Time",
                                              controller.currentLocationOrders
                                                  .isNotEmpty
                                                  ? controller
                                                  .currentLocationOrders.first
                                                  .duration! : controller
                                                  .ordersList.first.duration!),
                                          customRow("Order Amount.",
                                              controller.currentLocationOrders
                                                  .isNotEmpty
                                                  ? controller
                                                  .currentLocationOrders.first
                                                  .orderAmount ! : controller
                                                  .ordersList.first
                                                  .orderAmount!),
                                          customRow("Weight.",
                                              controller.currentLocationOrders
                                                  .isNotEmpty
                                                  ? controller
                                                  .currentLocationOrders.first
                                                  .weight! : controller
                                                  .ordersList.first.weight!),
                                          customRow("Consignee Name",
                                              controller.currentLocationOrders
                                                  .isNotEmpty
                                                  ? controller
                                                  .currentLocationOrders.first
                                                  .consigneeAddress!
                                                  : controller
                                                  .ordersList.first
                                                  .consigneeAddress!),
                                        ],
                                      ),
                                      SizedBox(height: 20,),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .start,
                                        crossAxisAlignment: CrossAxisAlignment
                                            .start,
                                        children: [
                                          customColumn("Pick-Up Location",
                                              controller.currentLocationOrders
                                                  .isNotEmpty
                                                  ? controller
                                                  .currentLocationOrders.first
                                                  .pickupAddress! : controller
                                                  .ordersList.first
                                                  .pickupAddress!),
                                          customColumn("Drop-Off Location",
                                              controller.currentLocationOrders
                                                  .isNotEmpty
                                                  ? controller
                                                  .currentLocationOrders.first
                                                  .consigneeAddress!
                                                  : controller
                                                  .ordersList.first
                                                  .consigneeAddress!),
                                        ],
                                      ),
                                    ],

                                  )
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Visibility(
                                visible: controller.currentLocationOrders
                                    .isNotEmpty
                                    ? controller.currentLocationOrders.first
                                    .status == PICKED ? true : false
                                    : controller
                                    .ordersList.first.status == PICKED
                                    ? true
                                    : false,
                                child: SizedBox(
                                  width: 150.sp,
                                  height: 30.sp,
                                  child: utils.mainButton("Mark OFD", () async {
                                    controller.selectedOrder.value =
                                    controller.currentLocationOrders.isNotEmpty
                                        ? controller.currentLocationOrders.first
                                        : controller.ordersList.first;
                                    bool isUpdated = await controller
                                        .updateOrder(
                                        OFD);
                                    if (isUpdated) {
                                      controller.startGuidedNavigation();
                                    }
                                  },
                                      AppColors.primaryThemeColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      InkWell(
                          onTap: () {
                            controller.bottomBarListType.value = 0;
                            controller.viewAcceptView.value = true;
                          },
                          child: Container(
                              decoration: utils.boxDecorationWhite(),
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: utils.tvCustom(
                                    "Show All Orders",
                                    AppColors.primaryThemeColor,
                                    14),
                              ))),
                    ],
                  ),
                );
              }),


              Positioned(
                  bottom: 1,
                  right: 10,
                  child: Row(
                    children: [
                      Visibility(
                        visible: !controller.isNavigationRunning.value,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: InkWell(
                            onTap: () {
                              controller.startGuidedNavigation();
                            },
                            child: Container(
                              height: context.isPhone ? 62 : 100,
                              width: context.isPhone ? 60 : 100,
                              decoration: utils.boxDecorationWhite(),
                              child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Column(
                                    children: [
                                      Icon(Icons.navigation,
                                          size: enableMapType.value
                                              ? context.isPhone
                                              ? 30
                                              : 50
                                              : context.isPhone
                                              ? 35
                                              : 55,
                                          color: AppColors.selectedBlue),
                                      Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          enableMapType.value
                                              ? "Start"
                                              : "Start",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize:
                                              context.isPhone ? 10 : 20),
                                        ),
                                      )
                                    ],
                                  )),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          controller.mapType =
                          (controller.mapType == MapType.normal)
                              ? MapType.hybrid
                              : MapType.normal;
                          enableMapType.toggle();
                        },
                        child: Obx(() {
                          return Container(
                              height: context.isPhone ? 60 : 100,
                              width: context.isPhone ? 60 : 100,
                              decoration: utils.boxDecorationWhite(),
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Column(
                                  children: [
                                    Icon(Icons.map,
                                        size: enableMapType.value
                                            ? context.isPhone
                                            ? 30
                                            : 50
                                            : context.isPhone
                                            ? 35
                                            : 55,
                                        color: enableMapType.value
                                            ? AppColors.greyColor4
                                            : AppColors.selectedBlue),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        enableMapType.value
                                            ? "Normal"
                                            : "Satellite",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize:
                                            context.isPhone ? 10 : 20),
                                      ),
                                    )
                                  ],
                                ),
                              ));
                        }),
                      ),
                      // Padding(
                      //   padding: EdgeInsets.all(5),
                      //   child: InkWell(
                      //     onTap: () {
                      //       enableNavigation.toggle();
                      //       if(enableNavigation.value) {
                      //         startGuidedNavigation();
                      //       }else{
                      //         stopGuidedNavigation();
                      //       }
                      //     },
                      //     child: Obx(() {
                      //       return Container(
                      //           height: 65,
                      //           width: 60,
                      //           decoration: utils.boxDecorationWhite(),
                      //           child:Column(
                      //             children: [
                      //               Icon(Icons.navigation,
                      //                   size: enableNavigation.value ? 35 : 30,
                      //                   color: enableNavigation.value
                      //                       ? AppColors.selectedBlue
                      //                       : AppColors.greyColor4),
                      //               Align(
                      //                 alignment: Alignment.center,
                      //                 child:  Text(enableNavigation.value?"Stop Navigation":"Start Navigation",textAlign: TextAlign.center,style: TextStyle(fontSize: 10),),
                      //               )
                      //
                      //             ],
                      //           )
                      //       );
                      //     }),
                      //   ),
                      // ),
                    ],
                  )),
              Obx(() {
                return Visibility(
                  visible: controller.viewAcceptView.value,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: utils.boxDecorationWhite(),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          children: [
                            Visibility(
                              visible: controller
                                  .bottomBarListType
                                  .value == 0,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                    onTap: () {
                                      controller.viewAcceptView.value = false;
                                    },
                                    child: const Icon(
                                      Icons.cancel,
                                      color: AppColors.red,
                                      size: 20,
                                    )),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () {
                                      if (controller.selectedOrderIndex.value >
                                          0) {
                                        controller.selectedOrderIndex.value--;
                                        controller.pageController.animateToPage(
                                          controller.selectedOrderIndex.value,
                                          duration:
                                          const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: const Icon(
                                      Icons.arrow_back_ios,
                                      color: AppColors.greyColor4,
                                      size: 15,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 10,
                                  child: SizedBox(
                                    height: min(350.sp, 400.sp),
                                    child: PageView.builder(
                                        scrollDirection: Axis.horizontal,
                                        controller: controller.pageController,
                                        itemCount: controller
                                            .bottomBarListType
                                            .value ==
                                            0
                                            ? controller.ordersList.length
                                            : controller
                                            .currentLocationOrders.length,
                                        itemBuilder: (context, position) {
                                          return clickedOrderItem(
                                              controller.bottomBarListType
                                                  .value == 0
                                                  ? controller
                                                  .ordersList[position]
                                                  : controller
                                                  .currentLocationOrders[
                                              position],
                                                  (clickedOrder, type) async {
                                                controller.selectedOrder.value =
                                                    clickedOrder;
                                                await controller.setMarkers();
                                                if (type == updateStatus) {
                                                  if (clickedOrder.status ==
                                                      REACHED) {
                                                    bool isTrue = await controller
                                                        .calculateBufferTime(
                                                        DateTime.now(),
                                                        PICKED);
                                                    if (isTrue) {
                                                      controller.updateOrder(
                                                          PICKED);
                                                    }
                                                  } else
                                                  if (clickedOrder.status ==
                                                      ASSIGNED ||
                                                      clickedOrder.status ==
                                                          RE_ASSIGNED) {
                                                    controller.updateOrder(
                                                        REACHED);
                                                    controller.startTime =
                                                        DateTime.now();
                                                  } else
                                                  if (clickedOrder.status ==
                                                      PICKED) {
                                                    controller.updateOrder(
                                                        OFD);
                                                  }
                                                } else
                                                if (type == updateOrder) {
                                                  controller.viewAcceptView
                                                      .value = false;
                                                  controller
                                                      .isUpdateCardVisibleForUpdate
                                                      .value = true;
                                                }
                                              },
                                              controller.bottomBarListType
                                                  .value ==
                                                  0
                                                  ? 0
                                                  : 1);
                                        }),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () {
                                      if (controller
                                          .selectedOrderIndex.value <
                                          controller.ordersList.length -
                                              1) {
                                        controller
                                            .selectedOrderIndex.value++;
                                        controller.pageController
                                            .animateToPage(
                                          controller
                                              .selectedOrderIndex.value,
                                          duration: const Duration(
                                              milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppColors.greyColor4,
                                      size: 15,
                                    ),
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
              }),
              Obx(() {
                return Visibility(
                  visible: controller.isUpdateCardVisibleForUpdate.value,
                  child: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Obx(() {
                              //   return AnimatedContainer(
                              //       width: showNotificationView.value
                              //           ? 250.0
                              //           : 50.0,
                              //       height: showNotificationView.value
                              //           ? 350.0
                              //           : 50.0,
                              //       decoration: utils.boxDecorationWhite(),
                              //       alignment: showNotificationView.value
                              //           ? Alignment.center
                              //           : AlignmentDirectional.topCenter,
                              //       duration: const Duration(seconds: 1),
                              //       curve: Curves.fastOutSlowIn,
                              //       child: Padding(
                              //           padding: const EdgeInsets.all(8.0),
                              //           child: showNotificationView.value
                              //               ? Column(
                              //                   children: [
                              //                     Row(
                              //                       mainAxisAlignment:
                              //                           MainAxisAlignment
                              //                               .spaceBetween,
                              //                       children: [
                              //                         utils.tvCustom(
                              //                             "Order Notifications",
                              //                             AppColors
                              //                                 .primaryThemeColor,
                              //                             13),
                              //                         InkWell(
                              //                           onTap: () {
                              //                             setState(() {
                              //                               controller.getNotification();
                              //                               showNotificationView
                              //                                   .toggle();
                              //                             });
                              //                           },
                              //                           child: const Icon(
                              //                             Icons.close,
                              //                             color: AppColors.red,
                              //                           ),
                              //                         )
                              //                       ],
                              //                     ),
                              //                     utils.dividerBlack(),
                              //                     Expanded(
                              //                       child: ListView.builder(
                              //                           itemCount: controller.notificationList.length,
                              //                           itemBuilder: (context, pos) {
                              //                             return ItemMapNotifications(
                              //                                 controller.notificationList[pos]);
                              //                           }),
                              //                     )
                              //                   ],
                              //                 )
                              //               : InkWell(
                              //                   onTap: () {
                              //                     setState(() {
                              //                       showNotificationView
                              //                           .toggle();
                              //                     });
                              //                   },
                              //                   child: const Center(
                              //                     child: Icon(
                              //                       Icons.notifications,
                              //                       color: AppColors
                              //                           .primaryThemeColor,
                              //                     ),
                              //                   ))));
                              // }),
                              // InkWell(
                              //   onTap: () {
                              //     enableMapLiveCamera.toggle();
                              //   },
                              //   child: Obx(() {
                              //     return Container(
                              //       height: 50,
                              //       width: 50,
                              //       decoration: utils.boxDecorationWhite(),
                              //       child: Icon(Icons.share_location_sharp,
                              //           size:
                              //               enableMapLiveCamera.value ? 36 : 30,
                              //           color: enableMapLiveCamera.value
                              //               ? AppColors.selectedBlue
                              //               : AppColors.greyColor4),
                              //     );
                              //   }),
                              // ),
                            ]),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom:
                              controller.markDelivered.value ? 10 : 100),
                          child: Container(
                            decoration: utils.boxDecorationWhite(),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Obx(() {
                                  return Column(
                                    children: [
                                      Column(
                                        children: [
                                          Visibility(
                                            visible: controller
                                                .markDelivered.value ||
                                                controller
                                                    .markUnDelivered.value,
                                            child: Align(
                                                alignment: Alignment.topRight,
                                                child: InkWell(
                                                    onTap: () {
                                                      controller.markDelivered
                                                          .value = false;
                                                      controller
                                                          .markUnDelivered
                                                          .value = false;
                                                    },
                                                    child: const Icon(
                                                        Icons.cancel,
                                                        color:
                                                        AppColors.red))),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          // Row(
                                          //   mainAxisAlignment:
                                          //       MainAxisAlignment
                                          //           .spaceBetween,
                                          //   children: [
                                          //     utils.tvMedium(
                                          //         "Pickup to Delivery Distance"),
                                          //     utils.tvCustom(
                                          //         orderDistanceByGoogle.value,
                                          //         AppColors.blue,
                                          //         10),
                                          //   ],
                                          // ),
                                          // Row(
                                          //   mainAxisAlignment:
                                          //       MainAxisAlignment
                                          //           .spaceBetween,
                                          //   children: [
                                          //     utils.tvMedium(
                                          //         "Estimated Time By Google"),
                                          //     utils.tvCustom(
                                          //         orderDurationByGoogle.value,
                                          //         AppColors.primaryThemeColor,
                                          //         10),
                                          //   ],
                                          // ),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              utils.tvMedium("Order Number"),
                                              utils.tvMedium(controller
                                                  .selectedOrder
                                                  .value
                                                  .awbNo ??
                                                  ""),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              utils.tvMedium("status"),
                                              utils.tvCustom(
                                                  controller.selectedOrder
                                                      .value.status ??
                                                      "",
                                                  AppColors.green,
                                                  10),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              utils.tvMedium("Item"),
                                              utils.tvCustom(
                                                  "${controller.selectedOrder
                                                      .value
                                                      .itemName}(${controller
                                                      .selectedOrder.value
                                                      .quantity})",
                                                  AppColors.black,
                                                  10),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              utils.tvMedium("Order Amount"),
                                              utils.tvCustom(
                                                  "${controller.selectedOrder
                                                      .value.orderAmount}(Qar)",
                                                  AppColors.black,
                                                  10),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                            children: [
                                              utils.tvMedium("Merchant Name"),
                                              utils.tvCustom(
                                                  controller
                                                      .selectedOrder
                                                      .value
                                                      .merchantName ??
                                                      "",
                                                  AppColors.black,
                                                  10),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Obx(() {
                                            return Visibility(
                                                visible: controller
                                                    .markDelivered
                                                    .value ||
                                                    controller.markUnDelivered
                                                        .value,
                                                child: Column(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                        children: [
                                                          utils.tvCustom(
                                                              "Image Proof",
                                                              AppColors
                                                                  .primaryThemeColor,
                                                              10),
                                                          InkWell(
                                                              onTap: () {
                                                                controller
                                                                    .captureImage(
                                                                    ImageSource
                                                                        .camera,
                                                                    imageOne);
                                                              },
                                                              child:
                                                              const Icon(
                                                                Icons.refresh,
                                                                color:
                                                                AppColors
                                                                    .blue,
                                                                size: 20,
                                                              ))
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .all(5),
                                                      child: Container(
                                                        height: 200,
                                                        width:
                                                        double.infinity,
                                                        decoration: utils
                                                            .roundedBorder(
                                                            AppColors
                                                                .primaryThemeColor,
                                                            5),
                                                        child: controller
                                                            .image
                                                            .value !=
                                                            null
                                                            ? Image.file(
                                                          controller
                                                              .image
                                                              .value!,
                                                          fit: BoxFit
                                                              .fill,
                                                        )
                                                            : InkWell(
                                                          onTap: () {
                                                            controller
                                                                .captureImage(
                                                                ImageSource
                                                                    .camera,
                                                                imageOne);
                                                          },
                                                          child: Column(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .camera,
                                                                size:
                                                                80,
                                                                color: AppColors
                                                                    .primaryThemeColor,
                                                              ),
                                                              utils.tvCustom(
                                                                  "capture Image",
                                                                  AppColors
                                                                      .primaryThemeColor,
                                                                  10)
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                        children: [
                                                          utils.tvCustom(
                                                              "Delivery Proof (optional)",
                                                              AppColors
                                                                  .primaryThemeColor,
                                                              10),
                                                          InkWell(
                                                              onTap: () {
                                                                utils
                                                                    .showCustomDialog(
                                                                  title:
                                                                  "Need Your Action",
                                                                  middleText:
                                                                  "Choose Image Source",
                                                                  buttons: [
                                                                    TextButton
                                                                        .icon(
                                                                      onPressed:
                                                                          () {
                                                                        controller
                                                                            .captureImage(
                                                                            ImageSource
                                                                                .camera,
                                                                            imageTwo);
                                                                        Get
                                                                            .back();
                                                                      },
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .camera_alt,
                                                                          color:
                                                                          AppColors
                                                                              .primaryThemeColor),
                                                                      label: const Text(
                                                                          "Camera",
                                                                          style:
                                                                          TextStyle(
                                                                              color: AppColors
                                                                                  .primaryThemeColor)),
                                                                    ),
                                                                    Obx(() {
                                                                      return Visibility(
                                                                        visible: controller
                                                                            .markUnDelivered
                                                                            .value ==
                                                                            true &&
                                                                            !controller
                                                                                .markUnDelivered
                                                                                .value,
                                                                        child: TextButton
                                                                            .icon(
                                                                          onPressed:
                                                                              () {
                                                                            controller
                                                                                .captureImage(
                                                                                ImageSource
                                                                                    .gallery,
                                                                                imageTwo);
                                                                            Get
                                                                                .back();
                                                                          },
                                                                          icon: const Icon(
                                                                              Icons
                                                                                  .image,
                                                                              color:
                                                                              AppColors
                                                                                  .lightBlue),
                                                                          label: const Text(
                                                                              "Gallery",
                                                                              style:
                                                                              TextStyle(
                                                                                  color: AppColors
                                                                                      .lightBlue)),
                                                                        ),
                                                                      );
                                                                    }),
                                                                  ],
                                                                );
                                                              },
                                                              child:
                                                              const Icon(
                                                                Icons
                                                                    .edit_note_rounded,
                                                                color:
                                                                AppColors
                                                                    .blue,
                                                                size: 20,
                                                              ))
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                      const EdgeInsets
                                                          .all(5),
                                                      child: Container(
                                                        height: 200,
                                                        width:
                                                        double.infinity,
                                                        decoration: utils
                                                            .roundedBorder(
                                                            AppColors
                                                                .lightBlue,
                                                            5),
                                                        child: controller
                                                            .paymentProof
                                                            .value != null
                                                            ? Image.file(
                                                          controller
                                                              .paymentProof
                                                              .value!,
                                                          fit: BoxFit
                                                              .fill,
                                                        )
                                                            : InkWell(
                                                          onTap: () {
                                                            utils
                                                                .showCustomDialog(
                                                              title:
                                                              "Need Your Action",
                                                              middleText:
                                                              "Choose Image Source",
                                                              buttons: [
                                                                TextButton
                                                                    .icon(
                                                                  onPressed:
                                                                      () {
                                                                    controller
                                                                        .captureImage(
                                                                        ImageSource
                                                                            .camera,
                                                                        imageTwo);
                                                                    Get.back();
                                                                  },
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .camera_alt,
                                                                      color: AppColors
                                                                          .primaryThemeColor),
                                                                  label: const Text(
                                                                      "Camera",
                                                                      style: TextStyle(
                                                                          color: AppColors
                                                                              .primaryThemeColor)),
                                                                ),
                                                                Obx(() {
                                                                  return Visibility(
                                                                    visible:
                                                                    controller
                                                                        .markUnDelivered
                                                                        .value ==
                                                                        true &&
                                                                        !controller
                                                                            .markUnDelivered
                                                                            .value,
                                                                    child:
                                                                    TextButton
                                                                        .icon(
                                                                      onPressed: () {
                                                                        controller
                                                                            .captureImage(
                                                                            ImageSource
                                                                                .gallery,
                                                                            imageTwo);
                                                                        Get
                                                                            .back();
                                                                      },
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .image,
                                                                          color: AppColors
                                                                              .lightBlue),
                                                                      label: const Text(
                                                                          "Gallery",
                                                                          style: TextStyle(
                                                                              color: AppColors
                                                                                  .lightBlue)),
                                                                    ),
                                                                  );
                                                                }),
                                                              ],
                                                            );
                                                          },
                                                          child: Column(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .image_outlined,
                                                                size:
                                                                80,
                                                                color: AppColors
                                                                    .lightBlue,
                                                              ),
                                                              utils.tvCustom(
                                                                  "capture/select Image",
                                                                  AppColors
                                                                      .lightBlue,
                                                                  10)
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Visibility(
                                                      visible: controller
                                                          .markDelivered
                                                          .value,
                                                      child: Column(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                5),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                              children: [
                                                                utils.tvCustom(
                                                                    "Signature (optional)",
                                                                    AppColors
                                                                        .primaryThemeColor,
                                                                    10),
                                                                InkWell(
                                                                    onTap:
                                                                        () {
                                                                      controller
                                                                          .signatureController
                                                                          .disabled =
                                                                      false;
                                                                      controller
                                                                          .signatureController
                                                                          .clear();
                                                                      controller
                                                                          .signImage
                                                                          ?.clear();
                                                                      controller
                                                                          .signatureFile =
                                                                      null;
                                                                    },
                                                                    child:
                                                                    const Icon(
                                                                      Icons
                                                                          .mode_edit,
                                                                      color: AppColors
                                                                          .blue,
                                                                      size:
                                                                      20,
                                                                    ))
                                                              ],
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .all(5.0),
                                                            child: Container(
                                                              decoration: utils
                                                                  .roundedBorder(
                                                                  AppColors
                                                                      .blue,
                                                                  3),
                                                              child: Padding(
                                                                padding:
                                                                const EdgeInsets
                                                                    .all(
                                                                    8.0),
                                                                child:
                                                                Signature(
                                                                  controller:
                                                                  controller
                                                                      .signatureController,
                                                                  width: Get
                                                                      .width,
                                                                  height: 180,
                                                                  backgroundColor:
                                                                  Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Visibility(
                                                        visible: controller
                                                            .markUnDelivered
                                                            .value,
                                                        child: utils
                                                            .iconButtonWithRoundedBorder(
                                                            controller
                                                                .selectedReason
                                                                .value ==
                                                                ""
                                                                ? "Select Reason"
                                                                : controller
                                                                .selectedReason
                                                                .value,
                                                            45, () {
                                                          controller
                                                              .popUpWindowReasons();
                                                        },
                                                            Icons
                                                                .arrow_drop_down_circle_outlined,
                                                            AppColors
                                                                .primaryThemeColor,
                                                            Icons
                                                                .keyboard_return,
                                                            1,
                                                            AppColors
                                                                .primaryThemeColor)),
                                                    const SizedBox(
                                                      height: 10,
                                                    )
                                                  ],
                                                ));
                                          })
                                        ],
                                      ),
                                      Obx(() {
                                        return Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Visibility(
                                            visible: !controller.markUnDelivered
                                                .value
                                                &&
                                                !controller.markDelivered.value
                                                &&
                                                controller.selectedOrder.value
                                                    .status == OFD,
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [

                                                Row(children: [
                                                  utils.iconButton(
                                                      "UnDeliver", () {
                                                    controller
                                                        .markUnDelivered
                                                        .value = true;
                                                    controller.startTime =
                                                        DateTime.now();
                                                  },
                                                      Icons.cancel,
                                                      AppColors.red,
                                                      AppColors.white),
                                                  const SizedBox(
                                                    width: 90,
                                                  ),
                                                  utils.iconButton(
                                                      "Deliver", () {
                                                    controller
                                                        .markDelivered
                                                        .value = true;
                                                    controller.startTime =
                                                        DateTime.now();
                                                  },
                                                      Icons.check_box,
                                                      AppColors
                                                          .greenLight,
                                                      AppColors.white),
                                                ])
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                      Obx(() {
                                        return Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Visibility(
                                              visible: controller
                                                  .selectedOrder
                                                  .value
                                                  .status ==
                                                  OFD &&
                                                  controller
                                                      .markDelivered.value,
                                              child: utils.iconButton(
                                                  "Mark Delivered", () async {
                                                bool isTrue = await controller
                                                    .calculateBufferTime(
                                                    DateTime.now(),
                                                    DELIVERED);
                                                if (isTrue) {
                                                  if (controller
                                                      .deliveredImage !=
                                                      null) {
                                                    var isDElivered =
                                                    await controller
                                                        .updateOrder(
                                                        DELIVERED);
                                                    if (isDElivered == true) {
                                                      clearImageSign();
                                                    }
                                                  } else {
                                                    utils.errorSnackBar(
                                                        " Error !",
                                                        "Delivery Image required");
                                                  }
                                                }
                                                // Get.toNamed(Routes.signatureImageScreen);
                                              },
                                                  Icons.check_box,
                                                  AppColors.greenLight,
                                                  AppColors.white)),
                                        );
                                      }),
                                      Obx(() {
                                        return Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Visibility(
                                              visible: controller
                                                  .selectedOrder
                                                  .value
                                                  .status ==
                                                  OFD &&
                                                  controller
                                                      .markUnDelivered.value,
                                              child: utils.iconButton(
                                                  "Mark Un-Delivered",
                                                      () async {
                                                    bool isTrue = await controller
                                                        .calculateBufferTime(
                                                        DateTime.now(),
                                                        DELIVERED);
                                                    if (isTrue) {
                                                      var isUpdated =
                                                      await controller
                                                          .updateOrder(
                                                          UNDELIVERED);
                                                      if (isUpdated ==
                                                          true) {
                                                        clearImageSign();
                                                      }
                                                    }
                                                  },

                                                  Icons
                                                      .cancel_presentation_outlined,
                                                  AppColors.red,
                                                  AppColors.white)),
                                        );
                                      }),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              })
            ]),
          ),
          )),
    );
  }

  // Future<void> _cameraToPosition(LatLng pos) async {
  //   final GoogleMapController controller = await _mapController.future;
  //   var zoomLevel = await controller.getZoomLevel();
  //   CameraPosition _newCameraPosition = CameraPosition(
  //     target: pos,
  //     zoom: 18,
  //   );
  //
  //   await controller.animateCamera(
  //     CameraUpdate.newCameraPosition(_newCameraPosition),
  //   );
  // }

  //
  //  void drawPolylineFromJson(dynamic jsonResponse) {
  //  final jsonData = jsonDecode(jsonResponse);
  //   final List<LatLng> polylineCoordinates = [];
  //
  //   if (jsonData["routes"].isNotEmpty) {
  //     final steps = jsonData["routes"][0]["legs"][0]["steps"];
  //     final legs = jsonData["routes"][0]["legs"][0];
  //     orderDurationByGoogle.value =  legs["duration"]["text"] ?? "";
  //     orderDistanceByGoogle.value =  legs["distance"]["text"] ?? "";
  //
  //     for (var step in steps) {
  //       String instruction = step["html_instructions"] ?? "Continue straight";
  //       double stepLat = step["end_location"]["lat"];
  //       double stepLng = step["end_location"]["lng"];
  //
  //       navigationSteps.add({
  //         "instruction": instruction.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
  //         "location": LatLng(stepLat, stepLng)
  //       });
  //       String encodedPolyline = step["polyline"]["points"];
  //       List<PointLatLng> decodedPoints = PolylinePoints().decodePolyline(encodedPolyline);
  //
  //       for (var point in decodedPoints) {
  //         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //       }
  //     }
  //   }
  //
  //   generatePolyLineFromPoints(polylineCoordinates);
  // }

  // void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
  //   PolylineId id = PolylineId("poly");
  //   Polyline polyline = Polyline(
  //       polylineId: id,
  //       color: AppColors.primaryThemeColor,
  //       points: polylineCoordinates,
  //       width: 6);
  //   setState(() {
  //     polylines[id] = polyline;
  //   });
  // }

  void clearImageSign() {
    controller.deliveredImage = null;
    controller.image.value = null;
    controller.signatureFile = null;
    controller.signatureController.value.clear();
    controller.markDelivered.value = false;
    controller.markUnDelivered.value = false;
  }

// void showCustomMarker(OrdersData data, int type) {
//   showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Wrap(
//           children: [
//             Column(
//               children: [
//                 Align(
//                   alignment: Alignment.topRight,
//                   child: InkWell(
//                       onTap: () {
//                         Get.back();
//                       },
//                       child: const Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Icon(
//                           Icons.cancel,
//                           color: AppColors.red,
//                         ),
//                       )),
//                 ),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     utils.tvCustom(
//                         type == 0
//                             ? "${data.merchantName!}\n${data.pickupAddress!},${data.pickupZoneNo!}"
//                             : "${data.consigneeName!}\n${data.consigneeAddress!},${data.consigneeStreetNumber!},${data.consigneeBuildingNo!},${data.consigneeUnitNo!},${data.consigneeZone!}",
//                         AppColors.black,
//                         14),
//                   ],
//                 ),
//                 const SizedBox(
//                   height: 5,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     utils.tvRegular("Landmark", AppColors.black),
//                     utils.tvRegular(":", AppColors.black),
//                     utils.tvCustom(
//                         type == 0
//                             ? data.pickupLocationName
//                             : data.consigneeAddress,
//                         AppColors.blue,
//                         13)
//                   ],
//                 ),
//                 Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: utils.iconButtonWithRoundedBorder(
//                         "Navigate Address", 40, () {
//                       utils.openMaps(type == 0
//                           ? data.pickupAddress!
//                           : data.consigneeAddress!);
//                     },
//                         Icons.assistant_navigation,
//                         AppColors.primaryThemeColor,
//                         Icons.alt_route_rounded,
//                         2,
//                         AppColors.primaryThemeColor))
//               ],
//             )
//           ],
//         );
//       });
// }

// @override
// void dispose() async {
//   _locationSubscription.cancel();
//   await GoogleMapsNavigator.cleanup();
//   _navigationSessionInitialized = false;
//   await controller.navigationViewController?.clear();
//   super.dispose();
// }

/*getDeliveryAddress() async {
    var address = await getLatLangFromAddress(
        controller.selectedOrder.value.consigneeAddress);
    setState(() {
      if (controller.selectedOrder.value.dropoffLatitude != null &&
          controller.selectedOrder.value.dropoffLongitude != null) {
        deliveryLocation = LatLng(
          latitude: double.parse(
              controller.selectedOrder.value.dropoffLatitude ?? "0.0"),
          longitude: double.parse(
              controller.selectedOrder.value.dropoffLongitude ?? "0.0"),
        );
      } else {
        deliveryLocation = LatLng(
          latitude: address!.latitude,
          longitude: address.longitude,
        );
      }
    });*/
// }
}

// double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//   const R = 6371000;
//   final dLat = _toRadians(lat2 - lat1);
//   final dLon = _toRadians(lon2 - lon1);
//   final a = sin(dLat / 2) * sin(dLat / 2) +
//       cos(_toRadians(lat1)) *
//           cos(_toRadians(lat2)) *
//           sin(dLon / 2) *
//           sin(dLon / 2);
//   final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//   return R * c;
// }
//
// double _toRadians(double degree) {
//   return degree * pi / 180;
// }

// Future<List<LatLng>?> getPolylinePoints() async {
//   List<LatLng> polylineCoordinates = [];
//   try {
//     PolylinePoints polylinePoints = PolylinePoints();
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       GOOGLE_MAPS_API_KEY,
//       PointLatLng(pickUpLocation.latitude, pickUpLocation.longitude),
//       PointLatLng(deliveryLocation!.latitude, deliveryLocation!.longitude),
//       travelMode: TravelMode.driving,
//     );
//     if (result.points.isNotEmpty) {
//       result.points.forEach((PointLatLng point) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       });
//       orderDurationByGoogle.value = result.duration ?? "";
//       orderDistanceByGoogle.value = result.distance ?? "";
//     } else {
//       if (kDebugMode) {
//         print(result.errorMessage);
//       }
//     }
//     return polylineCoordinates;
//   } catch (e) {
//     utils.errorDialog(e.toString());
//     return null;
//   }
// }

// Future<void> getLocationUpdates() async {
//   bool _serviceEnabled;
//   PermissionStatus _permissionGranted;
//
//   _serviceEnabled = await _locationController.serviceEnabled();
//   if (!_serviceEnabled) {
//     _serviceEnabled = await _locationController.requestService();
//     if (!_serviceEnabled) {
//       return;
//     }
//   }
//
//   _permissionGranted = await _locationController.hasPermission();
//   if (_permissionGranted == PermissionStatus.denied) {
//     _permissionGranted = await _locationController.requestPermission();
//     if (_permissionGranted != PermissionStatus.granted) {
//       return;
//     }
//   }
//
//   if (!mounted) return;
//
//   _locationSubscription = _locationController.onLocationChanged
//       .listen((LocationData currentLocation) {
//     if (currentLocation.latitude != null &&
//         currentLocation.longitude != null) {
//       setState(() {
//         curentLocation =
//             LatLng(currentLocation.latitude!, currentLocation.longitude!);
//         if (enableMapLiveCamera.value) {
//           _cameraToPosition(curentLocation!);
//         }
//         double distanceInMeters = calculateDistance(
//           curentLocation!.latitude,
//           curentLocation!.longitude,
//           pickUpLocation.latitude,
//           pickUpLocation.longitude,
//         );
//         if (widget.mapView == 1) {
//           if (distanceInMeters <= 5000) {
//             isPickUpVisible.value = true;
//           }
//         }
//       });
//     }
//   });
// }
