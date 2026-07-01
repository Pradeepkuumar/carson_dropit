import 'dart:async';
import 'dart:convert';
import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:location/location.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../apis/base_api_response.dart';
import '../../../../global/global.dart';
import '../../../../utils/colors.dart';
import '../../../b2c_pickup_delivery_orders/marker_generator/dynamic_marker_generator.dart';
import '../../orders/models/orders_model.dart';

class PlacedOrdersController extends GetxController {
  TextEditingController searchEditTextController = TextEditingController();
  final riderDashboardController  = Get.put(RiderDashboardController());
  var ordersList = <OrdersData>[].obs;
  var selectedMerchantOrdersList = <OrdersData>[].obs;
  var user = UserData();
  var viewAcceptView = false.obs;
  var selectedLocationId = "".obs;
  ImageDescriptor?  icon;
  final Location _locationController = Location();
  GoogleMapViewController? navigationViewController;
  Completer<void>? _mapReadyCompleter;
  Completer<void>? _markersReadyCompleter;

  final notifications = [
    "Enter Order Number",
    "Scan QR Code for Order",
  ];

  LatLng? currentLocation;
  // markerMap is not needed; google_navigation_flutter marker APIs expect MarkerOptions lists.
  // We won't store options to avoid Marker/MarkerOptions mismatch.
  // final Map<String, MarkerOptions> markerMap = {};

  List<Marker> markers = [];
  List<CircleOptions> circle = [];

  var isResponseSuccess = false.obs;

  Rx<MapType> mapType = MapType.normal.obs;

  late WebSocketChannel channel;
  var isConnected = false.obs;
   var markersLoading = true.obs;
  var markersReady = false.obs;
  var mapInitialized = false.obs;
  var markersInitialized = false.obs;


  @override
  void onInit() {
    getUser();
    loadIcon();
    connectSocket();
    super.onInit();
  }

