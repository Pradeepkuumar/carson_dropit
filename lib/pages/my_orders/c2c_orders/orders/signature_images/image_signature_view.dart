import 'package:carson_zyppy/pages/my_orders/c2c_orders/model/c2cOrdersModel.dart';
import 'package:carson_zyppy/pages/my_orders/c2c_orders/orders/c2c_orders_screens/c2c_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import '../../../../../global/consts.dart';
import '../../../../../global/global.dart';
import '../../../../../utils/colors.dart';

class C2cImageSignatureView extends GetView<C2COrdersController> {
   var orderType = "".obs;
   var clickedOrder;
   C2cImageSignatureView({super.key});
  

  @override
  Widget build(BuildContext context) {
     orderType.value = Get.arguments != null && Get.arguments['orderType'] != null ? Get.arguments['orderType'] : "";
      clickedOrder  = Get.arguments != null && Get.arguments['selectedOrder'] != null ? Get.arguments['selectedOrder'] : C2cOrdersData();
      controller.selectedOrder.value.awbNo = clickedOrder.awbNo;
      controller.selectedOrder.value.status = clickedOrder.status;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryThemeColor,
        title: const Text(
          "Picture & Signature Proof",
          style: TextStyle(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primaryThemeColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: GetBuilder<C2COrdersController>(
            builder: (controller) => Center(
              child: Card(
                color: AppColors.white,
                elevation: 2,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    utils.tvCustom(
                        "Signature(optional)", AppColors.primaryThemeColor, 15),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Container(
                        decoration: utils.mainBorder(),
                        child: Column(
                          children: [
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  decoration: utils.roundedBorder(
                                      AppColors.primaryThemeColor, 10),
                                  child: Obx(() => Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: IgnorePointer(
                                          ignoring:
                                              controller.isSignDisbled.value,
                                          child: SfSignaturePad(
                                            key: controller.signaturePadKey,
                                            minimumStrokeWidth: 1,
                                            maximumStrokeWidth: 3,
                                            strokeColor: AppColors.black,
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                      )),
                                )),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                utils.iconButton("Erase", () {
                                  controller.isSignDisbled.value = false;
                                  controller.signaturePadKey.currentState
                                      ?.clear();
                                  controller.signatureFile = null;
                                }, Icons.cleaning_services_rounded,
                                    AppColors.blue, AppColors.white),
                                const SizedBox(
                                  width: 10,
                                ),
                                utils.iconButton("Save", () {
                                  controller.isSignDisbled.value = true;
                                  controller.exportSignature();
                                }, Icons.save,
                                    AppColors.blue, AppColors.white),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            )
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: InkWell(
                        onTap: () {
                          controller.captureImage(ImageSource.camera, "0");
                        },
                        child: Container(
                          width: Get.width,
                          decoration: utils.mainBorder(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Visibility(
                                visible: controller.image.value != null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    utils.iconButtonWithoutBorder("Change", () {
                                      controller.image.refresh();
                                      controller.captureImage(
                                          ImageSource.camera,"0");
                                    }, Icons.refresh, null)
                                  ],
                                ),
                              ),
                              Obx(
                                () => Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(50)),
                                    height: 250,
                                    width: 250,
                                    child: controller.image.value != null
                                        ? Image.file(
                                            controller.image.value!,
                                            fit: BoxFit.fill,
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.camera,
                                                size: 80,
                                                color:
                                                    AppColors.primaryThemeColor,
                                              ),
                                              utils.tvCustom(
                                                  "Capture Image",
                                                  AppColors.primaryThemeColor,
                                                  15)
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.isUndelivring.value,
                        child: Padding(
                            padding: EdgeInsets.all(8),
                            child: utils.iconButtonWithRoundedBorder(
                                controller.selectedReason.value, 45, () async {
                                     await controller.getReasons().then((value){
                                        controller.popUpWindowReasons();
                                     });
                             
                            }, Icons.arrow_drop_down, AppColors.primaryLight,
                                Icons.bike_scooter, 2, AppColors.primaryLight)),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Obx(() {
                          final isUndelivered = controller.selectedOrder.value.status == UNDELIVERED;
                          return Column(
                            children: [

                              if (isUndelivered)
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: utils.mainButton(
                                    "DROP AT WAREHOUSE",
                                    () async {
                                      if (controller.deliveredImage != null) {
                                        var isDelivered = await controller.updateOrder(DROPBACK_CLW,orderType.value);
                                        if (isDelivered) {
                                          controller.isSignDisbled.value = false;
                                          controller.signaturePadKey.currentState?.clear();
                                          controller.signatureFile = null;
                                          Get.back();
                                        }
                                      } else {
                                        utils.errorSnackBar("Error", "Pls upload Sign & Image");
                                      }
                                    },
                                    AppColors.primaryThemeColor,
                                  ),
                                ),

                             
                              if (!isUndelivered)
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: utils.mainButton(
                                            "UNDELIVER",
                                            () async {
                                              controller.selectedOrder.value.awbNo = clickedOrder.awbNo;
                                              controller.selectedOrder.value.status = clickedOrder.status;
                                              if (controller.isUndelivring.value &&
                                                  controller.selectedReasonId.value != 0) {
                                                if (controller.deliveredImage != null) {
                                                  var isDelivered =
                                                      await controller.updateOrder(UNDELIVERED,orderType.value);
                                                  if (isDelivered) {
                                                    Get.back();
                                                  }
                                                } else {
                                                  utils.errorSnackBar(
                                                      "Error", "Pls upload Sign & Image");
                                                }
                                              } else {
                                                utils.errorSnackBar(
                                                    "Error", "Pls Select undeliver reason");
                                                controller.isUndelivring.value = true;
                                              }
                                            },
                                            AppColors.red.withAlpha(200),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: utils.mainButton(
                                          "DELIVER",
                                          () async {
                                              controller.selectedOrder.value.awbNo = clickedOrder.awbNo;
                                              controller.selectedOrder.value.status = clickedOrder.status;
                                            if (controller.deliveredImage != null) {
                                              var isDelivered =
                                                  await controller.updateOrder(DELIVERED,orderType.value);
                                              if (isDelivered) {
                                                controller.isSignDisbled.value = false;
                                                controller.signaturePadKey.currentState?.clear();
                                                controller.signatureFile = null;
                                                Get.back();
                                              }
                                            } else {
                                              utils.errorSnackBar("Error", "Pls upload Sign & Image");
                                            }
                                          },
                                          AppColors.greenLight.withAlpha(200),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }),
                    const SizedBox(
                      height: 10,
                    ) 
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
