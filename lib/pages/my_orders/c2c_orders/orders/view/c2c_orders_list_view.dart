import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../app_pages/app_pages.dart';
import '../../../../../global/qr_scanner.dart';
import '../../../../../utils/colors.dart';
import '../../../../../utils/utils.dart';
import '../c2c_orders_screens/c2c_controller.dart';
import '../signature_images/image_signature_view.dart';
import 'c2cOrders_item.dart';

class C2COrdersListView extends StatefulWidget {
  var orderStatus = "";

  C2COrdersListView({super.key, required this.orderStatus});

  @override
  OrdersListViewState createState() => OrdersListViewState();
}

class OrdersListViewState extends State<C2COrdersListView> {
  late final C2COrdersController controller;
  final Utils utils = Utils();
  var statusBarColor;

  @override
  void initState() {
    controller = Get.put(C2COrdersController());
    controller.getUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(controller.tabController.index == 0) {
        controller.getC2CFeOrders([ASSIGNED]);
      }
    });
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.transparent,
        body: Obx(() {
          return Stack(
            children: [
              Visibility(
                visible: !controller.viewFullMap.value,
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      controller.getC2CFeOrders([widget.orderStatus]);
                    });
                  },
                  child: SizedBox(
                    height: Get.height,
                    width: Get.width,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              height: context.isPhone?40:60,
                              child: Obx(() {
                                return TextField(
                                  onChanged: (value) {
                                    searchResult(value, 1);
                                  },
                                  controller:
                                      controller.searchEditTextController,
                                  decoration: InputDecoration(
                                    hintText: controller.currentHintText,
                                    prefixIcon: const Icon(Icons.search),
                                    prefixIconColor:
                                        AppColors.primaryThemeColor,
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.qr_code_scanner),
                                      onPressed: () async {

                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const QRScannerPage()),
                                        );

                                        if (result != null) {
                                          searchResult(result, 2);
                                        }

                                      },
                                    ),
                                    suffixIconColor:
                                        AppColors.primaryThemeColor,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13.0),
                                      borderSide: const BorderSide(
                                          color: AppColors.primaryThemeColor,
                                          width: 2.0),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                  ),
                                  style: const TextStyle(height: 1.2),
                                );
                              })),
                        ),
                        Expanded(
                          child: Obx(() => controller.isLoading.value ?
                              Center(child: utils.iosProgressIndicator(AppColors.white,"Loading...")):
                               controller.ordersList.isEmpty ?
                               Center(child: utils.tvRegular("No Order Found !", AppColors.white))
                                  : ListView.builder(
                                itemCount: controller.ordersList.length,
                                itemBuilder: (context, position) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: c2cOrderItem(
                                      controller.ordersList[position] ,
                                          (clickedOrder, clickType) async {
                                            controller.selectedOrder.value = clickedOrder;
                                        if (clickType == fullMapViewCLick) {

                                            utils.simpleDialog("Mark this orders as PICKED",
                                             "Please match order number and mark this order to picked", 
                                             (){
                                                  controller.updateOrder(PICKED);
                                                  Get.back();
                                             }, (){
                                              Get.back();
                                             });
                                          // var res = await Get.to(
                                          //   SimpleBarcodeScannerPage(
                                          //     appBarTitle: clickedOrder.awbNo,
                                          //   ),
                                          // );
                                          // if (res is String && res != "-1") {
                                          //   var result = res;
                                          //   if (clickedOrder.awbNo == result) {
                                          //
                                          //   } else {
                                          //     utils.errorSnackBar(
                                          //       "Error !",
                                          //       "Wrong Order Scanned",
                                          //     );
                                          //   }
                                          // }
                                        } else if (clickType == orderUpdateToOFD) {
                                          controller.selectedOrder.value = clickedOrder;
                                          controller.updateOrder(OFD);
                                        } else if (clickType == orderUpdateToDeliver) {
                                          controller.selectedOrder.value = clickedOrder;
                                          Get.toNamed(Routes.c2cImageSign);

                                        }
                                      },
                                    ),
                                  );
                                },
                              )
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              // Visibility(
              //     visible: controller.viewFullMap.value,
              //     child: Column(
              //       children: [
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           children: [
              //             utils.tvCustom(
              //                 "Order :${controller.selectedOrder.value.awbNo}",
              //                 AppColors.white,
              //                 15),
              //             InkWell(
              //               onTap: (){
              //                 controller.viewFullMap.value = false;
              //               },
              //               child:Icon(Icons.close,color: AppColors.white),
              //             )
              //
              //           ],
              //         ),
              //         SizedBox(
              //             height: Get.height - 130,
              //             width: Get.width,
              //             child: MapPage(orderDetails: controller.selectedOrder.value,mapView: 1)),
              //       ],
              //     ))
            ],
          );
        }));
  }

  void searchResult(String value, int type) {
    if (value.isNotEmpty) {
      var filteredList = controller.ordersList
          .where((element) => element.awbNo!.contains(value))
          .toList();
      setState(() {
        if (filteredList.isNotEmpty) {
          controller.ordersList.value = filteredList;
          if (type == 2) {
            // ecomOrdersController.changeOrderStatus(
            //     order.hawbNo, order.referenceNo, "");
            // ordersList[0].status = "PICKED-UP";
          }
        } else {
          utils.errorSnackBar("No Match Found", "");
        }
      });
    } else {
      controller.ordersList = controller.ordersList;
    }
  }
}
