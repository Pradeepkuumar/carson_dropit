import 'package:carson_zyppy/pages/my_orders/orders/controller/orders_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signature/signature.dart';

import '../../../../app_pages/app_pages.dart';
import '../../../../global/consts.dart';
import '../../../../global/global.dart';
import '../../../../utils/colors.dart';

class ImageSignatureView extends GetView<OrdersController> {
  const ImageSignatureView({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(
     // appBar: CustomAppBar(AppConstants.APPBAR_BUTTON_BACK),
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.primaryThemeColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: GetBuilder<OrdersController>(
            builder: (controller) =>
                Center(
                  child: Card(
                    color: AppColors.white,
                    elevation: 2,
                    child: Column(
                      children: [
                        const SizedBox(height: 10,),
                        utils.tvCustom(
                            "Signature & Image", AppColors.primaryThemeColor,
                            15),
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            decoration: utils.mainBorder(),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: utils.roundedBorder(AppColors.primaryThemeColor, 10),
                                    child: Signature(
                                      controller: controller
                                          .signatureController,
                                      width: Get.width,
                                      height: 200,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                Obx(() {
                                  return Visibility(
                                    visible: controller.isSignDraw.value,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center,

                                      children: [
                                        utils.iconButton("Erase", () {
                                          controller.signatureController.disabled = false;
                                          controller.signatureController.clear();
                                          controller.signImage?.clear();
                                          controller.signatureFile = null;
                                        },Icons.cleaning_services_rounded,
                                            AppColors.blue, AppColors.white),
                                      ],
                                    ),
                                  );
                                })
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: InkWell(
                            onTap: () {
                             // controller.captureImage(ImageSource.camera,0);
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
                                        utils.iconButtonWithoutBorder("Change",
                                                () {
                                              // controller.image.refresh();
                                              // controller.captureImage(
                                              //     ImageSource.camera,0);
                                            }, Icons.refresh, null)
                                      ],
                                    ),
                                  ),
                                  Obx(() =>
                                      Padding(
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
                                              :
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.camera,size: 80,color: AppColors.primaryThemeColor,),
                                              utils.tvCustom("Capture Image", AppColors.primaryThemeColor, 15)
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
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: utils.mainButton("DELIVER", () async{
                            if (controller.deliveredImage != null) {
                                 var isDelivered = await controller.updateOrder(DELIVERED);
                                 if(isDelivered){
                                   Get.offNamed(Routes.ordersScreen);
                                 }
                            } else {
                              utils.errorSnackBar(
                                  "Error", "Pls upload Sign & Image");
                            }
                          }, AppColors.primaryThemeColor),
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
