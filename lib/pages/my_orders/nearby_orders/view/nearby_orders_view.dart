import 'dart:math';
import 'package:carson_zyppy/pages/my_orders/placed_orders/controller/placed_orders_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../../../global/consts.dart';
import '../../../map/item_map_notifications.dart';
import 'item_nearby_oredrs/neaby_orders_item.dart';

class NearbyOrdersView extends StatefulWidget {
  @override
  State<NearbyOrdersView> createState() => _MapPageState();
}

class _MapPageState extends State<NearbyOrdersView> {
  final Location _locationController = Location();
  final controller = Get.put(PlacedOrdersController());
  final Completer<GoogleMapController> _mapController =
  Completer<GoogleMapController>();

  var showNotificationView = false.obs;
  var enableMapLiveCamera = false.obs;
  var enableOrdersSearch = false.obs;
  var acceptView = false.obs;
  LatLng? currentLocation;

  Map<MarkerId, Marker> markers = {};


  @override
  void initState() {
    super.initState();
    fetchOrdersAndInitialize();
    getLocationUpdates();
  }

  Future<void> fetchOrdersAndInitialize() async {
    controller.getUser();
  }


  void setMarkers() {
    markers.clear();
    if (currentLocation != null) {
      final markerId = MarkerId("current_location");
      final marker = Marker(
        markerId: markerId,
        position: currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: "Your Location",
          snippet: "This is your current location",
        ),
      );
      markers[markerId] = marker;
    }

    setState(() {
    for (var order in controller.ordersList) {
      final markerId = MarkerId(order.locationId.toString());
      final marker = Marker(
          markerId: markerId,
          position: LatLng(
            double.parse(order.pickupLatitude ?? "0.0"),
            double.parse(order.pickupLongitude ?? "0.0"),
          ),
          icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: order.pickupLocationName,
            snippet:"",
          ),
          onTap: () {
            controller.selectedLocationId.value = markerId.value;
            controller.selectedLocationOrders();
          });
      markers[markerId] = marker;
    }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              if (controller.ordersList.isEmpty) {
                return Center(child: utils.noDataFoundWidget());
              }
              return GoogleMap(
                gestureRecognizers: Set()
                  ..add(Factory<PanGestureRecognizer>(
                          () => PanGestureRecognizer()))..add(
                      Factory<ScaleGestureRecognizer>(
                              () => ScaleGestureRecognizer())),
                mapType: MapType.hybrid,
                onMapCreated: (GoogleMapController controller) =>
                    _mapController.complete(controller),
                initialCameraPosition: CameraPosition(
                  target: currentLocation ??
                      LatLng(
                        double.parse(
                            controller.ordersList.first.pickupLatitude ??
                                "0.0"),
                        double.parse(
                            controller.ordersList.first.pickupLongitude ??
                                "0.0"),
                      ),
                  zoom: 14,
                ),
                markers: Set<Marker>.of(markers.values),
              );
            }),
            buildControls(),

            Obx(() {
              return Visibility(
                visible: controller.viewAcceptView.value,
                child: Center(
                  child: Container(
                    decoration: utils.boxDecorationWhite(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        children: [
                          Align(
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
                          Align(
                            alignment: Alignment.center,
                            child: utils.tvCustom(
                                "Select Order From List(${controller
                                    .selectedMerchantOrdersList.length})",
                                AppColors.primaryThemeColor,
                                15),
                          ),

                          Row(
                            children: [
                              Expanded(
                                  flex: 1,

                                  child: InkWell(
                                      onTap: () {

                                      },
                                      child: const Icon(Icons.arrow_back_ios,
                                        color: AppColors.greyColor4,
                                        size: 15,))),
                              Expanded(
                                flex: 20,
                                child: SizedBox(
                                  height: 450,
                                  child: PageView.builder(
                                      scrollDirection: Axis.horizontal,
                                      controller: PageController(
                                          viewportFraction: 1),
                                      itemCount: controller
                                          .selectedMerchantOrdersList.length,
                                      itemBuilder: (context, position) {
                                        return nearByOrderItem(
                                            controller
                                                .selectedMerchantOrdersList[position],
                                                (clickedOrder, type) async {
                                              if (type == acceptOrder) {
                                                utils.simpleDialog(
                                                    "Accept Order",
                                                    "Do you want to accept this order ?",
                                                        () async {
                                                      await controller
                                                          .acceptRejectOrder(
                                                          acceptOrder,
                                                          clickedOrder.awbNo ??
                                                              "");
                                                    }, () {});
                                              } else {
                                                utils.simpleDialog(
                                                    "Reject Order",
                                                    "Do you want to reject this order ?",
                                                        () {
                                                      controller
                                                          .acceptRejectOrder(
                                                          rejectOrder,
                                                          clickedOrder
                                                              .awbNo ?? "");
                                                    }, () {});
                                              }
                                            });
                                      }
                                  ),
                                ),
                              ),

                              Expanded(
                                  flex: 1,
                                  child: InkWell(
                                      onTap: () {

                                      },
                                      child: Icon(Icons.arrow_forward_ios,
                                        color: AppColors.greyColor4,
                                        size: 15,))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })
          ],
        ),
      ),

    );
  }

  Widget buildControls() {
    return Padding(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        utils.tvCustom("Order Notifications",
                            AppColors.primaryThemeColor, 13),
                        InkWell(
                          onTap: () => showNotificationView.toggle(),
                          child: const Icon(Icons.close,
                              color: AppColors.red),
                        )
                      ],
                    ),
                    utils.dividerBlack(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: controller.ordersList.length,
                        itemBuilder: (context, pos) =>
                            ItemMapNotifications(
                                controller.notifications[pos]),
                      ),
                    ),
                  ],
                )
                    : InkWell(
                  onTap: () => showNotificationView.toggle(),
                  child: const Center(
                    child: Icon(Icons.notifications,
                        color: AppColors.primaryThemeColor),
                  ),
                ),
              ),
            );
          }),
          InkWell(
            onTap: () => {enableMapLiveCamera.toggle(), fetchNearbyOrders()},
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
        ],
      ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted =
    await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationController.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          currentLocation =
              LatLng(locationData.latitude!, locationData.longitude!);
        });
        if (enableMapLiveCamera.value) {
          _cameraToPosition(currentLocation!);
        }
        fetchNearbyOrders();
      }
    });
  }

  void fetchNearbyOrders() {
    setState(() {
      for (var order in controller.ordersList) {
        double distanceInMeters = calculateDistance(
          currentLocation!.latitude,
          currentLocation!.longitude,
          double.parse(order.pickupLatitude ?? "0.0"),
          double.parse(order.pickupLongitude ?? "0.0"),
        );
        if (distanceInMeters <= 5000) {
          setMarkers();
        }
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


  Future<void> _cameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 14)));
  }
}


