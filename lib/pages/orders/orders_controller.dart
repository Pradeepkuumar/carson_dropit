import 'dart:async';

import 'package:get/get.dart';

import '../../apis/base_api_response.dart';
import '../../global/global.dart';
import '../../utils/utils.dart';
import 'orders_model.dart';


class OrdersController extends GetxController {

  var isLoading = true.obs;
  var currentHintIndex = 0.obs;

  final List<String> hintTexts = [
    "Enter Order ID",
    "Scan QR Code for Order",
  ];
  var ordersList = <CargoOrderDataModel>[].obs;
  @override
  void onInit() {
    // getUser();
    getFeOrders("COLLECTED");
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
    Utils.showLoadingDialog("Loading...");
    try {
      Map<String, dynamic> model = {
        'fecode': "CL_FAYIS01",
        'status': "COLLECTED",
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
        Utils.closeLoadingDialog();
        return true;
      } else {
        utils.errorSnackBar("Exception", result.message.toString());
        Utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      Utils.closeLoadingDialog();
      update();
      utils.errorSnackBar("Exception", e.toString());
    }
    return null;
  }


  @override
  void onClose() {

  }
}





