import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../global/global.dart';
import '../../../../../utils/calculate_sla.dart';
import '../../../../../utils/colors.dart';
import '../../../../../utils/utils.dart';
import '../../my_orders/orders/models/orders_model.dart';

clickedOrderItem(
    OrdersData orderData, void Function(OrdersData,String) onClick,int listType) {
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                      Text(
                        orderData.awbNo.toString(),
                        style:  TextStyle(
                          fontSize: Get.context!.isPhone ? 12 : 15,
                          color: AppColors.black,
                        ),
                      ),

                    ],
                  ),
                  slaTimer(40, 40 ,orderData.createdAt ?? "", int.tryParse(orderData.sla_in_hours.toString()) ?? 0,12),

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
                    Column(
                      children: [
                        customRow("Item","${orderData.itemName!}(${orderData.quantity})" ?? ""),
                        customRow("Order Amount",orderData.orderAmount ?? ""),
                        customRow("Order Weight",orderData.weight ?? ""),
                        customRow("Location", orderData.status == "OFD" ? orderData.contact_person_name ?? "":orderData.pickupLocationName ?? ""),
                      ],
                    ),
                    const SizedBox(height: 10,),
                    Column(
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
                      ],
                    ),
                    Visibility(
                      visible: listType == 1,
                        child: utils.iconButton(orderData.status == "ASSIGNED"|| orderData.status == "RE-ASSIGNED" ? "REACHED" :orderData.status == "REACHED"? "PICK": orderData.status == "PICKED" ? "MARK OFD":orderData.status == "OFD" ? "UPDATE" : "",(){
                          orderData.status == "OFD" ?
                          onClick(orderData,updateOrder)
                              :
                      onClick(orderData,updateStatus);

                    }, Icons.update,orderData.status == "ASSIGNED"|| orderData.status == "RE-ASSIGNED"?AppColors.blue : orderData.status == "RE-ASSIGNED"?AppColors.orange : orderData.status == "PICKED" ?
                        AppColors.primaryThemeColor :AppColors.greenLight, AppColors.white)
                    )
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          Icon(Icons.location_on_sharp,color: name == "Drop-Off Location" ?AppColors.green : AppColors.blue),
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
