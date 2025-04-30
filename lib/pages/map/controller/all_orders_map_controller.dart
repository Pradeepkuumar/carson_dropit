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
import 'package:signature/signature.dart';
import '../../my_orders/orders/models/orders_model.dart';
import '../marker_generator/dynamic_marker_generator.dart';
import '../reasonsItem.dart';


class AllOrdersMapController extends GetxController  {
  var isLoading = true.obs;
  var currentHintIndex = 0.obs;
  var selectedOrder = OrdersData().obs;

  var user = UserData();

  final image = Rxn<File>();
  final paymentProof = Rxn<File>();

  File? deliveredImage;
  File? deliveryProof;

  var selectedOrderIndex = 0.obs;


  File? signatureFile;
  Uint8List? signImage;
  var isSignDraw = false.obs;



  var markDelivered = false.obs;
  var markUnDelivered = false.obs;
  var selectedReason = "".obs;
  var viewAcceptView = false.obs;
  var orderAcceptWaitView = false.obs;
  var selectedOrderAwbId = "".obs;

  final Location _locationController = Location();
  late var  googleMapsNavigator ;
  MapType mapType = MapType.normal;
  var isNavigationRunning = false.obs;





  GoogleNavigationViewController? navigationViewController;
  final List<NavigationWaypoint> waypoints = <NavigationWaypoint>[];
  final  markerLatLangList = <LatLng>[].obs;

  final List<String> hintTexts = [
    "Fetching Orders...",
    "Calculating Pick-Up and Drop Locations...",
    "Setting Navigation Directions...",
  ];

  List<Marker> markers = [];

  LatLng? currentLocation;
  RxDouble remainingDistance = 0.0.obs;
  StreamSubscription? locationSubscription;
  StreamSubscription? remainingTimeOrDistanceChangedSubscription;
  StreamSubscription? onArrivalSubscription;
  var isUpdateCardVisibleForUpdate = false.obs;


  final Map<String, MarkerOptions> markerMap = {};
  ImageDescriptor?  pickIcon;
  ImageDescriptor?  dropIcon;
  ImageDescriptor?  selectedPickIcon;
  ImageDescriptor?  selectedDropIcon;


  var ordersList = <OrdersData>[].obs;

  var reasonsList = <CancelReason>[].obs;
  var currentLocationOrders = <OrdersData>[].obs;
  TextEditingController searchEditTextController = TextEditingController();

  var notificationList = <String>[].obs;
  PageController pageController = PageController(
      initialPage: 0,
      viewportFraction: 1);

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  var initializeNavigation = false.obs;
  Timer? _apiCallTimer;
  DateTime? _lastApiCallTime;
  DateTime? updateDriverLocationInterval;

  var bottomBarListType = 0.obs;
  Timer? _hintTextTimer;
  Timer? _nearbyOrdersTimer;
  DateTime? startTime;

  var bufferMinutes = "".obs;








  @override
  void onInit() async {
    googleMapsNavigator  = GoogleMapsNavigator() ;
   // loadIcons();
    await getLocationUpdates();
    getUser();
    initializeNavigationSession();
    super.onInit();
  }


  Future<bool>calculateBufferTime(DateTime now, String status) async{
    if(startTime != null) {
      final difference = now.difference(startTime!);
     bufferMinutes.value  =  formatDurationToMinutes(difference.toString());
     return true;
    }
    return false;
  }

