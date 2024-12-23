import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/utils/utils.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';

import '../../apis/base_api_response.dart';
import '../../app_pages/app_pages.dart';
import '../../global/global.dart';
import '../../global/location_service.dart';


class RiderDashboardController extends GetxController {

  var isLoading = true.obs;
  var showSplashScreen = true.obs;
  var userData = UserData();
  var firebaseToken = "";
  var riderName  = "".obs;
  var isAttendanceMarked = false.obs;
  final locationUtils = LocationUtils();
  late LocationData currentLocation;
  var workingHours  = "".obs;
  var walletAmount  = "".obs;


  @override
  void onInit() {
    getUser();
    getCurrentLocation();
    getCountinuesLocation();
    super.onInit();
  }


  getUser() async {
    try {
      var value = await userRepository.getUser();
      if (value != null) {
        userData = value;
        riderName.value = userData.name ?? "";
      }
    } catch (e){
      utils.errorSnackBar("Exception", e.toString());
    }

  }






  Future<bool> logout() async {
    utils.showLoadingDialog("Logging out...");
    try {
      Map<String, dynamic> model = {
        apiKeys.userID: userData.id,
      };
      var response = await apiProvider.postRequest(apiEndPoints.logout, model );
      var result = BaseApiResponse.fromJson(response);
      if(result.status_code == 200){
        utils.closeLoadingDialog();
        update();
        return true;
      }else{
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
      return false;
    }
  }

  Future<bool> markAttendance(bool status) async {
    utils.showLoadingDialog("loading ...");
    try {
      Map<String, dynamic> model = {
        apiKeys.userID: userData.id,
        apiKeys.markAttendance : status,
        apiKeys.latitude : currentLocation.latitude,
        apiKeys.longitude : currentLocation.longitude
      };
      var response = await apiProvider.postRequest(apiEndPoints.driverCheckIn, model );
      var result = BaseApiResponse.fromJson(response);
      if(result.status_code == 200){
        utils.closeLoadingDialog();
        workingHours.value =  result.data["working_hours"].toString();
        update();
        return true;
      }else{
        utils.closeLoadingDialog();
        update();
        return false;
      }
    } catch (e) {
      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
      return false;
    }
  }



  @override
  void onClose() {}

  void getCurrentLocation() async {
    currentLocation = (await locationUtils.getCurrentLocation())!;
      if (currentLocation != null) {
    print('Current Location: ${currentLocation.latitude}, ${currentLocation.longitude}');
  } else {
    print('Unable to fetch location.');
  }

  }

  void getCountinuesLocation(){
    locationUtils.startListeningToLocationUpdates(
      onLocationChanged: (LocationData locationData) {
        print('Location Updated: ${locationData.latitude}, ${locationData.longitude}');
      },
    );
  }
}


