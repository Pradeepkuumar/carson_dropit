import 'dart:io';
import 'dart:math';
import 'package:carson_zyppy/core/network/api_keys.dart';
import 'package:carson_zyppy/firebase_notifications/firebase_notifiction_controller.dart';
import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/dashboard/models/dashboard_data.dart';
import 'package:carson_zyppy/pages/my_orders/orders/models/orders_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/network/base_api_response.dart';
import '../../../app_pages/app_pages.dart';
import '../../../global/consts.dart';
import '../../../global/cancelled_orders.dart';
import '../../../global/global.dart';
import '../../../global/location_service.dart';
import '../../../global/order_delivered_dialog.dart';
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
  // Sign In stays disabled until a lat/lng fix is in hand - see
  // syncLocation() and the guard at the top of markAttendance().
  var isLocationSynced = false.obs;
  var isSyncingLocation = false.obs;
  var syncedLatLng = "".obs;
  Future<void>? _locationSyncFuture;
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
  // A notification tap can arrive before this controller is registered or
  // before its first data load finishes (cold start) - the awb is stashed
  // here and opened by consumePendingNotificationOrder() once getUser()'s
  // initial load is done, instead of the notification tap being dropped.
  static String? pendingFocusOrderRef;
  bool _initialLoadDone = false;
  bool _dashboardIdentityLoaded = false;
  var checkBoxValue = false.obs;
  RxBool isConsentGiven = RxBool(false);
  late FirebaseMessagingController firebaseMessagingController;
  Worker? _notificationWorker;
  Worker? _cancelWorker;
  int _handledNotificationRevision = 0;
  int _pendingNotificationRevision = 0;
  bool _notificationRefreshInProgress = false;
  // Name of the route RiderDashboard sits on, set by the view - it isn't
  // always Routes.riderDashBord (see AppBottomNav), and it's compared with
  // Get.currentRoute to tell whether the dashboard is the screen on top.
  String? dashboardRouteName;
  // Every assigned order from the last getNextDelivery (upcomingOrders only
  // keeps 5) - compared on resume to spot orders cancelled meanwhile.
  List<OrdersData> _assignedOrders = [];
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
    // Get.isDarkMode reads Theme.of(context), which MaterialApp cross-fades
    // over kThemeAnimationDuration and only flips brightness midway through.
    // Flipping isDarkMode.value before that fade ends makes screens' Obx
    // rebuilds read a stale Get.isDarkMode, leaving text colors (from
    // utils.tvCustom, which reads Get.isDarkMode directly) stuck on the old
    // theme - so wait for the fade to finish first.
    Get.changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
    box.write(THEME_MODE_KEY, dark ? 'dark' : 'light');
    Future.delayed(kThemeAnimationDuration, () {
      isDarkMode.value = dark;
    });
  }

  void _locationLog(String source, String message) {
    if (kDebugMode) {
      final tag = source == 'auto' ? 'AUTO_LOCATION' : 'MANUAL_LOCATION';
      debugPrint('[$tag] $message');
    }
  }

  @override
  void onInit() {
    _locationLog(
      'auto',
      'Controller onInit instance=${identityHashCode(this)}; auth token available=${(box.read(apiKeys.apiToken) ?? '').toString().isNotEmpty}',
    );
    getUser();
    loadUserDetails();
    super.onInit();
  }

  @override
  void onReady() {
    isConsentGiven.value = box.read("isConsentGiven") ?? false;
    _locationLog(
      'auto',
      'Controller onReady instance=${identityHashCode(this)}; consent=${isConsentGiven.value}; auth token available=${(box.read(apiKeys.apiToken) ?? '').toString().isNotEmpty}',
    );
    // Authenticated profile and location calls start after getUser() loads
    // the persisted login identity and attendance state.
    firebaseMessagingController = Get.find<FirebaseMessagingController>();
    _notificationWorker = ever(
      firebaseMessagingController.notificationRevision,
          (int revision) => _queueNotificationRefresh(revision),
    );
    if (firebaseMessagingController.notificationRevision.value >
        _handledNotificationRevision) {
      _queueNotificationRefresh(
        firebaseMessagingController.notificationRevision.value,
      );
    }
    _cancelWorker = ever(firebaseMessagingController.onOrderCancelled, (
        Map<String, dynamic>? data,
        ) {
      if (data != null) _onOrderCancelledPush(data);
    });
    checkForUpdate();
    super.onReady();
  }

  void _queueNotificationRefresh(int revision) {
    if (revision > _pendingNotificationRevision) {
      _pendingNotificationRevision = revision;
    }
    if (!_dashboardIdentityLoaded || !_initialLoadDone) return;
    if (_notificationRefreshInProgress) return;
    _notificationRefreshInProgress = true;
    _drainNotificationRefreshes();
  }

  Future<void> _drainNotificationRefreshes() async {
    try {
      while (_handledNotificationRevision < _pendingNotificationRevision) {
        final revision = _pendingNotificationRevision;
        _locationLog(
          'auto',
          'Refreshing available orders for notification revision=$revision',
        );
        await Future.wait([
          getDashBoardData(),
          getNextDelivery(),
          fetchAvailableOrders(source: 'auto'),
        ]);
        _handledNotificationRevision = revision;
        final latestRevision =
            firebaseMessagingController.notificationRevision.value;
        if (latestRevision > _pendingNotificationRevision) {
          _pendingNotificationRevision = latestRevision;
        }
      }
    } catch (e, stackTrace) {
      _locationLog('auto', 'Notification order refresh failed: $e\n$stackTrace');
      // Do not spin on a persistent network failure; app resume or the next
      // notification will initiate the next refresh attempt.
      _handledNotificationRevision = _pendingNotificationRevision;
    } finally {
      _notificationRefreshInProgress = false;
      firebaseMessagingController.onNewNotification.value = false;
      if (_handledNotificationRevision < _pendingNotificationRevision) {
        _queueNotificationRefresh(_pendingNotificationRevision);
      }
    }
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
    // One-shot fix only (needed for the check-in lat/lng) - the continuous
    // background stream starts once attendance is marked, see
    // startLocationTracking().
    await syncLocation(source: 'auto');
    if (isAttendanceMarked.value) {
      await startLocationTracking();
    }
    await walletFuture;
  }

  Future<void> startLocationTracking() async {
    if (!isConsentGiven.value) return;
    await getCountinuesLocation();
  }

  Future<void> stopLocationTracking() async {
    await locationUtils.stopListeningToLocationUpdates();
  }

  void checkAttendance(AttendanceModel attendance) {
    print(attendance.markAttendance);
    if (attendance.markAttendance ?? false) {
      isAttendanceMarked.value = true;
    } else {
      isAttendanceMarked.value = false;
      stopLocationTracking();
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
        _dashboardIdentityLoaded = true;
        riderName.value = userData.name ?? "";
        loadUserDetails(); // Reload details when user data changes
        _locationLog(
          'auto',
          'Stored user loaded: id=${userData.id}; fe_code available=${(userData.code ?? '').isNotEmpty}',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            _locationLog('auto', 'Initial attendance request started');
            final attendanceLoaded = await driverCheckAttendance();
            _locationLog(
              'auto',
              'Initial attendance request completed: success=$attendanceLoaded; onDuty=${isAttendanceMarked.value}',
            );

            // Use the exact one-shot flow used by the dashboard button, now
            // that user identity and attendance state are ready.
            await syncLocation(source: 'auto');

            if (isConsentGiven.value) {
              await getUserData();
              await requestBackgroundPermission();
              if (isAttendanceMarked.value) {
                await startLocationTracking();
              }
            }

            await Future.wait([
              fetchWalletAmount(),
              getDashBoardData(),
              getNextDelivery(),
              fetchAvailableOrders(),
            ]);
          } catch (e, stackTrace) {
            _locationLog('auto', 'Dashboard initialization error: $e\n$stackTrace');
          } finally {
            _initialLoadDone = true;
            final pendingRevision =
                firebaseMessagingController.notificationRevision.value;
            if (pendingRevision > _handledNotificationRevision) {
              _queueNotificationRefresh(pendingRevision);
            }
            consumePendingNotificationOrder();
          }
        });
      } else {
        _locationLog('auto', 'No persisted login user found; skipping automatic location sync');
      }
    } catch (e) {
      _locationLog('auto', 'Stored user lookup failed: $e');
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
      _locationLog(
        'auto',
        'Attendance API request started: userId=${userData.id}; fe_code available=${(userData.code ?? '').isNotEmpty}; auth token available=${(box.read(apiKeys.apiToken) ?? '').toString().isNotEmpty}',
      );
      Map<String, dynamic> model = {apiKeys.feCode: userData.code};
      var response = await apiProvider.getRequestWithQueryParams(
        apiEndPoints.driverCheckAttendance,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      _locationLog(
        'auto',
        'Attendance API response status=${result.status_code}',
      );
      if (result.status_code == 200) {
        final attendance = AttendanceModel.fromJson(result.data);
        checkAttendance(attendance);
        _locationLog(
          'auto',
          'Attendance state updated: onDuty=${isAttendanceMarked.value}',
        );
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
        _assignedOrders = orders;
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
  // int remainingSecondsFor(OrdersData order) {
  //   final slaHours = int.tryParse(order.sla_in_hours ?? "") ?? 0;
  //   final createdAt = order.createdAt;
  //   if (createdAt == null || createdAt.isEmpty) return slaHours * 3600;
  //   try {
  //     final elapsed = getSecondsDifference(parseUtcTime(createdAt));
  //     return (slaHours * 3600) - elapsed;
  //   } catch (_) {
  //     return slaHours * 3600;
  //   }
  // }

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
    if (status &&
        (startLocation?.latitude == null || startLocation?.longitude == null)) {
      utils.errorSnackBar(
        "Location not found",
        "Sync your location before signing in.",
      );
      return false;
    }
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
        isAttendanceMarked.value = status;
        if (status) {
          await startLocationTracking();
        } else {
          await stopLocationTracking();
        }
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

  Future<bool> sendDriverLocation(
      LocationData locationData, {
        String source = 'manual',
      }) async {
    try {
      final model = <String, dynamic>{
        apiKeys.userID: userData.id,
        apiKeys.latitude: locationData.latitude,
        apiKeys.longitude: locationData.longitude,
      };
      _locationLog(
        source,
        'Location API request started: endpoint=${apiEndPoints.driverCurrentLocation}; payload=$model; auth token available=${(box.read(apiKeys.apiToken) ?? '').toString().isNotEmpty}',
      );
      final response = await apiProvider.postRequest(
        apiEndPoints.driverCurrentLocation,
        model,
      );
      final result = BaseApiResponse.fromJson(response);
      _locationLog(
        source,
        'Location API response: status=${result.status_code}; success=${result.status_code == 200}',
      );
      if (result.status_code == 200) {
        _locationLog(source, 'Location API succeeded');
        //driverData.value = DriverData.fromJson(result.data);
        Future.delayed(const Duration(seconds: 2));
        //attendancesList.value = driverData.value.attendances!.reversed.toList();
        //  await getDashBoardData();
        update();
        return true;
      } else {
        _locationLog(source, 'Location API rejected location');
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e, stackTrace) {
      _locationLog(source, 'Location API error: $e\n$stackTrace');
      return false;
    }
  }

  // One-shot fix that drives the Sign In card's "Finding your location..."
  // / "Location synced" / "Location not found" states.
  Future<void> syncLocation({String source = 'manual'}) {
    final inFlight = _locationSyncFuture;
    if (inFlight != null) {
      _locationLog(source, 'Sync joined existing request');
      return inFlight;
    }

    _locationLog(
      source,
      'Sync started; controller instance=${identityHashCode(this)}; location service instance=${identityHashCode(locationUtils)}',
    );
    isSyncingLocation.value = true;
    isLocationSynced.value = false;
    syncedLatLng.value = "";
    _locationLog(source, 'State changed: syncing=true, synced=false');
    final sync = _syncLocationOnce(source);
    _locationSyncFuture = sync;
    return sync.whenComplete(() {
      isSyncingLocation.value = false;
      _locationSyncFuture = null;
      _locationLog(
        source,
        'State changed: syncing=false, synced=${isLocationSynced.value}',
      );
    });
  }

  Future<void> _syncLocationOnce(String source) async {
    try {
      await getCurrentLocation(source: source)
          .timeout(const Duration(seconds: 35));
    } catch (e, stackTrace) {
      _locationLog(source, 'Sync failed/timeout: $e\n$stackTrace');
      isLocationSynced.value = false;
    }
  }

  Future<void> getCurrentLocation({String source = 'manual'}) async {
    _locationLog(source, 'Current position request started');
    final location = await locationUtils.getCurrentLocation(source: source);
    if (location == null ||
        location.latitude == null ||
        location.longitude == null) {
      _locationLog(
        source,
        'Current position unavailable (service/permission/GPS failure); provider synced=false',
      );
      isLocationSynced.value = false;
      syncedLatLng.value = "";
      return;
    }
    _locationLog(
      source,
      'Current position received: lat=${location.latitude}, lng=${location.longitude}',
    );

    startLocation = location;
    currentLocation = location;

    // Only report the rider's position to the server while on duty. In that
    // case, don't show "synced" until the existing API confirms acceptance.
    if (isAttendanceMarked.value) {
      if (!await sendDriverLocation(location, source: source)) {
        isLocationSynced.value = false;
        syncedLatLng.value = "";
        _locationLog(
          source,
          'Provider state updated: synced=false because location API failed',
        );
        return;
      }
    } else {
      _locationLog(
        source,
        'Location API skipped because rider is not on duty (existing behavior)',
      );
    }

    isLocationSynced.value = true;
    syncedLatLng.value =
    "${location.latitude!.toStringAsFixed(4)}, ${location.longitude!.toStringAsFixed(4)}";
    _locationLog(
      source,
      'Provider state updated: synced=true; syncedLatLng=${syncedLatLng.value}; onDuty=${isAttendanceMarked.value}',
    );
  }

  Future<void> getCountinuesLocation() async {
    await locationUtils.startListeningToLocationUpdates(
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
  Future<void> fetchAvailableOrders({String source = 'manual'}) async {
    _locationLog(source, 'Available orders fetch started');
    try {
      final location =
          currentLocation ?? await locationUtils.getCurrentLocation();
      double? latitude = location?.latitude;
      double? longitude = location?.longitude;
      if (latitude == null || longitude == null) {
        try {
          final last = await geo.Geolocator.getLastKnownPosition();
          latitude = last?.latitude;
          longitude = last?.longitude;
        } catch (_) {}
      }
      // The API rejects a request without latitude/longitude.
      if (latitude == null || longitude == null) {
        availableOrders.value = [];
        return;
      }
      Map<String, dynamic> model = {
        apiKeys.feCode: userData.code,
        apiKeys.latitude: latitude,
        apiKeys.longitude: longitude,
      };
      var response = await apiProvider.postRequest(
        apiEndPoints.fetchPlacedOrders,
        model,
      );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200 && result.data != null) {
        availableOrders.value = (result.data as List)
            .map((json) => OrdersData.fromJson(json as Map<String, dynamic>))
            .where((order) =>
        order.is_assigned_to_other != true &&
            order.is_accepted_by_other != true)
            .toList();
        _locationLog(
          source,
          'Available orders API succeeded: status=${result.status_code}; visibleOrders=${availableOrders.length}',
        );
      } else {
        availableOrders.value = [];
        _locationLog(
          source,
          'Available orders API failed: status=${result.status_code}; visibleOrders=0',
        );
      }
    } catch (e, stackTrace) {
      availableOrders.value = [];
      _locationLog(source, 'Available orders fetch error: $e\n$stackTrace');
    }
  }

  bool isCod(OrdersData order) =>
      (order.paymentType ?? "").toLowerCase() == "cod";

  bool isAtRisk(OrdersData order) => order.is_at_risk ?? false;

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
        await fetchAvailableOrders();
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
        if (type == acceptOrder) {
          await fetchAvailableOrders();
        }
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
        arguments: match.awbNo,
      )?.then((_) => fetchAvailableOrders());
    } else {
      utils.errorSnackBar("Order unavailable", "Order no longer available");
    }
  }

  // Opens the order stashed in pendingFocusOrderRef by a notification tap -
  // no-op until the initial dashboard load has finished (getUser()), which
  // calls this again itself once it has.
  void consumePendingNotificationOrder() {
    if (!_initialLoadDone) return;
    final ref = pendingFocusOrderRef;
    if (ref == null || ref.isEmpty) return;
    pendingFocusOrderRef = null;
    openOrderFromNotification(ref);
  }

  // Notification tap (any type) -> order detail by its awb_number; the
  // detail screen fetches the order itself (driver/order-details).
  void openOrderFromNotification(String orderRef) {
    if (orderRef.isEmpty) return;
    // Land on the dashboard first, whatever was open on top of it.
    Get.until((route) => route.isFirst);
    Get.toNamed(Routes.orderDetailScreen, arguments: orderRef)?.then((_) {
      fetchAvailableOrders();
      getDashBoardData();
      getNextDelivery();
    });
  }

  // The _notificationWorker above already re-fetches the dashboard for this
  // push - this drops the order from the upcoming list right away and tells
  // the rider, but only while the dashboard is the screen on top (the order
  // list / active delivery screens show their own dialog).
  void _onOrderCancelledPush(Map<String, dynamic> data) {
    final ref = (data['awb_number'] ?? data['awb_no'] ?? '').toString();
    if (ref.isEmpty) return;
    final reason = (data['reason'] ?? data['cancel_reason'])?.toString();
    final current = nextDelivery.value;
    final match =
        upcomingOrders.firstWhereOrNull((o) => o.awbNo == ref) ??
            (current?.awbNo == ref ? current : null);
    upcomingOrders.removeWhere((o) => o.awbNo == ref);
    _assignedOrders = _assignedOrders.where((o) => o.awbNo != ref).toList();
    if (!_isOnTop) return;
    if (!markCancellationNotified(ref)) return;
    showOrderCancelledDialog(
      order: match ?? OrdersData(awbNo: ref),
      reason: reason,
      buttonLabel: "Got it",
      onContinue: () {},
    );
  }

  bool get _isOnTop =>
      dashboardRouteName != null && Get.currentRoute == dashboardRouteName;

  // App back in the foreground - cancel pushes received in the background
  // never reached the workers, so re-sync and announce any assigned order
  // that disappeared because it was cancelled.
  Future<void> onAppResumed() async {
    getDashBoardData();
    await fetchAvailableOrders(source: 'auto');
    final before = _assignedOrders;
    if (!await getNextDelivery()) return;
    final nowKeys = _assignedOrders.map((o) => o.awbNo).toSet();
    final gone = before.where((o) => !nowKeys.contains(o.awbNo)).toList();
    await showCancelledOrdersAmong(
      gone,
      userData.code ?? "",
      isStillOnTop: () => _isOnTop,
    );
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
    _cancelWorker?.dispose();
    stopLocationTracking();
    address.dispose();
    phone.dispose();
    feCode.dispose();
    super.onClose();
  }
}
