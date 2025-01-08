import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../apis/base_api_response.dart';
import '../../app_pages/app_pages.dart';
import '../../global/global.dart';
import 'orders_model.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:signature/signature.dart';


class OrdersController extends GetxController  with
    GetTickerProviderStateMixin{

  var isLoading = true.obs;
  var currentHintIndex = 0.obs;
  late TabController tabController;
  var  selectedOrder = OrdersData().obs;
  var viewFullMap = false.obs;
  var user = UserData();

  final image = Rxn<File>();
  final paymentProof = Rxn<File>();

  File? deliveredImage;
  File? undeliveredImage;

  File? signatureFile;
  Uint8List? signImage;
  var isSignDraw = false.obs;


  var markDelivered = false.obs;
  var markUnDelivered = false.obs;



  final List<String> hintTexts = [
    "Enter Order Number",
    "Scan QR Code for Order",
  ];
  var ordersList = <OrdersData>[].obs;
  TextEditingController searchEditTextController = TextEditingController();
  var notificationList = <String>[].obs;

  final notifications = [
    "Enter Order Number",
    "Scan QR Code for Order",
    "Enter Order Number",
    "Scan QR Code for Order",
  ];

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );



  @override
 void onInit() async {
    tabController = TabController(initialIndex: 0, length: 4,vsync:this );
    getUser();
   tabController.addListener(() {
     viewFullMap.value = false;
     if (tabController.index == 0) {
         getFeOrders(["ASSIGNED","RE-ASSIGNED"]);
     } else if (tabController.index == 1) {
       getFeOrders(["PICKED"]);
     } else if (tabController.index == 2) {
       getFeOrders(["OFD"]);
     } else if (tabController.index == 3) {
       getFeOrders(["DELIVERED"]);
     }
     signatureController.addListener(signatureListner);
   });

    super.onInit();
    startHintTextTimer();
  }



  getUser() async {
    try {
      var value = await userRepository.getUser();
      if (value != null) {
        user = value;
        if(user.code != null) {
          getFeOrders(["ASSIGNED", "RE-ASSIGNED"]);
        }
      }
    } catch (e){
      utils.errorSnackBar("Exception", e.toString());
    }

  }

  void startHintTextTimer() {
    Timer.periodic(Duration(seconds: 2), (_) => _changeHintText());
  }

  void _changeHintText() {
    currentHintIndex.value = (currentHintIndex.value + 1) % hintTexts.length;
  }
  String get currentHintText => hintTexts[currentHintIndex.value];

  void signatureListner() {
    if (signatureController.isNotEmpty) {
      exportSignature();
    }
  }



  Future<bool?> getFeOrders(List<String> status) async {
    utils.showLoadingDialog("Loading...");
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: status,
      };
      dynamic response = await apiProvider.postRequest(
          apiEndPoints.driverFetchOrderList, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
        ordersList.clear();
        for (var json in result.data) {
          ordersList.add(OrdersData.fromJson(json));
        }
       // utils.successSnackBar("success", result.message.toString());
        utils.closeLoadingDialog();
        update();
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


  Future<bool> updateOrder(String status) async {
    try {
      utils.showLoadingDialog("Updating...");

      List<Map<String, dynamic>> images = [
        if (deliveredImage != null) {'key': 'delivery_proof', 'file': deliveredImage},
        if (undeliveredImage != null){'key': 'failed_delivery_proof', 'file': undeliveredImage},
        if (signatureFile != null) {'key': 'signature', 'file': signatureFile}
      ];

      Map<String, dynamic> data = {
        'status': status,
        'fe_code': user.code ?? "",
        'awb_no': selectedOrder.value.awbNo ?? "",
        if(status == "UNDELIVERED")'reason' : "undelivered reason",
      };
      print(data);
      var response = (await apiProvider.postRequestWithImages(
          apiEndPoints.updateOrderStatus, data, images));
      var result = BaseApiResponse.fromJson(response);
      if (response['status_code'] == 200) {
        var order =  OrdersData.fromJson(result.data);
        selectedOrder.value.status =  order.status;
        utils.closeLoadingDialog();
        // utils.dialogSuccess(result.message.toString(), () {
        //  Get.back();
        // });
        update();
        if(status == "OFD" ) {
          await  getFeOrders(["PICKED"]);
        }
        return true;
      } else {
        utils.closeLoadingDialog();
        utils.errorSnackBar("Error", result.message.toString());
        return false;
      }
    } catch (e) {
      utils.errorDialog(e.toString());
      return false;
    }
  }

  captureImage(ImageSource imageSource) async {
    if (imageSource == ImageSource.camera) {
      image.value = await utils.pickImage(imageSource);
    } else {
      paymentProof.value = await utils.pickImage(imageSource);
    }
    update();
    convertImage(imageSource);
  }

  convertImage(ImageSource imageSource) async {
    if (imageSource == ImageSource.camera) {
      deliveredImage = await FlutterNativeImage.compressImage(image.value!.path,
          quality: 50, percentage: 50);
    } else {
      deliveredImage = await FlutterNativeImage.compressImage(
          paymentProof.value!.path,
          quality: 50,
          percentage: 50);
    }
  }

  exportSignature() async {
    signImage = await signatureController.toPngBytes(width: 500, height: 500);
    signatureFile = await uint8ListToFile(signImage!, "signature.png");
  }

  Future<File> uint8ListToFile(Uint8List data, String fileName) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(data);
    return file;
  }

  @override
  void onClose() {

  }
}





