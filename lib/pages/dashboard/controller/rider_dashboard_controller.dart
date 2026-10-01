import 'dart:io';
import 'dart:math';
import 'package:carson_zyppy/apis/api_keys.dart';
import 'package:carson_zyppy/firebase_notifications/firebase_notifiction_controller.dart';
import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/dashboard/models/dashboard_data.dart';
import 'package:carson_zyppy/pages/my_orders/orders/models/orders_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../apis/base_api_response.dart';
import '../../../app_pages/app_pages.dart';
import '../../../global/consts.dart';
import '../../../global/global.dart';
import '../../../global/location_service.dart';
import '../../../utils/calculate_sla.dart';
import '../models/driver_data.dart';

class RiderDashboardController extends GetxController {
  var isLoading = true.obs;
  var showSplashScreen = true.obs;
  var userData = UserData();
  var firebaseToken = "";
  var riderName = "".obs;
  var isAttendanceMarked = false.obs;
  final locationUtils = LocationUtils();
  LocationData? startLocation;
  // Latest known fix, kept fresh by getCountinuesLocation()'s stream
  // listener (~every 10s) - other API calls (fetchAvailableOrders, etc.)
  // read this instead of doing their own one-shot GPS fetch each time.
  LocationData? currentLocation;
  var workingHours = "".obs;
  var walletAmount = "".obs;
  var isInternetOn = false.obs;
  var updateRiderLocation = false.obs;
  //var driverData = DriverData().obs;
  var dashBoardData = DashBoardData().obs;
  var c2cDashBoardData = DashBoardData().obs;
  var isAttendanceLoaded = false.obs;
  var attendancesList = [].obs;
  var isAnyActiveOrder = false.obs;
  // Lives on the controller (not the dashboard State) so the shared bottom
  // nav on other screens can open the account flyout after popping back to
  // the dashboard - see AppBottomNav.
  var showMenu = false.obs;
  var whatsAppDashBoardData = DashBoardData().obs;
  var nextDelivery = Rxn<OrdersData>();
  var upcomingOrders = <OrdersData>[].obs;
  // Unclaimed orders nearby the rider can accept, shown in the dashboard's
  // "New Requests" section - same data OrderListController's "available"
  // tab fetches.
  var availableOrders = <OrdersData>[].obs;
  // A "NearByOrders" notification can fire before this controller is
  // registered (cold start) - the ref is stashed here so fetchAvailableOrders
  // picks it up once it runs, instead of the notification tap being dropped.
  static String? pendingFocusOrderRef;
  var checkBoxValue = false.obs;
  RxBool isConsentGiven = RxBool(false);
  late FirebaseMessagingController firebaseMessagingController;
  Worker? _notificationWorker;
  var isNewAppUpdateAvailable = false.obs;

  // Profile fields for update
  var avatar = Rx<File?>(null);
  var address = TextEditingController();
  var phone = TextEditingController();
  var feCode = TextEditingController();

  final picker = ImagePicker();

  // Form key for validation
  final profileFormKey = GlobalKey<FormState>();

  // Account screen's Light/Dark toggle - persisted so it survives restarts,
  // see main.dart's _initialThemeMode.
  var isDarkMode = Get.isDarkMode.obs;

