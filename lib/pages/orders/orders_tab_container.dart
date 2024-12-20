import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tab_container/tab_container.dart';

import '../../utils/colors.dart';
import 'orders_controller.dart';
import 'orders_screens/orders_list_view.dart';

class OrdersTabContainer extends StatelessWidget {
  final OrdersController controller = Get.put(OrdersController());
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
              AppColors.lightGreen
            ],
            tabs: const [
              Text('Assigned(4)'),
              Text('Picked(3)'),
              Text('Delivered(7)'),
            ],
            children: [
              OrdersListView( orderStatus: 'ASSIGNED'),
              OrdersListView( orderStatus: 'COLLECTED'),
              OrdersListView( orderStatus: 'WAREHOUSE_IN'),
            ],
          ),
        ),
      ),
    );
  }
}