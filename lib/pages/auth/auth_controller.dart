import 'package:carson_zyppy/consts.dart';
import 'package:get/get.dart';

import '../../apis/base_api_response.dart';
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


  Future<void> login() async {
    try {
      Map<String, dynamic> model = {
        'fe_code': "",
        'password': "",
      };
      var response = await apiProvider
          .postRequest(apiEndPoints.login, model );
      var result = BaseApiResponse.fromJson(response);
     // dashBoardData =  CustomerDashBoardData.fromJson(result.data);
      isLoading.value = false;
      update();
      return response;
    } catch (e) {
      utils.errorSnackBar("Exception", e.toString());
    }
  }



  @override
  void onClose() {}
}


