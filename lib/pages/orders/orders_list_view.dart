import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../../utils/colors.dart';
import '../../utils/utils.dart';
import 'orders_controller.dart';
import 'orders_item.dart';

class OrdersListView extends StatefulWidget {
  var orderStatus = "COLLECTED";

  OrdersListView({required this.orderStatus});

  @override
  OrdersListViewState createState() => OrdersListViewState();
}

class OrdersListViewState extends State<OrdersListView> {
  TextEditingController editingController = TextEditingController();
  final controller = Get.put(OrdersController());


  final Utils utils = Utils();

  @override
  void initState()  {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getFeOrders(widget.orderStatus);
    });


  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
           controller.getFeOrders("");

          });
        },
        child: Container(
          height: Get.height,
          width: Get.width,
          decoration: utils.boxDecorationCustomColor(AppColors.white),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 50,
                  child: Obx(() {
                    return
                      TextField(
                        onChanged: (value) {
                          // searchResult(value, 1);
                        },
                        controller: null,
                        decoration: InputDecoration(
                          hintText: controller.currentHintText,
                          prefixIcon: Icon(Icons.search),
                          prefixIconColor: AppColors.primaryThemeColor,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.qr_code_scanner),
                            onPressed: () async {
                              // var res = await Get.to(
                              //   SimpleBarcodeScannerPage(),
                              // );
                              // if (res is String) {
                              //   var result = res;
                              //   searchResult(res, 2);
                              // }
                            },
                          ),
                          suffixIconColor: AppColors.primaryThemeColor,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide(color: AppColors.white, width: 2.0), // Adjust width as needed
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0),
                        ),
                        style: TextStyle(height: 1.2),
                      );
                  })

                ),
              ),
              Expanded(
                  child: Obx(() => controller.ordersList.isEmpty
                      ? const Center(
                    child: Text(
                      "No Order Found !",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
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
                                (clickedOrder) async {
                              var res = await Get.to(
                                SimpleBarcodeScannerPage(appBarTitle: clickedOrder.hawbNo,),
                              );
                              if (res is String && res != "-1") {
                                var result = res;
                                if(clickedOrder.hawbNo == result) {
                                  //controller.markOrderWareHouseIn(clickedOrder);
                                }else{
                                  utils.errorSnackBar("Error !","Wrong Order Scanned");
                                }
                              }
                            } ,
                          ),
                        );
                      }),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // void searchResult(String value, int type) {
  //   //List<EcomOrdersList> originalList = ordersList;
  //   if (value.isNotEmpty) {
  //     var filteredList = controller.ordersList
  //         .where((element) => element.contains(value))
  //         .toList();
  //     setState(() {
  //       if (filteredList.isNotEmpty) {
  //         controller.ordersList.value = filteredList;
  //         if (type == 2) {
  //           var order = controller.ordersList[0];
  //           // ecomOrdersController.changeOrderStatus(
  //           //     order.hawbNo, order.referenceNo, "");
  //           // ordersList[0].status = "PICKED-UP";
  //         }
  //       } else {
  //         utils.errorSnackBar("No Match Found", "");
  //       }
  //     });
  //   } else {
  //     setState(() {
  //       // ecomOrdersController.ordersList = widget.ordersList;
  //     });
  //   }
  // }

}
