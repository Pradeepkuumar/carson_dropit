import 'package:carson_zyppy/apis/base_api_provider.dart';
import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../global/global.dart';
import '../../../../../utils/calculate_sla.dart';
import '../../../../../utils/colors.dart';
import '../../../../../utils/utils.dart';
import '../../my_orders/orders/models/orders_model.dart';
import '../controller/all_orders_map_controller.dart';

class ClickedOrderItem extends StatefulWidget {
  final OrdersData orderData;
  final void Function(OrdersData, String) onClick;
  final int listType;

  const ClickedOrderItem({
    Key? key,
    required this.orderData,
    required this.onClick,
    required this.listType,
  }) : super(key: key);

  @override
  _ClickedOrderItemState createState() => _ClickedOrderItemState();
}

class _ClickedOrderItemState extends State<ClickedOrderItem> with WidgetsBindingObserver {
  Utils utils = Utils();
  final controller = Get.find<AllOrdersMapController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Handle app resume if needed
    }
  }

  void _startCall(String phoneNumber, String type) {
    if (controller.hasOngoingCall.value) {
      utils.errorSnackBar("Ongoing Call", "Cannot initiate another call while a call is in progress");
      return;
    }
    controller.callType = type;
    controller.hasOngoingCall.value = true;
    controller.ongoingCallAwbNo.value = widget.orderData.awbNo ?? "";
    controller.callStartTime.value = DateTime.now();
    utils.openDialPad(phoneNumber);
  }

  void _handleCallEnd() {
    if (controller.hasOngoingCall.value && controller.ongoingCallAwbNo.value == widget.orderData.awbNo) {
      controller.callStartTime.value = null;
      controller.hasOngoingCall.value = false;
      controller.ongoingCallAwbNo.value = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
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
                        color: Get.isDarkMode ? AppColors.white : Colors.black,
                      ),
                    ),
                    Text(
                      widget.orderData.awbNo.toString(),
                      style: TextStyle(
                        fontSize: Get.context!.isPhone ? 12 : 15,
                        color: Get.isDarkMode ? AppColors.white : AppColors.black,
                      ),
                    ),
                  ],
                ),
                slaTimer(50, 50, widget.orderData.createdAt ?? "", int.tryParse(widget.orderData.sla_in_hours.toString()) ?? 0, 10),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      customRow("Item","${widget.orderData.itemName!}(${widget.orderData.quantity})"),
                      customRow("Order Amount", widget.orderData.orderAmount ?? ""),
                      customRow("Order Weight", widget.orderData.weight ?? ""),
                      customRow("Location", widget.orderData.status == OFD ? widget.orderData.contact_person_name ?? "" : widget.orderData.pickupLocationName ?? ""),
                      customRow("Zone", widget.orderData.consigneeZone ?? ""),
                      customRow("Street", widget.orderData.consigneeStreetNumber ?? ""),
                      customRow("Building", widget.orderData.consigneeBuildingNo ?? ""),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Column(
                    children: [
                      const SizedBox(height: 10,),
                      Obx(() {
                        bool isThisOrderOnCall = controller.hasOngoingCall.value &&
                            controller.ongoingCallAwbNo.value == widget.orderData.awbNo;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isThisOrderOnCall) ...[
                              utils.clickableImageVertical("End Call", Get.isDarkMode ? AppColors.white : AppColors.black, AppColors.red, icTelephone, 30, 30, () {
                                _handleCallEnd();
                              }),
                            ] else if (controller.hasOngoingCall.value) ...[
                              utils.clickableImageVertical("Call Active", Get.isDarkMode ? AppColors.white : AppColors.black, AppColors.greyColor4, icTelephone, 30, 30, () {
                                utils.errorSnackBar("Ongoing Call", "Cannot initiate another call");
                              }),
                            ] else ...[
                              utils.clickableImageVertical("Call Pickup", Get.isDarkMode ? AppColors.white : AppColors.black, AppColors.lightBlue, icTelephone, 30, 30, () {
                                _startCall(widget.orderData.pickupPhoneNo.toString(), 'pickup');
                              }),
                              const SizedBox(width: 5,),
                              utils.clickableImageVertical("Pickup", Get.isDarkMode ? AppColors.white : AppColors.black, AppColors.green, icWhatsApp, 30, 30, () {
                                utils.openWhtsApp(widget.orderData.pickupPhoneNo.toString());
                              }),
                              const SizedBox(width: 5,),
                              utils.clickableImageVertical("Call Consignee", Get.isDarkMode ? AppColors.white : AppColors.black, AppColors.blue, icTelephone, 30, 30, () {
                                _startCall(widget.orderData.consigneeMobileNo.toString(), 'consignee');
                              }),
                              const SizedBox(width: 5,),
                              utils.clickableImageVertical("Consignee", Get.isDarkMode ? AppColors.white : AppColors.black, AppColors.green, icWhatsApp, 30, 30, () {
                                utils.openWhtsApp(widget.orderData.pickupPhoneNo.toString());
                              }),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 10,),
                    ],
                  ),
                  Visibility(
                    visible: widget.listType == 1,
                    child: utils.iconButton(widget.orderData.status == ASSIGNED || widget.orderData.status == RE_ASSIGNED ? REACHED : widget.orderData.status == REACHED ? "PICK" : widget.orderData.status == PICKED ? "MARK OFD" : widget.orderData.status == OFD ? "UPDATE" : "", () {
                      widget.orderData.status == OFD ?
                      widget.onClick(widget.orderData, updateOrder) :
                      widget.onClick(widget.orderData, updateStatus);
                    }, Icons.update, widget.orderData.status == ASSIGNED || widget.orderData.status == RE_ASSIGNED ? AppColors.blue : widget.orderData.status == RE_ASSIGNED ? AppColors.orange : widget.orderData.status == PICKED ?
                    AppColors.primaryThemeColor : AppColors.greenLight, AppColors.white)
                  )
                ],
              ),
            )
          ],
        ),
      ));
  }
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
            child: utils.tvCustom(name, Get.isDarkMode ? AppColors.white : AppColors.black, 10, textAlignment: TextAlign.start),
          ),
          Expanded(
            flex: 2,
            child: utils.tvRegular(":", Get.isDarkMode ? AppColors.white : AppColors.black),
          ),
          Expanded(flex: 4, child: utils.tvCustom(data, Get.isDarkMode ? AppColors.white : AppColors.black, 10, textAlignment: TextAlign.start)),
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
          Icon(Icons.location_on_sharp, color: name == "Drop-Off Location" ? AppColors.green : AppColors.blue),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                utils.tvCustom(name, Get.isDarkMode ? AppColors.white : AppColors.black, 13),
                utils.tvRegular(
                  data,
                  Get.isDarkMode ? AppColors.white : AppColors.black,
                ),
              ],
            ),
          ),
          utils.imageView("assets/icons/maps_logo.png", 30, 30)
        ],
      ),
    ),
  );
}
