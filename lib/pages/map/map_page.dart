import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/my_orders/orders/controller/orders_controller.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:signature/signature.dart';
import '../../utils/calculate_sla.dart';
import '../my_orders/orders/models/orders_model.dart';
import 'getLatlongFromAddress.dart';

class MapPage extends StatefulWidget {
  final OrdersData orderDetails;
  int mapView;

  MapPage({required this.orderDetails, required this.mapView});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late StreamSubscription<LocationData> _locationSubscription;
  Location _locationController = new Location();
  GoogleNavigationViewController? navigationViewController;
  bool _navigationSessionInitialized = false;

  final controller = Get.put(OrdersController());
  var enableMapLiveCamera = false.obs;
  var enableMapType = false.obs;
  var enableNavigation = false.obs;
  var showNotificationView = false.obs;
  late LatLng pickUpLocation;


  late LatLng deliveryLocation;

  var orderDurationByGoogle = "".obs;
  var orderDistanceByGoogle = "".obs;
  MapType mapType = MapType.hybrid;
  var isUpdateCardVisible = false.obs;


  LatLng? curentLocation = null;



  final List<NavigationWaypoint> _waypoints = <NavigationWaypoint>[];
  StreamSubscription<RemainingTimeOrDistanceChangedEvent>?
  remainingTimeOrDistanceChangedSubscription;

  @override
  void initState() {
    _initializeNavigationSession();
    controller.getDeliveryDirectionData().then((value) {
      if (value != null) {

      }
    });


    getDeliveryAddress().then((_) {
      pickUpLocation = LatLng(
        latitude: double.parse(widget.orderDetails.pickupLatitude ?? "0.0"),
        longitude: double.parse(widget.orderDetails.pickupLongitude ?? "0.0"),
      );

      if (widget.orderDetails.status == "OFD") {
        _waypoints.add(NavigationWaypoint.withLatLngTarget(
            title: "Delivery Location",
            target: deliveryLocation
        ));
      } else {
        _waypoints.add(NavigationWaypoint.withLatLngTarget(
            title: "Pick-Up Location",
            target: pickUpLocation
        ));
      }
    });


    getLocationUpdates().then(
          (_) =>
      {


        // drawPolylineFromJson
        // getPolylinePoints().then((coordinates) => {
        //  generatePolyLineFromPoints(coordinates!),
        //
        // }),
      },
    );
    // loadCustomIcons();
    super.initState();
  }

  Future<void> _initializeNavigationSession() async {
    if (!await GoogleMapsNavigator.areTermsAccepted()) {
      await GoogleMapsNavigator.showTermsAndConditionsDialog(
        'Carson Zyppy',
        'Logistics solutions',
      );
    }
    await GoogleMapsNavigator.initializeNavigationSession();
    setState(() {
      _navigationSessionInitialized = true;
    });
  }