  void connectSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('wss://zyppy.qa/app/Uzv4VuvaE8TFlVyF4o1howiAtK4Hpt/Vkr3yduLGgac=?protocol=7&client=js&version=8.4.0&flash=false'),
      );

      isConnected.value = true;

      channel.sink.add(jsonEncode({
        "event": "pusher:subscribe",
        "data": {
          "channel": "orders"
        }
      }));

      channel.stream.listen((message) {

        final decoded = json.decode(message);

        dynamic innerData;
        if (decoded['data'] is String) {
          innerData = json.decode(decoded['data']);
        } else {
          innerData = decoded['data'];
        }

        final event = decoded['event'];

        if (event == 'OrderShipmentStatusUpdated') {
          final orderNumber = innerData['data']['order_number'];
          Future.microtask(() => removeOrderFromList(orderNumber));

        }
      });


    } catch (e) {
      print("Connection failed: $e");
    }
  }


  void disconnectSocket() {
    channel.sink.close();
    isConnected.value = false;
  }

  Future<void> prepareAllMarkers() async {
    markersReady.value = false;
    await setMarkers();
    markersReady.value = true;
  }

  Future<void> waitForMapReady() async {
    if (_mapReadyCompleter == null) {
      _mapReadyCompleter = Completer<void>();
    }
    return _mapReadyCompleter!.future;
  }

  Future<void> waitForMarkersReady() async {
    if (_markersReadyCompleter == null) {
      _markersReadyCompleter = Completer<void>();
    }
    return _markersReadyCompleter!.future;
  }
  void onMapCreated(GoogleMapViewController controller) {
    navigationViewController = controller;
    mapInitialized.value = true;
    
    // Complete the map ready completer
    if (_mapReadyCompleter != null && !_mapReadyCompleter!.isCompleted) {
      _mapReadyCompleter!.complete();
    }
  }






  void removeOrderFromList(String acceptedOrderId) {
    ordersList.removeWhere((order) => order.awbNo == acceptedOrderId);
    selectedMerchantOrdersList.removeWhere((order) => order.awbNo == acceptedOrderId);

    selectedMerchantOrdersList.refresh();

    if (selectedMerchantOrdersList.isEmpty) {
      viewAcceptView.value = false;
    }
  }


   addCircle(){
     circle.add(
         CircleOptions(
           position: currentLocation!,
           radius: 1000,
           strokeWidth: 2,
           strokeColor: Colors.blue.shade900,
           fillColor: Colors.blue.withOpacity(0.2),
           visible: true,
           clickable: false,
         )
     );
   }

  void getUser() async{
    user = (await userRepository.getUser())!;
    if(user.code != null) {
      await getLocationUpdates().then((updated) async {
        if (updated == true) {
          await fetchOrders();
        }
      });

    }
  }

  void selectedLocationOrders() async {
    selectedMerchantOrdersList.clear();
    for (var order in ordersList) {
      if (order.pickupLocationName.toString() == selectedLocationId.value &&
          !selectedMerchantOrdersList.any((existingOrder) =>
          existingOrder.awbNo == order.awbNo)) {
        selectedMerchantOrdersList.add(order);
      }else{
         selectedMerchantOrdersList.add(order);
      }
    }
    update();
    viewAcceptView.value = true;
  }

  Future<bool?> getLocationUpdates() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }

    Completer<bool> locationUpdated = Completer<bool>();

    StreamSubscription<LocationData>? subscription;
    subscription = _locationController.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        currentLocation = LatLng(latitude: locationData.latitude!, longitude: locationData.longitude!);

        if (!locationUpdated.isCompleted) {
          locationUpdated.complete(true);
        }
        subscription?.cancel();
      }
    });

    return locationUpdated.future;
  }

  Future<bool?> fetchOrders() async {
    utils.showLoadingDialog("Loading...");
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.latitude: currentLocation?.latitude,
        apiKeys.longitude: currentLocation?.longitude,
      };
      dynamic response = await apiProvider.postRequest(
          apiEndPoints.fetchPlacedOrders, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
        ordersList.clear();
        for (var json in result.data) {
          ordersList.add(OrdersData.fromJson(json));
          update();
          await Future.delayed(const Duration(milliseconds: 100));
        }
        // Future.delayed(Duration(seconds: 1),(){
        //    setMarkers();
        // });
         await setMarkers();
       
        utils.closeLoadingDialog();
        isResponseSuccess.value  = true;
        return true;
      } else {
        utils.errorSnackBar("Exception", result.message.toString());
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      update();
      utils.errorSnackBar("Exception", e.toString());
    }
    return null;
  }

  Future<bool> acceptRejectOrder(String type, String orderNumber) async {
    utils.showLoadingDialog("wait while updating order...");
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: user.code,
        apiKeys.status: type,
        apiKeys.awbNo: orderNumber,
      };
      dynamic response = await apiProvider.postRequest(
          apiEndPoints.acceptRejectOrder, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {

        await riderDashboardController.getDashBoardData();
        selectedLocationOrders();
        removeOrderFromList(orderNumber);
        if(type == acceptOrder) {
          utils.successSnackBar("Order Accepted Successfully",
              "Please find accepted order in My Orders");
        }else{
          utils.errorSnackBar("Order Rejected",
              "This order no longer belongs to you");
        }
        utils.closeLoadingDialog();
        fetchOrders();
        return true;
      } else {
        utils.errorSnackBar("Exception", result.message.toString());
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      update();
      utils.errorSnackBar("Exception", e.toString());
    }
    return false;
  }


  Future<ImageDescriptor?> getOrCreateCustomImageFromAsset(
    String assetPath, double width, double height) async {
    final AssetImage assetImage = AssetImage(assetPath);
    final ImageConfiguration configuration =
    createLocalImageConfiguration(Get.context!);
    final AssetBundleImageKey assetBundleImageKey =
    await assetImage.obtainKey(configuration);
    final double imagePixelRatio = assetBundleImageKey.scale;
    final ByteData imageBytes = await rootBundle.load(assetBundleImageKey.name);
    return await registerBitmapImage(
      bitmap: imageBytes, imagePixelRatio: imagePixelRatio, width: width, height: height);
  }


  Future<ImageDescriptor> registerDynamicMarker(String ordersCount, String locationName) async {
    final ByteData byteData = await createCustomMarkerByteData(ordersCount, locationName);
    final ImageDescriptor descriptor = await registerBitmapImage(
      bitmap: byteData,
      imagePixelRatio: 2,
      width: 120,
      height: 90,
    );

    return descriptor;
  }


  // Future<void> setMarkers() async {
  //   await navigationViewController?.clearMarkers();
  //   markers.clear();
  //   markerMap.clear();

  //   if (currentLocation != null) {
  //     final marker = Marker(
  //       markerId: "current_location",
  //       options: MarkerOptions(
  //         infoWindow: const InfoWindow(title: "Current Location", snippet: ""),
  //         position: LatLng(
  //           latitude: currentLocation?.latitude ?? 0.0,
  //           longitude: currentLocation?.longitude ?? 0.0,
  //         ),
  //         icon: icon!,
  //         consumeTapEvents: true,
  //       ),
  //     );
  //     markers.add(marker);
  //     markerMap[marker.markerId] = marker.options;
  //     addCircle();
  //   }

  //   final futures = ordersList.map((order) async {
  //     final ImageDescriptor customIcon = await registerDynamicMarker(
  //       order.pickupLocationName ?? "location",
  //       "PICKUP",
  //     );

  //     final marker = Marker(
  //       markerId: order.locationId.toString(),
  //       options: MarkerOptions(
  //         position: LatLng(
  //           latitude: double.parse(order.pickupLatitude ?? "0.0"),
  //           longitude: double.parse(order.pickupLongitude ?? "0.0"),
  //         ),
  //         icon: customIcon,
  //         consumeTapEvents: true,
  //       ),
  //     );

  //     markers.add(marker);
  //     markerMap[marker.markerId] = marker.options;
  //   }).toList();

  //   await Future.wait(futures);
  // }

  // void loadIcon() async {
  //   try {
  //     icon = await getOrCreateCustomImageFromAsset(
  //       'assets/icons/car_top.png', 
  //       48, 
  //       60
  //     );
  //   } catch (e) {
  //     print("Error loading icon: $e");
  //   }
  // }

  Future<void> setMarkers() async {
    markersLoading.value = true;
    markersReady.value = false;
    
    try {
      // Clear existing markers
      markers.clear();
      // markerMap.clear();
      
      // Clear markers from map if it's initialized
      if (navigationViewController != null) {
        await navigationViewController!.clearMarkers();
      }

      // Wait for icon to be loaded
      if (icon == null) {
        loadIcon();
      }

      // Add current location marker if available
      if (currentLocation != null && icon != null) {
        final currentLocationMarker = Marker(
          markerId: "current_location",
          options: MarkerOptions(
            infoWindow: const InfoWindow(
              title: "Current Location", 
              snippet: ""
            ),
            position: LatLng(
              latitude: currentLocation!.latitude,
              longitude: currentLocation!.longitude,
            ),
            icon: icon!,
            consumeTapEvents: true,
          ),
        );
        
        markers.add(currentLocationMarker);
        // markerMap[currentLocationMarker.markerId] = currentLocationMarker.options;
        
        // Add circle
        addCircle();
      }

      // Create markers for orders
      final markerCreationFutures = <Future>[];
      
      for (var order in ordersList) {
        // Skip if coordinates are invalid
        if (order.pickupLatitude == null || 
            order.pickupLongitude == null ||
            order.pickupLatitude!.isEmpty || 
            order.pickupLongitude!.isEmpty) {
          continue;
        }

        final future = registerDynamicMarker(
          order.merchantName ?? "location",
          "PICKUP",
        ).then((customIcon) {
          final marker = Marker(
            markerId: order.pickupLocationName.toString(),
            options: MarkerOptions(
              position: LatLng(
                latitude: double.parse(order.pickupLatitude!),
                longitude: double.parse(order.pickupLongitude!),
              ),
              icon: customIcon,
              consumeTapEvents: true,
            ),
          );

          markers.add(marker);
          // markerMap[marker.markerId] = marker.options;
        }).catchError((e) {
          print("Error creating marker for order ${order.awbNo}: $e");
        });

        markerCreationFutures.add(future);
      }

      // Wait for all markers to be created
      await Future.wait(markerCreationFutures);

      // Add markers to map if it's initialized
      if (navigationViewController != null && markers.isNotEmpty) {
        // google_navigation_flutter expects List<MarkerOptions>.
        await navigationViewController!.addMarkers(markers.map((m) => m.options).toList());
      }

      markersInitialized.value = true;
      markersReady.value = true;
      
      // Complete markers ready completer
      if (_markersReadyCompleter != null && !_markersReadyCompleter!.isCompleted) {
        _markersReadyCompleter!.complete();
      }
    } catch (e) {
      print("Error setting markers: $e");
    } finally {
      markersLoading.value = false;
    }
  }





  Future showCustomMarker(OrdersData data, int type) {
    return Get.defaultDialog(
      barrierDismissible: false,
      title: data.awbNo.toString(),
      content: Stack(
        children: [
          Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.cancel,
                        color: AppColors.red,
                      ),
                    )),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  utils.tvCustom(
                      type == 0
                          ? "${data.merchantName!}\n${data.pickupAddress!},${data.pickupZoneNo!}"
                          : "${data.consigneeName!}\n${data.consigneeAddress!},${data.consigneeStreetNumber!},${data.consigneeBuildingNo!},${data.consigneeUnitNo!},${data.consigneeZone!}",
                      AppColors.black,
                      14),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  utils.tvRegular("Landmark", AppColors.black),
                  utils.tvRegular(":", AppColors.black),
                  utils.tvCustom(
                      type == 0
                          ? data.pickupLocationName
                          : data.consigneeAddress,
                      AppColors.blue,
                      13)
                ],
              ),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: utils.iconButtonWithRoundedBorder("Navigate", 40,
                          () {
                        utils.openMaps(type == 0
                            ? data.pickupAddress!
                            : data.consigneeAddress!);
                      },
                      Icons.assistant_navigation,
                      AppColors.primaryThemeColor,
                      Icons.alt_route_rounded,
                      2,
                      AppColors.primaryThemeColor))
            ],
          )
        ],
      ),
    );
  }



  void loadIcon() async {
    icon =   await getOrCreateCustomImageFromAsset(
        'assets/icons/car_top.png', 30, 40);
  }

  @override
  void dispose() {
    disconnectSocket(); 
     if (_mapReadyCompleter != null && !_mapReadyCompleter!.isCompleted) {
      _mapReadyCompleter!.completeError("Disposed");
    }
    if (_markersReadyCompleter != null && !_markersReadyCompleter!.isCompleted) {
      _markersReadyCompleter!.completeError("Disposed");
    }
    super.dispose();
  }
}



