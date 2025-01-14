import 'dart:ffi';
import 'dart:math';

import 'package:carson_zyppy/pages/my_orders/orders/models/orders_model.dart';
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
import '../../../map/item_map_notifications.dart';

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
    setMarkers();
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

    for (var order in controller.ordersList) {
      final markerId = MarkerId(order.id.toString());
      final marker = Marker(
          markerId: markerId,
          position: LatLng(
            double.parse(order.pickupLatitude ?? "0.0"),
            double.parse(order.pickupLongitude ?? "0.0"),
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: order.awbNo,
            snippet: order.itemDescription,
          ),
          onTap: () {
            OrdersData? clickedOrder;
            for (var order in controller.ordersList) {
              if (order.id.toString() == markerId.value ) {
                clickedOrder = order;
              }
            }
            controller.showCustomMarker(clickedOrder!, 0);
          });
      markers[markerId] = marker;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              if (controller.ordersList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return GoogleMap(
                gestureRecognizers: Set()
                  ..add(Factory<PanGestureRecognizer>(
                      () => PanGestureRecognizer()))
                  ..add(Factory<ScaleGestureRecognizer>(
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
            onTap: () => enableMapLiveCamera.toggle(),
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
          InkWell(
            onTap: () {
              fetchNearbyOrders();
            },
            child: Obx(() {
              return Container(
                height: 50,
                width: 50,
                decoration: utils.boxDecorationWhite(),
                child: Icon(Icons.search,
                    size: enableOrdersSearch.value ? 36 : 30,
                    color: enableOrdersSearch.value
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
