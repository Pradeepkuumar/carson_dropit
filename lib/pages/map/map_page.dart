import 'dart:async';
import 'dart:math';

import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:carson_zyppy/pages/my_orders/orders/controller/orders_controller.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:carson_zyppy/global/consts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:signature/signature.dart';

import '../../app_pages/app_pages.dart';
import '../my_orders/orders/models/orders_model.dart';
import 'item_map_notifications.dart';

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
  BitmapDescriptor riderIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor icPickLocation = BitmapDescriptor.defaultMarker;
  BitmapDescriptor icDropLocation = BitmapDescriptor.defaultMarker;
  final controller = Get.put(OrdersController());
  var enableMapLiveCamera = false.obs;
  var showNotificationView = false.obs;
  late LatLng locationOne;

  late LatLng locationTwo;

  var isPickUpVisible = false.obs;

  /// Load custom icons
  void loadCustomIcons() async {
    final riderIconFuture = BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      "assets/icons/ic_you.jpg",
    );

    final sourceIconFuture = BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      "assets/icons/ic_pick_point.jpg",
    );

    final destinationIconFuture = BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      "assets/icons/ic_drop_point.jpg",
    );

    final icons = await Future.wait(
        [riderIconFuture, sourceIconFuture, destinationIconFuture]);

    setState(() {
      riderIcon = icons[0];
      icPickLocation = icons[1];
      icDropLocation = icons[2];
    });
  }

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  LatLng? curentLocation = null;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    locationOne = LatLng(
      double.parse(widget.orderDetails.pickupLatitude ?? "0.0"),
      double.parse(widget.orderDetails.pickupLongitude ?? "0.0"),
    );
    locationTwo = LatLng(
      double.parse(widget.orderDetails.dropoffLatitude ?? "0.0"),
      double.parse(widget.orderDetails.dropoffLongitude ?? "0.0"),
    );
    loadCustomIcons();
    super.initState();
    getLocationUpdates().then(
      (_) => {
        // getPolylinePoints().then((coordinates) => {
        //       generatePolyLineFromPoints(coordinates),
        //     }),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: curentLocation == null
          ? Center(
              child: utils.iosProgressIndicator(AppColors.primaryThemeColor),
            )
          : Stack(children: [
              GoogleMap(
                gestureRecognizers: Set()
                  ..add(Factory<PanGestureRecognizer>(
                      () => PanGestureRecognizer()))
                  ..add(Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer())),
                mapType: MapType.hybrid,
                onMapCreated: ((GoogleMapController controller) =>
                    _mapController.complete(controller)),
                initialCameraPosition: CameraPosition(
                  target: locationOne,
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId("_currentLocation"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: curentLocation!,
                    infoWindow: const InfoWindow(
                      title: "You",
                      snippet: " Your Current Location",
                    ),
                  ),
                  Marker(
                    markerId: MarkerId("_sourceLocation"),
                    //icon: icPickLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(220.5),
                    position: locationOne,
                    onTap: () {
                      showCustomMarker(widget.orderDetails,0);
                    },
                    infoWindow: InfoWindow(
                      title: "Pick-Up Location",
                      snippet: "${widget.orderDetails.pickupLocationName}",
                    ),
                  ),
                  Marker(
                    markerId: MarkerId("_destionationLocation"),
                    // icon: icDropLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(120.5),
                    position: locationTwo,
                    onTap: () {
                      showCustomMarker(widget.orderDetails,1);
                    },
                    infoWindow: InfoWindow(
                      title: "Drop-Off Location",
                      snippet:
                          "${widget.orderDetails.consigneeName},${widget.orderDetails.consigneeAddress}",
                    ),
                  ),
                  // Marker(
                  //   markerId: MarkerId("_destionationLocationThree"),
                  //   // icon: icDropLocation,
                  //   icon: BitmapDescriptor.defaultMarkerWithHue(120.5),
                  //   position: locationThree,
                  //   infoWindow: InfoWindow(
                  //     title: "Delivery Address",
                  //     snippet: widget.orderDetails.itemDescription,
                  //   ),
                  // ),
                  // Marker(
                  //   markerId: MarkerId("_destionationLocationThree"),
                  //   // icon: icDropLocation,
                  //   icon: BitmapDescriptor.defaultMarkerWithHue(120.5),
                  //   position: locationFive,
                  //   infoWindow: InfoWindow(
                  //     title: "Delivery Address",
                  //     snippet: widget.orderDetails.dropoffLatitude,
                  //   ),
                  // )
                },
                // polylines: Set<Polyline>.of(polylines.values),
              ),
              Visibility(
                visible: widget.mapView == 1,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Obx(() {
                              return AnimatedContainer(
                                  width:
                                      showNotificationView.value ? 250.0 : 50.0,
                                  height:
                                      showNotificationView.value ? 350.0 : 50.0,
                                  decoration: utils.boxDecorationWhite(),
                                  alignment: showNotificationView.value
                                      ? Alignment.center
                                      : AlignmentDirectional.topCenter,
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.fastOutSlowIn,
                                  child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: showNotificationView.value
                                          ? Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    utils.tvCustom(
                                                        "Order Notifications",
                                                        AppColors
                                                            .primaryThemeColor,
                                                        13),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          showNotificationView
                                                              .toggle();
                                                        });
                                                      },
                                                      child: const Icon(
                                                        Icons.close,
                                                        color: AppColors.red,
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                utils.dividerBlack(),
                                                Expanded(
                                                  child: ListView.builder(
                                                      itemCount: controller
                                                          .notifications.length,
                                                      itemBuilder:
                                                          (context, pos) {
                                                        return ItemMapNotifications(
                                                            controller
                                                                    .notifications[
                                                                pos]);
                                                      }),
                                                )
                                              ],
                                            )
                                          : InkWell(
                                              onTap: () {
                                                setState(() {
                                                  showNotificationView.toggle();
                                                });
                                              },
                                              child: Center(
                                                child: Icon(
                                                  Icons.notifications,
                                                  color: AppColors
                                                      .primaryThemeColor,
                                                ),
                                              ))));
                            }),
                            InkWell(
                              onTap: () {
                                enableMapLiveCamera.toggle();
                              },
                              child: Obx(() {
                                return Container(
                                  height: 50,
                                  width: 50,
                                  decoration: utils.boxDecorationWhite(),
                                  child: Icon(Icons.share_location_sharp,
                                      size: enableMapLiveCamera.value ? 36 : 30,
                                      color: enableMapLiveCamera.value
                                          ? AppColors.selectedBlue
                                          : AppColors.greyColor4),
                                );
                              }),
                            ),
                          ]),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding:  EdgeInsets.only(left: 20,right: 20,bottom: controller.markDelivered.value ? 10 : 100),
                        child: Container(
                          decoration: utils.boxDecorationWhite(),
                          child:
                        SingleChildScrollView(
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
                                          visible: controller.markDelivered.value ||
                                              controller.markUnDelivered.value,
                                          child: Align(
                                              alignment: Alignment.topRight,
                                              child: InkWell(
                                                  onTap: () {
                                                    controller.markDelivered.value = false;
                                                    controller.markUnDelivered.value = false;
                                                  },
                                                  child: const Icon(Icons.cancel,
                                                      color: AppColors.red))),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            utils.tvMedium("Order Number"),
                                            utils.tvMedium(
                                                controller.selectedOrder.value.awbNo ?? ""),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            utils.tvMedium("status"),
                                            utils.tvCustom(
                                                controller.selectedOrder.value.status ?? "",
                                                AppColors.green,
                                                10),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            utils.tvMedium("Item"),
                                            utils.tvCustom(
                                                "${controller.selectedOrder.value.itemName}(${controller.selectedOrder.value.quantity})" ??
                                                    "",
                                                AppColors.black,
                                                10),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            utils.tvMedium("Item Amount"),
                                            utils.tvCustom(
                                                "${controller.selectedOrder.value.orderAmount}(Qar)" ??
                                                    "",
                                                AppColors.black,
                                                10),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            utils.tvMedium("Merchant Name"),
                                            utils.tvCustom(
                                                controller.selectedOrder.value.merchantName ??
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
                                              visible: controller.markDelivered.value ||
                                                  controller.markUnDelivered.value,
                                              child: Column(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 5),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        utils.tvCustom("Image Proof",
                                                            AppColors.primaryThemeColor, 10),
                                                        InkWell(
                                                            onTap: () {
                                                              controller.captureImage(
                                                                  ImageSource.camera);
                                                            },
                                                            child: Icon(
                                                              Icons.refresh,
                                                              color: AppColors.blue,
                                                              size: 20,
                                                            ))
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(5),
                                                    child: Container(
                                                      height: 200,
                                                      width: double.infinity,
                                                      decoration: utils.roundedBorder(
                                                          AppColors.primaryThemeColor, 5),
                                                      child: controller.image.value != null
                                                          ? Image.file(
                                                        controller.image.value!,
                                                        fit: BoxFit.fill,
                                                      )
                                                          : InkWell(
                                                        onTap: () {
                                                          controller.captureImage(
                                                              ImageSource.camera);
                                                        },
                                                        child: Column(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.camera,
                                                              size: 80,
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
                                                    visible: controller.markDelivered.value,
                                                    child: Column(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 5),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              utils.tvCustom(
                                                                  "Signature",
                                                                  AppColors.primaryThemeColor,
                                                                  10),
                                                              InkWell(
                                                                  onTap: () {
                                                                    controller
                                                                        .signatureController
                                                                        .disabled = false;
                                                                    controller
                                                                        .signatureController
                                                                        .clear();
                                                                    controller.signImage
                                                                        ?.clear();
                                                                    controller.signatureFile =
                                                                    null;
                                                                  },
                                                                  child: const Icon(
                                                                    Icons.mode_edit,
                                                                    color: AppColors.blue,
                                                                    size: 20,
                                                                  ))
                                                            ],
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.all(5.0),
                                                          child: Container(
                                                            decoration: utils.roundedBorder(
                                                                AppColors.blue, 3),
                                                            child: Padding(
                                                              padding:
                                                              const EdgeInsets.all(8.0),
                                                              child: Signature(
                                                                controller: controller
                                                                    .signatureController,
                                                                width: Get.width,
                                                                height: 180,
                                                                backgroundColor: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Visibility(
                                                      visible: controller.markUnDelivered.value,
                                                      child: utils.iconButtonWithRoundedBorder(controller.selectedReason.value == "" ? "Select Reason":controller.selectedReason.value ,
                                                          45,
                                                              (){
                                                            controller.popUpWindowReasons();
                                                          }, Icons.arrow_drop_down_circle_outlined,
                                                          AppColors.primaryThemeColor, Icons.keyboard_return,
                                                          1, AppColors.primaryThemeColor)),
                                                  const SizedBox(height: 10,)
                                                ],
                                              ));
                                        })
                                      ],
                                    ),
                                    Obx(() {
                                      return Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Visibility(
                                          visible: isPickUpVisible.value,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Visibility(
                                                visible:
                                                (controller.selectedOrder.value.status == "ASSIGNED" || controller.selectedOrder.value.status == "RE-ASSIGNED"),
                                                child: utils.iconButton("Mark Reached",
                                                        () async {
                                                     await controller.updateOrder("REACHED");

                                                    }, Icons.follow_the_signs_rounded,
                                                    AppColors.orange, AppColors.white),
                                              ),
                                              Visibility(
                                                visible: controller.selectedOrder.value.status == "REACHED",
                                                child: utils.iconButton("Mark Pick", () async {
                                                   await controller.updateOrder("PICKED");

                                                }, Icons.signpost_rounded, AppColors.blue,
                                                    AppColors.white),
                                              ),
                                              Obx(() => Visibility(
                                                  visible: !controller.markUnDelivered.value &&
                                                      !controller.markDelivered.value &&
                                                      controller.selectedOrder.value.status == "OFD",
                                                  child: Row(children: [
                                                    utils.iconButton("UnDeliver", () {
                                                      controller.markUnDelivered.value = true;
                                                    }, Icons.cancel, AppColors.red,
                                                        AppColors.white),
                                                    const SizedBox(
                                                      width: 90,
                                                    ),
                                                    utils.iconButton("Deliver", () {
                                                      controller.markDelivered.value = true;
                                                    }, Icons.check_box, AppColors.greenLight,
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
                                            visible: controller.selectedOrder.value.status == "OFD" && controller.markDelivered.value,
                                            child: utils.iconButton("Mark Delivered", () async {
                                              if (controller.deliveredImage != null &&
                                                  controller.signatureFile != null) {
                                                var isDElivered = await controller.updateOrder("DELIVERED");
                                                if (isDElivered == true) {
                                                  clearImageSign();
                                                }
                                              } else {
                                                utils.errorSnackBar("Image/Sign Error !",
                                                    "Delivery Image & Signature required");
                                              }
                                              // Get.toNamed(Routes.signatureImageScreen);
                                            }, Icons.check_box, AppColors.greenLight,
                                                AppColors.white)),
                                      );
                                    }),
                                    Obx(() {
                                      return Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Visibility(
                                            visible: controller.selectedOrder.value.status ==
                                                "OFD" &&
                                                controller.markUnDelivered.value,
                                            child: utils.iconButton("Mark Un-Delivered", () async{
                                              var isUpdated = await controller.updateOrder("UNDELIVERED");
                                              if (isUpdated == true) {
                                                clearImageSign();
                                              }
                                            }, Icons.cancel_presentation_outlined,
                                                AppColors.red, AppColors.white)),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),),
                      ),
                    )
                  ],
                ),
              )
            ]),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    var zoomLevel = await controller.getZoomLevel();
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: zoomLevel,
    );

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

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

    _locationSubscription = _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          curentLocation =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          if (enableMapLiveCamera.value) {
            _cameraToPosition(curentLocation!);
          }
          double distanceInMeters = calculateDistance(
            curentLocation!.latitude,
            curentLocation!.longitude,
            locationOne.latitude,
            locationOne.longitude,
          );
          if (widget.mapView == 1) {
            if (distanceInMeters <= 5000) {
              isPickUpVisible.value = true;
            }
          }
        });
      }
    });
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      GOOGLE_MAPS_API_KEY,
      PointLatLng(locationOne.latitude, locationOne.longitude),
      PointLatLng(locationTwo.latitude, locationTwo.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      if (kDebugMode) {
        print(result.errorMessage);
      }
    }
    return polylineCoordinates;
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: AppColors.primaryThemeColor,
        points: polylineCoordinates,
        width: 8);
    setState(() {
      polylines[id] = polyline;
    });
  }



  void clearImageSign(){
    controller.deliveredImage = null;
    controller.image.value = null;
    controller.signatureFile = null;
    controller.signatureController.value.clear();
    controller.viewFullMap.value = false;
    controller.markDelivered.value = false;
    controller.markUnDelivered.value = false;
  }

  void showCustomMarker(OrdersData data,int type) {
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
                    utils.tvCustom( type == 0 ?
                    "${data.merchantName!}\n${data.pickupAddress!},${data.pickupZoneNo!}"
                        : "${data.consigneeName!}\n${data.consigneeAddress!},${data.consigneeStreetNumber
                    !},${data.consigneeBuildingNo!},${data.consigneeUnitNo!},${data.consigneeZone!}",
                        AppColors.black, 14),
                  ],
                ),
                const SizedBox(height: 5,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    utils.tvRegular("Landmark", AppColors.black),
                    utils.tvRegular(":", AppColors.black),
                    utils.tvCustom(type == 0? data.pickupLocationName : data.consigneeAddress, AppColors.blue, 13)
                  ],
                ),

                Padding(padding: const EdgeInsets.all(20),
                child:  utils.iconButtonWithRoundedBorder("Navigate Address", 40, (){
                        utils.openMaps(type == 0 ? data.pickupAddress! : data.consigneeAddress!);
                }, Icons.assistant_navigation,
                    AppColors.primaryThemeColor,
                    Icons.alt_route_rounded, 2, AppColors.primaryThemeColor)
                )
              ],
            )],
          );
        });
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }
}
