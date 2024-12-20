import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/local_db/entity/UserData.dart';
import 'package:carson_zyppy/utils/utils.dart';
import 'package:get/get.dart';

import '../../apis/base_api_response.dart';
import '../../app_pages/app_pages.dart';
import '../../global/global.dart';


class RiderDashboardController extends GetxController {

  var isLoading = true.obs;
  var showSplashScreen = true.obs;
  var userData = UserData();
  var firebaseToken = "";
  var riderName  = "".obs;
  var isAttendanceMarked = false.obs;

  @override
  void onInit() {
    getUser();
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



  @override
  void onClose() {}
}


