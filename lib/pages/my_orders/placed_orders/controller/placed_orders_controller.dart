import 'dart:async';
import 'dart:ui';

import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/dashboard/controller/rider_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:location/location.dart';
import '../../../../apis/base_api_response.dart';
import '../../../../global/global.dart';
import '../../../../utils/colors.dart';
import '../../orders/models/orders_model.dart';

class PlacedOrdersController extends GetxController {
  TextEditingController searchEditTextController = TextEditingController();
  final riderDashboardController  = Get.put(RiderDashboardController());
  var ordersList = <OrdersData>[].obs;
  var selectedMerchantOrdersList = <OrdersData>[].obs;
  var user = UserData();
  var viewAcceptView = false.obs;
  var orderAcceptWaitView = false.obs;
  var selectedLocationId = "".obs;
  ImageDescriptor?  icon;
  final Location _locationController = Location();

  final notifications = [
    "Enter Order Number",
    "Scan QR Code for Order",
  ];

  LatLng? currentLocation;
  final Map<String, MarkerOptions> markerMap = {};
  List<Marker> markers = [];

  var isResponseSuccess = false.obs;


  @override
  void onInit() {
    getUser();
    loadIcon();
    super.onInit();
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
        await fetchOrders();
        await riderDashboardController.getDashBoardData();
        selectedLocationOrders();
        orderAcceptWaitView.value = false;
        viewAcceptView.value = false;
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

  Future<void> setMarkers() async {
    markers.clear();
    markerMap.clear();

    if (currentLocation != null) {
      final marker = Marker(
        markerId: "current_location",
        options: MarkerOptions(
          position: LatLng(
            latitude: currentLocation?.latitude ?? 0.0,
            longitude: currentLocation?.longitude ?? 0.0,
          ),
          icon: ImageDescriptor.defaultImage,
          infoWindow: const InfoWindow(title: "Current Location", snippet: ""),
          consumeTapEvents: true,
        ),
      );

      markers.add(marker);
      markerMap[marker.markerId] = marker.options;
    }

    for (var order in ordersList) {
      final marker = Marker(
        markerId: order.locationId.toString(),
        options: MarkerOptions(
          position: LatLng(
            latitude: double.parse(order.pickupLatitude ?? "0.0"),
            longitude: double.parse(order.pickupLongitude ?? "0.0"),
          ),
          icon: icon!,
          infoWindow: InfoWindow(title: order.pickupLocationName, snippet: ""),
          consumeTapEvents: true,
        ),
      );

      markers.add(marker);
      markerMap[marker.markerId] = marker.options;
    }
  }

  Future showSelectionMenu() {
    return Get.defaultDialog(
      barrierDismissible: true,
      title: "Select Orders",
      content: Stack(
        children: [
          Column(
            children: [

            ],
          )
        ],
      ),
    );
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




}