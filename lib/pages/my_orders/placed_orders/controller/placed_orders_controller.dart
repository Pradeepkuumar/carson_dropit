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
import '../../../map/marker_generator/dynamic_marker_generator.dart';
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

  final notifications = [
    "Enter Order Number",
    "Scan QR Code for Order",
  ];

  LatLng? currentLocation;
  final Map<String, MarkerOptions> markerMap = {};

  List<Marker> markers = [];
  List<CircleOptions> circle = [];

  var isResponseSuccess = false.obs;

  Rx<MapType> mapType = MapType.normal.obs;

  late WebSocketChannel channel;
  var isConnected = false.obs;


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
      if (order.locationId.toString() == selectedLocationId.value &&
          !selectedMerchantOrdersList.any((existingOrder) =>
          existingOrder.awbNo == order.awbNo)) {
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
        setMarkers();
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
      imagePixelRatio: 1,
      width: 90,
      height: 70,
    );

    return descriptor;
  }


  Future<void> setMarkers() async {
    await navigationViewController?.clearMarkers();
    markers.clear();
    markerMap.clear();

    if (currentLocation != null) {
      final marker = Marker(
        markerId: "current_location",
        options: MarkerOptions(
          infoWindow: const InfoWindow(title: "Current Location", snippet: ""),
          position: LatLng(
            latitude: currentLocation?.latitude ?? 0.0,
            longitude: currentLocation?.longitude ?? 0.0,
          ),
          icon: icon!,
          consumeTapEvents: true,
        ),
      );
      markers.add(marker);
      markerMap[marker.markerId] = marker.options;
      addCircle();
    }

    final futures = ordersList.map((order) async {
      final ImageDescriptor customIcon = await registerDynamicMarker(
        order.pickupLocationName ?? "location",
        "PICKUP",
      );

      final marker = Marker(
        markerId: order.locationId.toString(),
        options: MarkerOptions(
          position: LatLng(
            latitude: double.parse(order.pickupLatitude ?? "0.0"),
            longitude: double.parse(order.pickupLongitude ?? "0.0"),
          ),
          icon: customIcon,
          consumeTapEvents: true,
        ),
      );

      markers.add(marker);
      markerMap[marker.markerId] = marker.options;
    }).toList();

    await Future.wait(futures);
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
        'assets/icons/ic_scooter.png', 48, 48);
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}



// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';

// import 'package:carson_zyppy/global/consts.dart';
// import 'package:carson_zyppy/local_db/entity/UserData.dart';
// import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:google_navigation_flutter/google_navigation_flutter.dart';
// import 'package:location/location.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import '../../../../apis/base_api_response.dart';
// import '../../../../global/global.dart';
// import '../../../../utils/colors.dart';
// import '../../../map/marker_generator/dynamic_marker_generator.dart';
// import '../../nearby_orders/view/item_nearby_oredrs/neaby_orders_item.dart';
// import '../../orders/models/orders_model.dart';

// class PlacedOrdersController extends GetxController {
//   TextEditingController searchEditTextController = TextEditingController();
//   final riderDashboardController = Get.put(RiderDashboardController());
//   var ordersList = <OrdersData>[].obs;
//   var selectedMerchantOrdersList = <OrdersData>[].obs;
//   var user = UserData();
//   var viewAcceptView = false.obs;
//   var selectedLocationId = "".obs;
//   ImageDescriptor? riderIcon;
//   final Location _locationController = Location();
//   GoogleMapViewController? navigationViewController;

//   final notifications = [
//     "Enter Order Number",
//     "Scan QR Code for Order",
//   ];

//   LatLng? currentLocation;
//   final Map<String, MarkerOptions> markerMap = {};

//   List<Marker> markers = [];
//   List<CircleOptions> circle = [];

//   var isResponseSuccess = false.obs;
//   var markersReady = false.obs;

//   Rx<MapType> mapType = MapType.normal.obs;

//   late WebSocketChannel channel;
//   var isConnected = false.obs;

//   @override
//   void onInit() {
//     loadRiderIcon();
//     connectSocket();
//     super.onInit();
//   }

