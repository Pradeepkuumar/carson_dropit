import 'dart:math';
import 'package:carson_zyppy/pages/my_orders/placed_orders/controller/placed_orders_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:carson_zyppy/global/global.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:location/location.dart';
import '../../../../global/consts.dart';
import 'item_nearby_oredrs/neaby_orders_item.dart';

class NearbyOrdersView extends GetView<PlacedOrdersController> {

  var showNotificationView = false.obs;
  var enableMapLiveCamera = false.obs;
  var enableOrdersSearch = false.obs;
  var acceptView = false.obs;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Obx(() {
              if (!controller.isResponseSuccess.value) {
                return Center(child: utils.iosProgressIndicator(
                    AppColors.primaryThemeColor, ""));
              } else if (controller.ordersList.isEmpty) {
                return Center(child: utils.noDataFoundWidget(
                    "No orders are available near your location \n Please try checking another nearby pickup location."));
              } else {
                return Obx(() {
                  return GoogleMapsMapView(
                    gestureRecognizers: Set()
                      ..add(Factory<PanGestureRecognizer>(
                              () => PanGestureRecognizer()))..add(
                          Factory<ScaleGestureRecognizer>(
                                  () => ScaleGestureRecognizer())),

                    onViewCreated: (GoogleMapViewController mapController) {
                      controller.navigationViewController = mapController;
                      // mapController.updateMarkers(controller.markers);
                      for (var marker in controller.markers) {
                        mapController.addMarkers([marker]);
                      }
                      //mapController.addCircles(controller.circle);
                      // _mapController.complete(mapController);
                    },
                    initialMapType: controller.mapType.value,
                    initialCameraPosition: CameraPosition(
                      target: controller.currentLocation!,
                      zoom: 18,
                    ),
                    onMarkerClicked: (value) {
                      if (value != "current_location") {
                        controller.selectedLocationId.value = value;
                        controller.selectedLocationOrders();
                      } else {
                        print("Marker not found in map.");
                      }
                    },
                    onMarkerInfoWindowClicked: (value) {

                    },
                  );
                });
              }
            }),
            buildControls(),
            Obx(() {
              return Visibility(
                visible: controller.viewAcceptView.value,
                child: Center(
                  child: Container(
                    decoration: utils.boxDecorationWhite(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Wrap(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: InkWell(
                                onTap: () {
                                  controller.viewAcceptView.value = false;
                                },
                                child: const Icon(
                                  Icons.cancel,
                                  color: AppColors.red,
                                  size: 20,
                                )),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: utils.tvCustom(
                                "Select Order From List(${controller
                                    .selectedMerchantOrdersList.length})",
                                AppColors.primaryThemeColor,
                                15),
                          ),

                          Row(
                            children: [
                              Expanded(
                                  flex: 1,

                                  child: InkWell(
                                      onTap: () {

                                      },
                                      child: const Icon(Icons.arrow_back_ios,
                                        color: AppColors.greyColor4,
                                        size: 15,))),
                              Expanded(
                                flex: 20,
                                child: SizedBox(
                                  height: context.isPhone ? 520 : 800,
                                  child: Obx(() => PageView.builder(
                                        scrollDirection: Axis.horizontal,
                                        controller: PageController(
                                            viewportFraction: 1),
                                        itemCount: controller
                                            .selectedMerchantOrdersList.length,
                                        itemBuilder: (context, position) {
                                          return nearByOrderItem(
                                              controller
                                                  .selectedMerchantOrdersList[position],
                                                  (clickedOrder, type) async {
                                                if (type == acceptOrder) {
                                                  utils.simpleDialog(
                                                      "Accept Order",
                                                      "Do you want to accept this order ?",
                                                          () async {
                                                        Get.back();
                                                        await controller
                                                            .acceptRejectOrder(
                                                            acceptOrder,
                                                            clickedOrder
                                                                .awbNo ??
                                                                "");
                                                      }, () {});
                                                } else {
                                                  utils.simpleDialog(
                                                      "Reject Order",
                                                      "Do you want to reject this order ?",
                                                          () {
                                                        controller
                                                            .acceptRejectOrder(
                                                            rejectOrder,
                                                            clickedOrder
                                                                .awbNo ?? "");
                                                      }, () {});
                                                }
                                              });
                                        }
                                    )
                                  ),
                                ),
                              ),

                              Expanded(
                                  flex: 1,
                                  child: InkWell(
                                      onTap: () {

                                      },
                                      child: const Icon(Icons.arrow_forward_ios,
                                        color: AppColors.greyColor4,
                                        size: 15,))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

          ],
        ),
      ),

    );
  }


  Widget buildControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          InkWell(
            onTap: () =>
            {
              controller.
              mapType.value =
              (controller.mapType.value == MapType.hybrid)
                  ? MapType.normal
                  : MapType.hybrid,
              enableMapLiveCamera.toggle(),
              controller.navigationViewController?.setMapType(
                  mapType: controller.mapType.value),

            },
            child: Obx(() {
              return Container(
                height: 50,
                width: 50,
                decoration: utils.boxDecorationWhite(),
                child: Icon(Icons.map,
                    size: enableMapLiveCamera.value ? 36 : 30,
                    color: enableMapLiveCamera.value
                        ? AppColors.selectedBlue
                        : AppColors.greyColor4),
              );
            }),
          ),
        ],
      ),
    );
  }






}


