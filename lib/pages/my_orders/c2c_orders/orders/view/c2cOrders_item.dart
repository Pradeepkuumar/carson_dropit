import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../global/global.dart';
import '../../../../../utils/colors.dart';
import '../../../../../utils/utils.dart';
import '../../../../map/orderItem/clickedOrderItem.dart';
import '../../model/c2cOrdersModel.dart';


c2cOrderItem(C2cOrdersData orderData, void Function(C2cOrdersData,int) onClick) {
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
              // Row(
              //   crossAxisAlignment: CrossAxisAlignment.center,
              //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //   mainAxisSize: MainAxisSize.max,
              //   children: [
              //     Column(
              //       children: [
              //           Text(
              //           "Order No.",
              //           style: TextStyle(
              //             fontSize:  Get.context!.isPhone ? 12 : 15,
              //             color: Colors.black,
              //           ),
              //         ),
              //         Text(
              //           orderData.awbNo.toString(),
              //           style:   TextStyle(
              //             fontSize: Get.context!.isPhone ?10:15,
              //             color: AppColors.black,
              //           ),
              //         ),
              //       ],
              //     ),
              //      const Spacer(),
              //     Column(
              //       children: [
              //           Text(
              //           "Order Status",
              //           style: TextStyle(
              //             fontSize: Get.context!.isPhone?12:15,
              //             color: Colors.black,
              //           ),
              //         ),
              //         Container(
              //           decoration: BoxDecoration(
              //               color: orderData.status == ASSIGNED ? AppColors.linkColor :
              //               orderData.status == REACHED? AppColors.primaryThemeColor : orderData.status == PICKED ?
              //               AppColors.blue : orderData.status == DELIVERED ? AppColors.greenLight : orderData.status == UNDELIVERED ? AppColors.red : AppColors.primaryThemeColor,
              //               borderRadius: BorderRadius.circular(8)),
              //           child: Padding(
              //             padding:  const EdgeInsets.all(4.0),
              //             child: Text(
              //               orderData.status.toString().toUpperCase(),
              //               style:   TextStyle(
              //                 fontSize: Get.context!.isPhone ?10 :15,
              //                 color: Colors.white,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //      const Spacer(),
              //     Column(
              //       children: [
              //           Text(
              //           "Payment Type",
              //           style: TextStyle(
              //             fontSize: Get.context!.isPhone?12:15,
              //             color: Colors.black,
              //           ),
              //         ),
              //         Text(
              //           orderData.paymentType.toString(),
              //           style:   TextStyle(
              //             fontSize: Get.context!.isPhone?12:15,
              //             color: Colors.black,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
              //  const SizedBox(
              //   height: 5,
              // ),
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          orderData.awbNo.toString(),
          style: TextStyle(
            fontSize: Get.context!.isPhone ? 10 : 15,
            color: AppColors.black,
            fontWeight: FontWeight.w600,
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
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
                            : orderData.status == UNDELIVERED 
                                ? AppColors.red 
                                : AppColors.primaryThemeColor,
            borderRadius: BorderRadius.circular(8)
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              orderData.status.toString().toUpperCase(),
              style: TextStyle(
                fontSize: Get.context!.isPhone ? 10 : 15,
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: orderData.paymentType.toString().toLowerCase() == "cod" 
                ? Colors.orangeAccent // COD color
                : Colors.greenAccent, // PPD color
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              orderData.paymentType.toString().toUpperCase(),
              style: TextStyle(
                fontSize: Get.context!.isPhone ? 10 : 15,
                color: orderData.paymentType.toString().toLowerCase() == "cod" 
                    ? Colors.white // COD text color
                    : Colors.black, // PPD text color
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  ],
),
const SizedBox(height: 5),
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
                    padding:  EdgeInsets.all(8.0),
                    child: Container(
                      decoration: utils.roundedBorder(AppColors.greyColor2, 5),
                      child: Row(
                          children: [
                            Expanded(
                            flex: 1,
                             child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  
                                  children: [
                                     const Icon(
                                      Icons.local_shipping,
                                      color: AppColors.primaryThemeColor,),
                                      utils.tvCustom("Shipper", AppColors.primaryThemeColor, 12)
                                      
                                  ],
                                ),
                                  Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(
                                    "${orderData.shipperName}\n${orderData.shipperAddress}\n"'Zone '"${orderData.shipperZoneNo}\n"'Street '"${orderData.shipperStreetNo}\n"'Building '"${orderData.shipperBuildingNo}",
                                    style:  TextStyle(
                                      fontSize: Get.context!.isPhone?12:20,
                                    ),),
                                  )
                              ],)
                              
                            ),
                            
                            Expanded(
                              flex: 1,
                              child: Column(
                                 mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                Column(
                                  children: [
                                     const Icon(
                                      Icons.person,
                                      color: AppColors.blue,),
                                      utils.tvCustom("Consignee", AppColors.blue, 12)
                                      
                                  ],
                                ),
                                  Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(
                                    "${orderData.consigneeName}\n${orderData.consigneeAddress}\n"'Zone '"${orderData.consigneeZoneNo}\n"'Street '"${orderData.consigneeStreetNo}\n"'Building '"${orderData.consigneeBuildingNo}",
                                    style:  TextStyle(
                                      fontSize: Get.context!.isPhone?12:20,
                                    ),),
                                  )
                              ],)
                            ),
                      
                            
                          ]),
                    ),
                  ),

                  Column(
                    children: [
                      customRow("Item", orderData.itemName ?? ""),
                      customRow("Description", orderData.itemDescription ?? ""),
                      customRow("Quantity", orderData.quantity.toString()),
                      customRow("Order Amount.",'${orderData.orderAmount} (Qar) '),
                      customRow("Weight.",  ' ${orderData.weight} (Kg) '),
                      customRow("Created Date", utils.formatDate(orderData.createdAt.toString(),"dd MMM yyyy hh:mm a")),
                      customRow("Remark", orderData.remarks ?? ""),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: (){
                          if(orderData.status != DELIVERED && orderData.status != UNDELIVERED){
                            if(orderData.shipperLatitude != null && orderData.shipperLongitude != null){
                              utils.openMapsFromLatLang(double.parse(orderData.shipperLatitude!), double.parse(orderData.shipperLongitude!));
                            }else{  
                             utils.openMaps(orderData.shipperAddress ?? "");
                          }
                        }},
                        child: customColumn("Pick-Up Location", orderData.shipperAddress ?? "")),
                      InkWell(
                        onTap: (){
                          if(orderData.status != DELIVERED && orderData.status != UNDELIVERED){
                            if(orderData.consigneeLatitude != null && orderData.consigneeLongitude != null){
                              utils.openMapsFromLatLang(double.parse(orderData.consigneeLatitude!), double.parse(orderData.consigneeLongitude!));
                            }else{
                            utils.openMaps(orderData.consigneeAddress ?? "");
                           }
                          }
                        },
                        child: customColumn("Drop-Off Location", orderData.consigneeAddress ?? "")),
                    ],
                  ),
                  Visibility(
                    visible: orderData.status == DELIVERED || orderData.status == UNDELIVERED ? false : true,
                    child: Column(
                      children: [
                        const SizedBox(height: 10,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                              utils.clickableImageVertical("Call Shipper", AppColors.black, AppColors.lightBlue, icTelephone, 30, 30, (){
                                utils.openDialPad(
                                    orderData.shipperMobileNo.toString());
                              }),
                             const SizedBox(width:5,),
                            utils.clickableImageVertical("Shipper", AppColors.black, AppColors.green, icWhatsApp,30, 30, (){
                              utils.openWhtsApp(
                                  orderData.shipperMobileNo.toString());
                              }),
                            const SizedBox(width:5,),
                            utils.clickableImageVertical("Call Consignee", AppColors.black, AppColors.blue, icTelephone, 30, 30, (){
                              utils.openDialPad(
                                  orderData.consigneeMobileNo.toString());
                              }),
                            const SizedBox(width:5,),
                            utils.clickableImageVertical("Consignee", AppColors.black, AppColors.green, icWhatsApp,30, 30, (){
                              utils.openWhtsApp(
                                  orderData.consigneeMobileNo.toString());
                              }),

                          ],
                        ),
                        const SizedBox(height: 10,),
                       
                      ],
                    ),
                  ),
                   
                  Visibility( 
                      visible: orderData.status == DELIVERED || orderData.status == UNDELIVERED || orderData.status == OFD || orderData.status == PICKED ? false : true,
                      child: utils.iconButton("Update", () {
                          onClick(orderData,fullMapViewCLick);
                        }, Icons.arrow_circle_right_rounded,
                            AppColors.primaryThemeColor, AppColors.white),
                      ),
                  Visibility( 
                      visible: orderData.status == PICKED ? true : false,
                      child: utils.iconButton("Out For Delivery", () {
                        onClick(orderData,orderUpdateToOFD);
                      }, Icons.add_road, AppColors.blue, AppColors.white)),
                  Visibility(
                      visible: orderData.status == OFD ? true : false,
                      child: utils.iconButton("Deliver", () {
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
            child: utils.tvCustom(name, AppColors.black, 11,textAlignment: TextAlign.start),
          ),
          Expanded(
            flex: 2,
            child: utils.tvRegular(":", AppColors.black),
          ),
          Expanded(flex: 4, child: utils.tvCustom(data, AppColors.black, 11,textAlignment: TextAlign.start)),
        ],
      ),
    ),
  );
}