//   void connectSocket() {
//     try {
//       channel = WebSocketChannel.connect(
//         Uri.parse('wss://dev.zyppy.qa/app/ezuXpnkK4TJnZkxRV4BdpwUH9xjYKex?protocol=7&client=js&version=8.4.0&flash=false'),
//       );

//       isConnected.value = true;

//       channel.sink.add(jsonEncode({
//         "event": "pusher:subscribe",
//         "data": {
//           "channel": "orders"
//         }
//       }));

//       channel.stream.listen((message) {
//         final decoded = json.decode(message);

//         dynamic innerData;
//         if (decoded['data'] is String) {
//           innerData = json.decode(decoded['data']);
//         } else {
//           innerData = decoded['data'];
//         }

//         final event = decoded['event'];

//         if (event == 'OrderShipmentStatusUpdated') {
//           final orderNumber = innerData['data']['order_number'];
//           Future.microtask(() => removeOrderFromList(orderNumber));
//         }
//       });

//     } catch (e) {
//       print("Connection failed: $e");
//     }
//   }

//   void disconnectSocket() {
//     channel.sink.close();
//     isConnected.value = false;
//   }

//   void removeOrderFromList(String acceptedOrderId) {
//     ordersList.removeWhere((order) => order.awbNo == acceptedOrderId);
//     selectedMerchantOrdersList.removeWhere((order) => order.awbNo == acceptedOrderId);

//     selectedMerchantOrdersList.refresh();

//     if (selectedMerchantOrdersList.isEmpty) {
//       viewAcceptView.value = false;
//     }
//   }

//   void addCircle() {
//     circle.add(
//       CircleOptions(
//         position: currentLocation!,
//         radius: 1000,
//         strokeWidth: 2,
//         strokeColor: Colors.blue.shade900,
//         fillColor: Colors.blue.withOpacity(0.2),
//         visible: true,
//         clickable: false,
//       )
//     );
//   }

//   Future<void> getUser() async {
//     user = (await userRepository.getUser())!;
//     if (user.code != null) {
//       await getLocationUpdates().then((updated) async {
//         if (updated == true) {
//           await fetchOrders();
//         }
//       });
//     }
//   }

//   // New method to prepare all markers before showing map
//   Future<void> prepareAllMarkers() async {
//     markersReady.value = false;
//     await setMarkers();
//     markersReady.value = true;
//   }

//   void selectedLocationOrders() async {
//     selectedMerchantOrdersList.clear();
//     for (var order in ordersList) {
//       if (order.locationId.toString() == selectedLocationId.value &&
//           !selectedMerchantOrdersList.any((existingOrder) =>
//           existingOrder.awbNo == order.awbNo)) {
//         selectedMerchantOrdersList.add(order);
//       }
//     }
//     update();
//     viewAcceptView.value = true;
//   }

//   Future<bool?> getLocationUpdates() async {
//     bool serviceEnabled = await _locationController.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled = await _locationController.requestService();
//       if (!serviceEnabled) return false;
//     }

//     PermissionStatus permissionGranted = await _locationController.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await _locationController.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) return false;
//     }

//     Completer<bool> locationUpdated = Completer<bool>();

//     StreamSubscription<LocationData>? subscription;
//     subscription = _locationController.onLocationChanged.listen((LocationData locationData) {
//       if (locationData.latitude != null && locationData.longitude != null) {
//         currentLocation = LatLng(latitude: locationData.latitude!, longitude: locationData.longitude!);

//         if (!locationUpdated.isCompleted) {
//           locationUpdated.complete(true);
//         }
//         subscription?.cancel();
//       }
//     });

//     return locationUpdated.future;
//   }

