import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../global/global.dart';
import '../../../../../utils/calculate_sla.dart';
import '../../../../../utils/colors.dart';
import '../../../../../utils/utils.dart';
import '../../../orders/models/orders_model.dart';

nearByOrderItem(
    OrdersData orderData, void Function(OrdersData, String) onClick) {
    Utils utils = Utils();
  return Card(
      elevation: 4,
      shadowColor: Colors.black,
      color: AppColors.white,
      child: SizedBox(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Column(
                    children: [
                       Text(
                        "Order No.",
                        style: TextStyle(
                          fontSize: Get.context!.isPhone ? 12 : 15,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        child: Text(
                          orderData.awbNo.toString(),
                          style:  TextStyle(
                            fontSize: Get.context!.isPhone ? 12 : 15,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    children: [
                       Text(
                        "Order Status",
                        style: TextStyle(
                          fontSize: Get.context!.isPhone ? 12 : 15,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: orderData.status == ASSIGNED
                                ? AppColors.linkColor
                                : orderData.status == REACHED
                                    ? AppColors.primaryThemeColor
                                    : orderData.status == PICKED
                                        ? AppColors.blue
                                        : orderData.status == DELIVERED
                                            ? AppColors.greenLight
                                            : AppColors.primaryThemeColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            orderData.status.toString().toUpperCase(),
                            style:  TextStyle(
                              fontSize: Get.context!.isPhone ? 12 : 15,
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
                       Text(
                        "Payment Type",
                        style: TextStyle(
                          fontSize: Get.context!.isPhone ? 12 : 15,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        orderData.paymentType.toString(),
                        style:  TextStyle(
                          fontSize: Get.context!.isPhone ? 12 : 15,
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                        children: [
                      Expanded(
                        flex: 1,
                        child: ListTile(
                          leading: const Icon(
                            Icons.shopping_cart,
                            color: AppColors.primaryThemeColor,
                          ),
                          title: Text(
                            "${orderData.itemName}\n${orderData.itemDescription}(${orderData.quantity})",
                            style:  TextStyle(
                              fontSize: Get.context!.isPhone ? 12 : 15,
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        flex: 1,
                        child:slaTimer(60, 60 ,orderData.createdAt ?? "", int.tryParse(orderData.sla_in_hours.toString()) ?? 0,12)
                      )
                    ]),
                    Column(
                      children: [
                        customRow(
                            "Order SLA", "${orderData.sla_in_hours}(Hrs.)" ?? ""),
                        customRow("Pickup-Delivery Distance",orderData.distance ?? ""),
                        customRow("Approx. Time",orderData.duration ?? ""),
                        customRow("Order Amount.", orderData.orderAmount ?? ""),
                        customRow("Weight", "${orderData.weight}(kg)" ?? ""),
                        customRow(
                            "Consignee Name", orderData.consigneeName ?? ""),
                        customRow("Order Created Date", utils.formatDate(orderData.createdAt.toString(),"dd MMM yyyy hh:mm a")),
                        customRow("Zone", orderData.consigneeZone ?? ""),
                        customRow("Street", orderData.consigneeStreetNumber ?? ""),
                        customRow("Building", orderData.consigneeBuildingNo ?? ""),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        customColumn(
                            "Pick-Up Address", orderData.pickupAddress ?? ""),
                        customColumn("Drop-Off Address",
                            orderData.consigneeAddress ?? ""),
                      ],
                    ),
                    Visibility(
                      visible: orderData.status == PLACED ? true : false,
                      child: Column(
                        children: [
                          const SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              utils.iconButton("Accept ", () {
                                onClick(orderData, acceptOrder);
                              }, Icons.done, AppColors.green, AppColors.white),
                              utils.iconButton("Reject ", () {
                                onClick(orderData, rejectOrder);
                              }, Icons.cancel, AppColors.red, AppColors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ));
}





Widget customRow(String name, String data) {
  return Padding(
    padding: const EdgeInsets.only(top: 2.0, bottom: 2, right: 10, left: 10),
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
          Expanded(flex: 4, child: utils.tvCustom(data, AppColors.black, 10)),
        ],
      ),
    ),
  );
}

Widget customColumn(String name, String data) {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: Visibility(
      visible: data.isNotEmpty,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
           Icon(Icons.location_on_sharp,color: name == "Drop-Off Address" ?AppColors.green : AppColors.blue),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                utils.tvCustom(name, AppColors.black, 13),
                utils.tvRegular(
                  data,
                  AppColors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
