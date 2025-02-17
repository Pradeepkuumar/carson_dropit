import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tab_container/tab_container.dart';

import '../../../../utils/colors.dart';
import '../controller/orders_controller.dart';
import '../orders_screens/orders_list_view.dart';

class OrdersTabContainer extends GetView<OrdersController> {

  final RiderDashboardController riderDashboardController = Get.put(RiderDashboardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child:
          // Obx(
          //       () =>
          //       Column(
          //         children: [
          //           Padding(
          //             padding: EdgeInsets.only(
          //                 left: 10.w, top: 5.h, right: 10.h, bottom: 5.h),
          //             child: Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceAround,
          //               crossAxisAlignment: CrossAxisAlignment.center,
          //               children: [
          //                 GestureDetector(
          //                   onTap: () {
          //                     if (controller.tabController.index > 0) {
          //                       controller.tabController.animateTo(
          //                           controller.tabController.index - 1);
          //                     }
          //                   },
          //                   child: Icon(Icons.arrow_back_ios, size: 15.sp),
          //                 ),
          //                 Expanded(
          //                   child: TabBar(
          //                     onTap: (value) {
          //                       controller.tabController.index = value;
          //                     },
          //                     indicatorWeight: 10,
          //                     indicatorColor: AppColors.transparent,
          //                     isScrollable: true,
          //                     tabAlignment: TabAlignment.start,
          //                     indicator: const UnderlineTabIndicator(
          //                         borderSide: BorderSide(
          //                             color: AppColors.primaryThemeColor,
          //                             width: 1.0,
          //                             style: BorderStyle.solid)
          //                     ),
          //                     dividerColor: AppColors.transparent,
          //                     padding: EdgeInsets.all(5),
          //                     controller: controller.tabController,
          //                     labelStyle: const TextStyle(
          //                         fontSize: 15.0,
          //                         color: AppColors.primaryThemeColor),
          //                     unselectedLabelStyle: const TextStyle(
          //                         fontSize: 13.0),
          //                     unselectedLabelColor: AppColors.greyColor4,
          //                     labelColor: AppColors.primaryThemeColor,
          //                     labelPadding: const EdgeInsets.only(
          //                         top: 10, left: 10, right: 10),
          //                     tabs: [
          //                       Padding(
          //                         padding: const EdgeInsets.only(
          //                             left: 10, right: 10),
          //                         child: Text(
          //                             "Assigned(${riderDashboardController.dashBoardData.value
          //                                 .assigned})"),
          //                       ),
          //                       Padding(
          //                         padding: const EdgeInsets.only(
          //                             left: 10, right: 10),
          //                         child: Text("Assigned(${riderDashboardController.dashBoardData.value
          //                             .assigned})"),
          //                       ),
          //                       Padding(
          //                         padding: const EdgeInsets.only(
          //                             left: 10, right: 10),
          //                         child: Text("Assigned(${riderDashboardController.dashBoardData.value
          //                             .assigned})"),
          //                       ),Padding(
          //                         padding: const EdgeInsets.only(
          //                             left: 10, right: 10),
          //                         child: Text("Assigned(${riderDashboardController.dashBoardData.value
          //                             .assigned})"),
          //                       ),
          //                     ],
          //                   ),
          //                 ),
          //                 GestureDetector(
          //                   onTap: () {
          //                     if (controller.tabController.index < 3) {
          //                       controller.tabController.animateTo(
          //                           controller.tabController.index + 1);
          //                     } else {
          //                       Get.snackbar("Can't Go ahead", "Try Again");
          //                     }
          //                   },
          //                   child: Icon(Icons.arrow_forward_ios, size: 15
          //                       .sp),
          //                 ),
          //               ],
          //             ),
          //           ),
          //           Expanded(
          //             child: GestureDetector(
          //                 onHorizontalDragUpdate: (details) {
          //                   int sensitivity = 8;
          //                   if (details.delta.dx > sensitivity) {
          //                     if (controller.tabController.index > 0) {
          //                       controller.tabController.animateTo(
          //                           controller.tabController.index - 1);
          //                     }
          //                   } else if (details.delta.dx < -sensitivity) {
          //                     if (controller.tabController.index < 2) {
          //                       controller.tabController.animateTo(
          //                           controller.tabController.index + 1);
          //                     }
          //                   }
          //                 },
          //                 child: TabBarView(
          //                   controller: controller.tabController,
          //                   physics:  NeverScrollableScrollPhysics(),
          //                   children: [
          //                     OrdersListView(orderStatus: 'ASSIGNED'),
          //                     OrdersListView(orderStatus: 'PICKED'),
          //                     OrdersListView(orderStatus: 'OFD'),
          //                     OrdersListView(orderStatus: 'DELIVERED'),
          //                   ],
          //                 )),
          //           ),
          //         ],
          //       ),
          // )),


          Obx(() {
            return TabContainer(
              controller: controller.tabController,
              tabEdge: TabEdge.bottom,
              tabExtent: 45,
              borderRadius: BorderRadius.circular(1),
              tabBorderRadius: BorderRadius.circular(10),
              tabMaxLength: 100 ,
              childPadding: const EdgeInsets.all(3.0),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 10.0,
              ),
              unselectedTextStyle: const TextStyle(
                color: Colors.black,
                fontSize: 10.0,
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
                    ?.aSSIGNED})"),
                Text("Picked(${riderDashboardController.dashBoardData.value.allOrdersCount
                    ?.pICKED})"),
                Text(
                    "Ofd(${riderDashboardController.dashBoardData.value.allOrdersCount?.oFD})"),
                Text("Delivered(${riderDashboardController.dashBoardData.value.allOrdersCount
                    ?.dELIVERED})"),
                Text("UnDelivered(${riderDashboardController.dashBoardData.value.allOrdersCount
                    ?.uNDELIVERED})"),

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