//   Future<bool?> fetchOrders() async {
//     utils.showLoadingDialog("Loading...");
//     try {
//       Map<String, dynamic> model = {
//         apiKeys.feCode: user.code,
//         apiKeys.latitude: currentLocation?.latitude,
//         apiKeys.longitude: currentLocation?.longitude,
//       };
//       dynamic response = await apiProvider.postRequest(
//           apiEndPoints.fetchPlacedOrders, model);
//       var result = BaseApiResponse.fromJson(response);
//       if (result.data != null) {
//         ordersList.clear();
//         for (var json in result.data) {
//           ordersList.add(OrdersData.fromJson(json));
//         }
//         utils.closeLoadingDialog();
//         isResponseSuccess.value = true;
//         return true;
//       } else {
//         utils.errorSnackBar("Exception", result.message.toString());
//         utils.closeLoadingDialog();
//         update();
//         return false;
//       }
//     } catch (e) {
//       utils.closeLoadingDialog();
//       update();
//       utils.errorSnackBar("Exception", e.toString());
//     }
//     return null;
//   }

//   Future<bool> acceptRejectOrder(String type, String orderNumber) async {
//     utils.showLoadingDialog("wait while updating order...");
//     try {
//       Map<String, dynamic> model = {
//         apiKeys.feCode: user.code,
//         apiKeys.status: type,
//         apiKeys.awbNo: orderNumber,
//       };
//       dynamic response = await apiProvider.postRequest(
//           apiEndPoints.acceptRejectOrder, model);
//       var result = BaseApiResponse.fromJson(response);
//       if (result.data != null) {

//         await riderDashboardController.getDashBoardData();
//         selectedLocationOrders();
//         removeOrderFromList(orderNumber);
//         if (type == acceptOrder) {
//           utils.successSnackBar("Order Accepted Successfully",
//               "Please find accepted order in My Orders");
//         } else {
//           utils.errorSnackBar("Order Rejected",
//               "This order no longer belongs to you");
//         }
//         utils.closeLoadingDialog();
//         return true;
//       } else {
//         utils.errorSnackBar("Exception", result.message.toString());
//         utils.closeLoadingDialog();
//         update();
//         return false;
//       }
//     } catch (e) {
//       utils.closeLoadingDialog();
//       update();
//       utils.errorSnackBar("Exception", e.toString());
//     }
//     return false;
//   }

//   Future<ImageDescriptor?> getOrCreateCustomImageFromAsset(
//       String assetPath, double width, double height) async {
//     try {
//       final AssetImage assetImage = AssetImage(assetPath);
//       final ImageConfiguration configuration =
//       createLocalImageConfiguration(Get.context!);
//       final AssetBundleImageKey assetBundleImageKey =
//       await assetImage.obtainKey(configuration);
//       final double imagePixelRatio = assetBundleImageKey.scale;
//       final ByteData imageBytes = await rootBundle.load(assetBundleImageKey.name);

//       return await registerBitmapImage(
//           bitmap: imageBytes,
//           imagePixelRatio: imagePixelRatio,
//           width: width,
//           height: height);
//     } catch (e) {
//       print("Error loading image: $e");
//       return null;
//     }
//   }

//   Future<ImageDescriptor> registerDynamicMarker(String ordersCount, String locationName) async {
//     try {
//       final ByteData byteData = await createCustomMarkerByteData(ordersCount, locationName);

//       final ImageDescriptor descriptor = await registerBitmapImage(
//         bitmap: byteData,
//         imagePixelRatio: 1,
//         width: 90,
//         height: 70,
//       );

//       return descriptor;
//     } catch (e) {
//       print("Error creating dynamic marker: $e");
//       // Return a default marker if custom creation fails
//       return await getOrCreateCustomImageFromAsset(
//         'assets/icons/ic_location_marker.png', 90, 70) ?? 
//         await getDefaultMarker();
//     }
//   }

//   // Create rider marker with rider's name
//   Future<ImageDescriptor> createRiderMarker() async {
//     try {
//       // Use the rider's name from user data
//       String riderName = user.name?.split(' ').first ?? 'Rider';
      
//       final ByteData byteData = await createRiderMarkerByteData(riderName);

//       final ImageDescriptor descriptor = await registerBitmapImage(
//         bitmap: byteData,
//         imagePixelRatio: 1,
//         width: 80,
//         height: 80,
//       );

//       return descriptor;
//     } catch (e) {
//       print("Error creating rider marker: $e");
//       return await getOrCreateCustomImageFromAsset(
//         'assets/icons/ic_scooter.png', 48, 48) ?? 
//         await getDefaultMarker();
//     }
//   }

