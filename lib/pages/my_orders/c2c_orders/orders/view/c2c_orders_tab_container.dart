import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:carson_zyppy/pages/my_orders/c2c_orders/orders/c2c_orders_screens/c2c_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tab_container/tab_container.dart';
import '../../../../../global/app_bar.dart';
import '../../../../../utils/colors.dart';
import 'c2c_orders_list_view.dart';


class C2cOrdersTabContainer extends GetView<C2COrdersController> {
  final RiderDashboardController riderDashboardController = Get.put(RiderDashboardController());

  C2cOrdersTabContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(title: "}"),
      body: SafeArea(
        
        child: SizedBox.expand(
          child: Obx(() {
            // Get the latest dashboard data reactively
            final data = riderDashboardController.c2cDashBoardData.value.allOrdersCount;

            return TabContainer(
              controller: controller.tabController,
              tabEdge: TabEdge.bottom,
              tabExtent: context.isTablet ? 55.sp : 45.sp,
              borderRadius: BorderRadius.circular(1),
              tabBorderRadius: BorderRadius.circular(10),
              tabMaxLength: context.isTablet ? 200.sp : 200.sp,
              childPadding: const EdgeInsets.all(3.0),
              selectedTextStyle: TextStyle(
                color: Colors.white,
                fontSize: context.isPhone ? 10.sp : 20.sp,
              ),
              unselectedTextStyle: TextStyle(
                color: Get.isDarkMode ? AppColors.white : Colors.black,
                fontSize: context.isPhone ? 10.sp : 20.sp,
              ),
              colors: [
                AppColors.primaryLight.withAlpha(100),
                AppColors.lightBlue.withAlpha(100),
                AppColors.primaryThemeColor.withAlpha(100),
                AppColors.lightGreen.withAlpha(100),
                AppColors.red.withAlpha(100)
              ],
              tabs: [
                Text("Assigned(${data?.aSSIGNED ?? 0})", style: TextStyle(fontSize: context.isPhone ? 10 : 20)),
                Text("Picked(${data?.pICKED ?? 0})", style: TextStyle(fontSize: context.isPhone ? 10 : 20)),
                Text("OFD(${data?.oFD ?? 0})", style: TextStyle(fontSize: context.isPhone ? 10 : 20)),
                Text("Delivered(${data?.dELIVERED ?? 0})", style: TextStyle(fontSize: context.isPhone ? 10 : 20)),
                Text("UnDelivered(${data?.uNDELIVERED ?? 0})", style: TextStyle(fontSize: context.isPhone ? 10 : 20)),
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
        ),
      ),
    );
  }
}