  void _onViewCreated(GoogleNavigationViewController controller) async {
    navigationViewController = controller;
    await controller.setMyLocationEnabled(true);
    await GoogleMapsNavigator.setDestinations(Destinations(
      waypoints: _waypoints,
      displayOptions: NavigationDisplayOptions(
        showDestinationMarkers: true,
        showStopSigns: true,
        showTrafficLights: true,
      ),
      routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving),));
    startGuidedNavigation();
  }

  Future<void> startGuidedNavigation() async {
    await navigationViewController?.setNavigationUIEnabled(true);
    await navigationViewController?.setSpeedometerEnabled(true);
    await GoogleMapsNavigator.startGuidance();
    await navigationViewController?.followMyLocation(CameraPerspective.tilted);

  }

  void _onRemainingTimeOrDistanceChangedEvent(RemainingTimeOrDistanceChangedEvent event) {
    if (!mounted) {
      return;
    }
      var value = event.remainingDistance.toInt();
    if(value <= 50){
      setState(() {
        isUpdateCardVisible.value = true;
      });
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: curentLocation == null
          ? Center(
        child: utils.iosProgressIndicator(AppColors.primaryThemeColor),
      )
          : SafeArea(
        child: Stack(children: [
          _navigationSessionInitialized ?
          GoogleMapsNavigationView(
            key: ValueKey(mapType),
            gestureRecognizers: Set()
              ..add(Factory<PanGestureRecognizer>(
                      () => PanGestureRecognizer()))..add(
                  Factory<ScaleGestureRecognizer>(
                          () => ScaleGestureRecognizer())),
            onViewCreated: _onViewCreated,
            initialMapType: mapType,
            initialNavigationUIEnabledPreference: NavigationUIEnabledPreference
                .automatic,
            initialCameraPosition: CameraPosition(
              target: curentLocation!,
              zoom: 14,
            ),
          ) : Center(
            child: utils.iosProgressIndicator(AppColors.primaryThemeColor),),
          Padding(
            padding: const EdgeInsets.only(top: 100, left: 5),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(5),
                  child: InkWell(
                    onTap: () {

                    },
                    child: Container(
                      height: 62,
                      width: 60,
                      decoration: utils.boxDecorationWhite(),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: slaTimer(30, 30,
                            widget.orderDetails.createdAt ?? "", int.tryParse(
                                widget.orderDetails.sla_in_hours.toString()) ??
                                0, 7
                        ),
                      ),
                    ),
                  ),
                ),

                InkWell(
                  onTap: () {
                    setState(() {
                      mapType = (mapType == MapType.normal)
                          ? MapType.hybrid
                          : MapType.normal;
                      enableMapType.toggle();
                    });
                  },
                  child: Obx(() {
                    return Container(
                        height: 60,
                        width: 60,
                        decoration: utils.boxDecorationWhite(),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            children: [
                              Icon(Icons.map,
                                  size:
                                  enableMapType.value ? 30 : 35,
                                  color: enableMapType.value
                                      ? AppColors.greyColor4
                                      : AppColors.selectedBlue),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  enableMapType.value ? "Normal" : "Satellite",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10),),
                              )

                            ],
                          ),
                        )
                    );
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
            ),
          ),

          Obx(() {
            return Visibility(
              visible: isUpdateCardVisible.value,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
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
                          child: Container(
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
                                        SizedBox(
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
                                                                      .camera);
                                                            },
                                                            child: Icon(
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
                                                    EdgeInsets.all(5),
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
                                                                  .camera);
                                                        },
                                                        child: Column(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                          children: [
                                                            Icon(
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
                                                                  "Signature",
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
                                          //visible: isPickUpVisible.value,
                                          visible: true,
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Visibility(
                                                visible: (controller
                                                    .selectedOrder
                                                    .value
                                                    .status ==
                                                    "ASSIGNED" ||
                                                    controller.selectedOrder
                                                        .value.status ==
                                                        "RE-ASSIGNED"),
                                                child: utils.iconButton(
                                                    "Mark Reached",
                                                        () async {
                                                      await controller
                                                          .updateOrder(
                                                          "REACHED");
                                                    },
                                                    Icons
                                                        .follow_the_signs_rounded,
                                                    AppColors.orange,
                                                    AppColors.white),
                                              ),
                                              Visibility(
                                                visible: controller
                                                    .selectedOrder
                                                    .value
                                                    .status ==
                                                    "REACHED",
                                                child: utils.iconButton(
                                                    "Mark Pick", () async {
                                                  await controller.updateOrder(
                                                      "PICKED");
                                                },
                                                    Icons.signpost_rounded,
                                                    AppColors.blue,
                                                    AppColors.white),
                                              ),
                                              Obx(() =>
                                                  Visibility(
                                                      visible: !controller
                                                          .markUnDelivered
                                                          .value &&
                                                          !controller
                                                              .markDelivered
                                                              .value &&
                                                          controller
                                                              .selectedOrder
                                                              .value
                                                              .status ==
                                                              "OFD",
                                                      child: Row(children: [
                                                        utils.iconButton(
                                                            "UnDeliver", () {
                                                          controller
                                                              .markUnDelivered
                                                              .value = true;
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
                                                        },
                                                            Icons.check_box,
                                                            AppColors
                                                                .greenLight,
                                                            AppColors.white),
                                                      ])))
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
                                                "OFD" &&
                                                controller
                                                    .markDelivered.value,
                                            child: utils.iconButton(
                                                "Mark Delivered", () async {
                                              if (controller
                                                  .deliveredImage !=
                                                  null &&
                                                  controller
                                                      .signatureFile !=
                                                      null) {
                                                var isDElivered =
                                                await controller
                                                    .updateOrder(
                                                    "DELIVERED");
                                                if (isDElivered == true) {
                                                  clearImageSign();
                                                }
                                              } else {
                                                utils.errorSnackBar(
                                                    "Image/Sign Error !",
                                                    "Delivery Image & Signature required");
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
                                            visible: controller.selectedOrder
                                                .value.status == "OFD" &&
                                                controller.markUnDelivered
                                                    .value,
                                            child: utils.iconButton(
                                                "Mark Un-Delivered",
                                                    () async {
                                                  var isUpdated =
                                                  await controller
                                                      .updateOrder(
                                                      "UNDELIVERED");
                                                  if (isUpdated == true) {
                                                    clearImageSign();
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
                    ),
                  )
                ],
              ),
            );
          })
        ]),
      ),
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

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    if (!mounted) return;

    _locationSubscription = _locationController.onLocationChanged.listen((
        LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          curentLocation = LatLng(latitude: currentLocation.latitude!,
              longitude: currentLocation.longitude!);
          if (enableMapLiveCamera.value) {
            // _cameraToPosition(curentLocation!);
          }

          // double distance = 0.0;
          //
          // LatLng matchingLocation;
          //
          // if(widget.orderDetails.status == "OFD"){
          //   matchingLocation =  LatLng(latitude: deliveryLocation.latitude, longitude: deliveryLocation.longitude);
          // }else{
          //   matchingLocation =  LatLng(latitude: pickUpLocation.latitude, longitude: pickUpLocation.longitude);
          // }
          //   distance = calculateDistance(
          //     curentLocation!.latitude,
          //     curentLocation!.longitude,
          //     matchingLocation.latitude,
          //     matchingLocation.longitude,
          //   );

          // if(distance <= 50){
          //      controller.isUpdateCardVisible.value = true;
          // }
          remainingTimeOrDistanceChangedSubscription =
              GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
                  _onRemainingTimeOrDistanceChangedEvent,
                  remainingDistanceThresholdMeters: 10);


        });
      }
    });
  }


  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }


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
    controller.viewFullMap.value = false;
    controller.markDelivered.value = false;
    controller.markUnDelivered.value = false;
  }

  void showCustomMarker(OrdersData data, int type) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Wrap(
            children: [
              Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.cancel,
                            color: AppColors.red,
                          ),
                        )),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      utils.tvCustom(
                          type == 0
                              ? "${data.merchantName!}\n${data
                              .pickupAddress!},${data.pickupZoneNo!}"
                              : "${data.consigneeName!}\n${data
                              .consigneeAddress!},${data
                              .consigneeStreetNumber!},${data
                              .consigneeBuildingNo!},${data
                              .consigneeUnitNo!},${data.consigneeZone!}",
                          AppColors.black,
                          14),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      utils.tvRegular("Landmark", AppColors.black),
                      utils.tvRegular(":", AppColors.black),
                      utils.tvCustom(
                          type == 0
                              ? data.pickupLocationName
                              : data.consigneeAddress,
                          AppColors.blue,
                          13)
                    ],
                  ),
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: utils.iconButtonWithRoundedBorder(
                          "Navigate Address",
                          40, () {
                        utils.openMaps(type == 0
                            ? data.pickupAddress!
                            : data.consigneeAddress!);
                      },
                          Icons.assistant_navigation,
                          AppColors.primaryThemeColor,
                          Icons.alt_route_rounded,
                          2,
                          AppColors.primaryThemeColor))
                ],
              )
            ],
          );
        });
  }

  @override
  void dispose() async {
    _locationSubscription.cancel();
    await GoogleMapsNavigator.cleanup();
    _navigationSessionInitialized = false;
    await navigationViewController?.clear();
    super.dispose();
  }


  getDeliveryAddress() async {
    var address = await getLatLangFromAddress(
        widget.orderDetails.consigneeAddress);
    setState(() {
      if (widget.orderDetails.dropoffLatitude != null &&
          widget.orderDetails.dropoffLongitude != null) {
        deliveryLocation = LatLng(latitude:
        double.parse(widget.orderDetails.dropoffLatitude ?? "0.0"),
          longitude: double.parse(
              widget.orderDetails.dropoffLongitude ?? "0.0"),
        );
      } else {
        deliveryLocation = LatLng(
          latitude: address!.latitude,
          longitude: address.longitude,
        );
      }
    });
  }
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


