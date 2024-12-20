import 'dart:async';
import 'dart:math';

import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/pages/orders/orders_controller.dart';
import 'package:carson_zyppy/pages/orders/orders_model.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:carson_zyppy/global/consts.dart';
import 'package:location/location.dart';

import 'item_map_notifications.dart';

class MapPage extends StatefulWidget {
  final CargoOrderDataModel orderDetails;
  int mapView;

  MapPage({required this.orderDetails, required this.mapView});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = new Location();
  BitmapDescriptor riderIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor icPickLocation = BitmapDescriptor.defaultMarker;
  BitmapDescriptor icDropLocation = BitmapDescriptor.defaultMarker;
  final controller = Get.put(OrdersController());
  var enableMapLiveCamera = false.obs;
  var showNotificationView = false.obs;

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

  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();

  static LatLng locationOne = LatLng(31.092950, 77.173118);
  static LatLng locationTwo = LatLng(31.10377073511391, 77.19289128579997);
  static LatLng locationThree = LatLng(31.103530, 77.158849);
  static LatLng locationFour = LatLng(31.101245, 77.166641);
  static LatLng locationFive = LatLng(31.101109, 77.175512);
  LatLng? curentLocation = null;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
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
                    infoWindow: InfoWindow(
                      title: "You",
                      snippet: "Current Location",
                    ),
                  ),
                  Marker(
                    markerId: MarkerId("_sourceLocation"),
                    //icon: icPickLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(220.5),
                    position: locationOne,
                    infoWindow: InfoWindow(
                      title: "Pick-Up Address",
                      snippet: widget.orderDetails.shipperAddress,
                    ),
                  ),
                  Marker(
                    markerId: MarkerId("_destionationLocation"),
                    // icon: icDropLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(120.5),
                    position: locationTwo,
                    infoWindow: InfoWindow(
                      title: "Delivery Address",
                      snippet: widget.orderDetails.destination,
                    ),
                  ),
                  Marker(
                    markerId: MarkerId("_destionationLocationThree"),
                    // icon: icDropLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(120.5),
                    position: locationThree,
                    infoWindow: InfoWindow(
                      title: "Delivery Address",
                      snippet: widget.orderDetails.destination,
                    ),
                  ),
                  Marker(
                    markerId: MarkerId("_destionationLocationThree"),
                    // icon: icDropLocation,
                    icon: BitmapDescriptor.defaultMarkerWithHue(120.5),
                    position: locationFive,
                    infoWindow: InfoWindow(
                      title: "Delivery Address",
                      snippet: widget.orderDetails.destination,
                    ),
                  )
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
                                  width: showNotificationView.value ? 250.0 : 50.0,
                                  height: showNotificationView.value ? 350.0 : 50.0,
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
                                                            controller.notifications[pos]);
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(50, 5, 50, 70),
                      child: Align(
                          alignment: Alignment.bottomCenter,
                          child:  Container(
                            decoration: utils.boxDecorationWhite(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Wrap(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      utils.tvMedium("Order Number"),
                                      utils.tvMedium(controller.selectedOrder.hawbNo?? ""),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      utils.tvMedium("status"),
                                      utils.tvCustom(controller.selectedOrder.status ?? "",AppColors.green,10),
                                    ],
                                  ),
                                  Row(children: [
                                    utils.iconButton(
                                        "Pick",
                                            () {},
                                        Icons.add_circle,
                                        AppColors.primaryThemeColor,
                                        AppColors.white),
                                    utils.iconButton(
                                        "Pick",
                                            () {},
                                        Icons.add_circle,
                                        AppColors.primaryThemeColor,
                                        AppColors.white)
                                  ],)

                                ],
                              ),
                            ),
                          )),
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

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          curentLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          if (enableMapLiveCamera.value) {
            _cameraToPosition(curentLocation!);
            double distanceInMeters = calculateDistance(
              curentLocation!.latitude,
              curentLocation!.longitude,
              locationOne.latitude,
              locationOne.longitude,
            );
            if (widget.mapView == 1) {
              if (distanceInMeters <= 50) {
                // utils.dialogSuccess("Location", (){
                //   Get.back();
                // });
              }
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
}
