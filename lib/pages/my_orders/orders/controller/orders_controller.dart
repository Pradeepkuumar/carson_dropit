import 'dart:async';
import 'dart:io';
import 'package:carson_zyppy/firebase_notifications/notification_model/notification.dart';
import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/my_orders/orders/models/reason_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../apis/base_api_response.dart';
import '../../../../global/consts.dart';
import '../../../../global/global.dart';
import '../../../../utils/colors.dart';
import '../../../dashboard/controller/rider_dashboard_controller.dart';
import '../../../map/reasonsItem.dart';
import 'package:signature/signature.dart';

import '../models/orders_model.dart';

class OrdersController extends GetxController with GetTickerProviderStateMixin {
  var isLoading = true.obs;
  var currentHintIndex = 0.obs;
  late TabController tabController;
  var selectedOrder = OrdersData().obs;
  var viewFullMap = false.obs;
  var user = UserData();

  final image = Rxn<File>();
  final paymentProof = Rxn<File>();

  File? deliveredImage;
  File? deliveryProof;

  File? signatureFile;
  Uint8List? signImage;
  var isSignDraw = false.obs;

  var markDelivered = false.obs;
  var markUnDelivered = false.obs;

  var selectedReason = "".obs;

  final List<String> hintTexts = [
    "Enter Order Number",
    "Scan QR Code for Order",
  ];

  List<Marker> markers = [];
  LatLng? currentLocation;
  final Map<String, MarkerOptions> markerMap = {};
  ImageDescriptor?  icon;
  final Location _locationController = Location();
  late StreamSubscription<LocationData> _locationSubscription;


  var ordersList = <OrdersData>[].obs;
  var sortedOrders = <OrdersData>[].obs;
  var reasonsList = <CancelReason>[].obs;
  TextEditingController searchEditTextController = TextEditingController();
  final riderDashboardController = Get.put(RiderDashboardController());
  var notificationList = <String>[].obs;

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void onInit() {
    super.onInit();
    getLocationUpdates();
    getOrCreateCustomImageFromAsset();
    tabController = TabController(initialIndex: 0, length: 5, vsync: this);
    getUser();
    tabController.addListener(() {
      viewFullMap.value = false;
      if (tabController.index == 0) {
        getFeOrders(["ASSIGNED", "RE-ASSIGNED"]);
      } else if (tabController.index == 1) {
        getFeOrders(["PICKED"]);
      } else if (tabController.index == 2) {
        getFeOrders(["OFD"]);
      } else if (tabController.index == 3) {
        getFeOrders(["DELIVERED"]);
      } else if (tabController.index == 4) {
        getFeOrders(["UNDELIVERED"]);
      }
      signatureController.addListener(signatureListner);
    });
    startHintTextTimer();
  }

  getUser() async {
    await userRepository.getUser().then((value) => {user = value!});
    await getReasons();

  }

  void startHintTextTimer() {
    Timer.periodic(const Duration(seconds: 2), (_) => _changeHintText());
  }

  void _changeHintText() {
    currentHintIndex.value = (currentHintIndex.value + 1) % hintTexts.length;
  }

  String get currentHintText => hintTexts[currentHintIndex.value];

  void signatureListner() {
    if (signatureController.isNotEmpty) {
      exportSignature();
    }
  }

  void getNotification() async {
    LocalNotification? noti = await userRepository.getAllNotification();
    notificationList.add(noti?.title ?? "");
  }

