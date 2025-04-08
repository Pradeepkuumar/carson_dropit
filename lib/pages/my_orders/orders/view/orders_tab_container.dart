import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tab_container/tab_container.dart';

import '../../../../utils/colors.dart';
import '../controller/orders_controller.dart';
import '../orders_screens/orders_list_view.dart';

class OrdersTabContainer extends GetView<OrdersController> {

  final RiderDashboardController riderDashboardController = Get.put(RiderDashboardController());

  OrdersTabContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child:
          Obx(() {
            return TabContainer(
              controller: controller.tabController,
              tabEdge: TabEdge.bottom,
              tabExtent: context.isTablet?55:45,
              borderRadius: BorderRadius.circular(1),
              tabBorderRadius: BorderRadius.circular(10),
              tabMaxLength: context.isTablet ? 200 : 150,
              childPadding: const EdgeInsets.all(3.0),
              selectedTextStyle:  TextStyle(
                color: Colors.white,
                fontSize: context.isPhone?10:20,
              ),
              unselectedTextStyle:  TextStyle(
                color: Colors.black,
                fontSize: context.isPhone?10:20,
              ),
              colors: const [
                AppColors.primaryLight,
                AppColors.lightBlue,
                AppColors.primaryThemeColor,
                AppColors.lightGreen,
                AppColors.red
              ],
              tabs: [
                Text("Assigned(${riderDashboardController.dashBoardData.value.allOrdersCount
                    ?.aSSIGNED})",style: TextStyle(fontSize: context.isPhone?10:20),),
                Text("Picked(${riderDashboardController.dashBoardData.value.allOrdersCount
                    ?.pICKED})",style: TextStyle(fontSize: context.isPhone?10:20),),
                Text(
                    "Ofd(${riderDashboardController.dashBoardData.value.allOrdersCount?.oFD})",style: TextStyle(fontSize: context.isPhone?10:20),),
                Text("Delivered(${riderDashboardController.dashBoardData.value.allOrdersCount
                    ?.dELIVERED})",style: TextStyle(fontSize: context.isPhone?10:20),),
                Text("UnDelivered(${riderDashboardController.dashBoardData.value.allOrdersCount
                    ?.uNDELIVERED})",style: TextStyle(fontSize: context.isPhone?10:20),),

              ],
              children: [
                OrdersListView(orderStatus: 'ASSIGNED'),
                OrdersListView(orderStatus: 'PICKED'),
                OrdersListView(orderStatus: 'OFD'),
                OrdersListView(orderStatus: 'DELIVERED'),
                OrdersListView(orderStatus: 'UNDELIVERED'),
              ],
            );
          }),
        )
      ));
  }
}