  String formatDurationToMinutes(String durationStr) {

    final parts = durationStr.split(':');

    if (parts.length != 3) return "Invalid format";

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = double.parse(parts[2]);

    final totalSeconds = (hours * 3600) + (minutes * 60) + seconds;

    final totalMinutes = totalSeconds ~/ 60;
    final remainingSeconds = totalSeconds.toInt() % 60;

    return '${totalMinutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void onReady() {
    Future.delayed(const Duration(seconds: 5), () {
       getReasons();
       getFeAllOrders(["ASSIGNED", "RE-ASSIGNED","REACHED","PICKED","OFD"]);
    });

    signatureController.addListener(signatureListner);
    startHintTextTimer();
    pageController.addListener(() {
      double page = pageController.page ?? 0.0;
      int newPageIndex = page.round();
      if (selectedOrder.value != ordersList[newPageIndex]) {
        selectedOrder.value = ordersList[newPageIndex];
        navigationViewController!.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(
            latitude: selectedOrder.value.status == "PICKED" || selectedOrder.value.status == "OFD"
                ? double.parse(selectedOrder.value.dropoffLatitude ?? "0.0")
                : double.parse(selectedOrder.value.pickupLatitude ?? "0.0"),
            longitude: selectedOrder.value.status == "PICKED" || selectedOrder.value.status == "OFD"
                ? double.parse(selectedOrder.value.dropoffLongitude ?? "0.0")
                : double.parse(selectedOrder.value.pickupLongitude ?? "0.0"),
          ),
          15.0,
        ));
        setMarkers();
      }
    });

    super.onReady();
  }


  void startHintTextTimer() {
    _hintTextTimer?.cancel();
    _hintTextTimer = Timer.periodic(const Duration(seconds: 2), (_) => _changeHintText());
  }

  void fetchNearByOrders() {
    _nearbyOrdersTimer?.cancel();
    _nearbyOrdersTimer = Timer.periodic(const Duration(minutes: 5), (_)  {
      //getFeAllOrders(["PLACED"]);
    });
  }

  void _changeHintText() {
    currentHintIndex.value = (currentHintIndex.value + 1) % hintTexts.length;
  }

  String get currentHintText => hintTexts[currentHintIndex.value];



  void _onRemainingTimeOrDistanceChangedEvent(RemainingTimeOrDistanceChangedEvent event) {
    remainingDistance.value = event.remainingDistance;
      DateTime now = DateTime.now();
      if (_lastApiCallTime == null || now.difference(_lastApiCallTime!).inMinutes >= 1) {
        _lastApiCallTime = now;
        if (remainingDistance.value <= 100) {

        filterCurrentLocationOrders(100);
       }
     }
  }

  void onArrivalEvent(OnArrivalEvent onArrive){
    NavigationWaypoint arrivedWaypoint = onArrive.waypoint;
    filterCurrentLocationOrders(100);
  }


  void checkForLocationUpdate() async {
    if (currentLocation?.longitude != null) {
      remainingTimeOrDistanceChangedSubscription =
          googleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
            _onRemainingTimeOrDistanceChangedEvent,
            remainingDistanceThresholdMeters: 100,
          );
      googleMapsNavigator.setOnArrivalListener(onArrivalEvent);
    }
  }

  filterCurrentLocationOrders(double distanceThresholdInMeters) async {
    currentLocationOrders.clear();
    if (currentLocation == null || ordersList.isEmpty) return;
    final nearbyOrders = ordersList.where((order) {
      final orderLatLng = LatLng(
       latitude:  order.status == "PICKED" || order.status == "OFD"
            ? double.parse(order.dropoffLatitude ?? "0.0")
            : double.parse(order.pickupLatitude ?? "0.0"),
        longitude:  order.status == "PICKED" || order.status == "OFD"
            ? double.parse(order.dropoffLongitude ?? "0.0")
            : double.parse(order.pickupLongitude ?? "0.0"),
      );
      final distance = calculateDistance(
        currentLocation!.latitude,
        currentLocation!.longitude,
        orderLatLng.latitude,
        orderLatLng.longitude,
      );
      return distance <= distanceThresholdInMeters;
    }).toList();
    currentLocationOrders.addAll(nearbyOrders);
    if(currentLocationOrders.isNotEmpty) {
      bottomBarListType.value = 1;
      viewAcceptView.value = true;
    }else{
      viewAcceptView.value = false;
      bottomBarListType.value = 0;
    }
    update();
  }


  // Future<void> loadIcons() async {
  //
  //   pickIcon = await getOrCreateCustomImageFromAsset(
  //       'assets/icons/ic_location.png', 48, 48);
  //   dropIcon = await getOrCreateCustomImageFromAsset(
  //       'assets/icons/ic_box.png', 48, 48);
  //
  //   selectedPickIcon = await getOrCreateCustomImageFromAsset(
  //       'assets/icons/ic_location.png', 80, 80);
  //   selectedDropIcon = await getOrCreateCustomImageFromAsset(
  //       'assets/icons/ic_box.png', 80, 80);
  // }


  initializeNavigationSession() async {
    if (!await googleMapsNavigator.areTermsAccepted()) {
      await googleMapsNavigator.showTermsAndConditionsDialog(
        'Carson Zyppy',
        'Logistics solutions',
      );
    }
    await googleMapsNavigator.initializeNavigationSession().then((value){
      initializeNavigation.value = true;
    });
  }

  getUser() async {
    await userRepository.getUser().then((value) => {user = value!});
  }

  Future<void> startGuidedNavigation() async {
    if(!isNavigationRunning.value) {
      await googleMapsNavigator.startGuidance();
      await navigationViewController?.followMyLocation(
          CameraPerspective.tilted);
      isNavigationRunning.value = true;
      //await navigationViewController?.showRouteOverview();
    }

  }
  Future<void> stopGuidedNavigation() async {
    googleMapsNavigator.stopGuidance();
    isNavigationRunning.value = false;

  }


  void signatureListner() {
    if (signatureController.isNotEmpty) {
      exportSignature();
    }
  }


  void getNotification() async {
    LocalNotification? noti = await userRepository.getAllNotification();
    notificationList.add(noti?.title ?? "");
  }


  selectedLocationOrders() async {
    for (int i = 0; i < ordersList.length; i++) {
      if (ordersList[i].awbNo.toString() == selectedOrderAwbId.value) {
        selectedOrder.value = ordersList[i];
        selectedOrderIndex.value = i;
        // updateSelectedMarker(  LatLng(
        //   latitude: selectedOrder.value.status == "PICKED" || selectedOrder.value.status == "OFD"
        //       ? double.parse(selectedOrder.value.dropoffLatitude ?? "0.0")
        //       : double.parse(selectedOrder.value.pickupLatitude ?? "0.0"),
        //   longitude: selectedOrder.value.status == "PICKED" || selectedOrder.value.status == "OFD"
        //       ? double.parse(selectedOrder.value.dropoffLongitude ?? "0.0")
        //       : double.parse(selectedOrder.value.pickupLongitude ?? "0.0"),
        // ));
        break;
      }
    }
    update();
    viewAcceptView.value = true;

  }

  void updateSelectedMarker(LatLng selectedLocation) {
    // Find the index of the selected location in the waypoints list
    int index = waypoints.indexWhere((waypoint) => waypoint.target == selectedLocation);

    // If the selected location is found in the waypoints list
    if (index != -1) {
      // Remove the selected location from its current position
      NavigationWaypoint selectedWaypoint = waypoints.removeAt(index);

      // Insert the selected location at the top of the waypoints list
      waypoints.insert(0, selectedWaypoint);
    } else {
      // If the selected location is not found, add it as a new waypoint at the top
      waypoints.insert(0, NavigationWaypoint.withLatLngTarget(title: "current", target: selectedLocation));
    }

    // Update the destinations in the Google Maps Navigator
    googleMapsNavigator.setDestinations(Destinations(
      waypoints: waypoints,
      displayOptions: NavigationDisplayOptions(
        showDestinationMarkers: false,
        showStopSigns: true,
        showTrafficLights: true,
      ),
      routingOptions: RoutingOptions(
        travelMode: NavigationTravelMode.driving,
      ),
    ));
  }


  Future<bool?> getFeAllOrders(List<String> status) async {
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
        // ordersList.sort((a, b) {
        //   double extractDistance(String distance) {
        //         final match = RegExp(r'\d+(\.\d+)?').firstMatch(distance);
        //         return match != null ? double.parse(match.group(0)!) : double.infinity;
        //       }
        //       return extractDistance(a.distance!).compareTo(extractDistance(b.distance!));
        // });

        if(ordersList.isEmpty) {
         Get.back();
        }
        await filterCurrentLocationOrders(100);
        await setMarkers();
        isLoading.value = false;
        utils.closeLoadingDialog();
        return true;
      } else {
        utils.closeLoadingDialog();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
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
        if(status == "PICKED") 'picked_buffer_time': bufferMinutes.value,
        if(status == "DELIVERED") 'dropoff_buffer_time': bufferMinutes.value,
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
        // selectedOrder.value.status = order.status;
        // updateExistingOrder(order);
        isUpdateCardVisibleForUpdate.value =  false;

        getFeAllOrders(["ASSIGNED","RE-ASSIGNED","REACHED","PICKED","OFD"]);
        if(status == "DELIVERED" || status == "UNDELIVERED" ){
          deliveredImage = null;
          deliveryProof = null;
          paymentProof.value = null;
          signatureFile = null;
          image.value = null;
        }
        utils.closeLoadingDialog();
        update();
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



  Future<bool?> updateBuffert() async {
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


  void updateExistingOrder(OrdersData updatedOrder) {
    int index = ordersList.indexWhere((order) => order.awbNo == updatedOrder.awbNo);
    if (index != -1) {
      ordersList[index] = updatedOrder;
    }
    setMarkers();
  }


  Future<bool> sendDriverLocation(LatLng locationData) async {
    try {
      Map<String, dynamic> model = {
        apiKeys.userID: user.id,
        apiKeys.latitude: locationData.latitude,
        apiKeys.longitude: locationData.longitude
      };
      var response = await apiProvider.postRequest(
          apiEndPoints.driverCurrentLocation, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        utils.closeLoadingDialog();
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      // utils.errorSnackBar("Exception", e.toString());
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

  void updateNavigationSessionWithNearestDestination(LatLng currentLocation) {
    LatLng? nearestDestination =
    findNearestDestination(currentLocation, markerLatLangList);

    if (nearestDestination != null) {
      waypoints.clear();

      waypoints.add(NavigationWaypoint.withLatLngTarget(
        title: "Nearest Destination",
        target: nearestDestination,
      ));

      googleMapsNavigator.setDestinations(Destinations(
        waypoints: waypoints,
        displayOptions: NavigationDisplayOptions(
          showDestinationMarkers: false,
          showStopSigns: true,
          showTrafficLights: true,
        ),
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
        ),
      ));

      //startGuidedNavigation();
    }
  }




  // Future<ImageDescriptor?> getOrCreateCustomImageFromAsset(
  //     String assetPath, double width, double height) async {
  //   final AssetImage assetImage = AssetImage(assetPath);
  //   final ImageConfiguration configuration =
  //   createLocalImageConfiguration(Get.context!);
  //   final AssetBundleImageKey assetBundleImageKey =
  //   await assetImage.obtainKey(configuration);
  //   final double imagePixelRatio = assetBundleImageKey.scale;
  //   final ByteData imageBytes = await rootBundle.load(assetBundleImageKey.name);
  //
  //   return await registerBitmapImage(
  //       bitmap: imageBytes, imagePixelRatio: imagePixelRatio, width: width, height: height);
  // }

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

  Future<bool> setMarkers() async {
    await navigationViewController?.clearMarkers();
    markers.clear();
    markerMap.clear();
    waypoints.clear();
    markerLatLangList.clear();

    var currentOrdersList = currentLocationOrders.isNotEmpty
        ? currentLocationOrders
        : ordersList;

    final List<Marker> tempMarkers = [];
    final Map<String, MarkerOptions> tempMarkerMap = {};
    final List<NavigationWaypoint> tempWaypoints = [];
    final List<LatLng> tempLatLngList = [];

    for (var order in currentOrdersList) {
      final double latitude = (order.status == "PICKED" || order.status == "OFD")
          ? double.tryParse(order.dropoffLatitude ?? "0.0") ?? 0.0
          : double.tryParse(order.pickupLatitude ?? "0.0") ?? 0.0;

      final double longitude = (order.status == "PICKED" || order.status == "OFD")
          ? double.tryParse(order.dropoffLongitude ?? "0.0") ?? 0.0
          : double.tryParse(order.pickupLongitude ?? "0.0") ?? 0.0;

      final LatLng position = LatLng(latitude: latitude, longitude: longitude);

      final ImageDescriptor customIcon = await registerDynamicMarker(
        order.awbNo.toString(),
        (order.status == "PICKED" || order.status == "OFD") ? "DELIVERY" : "PICKUP",
      );

      final marker = Marker(
        markerId: order.awbNo!,
        options: MarkerOptions(
          position: position,
          icon: customIcon,
          infoWindow: InfoWindow(
            title: order.pickupLocationName,
            snippet: "location",
          ),
          consumeTapEvents: true,
        ),
      );

      tempMarkers.add(marker);
      tempMarkerMap[marker.markerId] = marker.options;
      tempWaypoints.add(NavigationWaypoint.withLatLngTarget(
        title: order.consigneeAddress?.toString() ?? "Destination",
        target: position,
      ));
      tempLatLngList.add(position);
    }

    // Commit everything to actual shared state
    markers.addAll(tempMarkers);
    markerMap.addAll(tempMarkerMap);
    waypoints.addAll(tempWaypoints);
    markerLatLangList.addAll(tempLatLngList);

    // Set all waypoints at once
    googleMapsNavigator.setDestinations(
      Destinations(
        waypoints: waypoints,
        displayOptions: NavigationDisplayOptions(
          showDestinationMarkers: false,
          showStopSigns: true,
          showTrafficLights: true,
        ),
        routingOptions: RoutingOptions(
          travelMode: NavigationTravelMode.driving,
          alternateRoutesStrategy: NavigationAlternateRoutesStrategy.all,
        ),
      ),
    );

    // Add all markers in a single batch
    await navigationViewController?.addMarkers(tempMarkers);

    return true;
  }



  // Future<bool> setMarkers() async {
  //   await navigationViewController?.clearMarkers();
  //   markers.clear();
  //   markerMap.clear();
  //   waypoints.clear();
  //   markerLatLangList.clear();
  //
  //   var currentOrdersList = <OrdersData>[].obs;
  //   if (currentLocationOrders.isNotEmpty) {
  //     currentOrdersList = currentLocationOrders;
  //   } else {
  //     currentOrdersList = ordersList;
  //   }
  //
  //   for (var order in currentOrdersList) {
  //     final double latitude = order.status == "PICKED" || order.status == "OFD"
  //         ? double.parse(order.dropoffLatitude ?? "0.0")
  //         : double.parse(order.pickupLatitude ?? "0.0");
  //
  //     final double longitude = order.status == "PICKED" || order.status == "OFD"
  //         ? double.parse(order.dropoffLongitude ?? "0.0")
  //         : double.parse(order.pickupLongitude ?? "0.0");
  //
  //     final LatLng position = LatLng(latitude: latitude, longitude: longitude);
  //
  //
  //     final ImageDescriptor customIcon = await registerDynamicMarker(
  //       order.awbNo.toString(),
  //       order.status == "PICKED" || order.status == "OFD"
  //           ? "DELIVERY":"PICKUP",
  //     );
  //
  //
  //     final marker = Marker(
  //       markerId: order.awbNo!,
  //       options: MarkerOptions(
  //         position: position,
  //         icon: customIcon,
  //         infoWindow: InfoWindow(
  //           title: order.pickupLocationName,
  //           snippet: "location",
  //         ),
  //         consumeTapEvents: true,
  //       ),
  //     );
  //
  //     markers.add(marker);
  //     markerMap[marker.markerId] = marker.options;
  //
  //     waypoints.add(NavigationWaypoint.withLatLngTarget(
  //       title: order.consigneeAddress.toString(),
  //       target: position,
  //     ));
  //
  //     markerLatLangList.add(position);
  //   }
  //
  //
  //   googleMapsNavigator.setDestinations(Destinations(
  //     waypoints: waypoints,
  //     displayOptions: NavigationDisplayOptions(
  //       showDestinationMarkers: false,
  //       showStopSigns: true,
  //       showTrafficLights: true,
  //     ),
  //     routingOptions: RoutingOptions(
  //       travelMode: NavigationTravelMode.driving,
  //       alternateRoutesStrategy: NavigationAlternateRoutesStrategy.all,
  //     ),
  //   ));
  //
  //
  //   for (var marker in markers) {
  //     await navigationViewController?.addMarkers([marker]);
  //   }
  //
  //   return true;
  // }



  // Future<bool> setMarkers() async {
  //   navigationViewController?.clearMarkers();
  //   markers.clear();
  //   markerMap.clear();
  //   waypoints.clear();
  //   markerLatLangList.clear();
  //   var currentOrdersList = <OrdersData>[].obs;
  //   if(currentLocationOrders.isNotEmpty){
  //     currentOrdersList =  currentLocationOrders;
  //   }else{
  //     currentOrdersList =  ordersList;
  //   }
  //
  //   for (var order in currentOrdersList) {
  //     bool isSelected = selectedOrder.value == order;
  //
  //     final marker = Marker(
  //       markerId: order.awbNo!,
  //       options: MarkerOptions(
  //         position: LatLng(
  //           latitude: order.status == "PICKED" || order.status == "OFD"
  //               ? double.parse(order.dropoffLatitude ?? "0.0")
  //               : double.parse(order.pickupLatitude ?? "0.0"),
  //           longitude: order.status == "PICKED" || order.status == "OFD"
  //               ? double.parse(order.dropoffLongitude ?? "0.0")
  //               : double.parse(order.pickupLongitude ?? "0.0"),
  //         ),
  //         icon: isSelected
  //             ? (order.status == "PICKED" || order.status == "OFD" ? selectedDropIcon! : selectedPickIcon!)
  //             : (order.status == "PICKED" || order.status == "OFD" ? dropIcon! : pickIcon!),
  //         infoWindow: InfoWindow(
  //           title: order.pickupLocationName,
  //           snippet: "location",
  //         ),
  //         consumeTapEvents: true,
  //       ),
  //     );
  //
  //     markers.add(marker);
  //     markerMap[marker.markerId] = marker.options;
  //
  //     waypoints.add(NavigationWaypoint.withLatLngTarget(
  //       title: order.consigneeAddress.toString(),
  //       target: LatLng(
  //         latitude: order.status == "PICKED" || order.status == "OFD"
  //             ? double.parse(order.dropoffLatitude ?? "0.0")
  //             : double.parse(order.pickupLatitude ?? "0.0"),
  //         longitude: order.status == "PICKED" || order.status == "OFD"
  //             ? double.parse(order.dropoffLongitude ?? "0.0")
  //             : double.parse(order.pickupLongitude ?? "0.0"),
  //       ),
  //     ));
  //
  //     markerLatLangList.add(LatLng(
  //       latitude: order.status == "PICKED" || order.status == "OFD"
  //           ? double.parse(order.dropoffLatitude ?? "0.0")
  //           : double.parse(order.pickupLatitude ?? "0.0"),
  //       longitude: order.status == "PICKED" || order.status == "OFD"
  //           ? double.parse(order.dropoffLongitude ?? "0.0")
  //           : double.parse(order.pickupLongitude ?? "0.0"),
  //     ));
  //   }
  //
  //   googleMapsNavigator.setDestinations(Destinations(
  //     waypoints: waypoints,
  //     displayOptions: NavigationDisplayOptions(
  //       showDestinationMarkers: true,
  //       showStopSigns: true,
  //       showTrafficLights: true,
  //     ),
  //     routingOptions: RoutingOptions(
  //       travelMode: NavigationTravelMode.driving,
  //       alternateRoutesStrategy: NavigationAlternateRoutesStrategy.all
  //     ),
  //   ));
  //   for (var marker in markers) {
  //     navigationViewController?.addMarkers([marker]);
  //   }
  //   return true;
  // }



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
    locationSubscription = _locationController.onLocationChanged.listen((
        LocationData current) {
      if (current.latitude != null &&
          current.longitude != null) {
        currentLocation = LatLng(latitude: current.latitude!, longitude: current.longitude!);
        checkForLocationUpdate();
        DateTime now = DateTime.now();
        if (updateDriverLocationInterval == null || now.difference(updateDriverLocationInterval!).inMinutes >= 1) {
          updateDriverLocationInterval = now;
          sendDriverLocation(currentLocation!);
        }
      }

      // remainingTimeOrDistanceChangedSubscription =
      //     GoogleMapsNavigator.setOnRemainingTimeOrDistanceChangedListener(
      //         onRemainingTimeOrDistanceChangedEvent, remainingDistanceThresholdMeters: 50);
    });
  }






  // double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  //   return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  // }


  // LatLng? findNearestDestination(
  //     LatLng currentLocation, List<LatLng> destinations) {
  //   if (destinations.isEmpty) return null;
  //
  //   LatLng nearestDestination = destinations[0];
  //   double nearestDistance = calculateDistance(
  //     currentLocation.latitude,
  //     currentLocation.longitude,
  //     nearestDestination.latitude,
  //     nearestDestination.longitude,
  //   );
  //
  //   for (var destination in destinations) {
  //     double distance = calculateDistance(
  //       currentLocation.latitude,
  //       currentLocation.longitude,
  //       destination.latitude,
  //       destination.longitude,
  //     );
  //
  //     if (distance < nearestDistance) {
  //       nearestDestination = destination;
  //       nearestDistance = distance;
  //     }
  //   }
  //
  //   return nearestDestination;
  // }




  // sortOrdersByDistanceAndRemainingTime(LatLng currentLocation, List<OrdersData> ordersList) async {
  //   // Step 1: Calculate distance for each order and store it in a list
  //   final ordersWithDistance = ordersList.map((order) {
  //     final latLng = LatLng(
  //       latitude: order.status == "PICKED" || order.status == "OFD"  ? double.parse(order.dropoffLatitude ?? "0.0") : double.parse(order.pickupLatitude ?? "0.0"),
  //       longitude: order.status == "PICKED" || order.status == "OFD"   ? double.parse(order.dropoffLongitude ?? "0.0") : double.parse(order.pickupLongitude ?? "0.0"),
  //     );
  //     final distance = order.status == "PICKED" || order.status == "OFD"  ? order.current_dropoff_distance_value: order.current_pickup_distance_value;
  //     return {
  //       'order': order,
  //       'distance': distance,
  //     };
  //   }).toList();
  //
  //   // Step 2: Sort orders by distance
  //   ordersWithDistance.sort((a, b) {
  //     return (a['distance'] as double).compareTo(b['distance'] as double);
  //   });
  //
  //   // Step 3: Calculate remaining time for each order
  //   final now = DateTime.now();
  //   final ordersWithRemainingTime = ordersWithDistance.map((entry) {
  //     final order = entry['order'] as OrdersData;
  //     final createdTime = DateTime.parse(order.createdAt!);
  //     final deadline = createdTime.add(Duration(hours: int.tryParse(order.sla_in_hours ?? "0")!));
  //     final remainingTime = deadline.difference(now);
  //
  //     String remainingTimeFormatted;
  //     if (remainingTime.inMinutes < 60) {
  //       remainingTimeFormatted = '${remainingTime.inMinutes} mins';
  //     } else {
  //       remainingTimeFormatted = '${remainingTime.inHours} hours ${remainingTime.inMinutes.remainder(60)} mins';
  //     }
  //
  //     return {
  //       'order': order,
  //       'distance': entry['distance'],
  //       'remainingTime': remainingTime,
  //       'remainingTimeFormatted': remainingTimeFormatted,
  //     };
  //   }).toList();
  //
  //   // Step 4: Apply the custom sorting logic
  //   ordersWithRemainingTime.sort((a, b) {
  //     final distanceA = a['distance'] as double;
  //     final distanceB = b['distance'] as double;
  //     final remainingTimeA = a['remainingTime'] as Duration;
  //     final remainingTimeB = b['remainingTime'] as Duration;
  //     final statusA = (a['order'] as OrdersData).status;
  //     final statusB = (b['order'] as OrdersData).status;
  //
  //     // Check if the orders are nearby (e.g., within 2 km of each other)
  //     if ((distanceA - distanceB).abs() <= 2000) {
  //       // Check if the 2nd order is within 5 km
  //       if (distanceB <= 5000) {
  //         // Check if one of the orders is critical (status is "OFD" or "PICKED" || order.status == "OFD")
  //         final isACritical = statusA == "OFD" || statusA == "PICKED" ;
  //         final isBCritical = statusB == "OFD" || statusB == "PICKED" ;
  //
  //         // If both are critical, prioritize the one with less remaining time
  //         if (isACritical && isBCritical) {
  //           return remainingTimeA.compareTo(remainingTimeB);
  //         }
  //         // If only one is critical, prioritize it
  //         else if (isACritical) {
  //           return -1;
  //         } else if (isBCritical) {
  //           return 1;
  //         }
  //       }
  //     }
  //
  //     // Default sorting by distance
  //     return distanceA.compareTo(distanceB);
  //   });
  //
  //   // Step 5: Update the orders with the caslculated remaining time
  //   sortedOrders.value = ordersWithRemainingTime.map((entry) {
  //     final order = entry['order'] as OrdersData;
  //     order.distanceInKms = (entry['distance'] as double) < 1000
  //         ? '${(entry['distance'] as double).toStringAsFixed(0)} m'
  //         : '${((entry['distance'] as double) / 1000).toStringAsFixed(2)} km';
  //     order.remainingTime = entry['remainingTimeFormatted'] as String;
  //     return order;
  //   }).toList();
  //
  //
  //
  // }




  @override
  void onClose() {
    remainingTimeOrDistanceChangedSubscription?.cancel();
    locationSubscription?.cancel();
    googleMapsNavigator.stopGuidance();
    googleMapsNavigator.cleanup();
    initializeNavigation.value = false;
    navigationViewController?.clear();
    _hintTextTimer?.cancel();
    _nearbyOrdersTimer?.cancel();
    super.onClose();
  }



}