//   Future<ImageDescriptor> getDefaultMarker() async {
//     // Create a simple default marker
//     final pictureRecorder = PictureRecorder();
//     final canvas = Canvas(pictureRecorder);
    
//     final paint = Paint()
//       ..color = Colors.blue
//       ..style = PaintingStyle.fill;
    
//     canvas.drawCircle(Offset(24, 24), 24, paint);
    
//     final picture = pictureRecorder.endRecording();
//     final image = await picture.toImage(48, 48);
//     final bytes = await image.toByteData(format: ImageByteFormat.png);
    
//     return await registerBitmapImage(
//       bitmap: bytes!,
//       imagePixelRatio: 1,
//       width: 48,
//       height: 48,
//     );
//   }

//   Future<void> setMarkers() async {
//     markers.clear();
//     markerMap.clear();

//     // Wait for rider icon to be loaded
//     if (riderIcon == null) {
//       await loadRiderIcon();
//     }

//     // Add current location marker with rider icon
//     if (currentLocation != null && riderIcon != null) {
//       final riderMarker = Marker(
//         markerId: "current_location",
//         options: MarkerOptions(
//           infoWindow: InfoWindow(
//             title: "Your Location", 
//             snippet: user.name ?? "Rider"
//           ),
//           position: LatLng(
//             latitude: currentLocation!.latitude,
//             longitude: currentLocation!.longitude,
//           ),
//           icon: riderIcon!,
//           consumeTapEvents: true,
//         ),
//       );
//       markers.add(riderMarker);
//       markerMap[riderMarker.markerId] = riderMarker.options;
//     }

//     // Add order location markers
//     final orderMarkerFutures = ordersList.map((order) async {
//       try {
//         final ImageDescriptor customIcon = await registerDynamicMarker(
//           order.pickupLocationName ?? "location",
//           "PICKUP",
//         );

//         final marker = Marker(
//           markerId: order.locationId.toString(),
//           options: MarkerOptions(
//             position: LatLng(
//               latitude: double.parse(order.pickupLatitude ?? "0.0"),
//               longitude: double.parse(order.pickupLongitude ?? "0.0"),
//             ),
//             icon: customIcon,
//             consumeTapEvents: true,
//           ),
//         );

//         markers.add(marker);
//         markerMap[marker.markerId] = marker.options;
//       } catch (e) {
//         print("Error creating marker for order ${order.awbNo}: $e");
//       }
//     }).toList();

//     // Wait for all markers to be created
//     await Future.wait(orderMarkerFutures);

//     // Add circle after markers
//     addCircle();

//     update();
//   }

//   Future<void> loadRiderIcon() async {
//     riderIcon = await createRiderMarker();
//   }

//   // You'll need to implement this method to create the rider marker byte data
//   Future<ByteData> createRiderMarkerByteData(String riderName) async {
//     // Implement your custom rider marker creation logic here
//     // This should create a marker with the rider's name and possibly an icon
//     final pictureRecorder = PictureRecorder();
//     final canvas = Canvas(pictureRecorder);
//     final size = Size(80, 80);
    
//     // Draw background circle
//     final backgroundPaint = Paint()
//       ..color = AppColors.primaryThemeColor
//       ..style = PaintingStyle.fill;
    
//     canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, backgroundPaint);
    
//     // Draw rider icon or initial
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text: riderName.length > 1 ? riderName.substring(0, 1).toUpperCase() : 'R',
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
    
//     textPainter.layout();
//     textPainter.paint(
//       canvas,
//       Offset(
//         (size.width - textPainter.width) / 2,
//         (size.height - textPainter.height) / 2,
//       ),
//     );
    
//     final picture = pictureRecorder.endRecording();
//     final image = await picture.toImage(size.width.toInt(), size.height.toInt());
//     final byteData = await image.toByteData(format: ImageByteFormat.png);
    
//     return byteData!;
//   }

//   @override
//   void dispose() {
//     disconnectSocket();
//     super.dispose();
//   }
// }