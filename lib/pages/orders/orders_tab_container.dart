import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tab_container/tab_container.dart';

import '../../utils/colors.dart';
import 'orders_controller.dart';
import 'orders_screens/orders_list_view.dart';

class OrdersTabContainer extends StatelessWidget {
  final OrdersController controller = Get.put(OrdersController());
  final RiderDashboardController riderDashboardController = Get.put(RiderDashboardController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: TabContainer(
            controller: controller.tabController,
            tabEdge: TabEdge.bottom,
            tabExtent: 40,
            borderRadius: BorderRadius.circular(1),
            tabBorderRadius: BorderRadius.circular(10),
            childPadding: const EdgeInsets.all(3.0),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
            ),
            unselectedTextStyle: const TextStyle(
              color: Colors.black,
              fontSize: 11.0,
            ),
            colors: const [
              AppColors.primaryLight,
              AppColors.lightBlue,
              AppColors.primaryThemeColor,
              AppColors.lightGreen
            ],
            tabs:  [
              Text("Assigned(${riderDashboardController.dashBoardData.value.assigned})"),
              Text("Picked(${riderDashboardController.dashBoardData.value.picked})"),
              Text("Ofd(${riderDashboardController.dashBoardData.value.ofd})"),
              Text("Delivered(${riderDashboardController.dashBoardData.value.delivered})"),

            ],
            children: [
              OrdersListView( orderStatus: 'ASSIGNED'),
              OrdersListView( orderStatus: 'PICKED'),
              OrdersListView( orderStatus: 'OFD'),
              OrdersListView( orderStatus: 'DELIVERED'),
            ],
          ),
        ),
      ),
    );
  }
}