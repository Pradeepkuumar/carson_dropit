import 'dart:io';

import 'package:flutter/material.dart';
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
  late OrdersData order;
  GoogleMapViewController? mapViewController;
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
    getUser();
    order = (Get.arguments is OrdersData) ? Get.arguments as OrdersData : OrdersData();
    super.onInit();
  }
  Future<void> getUser() async {
    final value = await userRepository.getUser();
    if (value != null) {
      user = value;
    }
  }
  bool get isAvailable => order.status == PLACED;

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

  @override
  void onClose() {
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
