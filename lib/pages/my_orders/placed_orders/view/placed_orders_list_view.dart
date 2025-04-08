import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/utils.dart';
import '../controller/placed_orders_controller.dart';
import '../order_item/placed_orders_item.dart';

class PlacedOrdersListView extends GetView<PlacedOrdersController> {

  final Utils utils = Utils();

  PlacedOrdersListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.primaryThemeColor,
        body: SafeArea(
          child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                      controller.fetchOrders();
                  },
                  child: SizedBox(
                    height: Get.height,
                    width: Get.width,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              height: 40,
                              child:  TextField(
                                  onChanged: (value) {
                                    searchResult(value, 1);
                                  },
                                  controller: controller.searchEditTextController,
                                  decoration: InputDecoration(
                                    hintText: "search order by number",
                                    hintStyle: const TextStyle(color: Colors.grey),
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
                                    suffixIconColor: AppColors.primaryThemeColor,
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
                                )
                              ),
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
                                      child: placedOrderItem(controller.ordersList[position],
                                          (clickedOrder,type) async {
                                            if(type == acceptOrder){
                                              utils.simpleDialog("Accept Order", "Do you want to accept this order ?", (){
                                                controller.acceptRejectOrder(acceptOrder, clickedOrder.awbNo ?? "");
                                              }, (){
                                              });

                                            }else{
                                              utils.simpleDialog("Reject Order", "Do you want to reject this order ?", (){
                                                controller.acceptRejectOrder(rejectOrder, clickedOrder.awbNo ?? "");
                                              }, (){
                                              });

                                            }
                                      }),
                                    );
                                  }),
                        )),
                      ],
                    ),
                  ),
                ),
          
              ],
            ),
        )
        );
  }

  void searchResult(String value, int type) {
    if (value.isNotEmpty) {
      var filteredList = controller.ordersList
          .where((element) => element.awbNo!.contains(value))
          .toList();

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

    } else {
      controller.ordersList = controller.ordersList;
    }
  }
}
