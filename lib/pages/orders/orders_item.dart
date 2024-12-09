
import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/pages/map/map_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_pages/app_pages.dart';
import '../../global/global.dart';
import '../../utils/colors.dart';
import '../../utils/utils.dart';
import 'orders_model.dart';


orderItem(
    CargoOrderDataModel orderData, void Function(CargoOrderDataModel,int) onClick) {
  Utils utils = Utils();
  String? result;
  BuildContext context;
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
                        "HAWB No.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        child: Text(
                          orderData.hawbNo.toString(),
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
                            color: orderData.status == "ASSIGNED" ? AppColors.linkColor : AppColors.greenLight,
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
                        "Order Type",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        orderData.cargoType.toString(),
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
                      child: InkWell(
                    onTap: () {
                      utils.openMaps(orderData.shipperAddress.toString());
                      //utils.successSnackBar("click", "redirecting to google maps");
                    },
                    child: ListTile(
                      leading:  const Icon(
                        Icons.location_history,
                        color: AppColors.primaryThemeColor,
                      ),
                      title: Text(
                        "${orderData.shipperName}\n${orderData.shipperAddress}",
                        style:  const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )),
                  Container(
                      margin:  const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          customRow("QATAR ID", orderData.qatarId ?? ""),
                          customRow("BILL NO.", orderData.billNo ?? ""),
                          customRow(
                              "PICK-UP TIME", orderData.pickupDate ?? ""),
                          customRow(
                              "DESTINATION", orderData.destination ?? ""),
                          customRow(
                              "MOVEMENT TYPE", orderData.movementType ?? ""),
                          Visibility(
                              visible: (orderData.status ==
                                      "COLLECTED" ||
                                  orderData.status ==
                                      "WAREHOUSE_IN"),
                              child: Column(
                                children: [
                                  customRow("GROSS WEIGHT",
                                      "${orderData.grW} (kg)" ?? ""),
                                  customRow("VOLUMETRIC WEIGHT",
                                      "${orderData.volumeWeight} (kg)" ?? ""),
                                  customRow(
                                      "CHARGEABLE AMOUNT",
                                      "${orderData.chargeableAmount} (qar)" ??
                                          "")
                                ],
                              )),
                        ],
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    InkWell(
                      onTap: (){
                       onClick(orderData,fullMapViewCLick);
                      } ,
                      child: utils.tvCustom("+ view full map",AppColors.primaryThemeColor,10),
                    )
                  ],),

                  Visibility(
                    visible: orderData.status == "ASSIGNED"|| orderData.status == "RE-ASSIGNED" ? true : false,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: MapPage(orderDetails: orderData)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            utils.iconButton("Call Shipper ", () {
                              utils.openDialPad(
                                  orderData.shipperContactNo.toString());
                            }, Icons.call, AppColors.blue, AppColors.white),
                            // utils.iconButton("Navigate", () {
                            //   utils.openMaps(
                            //       orderData.shipperAddress.toString());
                            // }, Icons.navigation_sharp, AppColors.greenLight,
                            //     AppColors.white),
                            utils.iconButton("Update Order ", () {
                              Get.toNamed(Routes.auth,
                                  arguments: orderData);
                            }, Icons.arrow_circle_right_rounded,
                                AppColors.primaryThemeColor, AppColors.white)
                          ],
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                      visible: orderData.status == "COLLECTED" ? true : false,
                      child: utils.iconButton("Update Picked Orders", () {
                        onClick(orderData,orderScanCLick);
                      }, Icons.warehouse, AppColors.blue, AppColors.white))
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
