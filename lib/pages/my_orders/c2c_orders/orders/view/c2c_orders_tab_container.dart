import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:carson_zyppy/pages/my_orders/c2c_orders/orders/c2c_orders_screens/c2c_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tab_container/tab_container.dart';
import '../../../../../utils/colors.dart';
import 'c2c_orders_list_view.dart';

class C2cOrdersTabContainer extends GetView<C2COrdersController> {

  final RiderDashboardController riderDashboardController = Get.put(RiderDashboardController());

  C2cOrdersTabContainer({super.key});

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
              tabExtent: context.isTablet?55.sp:45.sp,
              borderRadius: BorderRadius.circular(1),
              tabBorderRadius: BorderRadius.circular(10),
              tabMaxLength: context.isTablet ? 200.sp : 200.sp,
              childPadding: const EdgeInsets.all(3.0),
              selectedTextStyle:  TextStyle(
                color: Colors.white,
                fontSize: context.isPhone ? 10.sp:20.sp,
              ),
              unselectedTextStyle:  TextStyle(
                color: Get.isDarkMode ? AppColors.white : Colors.black,
                fontSize: context.isPhone?10.sp:20.sp,
              ),
              colors:  [
                AppColors.primaryLight.withAlpha(200),
                AppColors.lightBlue.withAlpha(200),
                AppColors.primaryThemeColor.withAlpha(200),
                AppColors.lightGreen.withAlpha(200),
                AppColors.red.withAlpha(200)
              ],
              tabs: [
                Text("Assigned(${riderDashboardController.c2cDashBoardData.value.allOrdersCount
                    ?.aSSIGNED})",style: TextStyle(fontSize: context.isPhone?10:20),),
                Text("Picked(${riderDashboardController.c2cDashBoardData.value.allOrdersCount
                    ?.pICKED})",style: TextStyle(fontSize: context.isPhone?10:20),),
                Text(
                    "Ofd(${riderDashboardController.c2cDashBoardData.value.allOrdersCount?.oFD})",style: TextStyle(fontSize: context.isPhone?10:20),),
                Text("Delivered(${riderDashboardController.c2cDashBoardData.value.allOrdersCount
                    ?.dELIVERED})",style: TextStyle(fontSize: context.isPhone?10:20),),
                Text("UnDelivered(${riderDashboardController.c2cDashBoardData.value.allOrdersCount
                    ?.uNDELIVERED})",style: TextStyle(fontSize: context.isPhone?10:20),),

              ],
              children: [
                C2COrdersListView(orderStatus: 'ASSIGNED'),
                C2COrdersListView(orderStatus: 'PICKED'),
                C2COrdersListView(orderStatus: 'OFD'),
                C2COrdersListView(orderStatus: 'DELIVERED'),
                C2COrdersListView(orderStatus: 'UNDELIVERED'),
              ],
            );
          }),
        )
      ));
  }
}