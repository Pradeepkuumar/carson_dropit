import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import '../../apis/base_api_response.dart';
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../utils/colors.dart';
import '../dashboard/controller/rider_dashboard_controller.dart';
import '../my_orders/orders/models/orders_model.dart';

class OrderDetailController extends GetxController {
  late OrdersData order;
  GoogleMapViewController? mapViewController;

  @override
  void onInit() {
    order = (Get.arguments is OrdersData) ? Get.arguments as OrdersData : OrdersData();
    super.onInit();
  }

  bool get isAvailable => order.status == PLACED;

  LatLng? get pickupLatLng {
    final lat = double.tryParse(order.pickupLatitude ?? "");
    final lng = double.tryParse(order.pickupLongitude ?? "");
    if (lat == null || lng == null) return null;
    return LatLng(latitude: lat, longitude: lng);
  }

  LatLng? get dropoffLatLng {
    final lat = double.tryParse(order.dropoffLatitude ?? "");
    final lng = double.tryParse(order.dropoffLongitude ?? "");
    if (lat == null || lng == null) return null;
    return LatLng(latitude: lat, longitude: lng);
  }

  Future<void> onMapViewCreated(GoogleMapViewController controller) async {
    mapViewController = controller;
    final pickup = pickupLatLng;
    final dropoff = dropoffLatLng;

    final markerOptions = <MarkerOptions>[
      if (pickup != null)
        MarkerOptions(position: pickup, icon: await _dotMarker(AppColors.red)),
      if (dropoff != null)
        MarkerOptions(
            position: dropoff, icon: await _dotMarker(AppColors.greenLight)),
    ];
    if (markerOptions.isNotEmpty) {
      await controller.addMarkers(markerOptions);
    }

    if (pickup != null && dropoff != null) {
      await _drawRoute(controller, pickup, dropoff);
    }

    if (pickup != null && dropoff != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          latitude: pickup.latitude < dropoff.latitude ? pickup.latitude : dropoff.latitude,
          longitude: pickup.longitude < dropoff.longitude ? pickup.longitude : dropoff.longitude,
        ),
        northeast: LatLng(
          latitude: pickup.latitude > dropoff.latitude ? pickup.latitude : dropoff.latitude,
          longitude: pickup.longitude > dropoff.longitude ? pickup.longitude : dropoff.longitude,
        ),
      );
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding: 60));
    } else if (pickup != null) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(pickup, 14));
    }
  }

  // A simple colored dot-with-white-ring marker, drawn at runtime so pickup
  // (red) and dropoff (green) are visually distinct on the map - the
  // package's default marker icon has no color/hue option.
  Future<ImageDescriptor> _dotMarker(Color color) async {
    const double size = 72;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(
        center, size / 2 - 4, Paint()..color = Colors.white);
    canvas.drawCircle(
        center, size / 2 - 10, Paint()..color = color);
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
  // the same Maps API key already configured for Android in
  // AndroidManifest.xml). Falls back to a straight connector if the
  // directions request fails (e.g. API not enabled for this key) so the
  // map never ends up with no line at all.
  Future<void> _drawRoute(
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

  void callPickup() {
    final phone = order.pickupPhoneNo ?? "";
    if (phone.isNotEmpty) utils.openDialPad(phone);
  }

  void callConsignee() {
    final phone = order.consigneeMobileNo ?? "";
    if (phone.isNotEmpty) utils.openDialPad(phone);
  }

  Future<void> accept() => _acceptReject(acceptOrder);
  Future<void> decline() => _acceptReject(rejectOrder);

  Future<void> _acceptReject(String type) async {
    utils.showLoadingDialog(
        type == acceptOrder ? "Accepting order..." : "Rejecting order...");
    try {
      Map<String, dynamic> model = {
        apiKeys.status: type,
        apiKeys.awbNo: order.awbNo ?? "",
      };
      var response = await apiProvider.postRequest(
          apiEndPoints.acceptRejectOrder, model);
      var result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        if (Get.isRegistered<RiderDashboardController>()) {
          Get.find<RiderDashboardController>().getDashBoardData();
        }
        if (type == acceptOrder) {
          utils.successSnackBar("Order Accepted",
              "Please find the accepted order under Assigned");
        } else {
          utils.errorSnackBar(
              "Order Rejected", "This order no longer belongs to you");
        }
        Get.back(result: true);
      } else {
        utils.errorSnackBar("Error", result.message.toString());
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
    }
  }
}