  Future<bool?> getFeOrders(List<String> status) async {
    utils.showLoadingDialog("Loading...");
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: box.read(apiKeys.feCode) ?? "",
        apiKeys.status: status,
      };
      dynamic response = await apiProvider.postRequest(
          apiEndPoints.driverFetchOrderList, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
        ordersList.clear();
        await Future.forEach(result.data, (json) async {
          ordersList.add(OrdersData.fromJson(json as Map<String, dynamic>));
        });

        setMarkers();
        await  sortOrdersBySLAAndDistance(currentLocation!,ordersList);
        isLoading.value = false;
        utils.closeLoadingDialog();
        return true;
      } else {
        // utils.errorSnackBar("Exception", result.message.toString());
        utils.closeLoadingDialog();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      // utils.errorSnackBar("Exception", e.toString());
    }
    return null;
  }

  Future<bool?> getReasons() async {
    utils.showLoadingDialog("Loading...");
    try {
      dynamic response = await apiProvider.getRequest(apiEndPoints.getReasons);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
        reasonsList.clear();
        for (var json in result.data) {
          reasonsList.add(CancelReason.fromJson(json));
        }
        utils.closeLoadingDialog();
        update();
        return true;
      } else {
        //  utils.errorSnackBar("Exception", result.message.toString());
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      update();
      // utils.errorSnackBar("Exception", e.toString());
    }
    return null;
  }

  Future<dynamic> getDeliveryDirectionData() async {
    try {
      Map<String, dynamic> model = {
        apiKeys.awbNo: selectedOrder.value.awbNo ?? "",
      };
      dynamic response = await apiProvider.getRequestWithQueryParams(
          apiEndPoints.getDeliveryDirectionData, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.data != null) {
        var directionData = result.data["direction_data"];
        utils.closeLoadingDialog();
        return directionData;
      } else {
        utils.errorSnackBar("Exception", result.message.toString());
        utils.closeLoadingDialog();
        return null;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
    }
    return null;
  }

  Future<bool> updateOrder(String status) async {
    try {
      utils.showLoadingDialog("Updating...");

      List<Map<String, dynamic>> images = [
        if (markDelivered.value)
          {'key': 'delivery_proof', 'file': deliveredImage},
        if (markUnDelivered.value)
          {'key': 'failed_delivery_proof', 'file': deliveredImage},
        if (signatureFile != null) {'key': 'signature', 'file': signatureFile},
        if (deliveryProof != null) {'key': 'delivery_proof_image_2', 'file': deliveryProof}
      ];

      Map<String, dynamic> data = {
        'status': status,
        'fe_code': user.code ?? "",
        'awb_no': selectedOrder.value.awbNo ?? "",
        if (status == "UNDELIVERED") 'reason': selectedReason.value,
      };
      if (kDebugMode) {
        print(data);
      }
      var response = (await apiProvider.postRequestWithImages(
          apiEndPoints.updateOrderStatus, data, images));
      var result = BaseApiResponse.fromJson(response);
      if (response['status_code'] == 200) {
        var order = OrdersData.fromJson(result.data);
        selectedOrder.value.status = order.status;
        utils.closeLoadingDialog();
        update();
        if (status == "PICKED") {
          await riderDashboardController.getDashBoardData();
          await getFeOrders(["ASSIGNED", "RE-ASSIGNED"]);
        }
        if (status == "OFD") {
          await riderDashboardController.getDashBoardData();
          await getFeOrders(["PICKED"]);
        }
        if (status == "DELIVERED" || status == "UNDELIVERED") {
          await riderDashboardController.getDashBoardData();
          await getFeOrders(["OFD"]);
        }
        return true;
      } else {
        utils.closeLoadingDialog();
        utils.errorSnackBar("Error", result.message.toString());
        return false;
      }
    } catch (e) {
      utils.errorDialog(e.toString());
      return false;
    }
  }

  captureImage(ImageSource imageSource, String type) async {
    if (imageSource == ImageSource.camera && type == imageOne) {
      image.value = await utils.pickImage(imageSource);
      deliveredImage = image.value;
    } else if(imageSource == ImageSource.camera && type == imageTwo) {
      paymentProof.value = await utils.pickImage(imageSource);
      deliveryProof = paymentProof.value;
    }else{
      paymentProof.value = await utils.pickImage(imageSource);
          deliveryProof = paymentProof.value;

    }

    update();
  }

  exportSignature() async {
    signImage = await signatureController.toPngBytes(width: 500, height: 500);
    signatureFile = await uint8ListToFile(signImage!, "signature.png");
  }

  Future<File> uint8ListToFile(Uint8List data, String fileName) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(data);
    return file;
  }

  Future<void> popUpWindowReasons() async {
    TextEditingController searchController = TextEditingController();
    RxList<CancelReason> filteredCountriesList = RxList.from(reasonsList);
    return Get.defaultDialog(
      title: "",
      content: Container(
        child: Expanded(
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search....',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  filteredCountriesList.assignAll(reasonsList.where((country) {
                    var countryName = country.reason.toLowerCase();
                    return countryName.startsWith(value.toLowerCase());
                  }).toList());
                },
              ),
              Obx(() => Expanded(
                    flex: 1,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCountriesList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return popUpWindowItem<CancelReason>(
                          filteredCountriesList[index],
                          filteredCountriesList[index].reason,
                          (selectedItem) {
                            selectedReason.value = selectedItem.reason;
                            Get.back();
                          },
                        );
                      },
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<ImageDescriptor?> getOrCreateCustomImageFromAsset() async {
    const AssetImage assetImage = AssetImage('assets/icons/icon_pickup.png');
    final ImageConfiguration configuration =
    createLocalImageConfiguration(Get.context!);
    final AssetBundleImageKey assetBundleImageKey =
    await assetImage.obtainKey(configuration);
    final double imagePixelRatio = assetBundleImageKey.scale;
    final ByteData imageBytes = await rootBundle.load(assetBundleImageKey.name);
    icon = await registerBitmapImage(
        bitmap: imageBytes, imagePixelRatio: imagePixelRatio,width: 48,height: 48);
    return icon;
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





  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) {
        return;
      }
    }
    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationSubscription = _locationController.onLocationChanged.listen((
        LocationData current) {
      if (current.latitude != null &&
          current.longitude != null) {

        currentLocation = LatLng(latitude: current.latitude!,
              longitude: current.longitude!);

      }
    });
  }



  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }


  LatLng? findNearestDestination(
      LatLng currentLocation, List<LatLng> destinations) {
    if (destinations.isEmpty) return null;

    LatLng nearestDestination = destinations[0];
    double nearestDistance = calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      nearestDestination.latitude,
      nearestDestination.longitude,
    );

    for (var destination in destinations) {
      double distance = calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        destination.latitude,
        destination.longitude,
      );

      if (distance < nearestDistance) {
        nearestDestination = destination;
        nearestDistance = distance;
      }
    }

    return nearestDestination;
  }

   sortOrdersBySLAAndDistance(LatLng currentLocation, List<OrdersData> ordersList) async{
    final ordersWithDistance = ordersList.map((order) {
      final pickupLatLng = LatLng(latitude:
        double.parse(order.pickupLatitude!),
       longitude:  double.parse(order.pickupLongitude!),
      );
      final distance = calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        pickupLatLng.latitude,
        pickupLatLng.longitude,
      );
      return {
        'order': order,
        'distance': distance,
      };
    }).toList();

    ordersWithDistance.sort((a, b) {
      final slaComparison = (a['order'] as OrdersData).sla_in_hours?.compareTo(
        (b['order'] as OrdersData).sla_in_hours!,
      );
      if (slaComparison != 0) {
        return slaComparison!;
      }
      return (a['distance'] as double).compareTo(b['distance'] as double);
    });

    sortedOrders.value = ordersWithDistance.map((order) => order['order'] as OrdersData).toList();
  }

  @override
  void onClose() {

  }
}
