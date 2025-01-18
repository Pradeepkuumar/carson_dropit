import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../apis/base_api_response.dart';
import '../../../../global/global.dart';
import '../../../../utils/colors.dart';
import '../../orders/models/orders_model.dart';

class PlacedOrdersController extends GetxController {
  TextEditingController searchEditTextController = TextEditingController();
  final riderDashboardController  = Get.put(RiderDashboardController());
  var ordersList = <OrdersData>[].obs;
  var selectedMerchantOrdersList = <OrdersData>[].obs;
  var user = UserData();
  var viewAcceptView = false.obs;
  var selectedLocationId = "".obs;

  final notifications = [
    "Enter Order Number",
    "Scan QR Code for Order",
    "Enter Order Number",
    "Scan QR Code for Order",
  ];



  @override
  void onInit() {
    getUser();
    super.onInit();
  }

  void getUser() async{
    user = (await userRepository.getUser())!;
    if(user.code != null) {
      await fetchOrders();
    }
  }

  void selectedLocationOrders() async {
    selectedMerchantOrdersList.clear();
    for (var order in ordersList) {
      if (order.locationId.toString() == selectedLocationId.value &&
          !selectedMerchantOrdersList.any((existingOrder) =>
          existingOrder.awbNo == order.awbNo)) {
        selectedMerchantOrdersList.add(order);
      }
    }
    update();
    viewAcceptView.value = true;
  }

  Future<bool?> fetchOrders() async {
    utils.showLoadingDialog("Loading...");
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
      };
      dynamic response = await apiProvider.postRequest(
          apiEndPoints.fetchPlacedOrders, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
        ordersList.clear();
        for (var json in result.data) {
          ordersList.add(OrdersData.fromJson(json));
          update();
          await Future.delayed(const Duration(milliseconds: 100));
        }
        utils.closeLoadingDialog();
        return true;
      } else {
        utils.errorSnackBar("Exception", result.message.toString());
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      update();
      utils.errorSnackBar("Exception", e.toString());
    }
    return null;
  }

  Future<bool> acceptRejectOrder(String type, String orderNumber) async {
    utils.showLoadingDialog("Loading...");
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: type,
        apiKeys.awbNo: orderNumber,
      };
      dynamic response = await apiProvider.postRequest(
          apiEndPoints.acceptRejectOrder, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
         await fetchOrders();
        riderDashboardController.getDashBoardData();
        selectedLocationOrders();
        viewAcceptView.value = false;
        utils.closeLoadingDialog();
        return true;
      } else {
        utils.errorSnackBar("Exception", result.message.toString());
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      update();
      utils.errorSnackBar("Exception", e.toString());
    }
    return false;
  }


  Future showCustomMarker(OrdersData data, int type) {
    return Get.defaultDialog(
      barrierDismissible: false,
      title: data.awbNo.toString(),
      content: Stack(
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
                          ? "${data.merchantName!}\n${data.pickupAddress!},${data.pickupZoneNo!}"
                          : "${data.consigneeName!}\n${data.consigneeAddress!},${data.consigneeStreetNumber!},${data.consigneeBuildingNo!},${data.consigneeUnitNo!},${data.consigneeZone!}",
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
                  child: utils.iconButtonWithRoundedBorder("Navigate", 40,
                          () {
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
      ),
    );
  }

}