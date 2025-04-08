import 'dart:math';

import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/pages/dashboard/models/dashboard_data.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../apis/base_api_response.dart';
import '../../../global/global.dart';
import '../../../global/location_service.dart';
import '../models/driver_data.dart';

class RiderDashboardController extends GetxController {
  var isLoading = true.obs;
  var showSplashScreen = true.obs;
  var userData = UserData();
  var firebaseToken = "";
  var riderName = "".obs;
  var isAttendanceMarked = false.obs;
  final locationUtils = LocationUtils();
  late LocationData startLocation;
  var workingHours = "".obs;
  var walletAmount = "".obs;
  var isInternetOn = false.obs;
  var updateRiderLocation = false.obs;
  var driverData = DriverData().obs;
  var dashBoardData = DashBoardData().obs;
  var isAttendanceLoaded = false.obs;
  var attendancesList = [].obs;


  @override
  void onInit() {
    requestBackgroundPermission();
    getUser();
    updateLocation();
    super.onInit();
  }

  // final listener = InternetConnection().onStatusChange.listen((InternetStatus status) {
  //   switch (status) {
  //     case InternetStatus.connected:
  //       break;
  //     case InternetStatus.disconnected:
  //       utils.nonCancellableDialog("Please Enable Internet");
  //       break;
  //   }
  // });

  updateLocation() async {
    await getCurrentLocation();
    checkAttendance();
    await getCountinuesLocation();
    await fetchWalletAmount();
  }

  void checkAttendance() {
    if (driverData.value.attendances?.last.markAttendance == 1) {
      isAttendanceMarked.value = true;
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
        await getDashBoardData();
      }
    } catch (e) {
      //  utils.errorSnackBar("Exception", e.toString());
    }
  }

  Future<bool> logout() async {
    utils.showLoadingDialog("Logging out...");
    try {
      Map<String, dynamic> model = {
        apiKeys.userID: userData.id,
      };
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
      //  utils.errorSnackBar("Exception", e.toString());
      return false;
    }
  }

  Future<bool> getDashBoardData() async {
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: userData.code,
      };
      var response = await apiProvider.getRequestWithQueryParams(
          apiEndPoints.dashBoardDetails, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        dashBoardData.value = DashBoardData.fromJson(result.data);
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
      //   utils.errorSnackBar("Exception", e.toString());
      return false;
    }
  }

  Future<bool> fetchWalletAmount() async {
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: userData.code,
      };
      var response = await apiProvider.getRequestWithQueryParams(
          apiEndPoints.fetchWalletAmount, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        walletAmount.value = result.data.toString();
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
        apiKeys.latitude: startLocation.latitude,
        apiKeys.longitude: startLocation.longitude
      };
      var response =
          await apiProvider.postRequest(apiEndPoints.driverCheckIn, model);
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
      //utils.errorSnackBar("Exception", e.toString());
      return false;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
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
        apiKeys.longitude: locationData.longitude
      };
      var response = await apiProvider.postRequest(
          apiEndPoints.driverCurrentLocation, model);
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        driverData.value = DriverData.fromJson(result.data);
        attendancesList.value = driverData.value.attendances!.reversed.toList();
        // print(driverData.value.toJson().toString());
        await getDashBoardData();
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

  // @override
  // void onClose() {
  //   listener.cancel();
  // }

  getCurrentLocation() async {
    startLocation = (await locationUtils.getCurrentLocation())!;
    await sendDriverLocation(startLocation);
    print(
        'Current Location: ${startLocation.latitude}, ${startLocation.longitude}');
    }

  getCountinuesLocation() {
    locationUtils.startListeningToLocationUpdates(
      onLocationChanged: (LocationData locationData) async {
        double distance = calculateDistance(
            startLocation.latitude!,
            startLocation.longitude!,
            locationData.latitude!,
            locationData.longitude!);
        if (kDebugMode) {
          print(
              "start latlng :- ${startLocation.latitude},${startLocation.longitude}\ncurrent latlng :-${locationData.latitude},${locationData.longitude}");
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
}
