
import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/pages/map/map_page.dart';
import 'package:flutter/material.dart';
import '../../../../global/global.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/utils.dart';
import '../models/orders_model.dart';


orderItem(OrdersData orderData, void Function(OrdersData,int) onClick) {
  Utils utils = Utils();
  return Card(
      elevation: 4,
      shadowColor: Colors.black,
      color: AppColors.white,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding:  const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Column(
                    children: [
                       const Text(
                        "Order No.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        child: Text(
                          orderData.awbNo.toString(),
                          style:  const TextStyle(
                            fontSize: 10,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                   const Spacer(),
                  Column(
                    children: [
                       const Text(
                        "Order Status",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: orderData.status == "ASSIGNED" ? AppColors.linkColor :
                            orderData.status == "REACHED"? AppColors.primaryThemeColor:orderData.status == "PICKED"?
                            AppColors.blue : orderData.status == "DELIVERED" ? AppColors.greenLight : AppColors.primaryThemeColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding:  const EdgeInsets.all(4.0),
                          child: Text(
                            orderData.status.toString().toUpperCase(),
                            style:  const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                   const Spacer(),
                  Column(
                    children: [
                       const Text(
                        "Payment Type",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        orderData.paymentType.toString(),
                        style:  const TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
               const SizedBox(
                height: 5,
              ),
               const Divider(
                thickness: 1,
                indent: 5,
                endIndent: 5,
                color: AppColors.greyColor4,
                height: 5,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                      child: ListTile(
                        leading:  const Icon(
                          Icons.shopping_cart,
                          color: AppColors.primaryThemeColor,
                        ),
                        title: Text(
                          "${orderData.merchantName}\n${orderData.itemName}\n${orderData.itemDescription}(${orderData.quantity})",
                          style:  const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      )),
                  Container(
                      child: Column(
                        children: [
                          customRow("Item amount.",orderData.orderAmount ?? ""),
                          customRow("Weight.",  orderData.weight ?? ""),
                          customRow("Consignee Name", orderData.consigneeName ?? ""),
                        ],
                      )),

                  Visibility(
                    visible: orderData.status == "ASSIGNED" || orderData.status == "RE-ASSIGNED" ? true : false,
                    child: Column(
                      children: [
                        SizedBox (
                          height: 300,
                          child: MapPage(orderDetails: orderData,mapView: 0)),
                        SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            utils.iconButton("Call PickUp", () {
                              utils.openDialPad(
                                  orderData.pickupPhoneNo.toString());
                            }, Icons.call, AppColors.blue, AppColors.white),
                            utils.iconButton("Call Consignee", () {
                              utils.openDialPad(
                                  orderData.consigneeMobileNo.toString());
                            }, Icons.call, AppColors.green, AppColors.white),
                            utils.iconButton("Update", () {
                              onClick(orderData,fullMapViewCLick);
                            }, Icons.arrow_circle_right_rounded,
                                AppColors.primaryThemeColor, AppColors.white),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Visibility(
                      visible: orderData.status == "PICKED" ? true : false,
                      child: utils.iconButton("Out For Delivery", () {
                        onClick(orderData,orderUpdateToOFD);
                      }, Icons.add_road, AppColors.blue, AppColors.white)),
                  Visibility(
                      visible: orderData.status == "OFD" ? true : false,
                      child: utils.iconButton("Update", () {
                        onClick(orderData,orderUpdateToDeliver);
                      }, Icons.update, AppColors.primaryThemeColor, AppColors.white))

                ],
              )
            ],
          ),
        ),
      ));
}


Widget customRow(String name, String data) {
  return Padding(
    padding:  const EdgeInsets.only(top: 2.0, bottom: 2, right: 10, left: 10),
    child: Visibility(
      visible: data.isNotEmpty,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: utils.tvCustom(name, AppColors.black, 10),
          ),
          Expanded(
            flex: 2,
            child: utils.tvRegular(":", AppColors.black),
          ),
          Expanded(flex: 4, child: utils.tvCustom(data, AppColors.black, 12)),
        ],
      ),
    ),
  );
}
