import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
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
}
