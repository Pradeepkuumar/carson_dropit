
import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/pages/map/orderItem/clickedOrderItem.dart';
import 'package:carson_zyppy/pages/my_orders/orders/models/orders_model.dart';
import 'package:carson_zyppy/pages/osrm/OSMMapController.dart';
import 'package:carson_zyppy/pages/osrm/latlng_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:get/get.dart';
import 'package:carson_zyppy/utils/colors.dart';
import 'package:carson_zyppy/global/global.dart';


class OSMMapPage extends GetView<OSMMapController> {
  const OSMMapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Obx(() => 
        // controller.isLoading.value
        //     ? _buildLoadingView()
        //     : 
            controller.ordersList.isEmpty
                ? _buildNoOrdersView()
                : _buildMapView()),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 150,
            width: Get.width - 50,
            child: Image.asset(appLogo),
          ),
          utils.iosProgressIndicator(
              AppColors.primaryThemeColor, "Loading Maps Please wait..."),
          const SizedBox(height: 20),
          Obx(() => utils.tvCustom(
              controller.currentHintText, AppColors.primaryThemeColor, 15)),
        ],
      ),
    );
  }

  Widget _buildNoOrdersView() {
    return Center(
      child: utils.noDataFoundWidget("No Order For Pickup/Delivery"),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // Main Map
        FlutterMap(
          mapController: controller.mapController,
          options: MapOptions(
            center: controller.currentLocation?.toOSM(), 
            zoom: 14.0,
            onTap: (tapPosition, point) {
              
            },
          ),
          children: [
            // Tile Layer (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carson.zyppy',
              tileProvider: CancellableNetworkTileProvider(),
            ),
            
            // Current Location Marker
            if (controller.currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: controller.currentLocation!.toOSM(),
                    width: 40,
                    height: 40,
                    child:  Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            
            // Order Markers
            MarkerLayer(
              markers: controller.osmMarkers,
            ),
            
            // Route Polyline
            PolylineLayer(
              polylines: controller.polylines,
            ),
          ],
        ),
        
        // Navigation Controls
        Positioned(
          bottom: 20,
          right: 10,
          child: Column(
            children: [
              _buildNavigationButton(),
              const SizedBox(height: 10),
              _buildMapTypeButton(),
            ],
          ),
        ),
        
        // Current Order Info Card
        if (controller.currentLocationOrders.isNotEmpty)
          Positioned(
            top: 20,
            right: 10,
            child: _buildCurrentOrderCard(),
          ),
        
        // Bottom Sheet for Orders
        if (controller.viewAcceptView.value)
          _buildOrdersBottomSheet(),
      ],
    );
  }

  Widget _buildNavigationButton() {
    return Obx(() => InkWell(
      onTap: () {
        if (controller.isNavigationRunning.value) {
          controller.stopGuidedNavigation();
        } else {
          controller.startGuidedNavigation();
        }
      },
      child: Container(
        height: 60,
        width: 60,
        decoration: utils.boxDecorationWhite(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.isNavigationRunning.value
                  ? Icons.stop
                  : Icons.navigation,
              color: controller.isNavigationRunning.value
                  ? Colors.red
                  : AppColors.selectedBlue,
              size: 30,
            ),
            Text(
              controller.isNavigationRunning.value ? "Stop" : "Start",
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildMapTypeButton() {
    return  InkWell(
      onTap: () {
        // Toggle between different map styles
        // You can implement different tile providers here
      },
      child: Container(
        height: 60,
        width: 60,
        decoration: utils.boxDecorationWhite(),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              color: AppColors.selectedBlue,
              size: 30,
            ),
            Text(
              "Satellite",
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentOrderCard() {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      decoration: utils.boxDecorationWhite(),
      child: Column(
        children: [
          utils.tvCustom("Current Order", AppColors.primaryThemeColor, 14),
          const SizedBox(height: 10),
          Text(
            "Order No.",
            style: TextStyle(
              fontSize: Get.context!.isPhone ? 12 : 15,
            ),
          ),
          Text(
            controller.currentLocationOrders.first.awbNo ?? "",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          // Add more order details as needed
        ],
      ),
    );
  }

  Widget _buildOrdersBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: utils.boxDecorationWhite(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.red),
                onPressed: () => controller.viewAcceptView.value = false,
              ),
            ),
            
            // Orders carousel
            SizedBox(
              height: 350,
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: controller.bottomBarListType.value == 0
                    ? controller.ordersList.length
                    : controller.currentLocationOrders.length,
                itemBuilder: (context, index) {
                  final order = controller.bottomBarListType.value == 0
                      ? controller.ordersList[index]
                      : controller.currentLocationOrders[index];
                      
                  return ClickedOrderItem(
                    orderData: order,
                    onClick: (clickedOrder, type) async {
                      controller.selectedOrder.value = clickedOrder;
                      await controller.setMarkers();
                      
                      if (type == updateStatus) {
                        _handleOrderStatusUpdate(clickedOrder);
                      } else if (type == updateOrder) {
                        controller.viewAcceptView.value = false;
                        controller.isUpdateCardVisibleForUpdate.value = true;
                      }
                    },
                    listType: controller.bottomBarListType.value == 0 ? 0 : 1,
                  );
                },
              ),
            ),
            
            // Navigation arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    if (controller.selectedOrderIndex.value > 0) {
                      controller.selectedOrderIndex.value--;
                      controller.pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    if (controller.selectedOrderIndex.value < 
                        controller.ordersList.length - 1) {
                      controller.selectedOrderIndex.value++;
                      controller.pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleOrderStatusUpdate(OrdersData clickedOrder) async {
    if (clickedOrder.status == REACHED) {
      bool isTrue = await controller.calculateBufferTime(
          DateTime.now(), PICKED);
      controller.updateOrder(PICKED);
    } else if (clickedOrder.status == ASSIGNED || 
               clickedOrder.status == RE_ASSIGNED) {
      controller.updateOrder(REACHED);
      controller.startTime = DateTime.now();
    } else if (clickedOrder.status == PICKED) {
      controller.updateOrder(OFD);
    }
  }
}