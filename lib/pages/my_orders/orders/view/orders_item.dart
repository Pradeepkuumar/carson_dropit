
import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../global/global.dart';
import '../../../../utils/calculate_sla.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/utils.dart';
import '../../nearby_orders/view/item_nearby_oredrs/neaby_orders_item.dart';
import '../models/orders_model.dart';


orderItem(OrdersData orderData, void Function(OrdersData,int) onClick) {
  Utils utils = Utils();

  return Card(
      elevation: 4,
      shadowColor: Colors.black,
      color: AppColors.white,
      child: SizedBox(
        width: Get.width,
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
                        Text(
                        "Order No.",
                        style: TextStyle(
                          fontSize:  Get.context!.isPhone ? 12 : 15,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        orderData.awbNo.toString(),
                        style:   TextStyle(
                          fontSize: Get.context!.isPhone ?10:15,
                          color: AppColors.black,
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
                          fontSize: Get.context!.isPhone?12:15,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: orderData.status == ASSIGNED ? AppColors.linkColor :
                            orderData.status == REACHED? AppColors.primaryThemeColor : orderData.status == PICKED ?
                            AppColors.blue : orderData.status == DELIVERED ? AppColors.greenLight : orderData.status == UNDELIVERED ? AppColors.red : AppColors.primaryThemeColor,
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding:  const EdgeInsets.all(4.0),
                          child: Text(
                            orderData.status.toString().toUpperCase(),
                            style:   TextStyle(
                              fontSize: Get.context!.isPhone ?10 :15,
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
                          fontSize: Get.context!.isPhone?12:15,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        orderData.paymentType.toString(),
                        style:   TextStyle(
                          fontSize: Get.context!.isPhone?12:15,
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: ListTile(
                              leading: const Icon(
                                Icons.shopping_cart,
                                color: AppColors.primaryThemeColor,
                              ),
                              title: Text(
                                "${orderData.merchantName})",
                                style:  TextStyle(
                                  fontSize: Get.context!.isPhone?12:20,
                                ),
                              ),
                            ),
                          ),

                          Visibility(
                            visible:orderData.status == DELIVERED || orderData.status == UNDELIVERED  ? false : true ,
                            child: Expanded(
                                flex: 1,
                                child: slaTimer(60, 60,orderData.createdAt ?? "", int.tryParse(orderData.sla_in_hours.toString()) ?? 0 ,12),

                            ),
                          )
                        ]),
                  ),

                  Column(
                    children: [
                      // \n${orderData.itemName}\n${orderData.itemDescription}(${orderData.quantity}
                      customRow("Order SLA","${orderData.sla_in_hours}(Hrs)"),
                      customRow("Pickup-Delivery Distance",orderData.distance ?? ""),
                      customRow("Approx. Time",orderData.duration ?? ""),
                      customRow("Order Amount.",orderData.orderAmount ?? ""),
                      customRow("Weight.",  orderData.weight ?? ""),
                      customRow("Consignee Name", orderData.consigneeName ?? ""),
                      customRow("Created Date", utils.formatDate(orderData.createdAt.toString(),"dd MMM yyyy hh:mm a")),
                      customRow("Zone", orderData.consigneeZone ?? ""),
                      customRow("Street", orderData.consigneeStreetNumber ?? ""),
                      customRow("Building", orderData.consigneeBuildingNo ?? ""),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customColumn("Pick-Up Location", orderData.pickupAddress ?? ""),
                      customColumn("Drop-Off Location", orderData.consigneeAddress ?? ""),
                    ],
                  ),
                  // Visibility(
                  //   visible: orderData.status == UNDELIVERED,
                  //     child: Column( children: [
                  //         customRow("Undelivered Reason", orderData.reason ?? ""),
                  //         Image.network(orderData.failed_delivery_proof ?? "",height: 350,width: 300,fit: BoxFit.fill,)
                  //     ])),
                  Visibility(
                    visible: orderData.status == ASSIGNED || orderData.status == RE_ASSIGNED ||orderData.status == REACHED ? true : false,
                    child: Column(
                      children: [
                        const SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                              utils.clickableImageVertical("Call Pickup", AppColors.black, AppColors.lightBlue, icTelephone, 30, 30, (){
                                utils.openDialPad(
                                    orderData.pickupPhoneNo.toString());
                              }),
                             const SizedBox(width:5,),
                            utils.clickableImageVertical("Pickup", AppColors.black, AppColors.green, icWhatsApp,30, 30, (){
                              utils.openWhtsApp(
                                  orderData.pickupPhoneNo.toString());
                              }),
                            const SizedBox(width:5,),
                            utils.clickableImageVertical("Call Consignee", AppColors.black, AppColors.blue, icTelephone, 30, 30, (){
                              utils.openDialPad(
                                  orderData.consigneeMobileNo.toString());
                              }),
                            const SizedBox(width:5,),
                            utils.clickableImageVertical("Consignee", AppColors.black, AppColors.green, icWhatsApp,30, 30, (){
                              utils.openWhtsApp(
                                  orderData.pickupPhoneNo.toString());
                              }),

                          ],
                        ),
                        const SizedBox(height: 10,),
                        utils.iconButton("Update", () {
                          onClick(orderData,fullMapViewCLick);
                        }, Icons.arrow_circle_right_rounded,
                            AppColors.primaryThemeColor, AppColors.white),


                      ],
                    ),
                  ),

                  Visibility(
                      visible: orderData.status == PICKED ? true : false,
                      child: utils.iconButton("Out For Delivery", () {
                        onClick(orderData,orderUpdateToOFD);
                      }, Icons.add_road, AppColors.blue, AppColors.white)),
                  Visibility(
                      visible: orderData.status == OFD ? true : false,
                      child: utils.iconButton("Update", () {
                        onClick(orderData,orderUpdateToDeliver);
                      }, Icons.update, AppColors.primaryThemeColor, AppColors.white)),
                       Visibility(
                      visible: orderData.status == UNDELIVERED ? true : false,
                      child: utils.iconButton("Drop at Warehouse", () {
                        onClick(orderData,orderUpdateDropClw);
                      }, Icons.add_road, AppColors.greenLight, AppColors.white)),

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
        mainAxisAlignment: MainAxisAlignment.center,
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
