import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../apis/base_api_response.dart';
import '../../global/global.dart';
import '../../utils/utils.dart';
import 'orders_model.dart';


class OrdersController extends GetxController  with
    GetTickerProviderStateMixin{

  var isLoading = true.obs;
  var currentHintIndex = 0.obs;
  late TabController tabController;
  CargoOrderDataModel  selectedOrder = CargoOrderDataModel();
  var viewFullMap = false.obs;

  final List<String> hintTexts = [
    "Enter Order Number",
    "Scan QR Code for Order",
  ];
  var ordersList = <CargoOrderDataModel>[].obs;
  TextEditingController searchEditTextController = TextEditingController();
  var notificationList = <String>[].obs;

  final notifications = [
    "Enter Order Number",
    "Scan QR Code for Order",
    "Enter Order Number",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
    "Scan QR Code for Order",
  ];


  @override
  void onInit() {
    // getUser();
   tabController = TabController(initialIndex: 0, length: 3,vsync:this );
   tabController.addListener(() {
     viewFullMap.value = false;
     if (tabController.index == 0) {
       getFeOrders("ASSIGNED");
     } else if (tabController.index == 1) {
       getFeOrders("COLLECTED");
     } else if (tabController.index == 2) {
       getFeOrders("WAREHOUSE_IN");
     }
   });
    super.onInit();
    startHintTextTimer();
  }

  // getUser() async {
  //   try {
  //     await userRepository.getUser().then((value) => {user = value!});
  //   } catch (e){
  //     utils.errorSnackBar("Exception", e.toString());
  //   }
  //   getDashBoardData();
  // }

  void startHintTextTimer() {
    Timer.periodic(Duration(seconds: 2), (_) => _changeHintText());
  }

  void _changeHintText() {
    currentHintIndex.value = (currentHintIndex.value + 1) % hintTexts.length;
  }
  String get currentHintText => hintTexts[currentHintIndex.value];



  Future<bool?> getFeOrders(String status) async {
    utils.showLoadingDialog("Loading...");
    try {
      Map<String, dynamic> model = {
        'fecode': "CL_FAYIS01",
        'status': status,
      };
      dynamic response = await apiProvider.postRequest(
          apiEndPoints.fetchCargoOrderDetails, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
        ordersList.clear();
        for (var json in result.data) {
          ordersList.add(CargoOrderDataModel.fromJson(json));
        }
        update();
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


  @override
  void onClose() {

  }
}





