import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/pages/map/map_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../../utils/colors.dart';
import '../../../utils/utils.dart';
import '../orders_controller.dart';
import '../orders_item.dart';

class OrdersListView extends StatefulWidget {
  var orderStatus = "";

  OrdersListView({required this.orderStatus});

  @override
  OrdersListViewState createState() => OrdersListViewState();
}

class OrdersListViewState extends State<OrdersListView> {
  final controller = Get.put(OrdersController());
  final Utils utils = Utils();
  var statusBarColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.tabController.index == 0) {
       // controller.getFeOrders(["ASSIGNED"]);
      }
    });
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
                      controller.getFeOrders([widget.orderStatus]);
                    });
                  },
                  child: SizedBox(
                    height: Get.height,
                    width: Get.width,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                              height: 40,
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
                                        var res = await Get.to(
                                            const SimpleBarcodeScannerPage());
                                        if (res is String) {
                                          searchResult(res, 2);
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
                                          width: 2.0), // Adjust width as needed
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                  ),
                                  style: const TextStyle(height: 1.2),
                                );
                              })),
                        ),
                        Expanded(
                            child: Obx(
                          () => controller.ordersList.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No Order Found !",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.white,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: controller.ordersList.length,
                                  itemBuilder: (context, position) {
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: orderItem(
                                          controller.ordersList[position],
                                          (clickedOrder, clickType) async {
                                        if (clickType == orderScanCLick) {
                                          var res = await Get.to(
                                            SimpleBarcodeScannerPage(
                                              appBarTitle: clickedOrder.awbNo,
                                            ),
                                          );
                                          if (res is String && res != "-1") {
                                            var result = res;
                                            if (clickedOrder.awbNo == result) {
                                              //controller.markOrderWareHouseIn(clickedOrder);
                                            } else {
                                              utils.errorSnackBar("Error !",
                                                  "Wrong Order Scanned");
                                            }
                                          }
                                        } else if(clickType == orderUpdateToOFD) {
                                          controller.selectedOrder.value  = clickedOrder;
                                         controller.updateOrder("OFD");
                                        }else if(clickType == orderUpdateToDeliver || clickType == fullMapViewCLick){
                                          controller.selectedOrder.value = clickedOrder;
                                          controller.viewFullMap.value = true;
                                        }
                                      }),
                                    );
                                  }),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                  visible: controller.viewFullMap.value,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          utils.tvCustom(
                              "Order :${controller.selectedOrder.value.awbNo}",
                              AppColors.white,
                              15),
                          InkWell(
                            onTap: (){
                              controller.viewFullMap.value = false;
                            },
                            child:Icon(Icons.close,color: AppColors.white),
                          )

                        ],
                      ),
                      SizedBox(
                          height: Get.height - 130,
                          width: Get.width,
                          child: MapPage(orderDetails: controller.selectedOrder.value,mapView: 1)),
                    ],
                  ))
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
