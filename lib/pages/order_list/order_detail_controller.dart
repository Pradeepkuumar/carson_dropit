import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import '../../apis/base_api_response.dart';
import '../../global/consts.dart';
import '../../global/global.dart';
import '../../local_db/entity/UserData.dart';
import '../../utils/colors.dart';
import '../dashboard/controller/rider_dashboard_controller.dart';
import '../my_orders/orders/models/orders_model.dart';

class OrderDetailController extends GetxController {
  // Callers pass only the awb number - the order itself is fetched here.
  String awbNumber = "";
  OrdersData order = OrdersData();
  var isLoading = true.obs;
  var errorMessage = RxnString();
  GoogleMapViewController? mapViewController;
  StreamSubscription<Position>? _riderSubscription;
  var user = UserData();

  // Capture state for the "back to warehouse" (dropback) sheet, shown when
  // this order is undelivered - same shape as OrderListController's.
  File? dropbackPhoto;
  final SignatureController dropbackSignatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  File? dropbackSignatureFile;
  var isSubmittingDropback = false.obs;
  @override
  void onInit() {
    awbNumber = (Get.arguments ?? "").toString();
    _load();
    super.onInit();
  }

  Future<void> _load() async {
    await getUser();
    await fetchOrderDetails();
  }

  Future<void> getUser() async {
    final value = await userRepository.getUser();
    if (value != null) {
      user = value;
    }
  }

  // GET driver/order-details/{awb}?fe_code= - also used by "Try again".
  Future<void> fetchOrderDetails() async {
    isLoading.value = true;
    errorMessage.value = null;
    String? message;
    OrdersData? fetched;
    try {
      if (awbNumber.isNotEmpty) {
        var response = await apiProvider.getRequestWithQueryParams(
          "${apiEndPoints.driverOrderDetails}/$awbNumber",
          {apiKeys.feCode: user.code ?? ""},
        );
        var result = BaseApiResponse.fromJson(response);
        message = result.message;
        final data = result.data;
        if (result.status_code == 200 && data != null) {
          final json = data is List ? (data.isEmpty ? null : data.first) : data;
          if (json is Map<String, dynamic>) fetched = OrdersData.fromJson(json);
        }
      }
    } catch (ex,stackTrace) {
      print("❌ FetchAvailable Exception: $ex");
      print("❌ StackTrace: $stackTrace");
    }
    if (fetched != null) {
      order = fetched;
    } else {
      errorMessage.value = (message == null || message.isEmpty)
          ? "Check your connection and try again."
          : message;
    }
    isLoading.value = false;
  }
  //bool get isAvailable => order.status == PLACED || order.status == DRIVER_ASSIGNMENT_PENDING ;
  bool get isAvailable => order.can_accept ?? false;
  // Still PLACED but not acceptable - another rider accepted it first.
  bool get isTakenByOtherRider => !isAvailable && (order.is_accepted_by_other ??false);
  LatLng? get pickupLatLng =>
      utils.parseLatLng(order.pickupLatitude, order.pickupLongitude);

  LatLng? get dropoffLatLng =>
      utils.parseLatLng(order.dropoffLatitude, order.dropoffLongitude);

  Future<void> onMapViewCreated(GoogleMapViewController controller) async {
    mapViewController = controller;
    final pickup = pickupLatLng;
    final dropoff = dropoffLatLng;

    final markerOptions = <MarkerOptions>[
      if (pickup != null)
        MarkerOptions(position: pickup, icon: await utils.mapDotMarker(AppColors.red)),
      if (dropoff != null)
        MarkerOptions(
            position: dropoff, icon: await utils.mapDotMarker(AppColors.greenLight)),
    ];
    if (markerOptions.isNotEmpty) {
      await controller.addMarkers(markerOptions);
    }

    if (pickup != null && dropoff != null) {
      await utils.drawMapRoute(controller, pickup, dropoff);
    }

    // Rider's live position as the bike marker.
    await _riderSubscription?.cancel();
    final rider = await utils.showRiderBikeOnMap(controller);
    _riderSubscription = rider.subscription;

    final fitPoints = [?pickup, ?dropoff, ?rider.position];
    if (pickup != null && dropoff != null) {
      await controller.animateCamera(
          CameraUpdate.newLatLngBounds(utils.mapBoundsFor(fitPoints), padding: 60));
    } else if (pickup != null) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(pickup, 14));
    }
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
        apiKeys.feCode: user.code,
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
        Get.back(result: true);
        if (type == acceptOrder) {
          utils.successSnackBar("Order Accepted",
              "Please find the accepted order under Assigned");
        } else {
          utils.errorSnackBar(
              "Order Rejected", "This order no longer belongs to you");
        }

      } else {
        utils.errorSnackBar("Error", result.message.toString());
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
    }
  }

  @override
  void onClose() {
    _riderSubscription?.cancel();
    dropbackSignatureController.dispose();
    super.onClose();
  }

  Future<void> captureDropbackPhoto() async {
    final file = await utils.pickImage(ImageSource.camera);
    if (file != null) dropbackPhoto = file;
    update();
  }

  Future<void> captureDropbackSignature() async {
    if (dropbackSignatureController.isEmpty) return;
    final bytes = await dropbackSignatureController.toPngBytes(
      width: 500,
      height: 500,
    );
    if (bytes == null) return;
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/dropback_signature_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    dropbackSignatureFile = file;
    update();
  }

  void clearDropbackSignature() {
    dropbackSignatureController.clear();
    dropbackSignatureFile = null;
    update();
  }

  void resetDropbackState() {
    dropbackPhoto = null;
    dropbackSignatureFile = null;
    dropbackSignatureController.clear();
    update();
  }

  Future<bool> confirmDropback() async {
    if (dropbackPhoto == null) return false;
    if (isSubmittingDropback.value) return false;
    isSubmittingDropback.value = true;
    utils.showLoadingDialog("Updating...");
    try {
      final images = <Map<String, dynamic>>[
        {'key': 'dropback_proof', 'file': dropbackPhoto},
        if (dropbackSignatureFile != null)
          {'key': 'signature', 'file': dropbackSignatureFile},
      ];
      final data = <String, dynamic>{
        'status': DROPBACK_CLW,
        'fe_code': user.code ?? "",
        'awb_no': order.awbNo ?? "",
      };
      final response = await apiProvider.postRequestWithImagesDio(
        apiEndPoints.updateOrderStatus,
        data,
        images,
      );
      final result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        if (Get.isRegistered<RiderDashboardController>()) {
          Get.find<RiderDashboardController>().getDashBoardData();
        }
        Get.back(result: true);
        return true;
      } else {
        utils.errorSnackBar("Error", result.message.toString());
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
      return false;
    } finally {
      isSubmittingDropback.value = false;
    }
  }
}
