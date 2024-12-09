import 'package:carson_zyppy/global/consts.dart';
import 'package:carson_zyppy/utils/utils.dart';
import 'package:get/get.dart';

import '../../apis/base_api_response.dart';
import '../../app_pages/app_pages.dart';
import '../../global/global.dart';


class AuthController extends GetxController {

  var isLoading = true.obs;
  var showSplashScreen = true.obs;
  var userId = 0.obs;

  @override
  void onInit() {
   getUser();
   Future.delayed(Duration(seconds: 3), () {
     showSplashScreen.value = false;
   });
    super.onInit();
  }

  getUser() async {
    try {
       userId.value = box.read(USER_ID_KEY) ;
    } catch (e){
      utils.errorSnackBar("Exception", e.toString());
    }

  }


  Future<bool> login() async {
    utils.showLoadingDialog("Logging in...");
    try {
      Map<String, dynamic> model = {
        'fecode': "CL_FAYIS01",
        'password': "1234",
        'device_token': "1234qwrsf234512232fwdfwqt",
      };
      var response = await apiProvider
          .postRequest(apiEndPoints.login, model );
      var result = BaseApiResponse.fromJson(response);
      utils.closeLoadingDialog();
      box.write(USER_ID_KEY, 1);

      update();
      return true;
    } catch (e) {

      utils.closeLoadingDialog();
      utils.errorSnackBar("Exception", e.toString());
      return false;
    }
  }



  @override
  void onClose() {}
}