  void setThemeMode(bool dark) {
    // Get.changeThemeMode must land (and its MaterialApp rebuild finish)
    // before isDarkMode.value flips - otherwise screens' Obx rebuilds can
    // run a frame early and read a stale Get.isDarkMode, leaving text
    // colors (from utils.tvCustom, which reads Get.isDarkMode directly)
    // out of sync with the already-updated backgrounds until some other
    // rebuild happens to catch them up.
    Get.changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
    box.write(THEME_MODE_KEY, dark ? 'dark' : 'light');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isDarkMode.value = dark;
    });
  }

  @override
  void onInit() {
    getUser();
    loadUserDetails();
    super.onInit();
  }

  @override
  void onReady() {
    isConsentGiven.value = box.read("isConsentGiven") ?? false;
    if (isConsentGiven.value) {
      updateLocation();
      requestBackgroundPermission();
      getUserData();
     // driverCheckAttendance();
    }
    firebaseMessagingController = Get.find<FirebaseMessagingController>();
    _notificationWorker = ever(firebaseMessagingController.onNewNotification, (bool isNew) {
      if (isNew) {
       // getC2CCDashBoardData();
        // driverCheckAttendance();
        getDashBoardData();
       // getWhatsAppDashBoardData();
        getNextDelivery();
        fetchAvailableOrders();
        getCurrentLocation();

        firebaseMessagingController.onNewNotification.value = false;
      }
    });
    checkForUpdate();
    super.onReady();
  }

  // Load user details into controllers
  void loadUserDetails() {
    address.text = userData.address ?? "";
    phone.text = userData.phone ?? "";
    feCode.text = userData.code ?? "";
  }

  // Pick avatar from gallery
  Future<void> pickAvatar() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        avatar.value = File(pickedFile.path);
        update();
      }
    } catch (e) {
      utils.errorSnackBar("Error", "Failed to pick image: $e");
    }
  }

  // Pick avatar from camera
  Future<void> pickAvatarFromCamera() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 100,
      );
      if (pickedFile != null) {
        avatar.value = File(pickedFile.path);
        update();
      }
    } catch (e) {
      utils.errorSnackBar("Error", "Failed to capture image: $e");
    }
  }

  void showImageSourceDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Select Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.of(Get.context!).pop();
                pickAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                Navigator.of(Get.context!).pop();
                pickAvatarFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Validate phone number
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!value.isPhoneNumber) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // Validate address
  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 5) {
      return 'Address must be at least 5 characters';
    }
    return null;
  }

  // Update profile details
  Future<bool> updateProfileDetails() async {
    if (!profileFormKey.currentState!.validate()) {
      return false;
    }

    try {
      utils.showLoadingDialog("Updating profile...");

      List<Map<String, dynamic>> images = [];

      if (avatar.value != null) {
        images.add({'key': 'avatar', 'file': avatar.value});
      }

      Map<String, dynamic> data = {
        'address': address.text.trim(),
        'phone': phone.text.trim(),
        'fe_code': userData.code,
      };

      if (kDebugMode) {
        print("Profile Update Data: $data");
        print("Images count: ${images.length}");
      }

      var response = await apiProvider.postRequestWithImagesDio(
        'driver/update-profile-details',
        data,
        images,
      );

      var result = BaseApiResponse.fromJson(response);

      if (response['status_code'] == 200) {
        utils.closeLoadingDialog();
        utils.successSnackBar("Success", "Profile updated successfully");
        userData = UserData.fromJson(result.data);
        await userRepository.updateUser(userData);
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        utils.errorSnackBar("Error", result.message.toString());
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorDialog("Failed to update profile: $e");
      return false;
    }
  }

  updateLocation() async {
    //driverCheckAttendance();
    final walletFuture = fetchWalletAmount();
    await getCurrentLocation();
    await getCountinuesLocation();
    await walletFuture;
  }

  void checkAttendance(AttendanceModel attendance) {
    print(attendance.markAttendance);
    if (attendance.markAttendance ??false) {
      isAttendanceMarked.value =  true;
     } else {
       isAttendanceMarked.value = false;
    }
     isAttendanceLoaded.value = true;
  }

  Future<void> requestBackgroundPermission() async {
    if (await Permission.locationWhenInUse.isGranted) {
      final status = await Permission.locationAlways.request();
      if (!status.isGranted) {
        if (kDebugMode) {
          print("Background location permission not granted.");
        }
      } else {
        if (kDebugMode) {
          print("Enable service from settings");
        }
      }
    } else {
      if (kDebugMode) {
        print("Foreground location permission is required first.");
      }
    }
  }

  getUser() async {
    try {
      var value = await userRepository.getUser();
      if (value != null) {
        userData = value;
        riderName.value = userData.name ?? "";
        loadUserDetails(); // Reload details when user data changes
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // await getC2CCDashBoardData();
          // await getWhatsAppDashBoardData();
          await Future.wait([
            driverCheckAttendance(),
            fetchWalletAmount(),
            getDashBoardData(),
            getNextDelivery(),
            fetchAvailableOrders(),
          ]);
        });
      }
    } catch (e) {
      // utils.errorSnackBar("Exception", e.toString());
    }
  }

  Future<void> checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        isNewAppUpdateAvailable.value = true;
        performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }

  Future<void> performImmediateUpdate() async {
    try {
      AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.success) {
        isNewAppUpdateAvailable.value = false;
      } else {
        // Forcefully ask again if the user denies or if it fails
        performImmediateUpdate();
      }
    } on FormatException catch (e) {
      debugPrint('FormatException: $e');
      utils.errorSnackBar('Update Failed', 'Failed to start update process');
      Future.delayed(const Duration(seconds: 1), () {
        performImmediateUpdate();
      });
    } on PlatformException catch (e) {
      debugPrint('PlatformException: $e');
      Future.delayed(const Duration(seconds: 1), () {
        performImmediateUpdate();
      });
    } catch (e) {
      debugPrint('Exception: $e');
      Future.delayed(const Duration(seconds: 1), () {
        performImmediateUpdate();
      });
    }
  }

  Future<void> startFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
      utils.successSnackBar(
        'Update Complete',
        'App has been updated successfully',
      );
    } catch (e) {
      debugPrint('Error with flexible update: $e');
    }
  }

  Future<bool> logout() async {
    utils.showLoadingDialog("Logging out...");
    try {
      Map<String, dynamic> model = {apiKeys.userID: userData.id};
      var response = await apiProvider.postRequest(apiEndPoints.logout, model);
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
      utils.closeLoadingDialog();
      return false;
    }
  }

  Future<bool> driverCheckAttendance() async {
    try {
      Map<String, dynamic> model = {apiKeys.feCode: userData.code};
      var response = await apiProvider.getRequestWithQueryParams(
        apiEndPoints.driverCheckAttendance,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        final attendance = AttendanceModel.fromJson(result.data);
        checkAttendance(attendance);
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e,stackTrace) {
      print("❌ FetchAvailable Exception: $e");
      print("❌ StackTrace: $stackTrace");
      utils.closeLoadingDialog();
      return false;
    }
  }

  Future<bool> getDashBoardData() async {
    try {
      Map<String, dynamic> model = {apiKeys.feCode: userData.code};
      var response = await apiProvider.getRequestWithQueryParams(
        apiEndPoints.dashBoardDetails,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        dashBoardData.value = DashBoardData.fromJson(result.data);
        if (dashBoardData.value.allOrdersCount?.aSSIGNED != 0 ||
            dashBoardData.value.allOrdersCount?.pICKED != 0 ||
            dashBoardData.value.allOrdersCount?.oFD != 0 ||
            dashBoardData.value.allOrdersCount?.reached != 0) {
          isAnyActiveOrder.value = true;
        } else {
          isAnyActiveOrder.value = false;
        }
        update();
        return true;
      } else {
        update();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> getC2CCDashBoardData() async {
    try {
      Map<String, dynamic> model = {apiKeys.feCode: userData.code};
      var response = await apiProvider.getRequestWithQueryParams(
        apiEndPoints.c2cDashBoardDetails,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        c2cDashBoardData.value = DashBoardData.fromJson(result.data);
        utils.closeLoadingDialog();
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      return false;
    }
  }

  Future<bool> getNextDelivery() async {
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: userData.code,
        //  apiKeys.channel: "ALL",
        apiKeys.status: [ASSIGNED, RE_ASSIGNED, PICKED, OFD,REACHED],
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.driverFetchOrderList,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        List<OrdersData> orders = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
        // orders.sort((a, b) =>
        //     remainingSecondsFor(a).compareTo(remainingSecondsFor(b)));
        nextDelivery.value = orders.isNotEmpty ? orders.first : null;
        upcomingOrders.value = orders.take(5).toList();
        return true;
      } else {
        nextDelivery.value = null;
        upcomingOrders.value = [];
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Seconds left in an order's SLA window (createdAt + sla_in_hours), used
  // to sort upcoming orders soonest-due-first and to show a "Due in" label.
  // Negative once the SLA has elapsed.
  int remainingSecondsFor(OrdersData order) {
    final slaHours = int.tryParse(order.sla_in_hours ?? "") ?? 0;
    final createdAt = order.createdAt;
    if (createdAt == null || createdAt.isEmpty) return slaHours * 3600;
    try {
      final elapsed = getSecondsDifference(parseUtcTime(createdAt));
      return (slaHours * 3600) - elapsed;
    } catch (_) {
      return slaHours * 3600;
    }
  }

  Future<bool> getWhatsAppDashBoardData() async {
    try {
      Map<String, dynamic> model = {apiKeys.feCode: userData.code};
      var response = await apiProvider.getRequestWithQueryParams(
        apiEndPoints.whatsAppDashBoardDetails,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        whatsAppDashBoardData.value = DashBoardData.fromJson(result.data);
        utils.closeLoadingDialog();
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      return false;
    }
  }

  Future<bool> fetchWalletAmount() async {
    try {
      Map<String, dynamic> model = {apiKeys.feCode: userData.code};
      var response = await apiProvider.getRequestWithQueryParams(
        apiEndPoints.fetchWalletAmount,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        walletAmount.value =
            (result.data?['total_cod'] ?? 0).toString();
        utils.closeLoadingDialog();
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      return false;
    }
  }

  Future<bool> getUserData() async {
    try {
      Map<String, dynamic> model = {apiKeys.feCode: userData.code};
      var response = await apiProvider.getRequestWithQueryParams(
        apiEndPoints.getProfileData,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        userData = UserData.fromJson(result.data);
        await userRepository.updateUser(userData);
        utils.closeLoadingDialog();
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      return false;
    }
  }

  Future<bool> markAttendance(bool status) async {
    utils.showLoadingDialog("loading ...");
    try {
      Map<String, dynamic> model = {
        apiKeys.userID: userData.id,
        apiKeys.markAttendance: status,
        apiKeys.latitude: startLocation?.latitude,
        apiKeys.longitude: startLocation?.longitude,
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.driverCheckIn,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        utils.closeLoadingDialog();
        workingHours.value = result.data["working_hours"].toString();
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  Future<bool> sendDriverLocation(LocationData locationData) async {
    try {
      Map<String, dynamic> model = {
        apiKeys.userID: userData.id,
        apiKeys.latitude: locationData.latitude,
        apiKeys.longitude: locationData.longitude,
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.driverCurrentLocation,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        //driverData.value = DriverData.fromJson(result.data);
        Future.delayed(const Duration(seconds: 2));
        //attendancesList.value = driverData.value.attendances!.reversed.toList();
      //  await getDashBoardData();
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  getCurrentLocation() async {
    final location = await locationUtils.getCurrentLocation();
    if (location == null) return;
    startLocation = location;
    currentLocation = location;
    await sendDriverLocation(location);
    print(
      'Current Location: ${location.latitude}, ${location.longitude}',
    );
  }

  getCountinuesLocation() {
    locationUtils.startListeningToLocationUpdates(
      onLocationChanged: (LocationData locationData) async {
        currentLocation = locationData;
        final baseline = startLocation;
        if (baseline == null) {
          startLocation = locationData;
          return;
        }
        double distance = calculateDistance(
          baseline.latitude!,
          baseline.longitude!,
          locationData.latitude!,
          locationData.longitude!,
        );
        if (kDebugMode) {
          print(
            "start latlng :- ${baseline.latitude},${baseline.longitude}\ncurrent latlng :-${locationData.latitude},${locationData.longitude}",
          );
        }
        print(distance.toString());
        if (distance >= 10) {
          bool isUpdated = await sendDriverLocation(locationData);
          if (isUpdated) {
            await getCurrentLocation();
          }
        }
      },
    );
  }

  // ---------------------------------------------------------------------
  // "New Requests" (unclaimed nearby orders) - same fetchPlacedOrders call
  // OrderListController.fetchAvailable() makes, kept separate so the
  // dashboard doesn't depend on that controller being registered.
  // ---------------------------------------------------------------------
  Future<void> fetchAvailableOrders() async {
    try {
      final location = currentLocation ?? await locationUtils.getCurrentLocation();
      Map<String, dynamic> model = {
        apiKeys.feCode: userData.code,
        apiKeys.latitude: location?.latitude,
        apiKeys.longitude: location?.longitude,
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.fetchPlacedOrders,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        availableOrders.value = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        availableOrders.value = [];
      }
    } catch (_) {
      availableOrders.value = [];
    }

    final ref = pendingFocusOrderRef;
    if (ref != null) {
      pendingFocusOrderRef = null;
      openAvailableOrderDetail(ref);
    }
  }

  bool isCod(OrdersData order) =>
      (order.paymentType ?? "").toLowerCase() == "cod";

  bool isAtRisk(OrdersData order) => remainingSecondsFor(order) < 1800;

  Future<bool> acceptRejectOrder(String type, String awbNo) async {
    utils.showLoadingDialog(
      type == acceptOrder ? "Accepting order..." : "Rejecting order...",
    );
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: userData.code,
        apiKeys.status: type,
        apiKeys.awbNo: awbNo,
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.acceptRejectOrder,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      if (result.status_code == 200) {
        availableOrders.removeWhere((o) => o.awbNo == awbNo);
        if (type == acceptOrder) {
          utils.successSnackBar(
            "Order Accepted",
            "Please find the accepted order under Assigned",
          );
          getDashBoardData();
          getNextDelivery();
        } else {
          utils.errorSnackBar(
            "Order Rejected",
            "This order no longer belongs to you",
          );
        }
        return true;
      } else {
        utils.errorSnackBar("Error", result.message.toString());
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
      return false;
    }
  }

  // Shared by the dashboard's "New Requests" cards and the "NearByOrders"
  // push-notification tap flow (see FirebaseNotifiactionController) - both
  // resolve against this same availableOrders list instead of each doing
  // their own fetch.
  Future<void> openAvailableOrderDetail(String orderRef) async {
    if (orderRef.isEmpty) return;
    if (availableOrders.isEmpty) {
      await fetchAvailableOrders();
    }
    OrdersData? match;
    for (final o in availableOrders) {
      if (o.orderRefNumber == orderRef || o.awbNo == orderRef) {
        match = o;
        break;
      }
    }
    if (match != null) {
      Get.toNamed(
        Routes.orderDetailScreen,
        arguments: match,
      )?.then((_) => fetchAvailableOrders());
    } else {
      utils.errorSnackBar("Order unavailable", "Order no longer available");
    }
  }

  // Clear profile fields
  void clearProfileFields() {
    avatar.value = null;
    address.clear();
    phone.clear();
    feCode.clear();
  }

  @override
  void onClose() {
    _notificationWorker?.dispose();
    address.dispose();
    phone.dispose();
    feCode.dispose();
    super.onClose();
  }
}
