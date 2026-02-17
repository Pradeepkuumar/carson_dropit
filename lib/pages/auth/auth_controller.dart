import 'package:carson_zyppy/firebase_notifications/firebase_notifiction_controller.dart';
import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../apis/base_api_response.dart';
import '../../global/global.dart';
import '../../local_db/entity/UserData.dart';


class AuthController extends GetxController {
  var isLoading = true.obs;
  var showSplashScreen = true.obs;
  var userId = 0.obs;
  var userData =  UserData();
  final TextEditingController feCode =  TextEditingController();
  final TextEditingController password =  TextEditingController();
  FirebaseMessagingController? firebaseNotificationController;
  var fcmToken = "".obs;
  var isTokenLoaded = false.obs;


  @override
  void onInit() {
    getUser();
    Future.delayed(const Duration(seconds: 3), () {
      showSplashScreen.value = false;
    });  
    super.onInit();
  }

  @override
  void onReady() async {
    await getFireBaseToken();
    super.onReady();
  } 

  getFireBaseToken() async{
    utils.showLoadingDialog("Loading please wait...");
    await  firebaseNotificationController?.getFCMTokenWithRetry();
    await Future.delayed(const Duration(seconds: 5), () async{
       firebaseNotificationController =  Get.find<FirebaseMessagingController>();
       fcmToken.value = firebaseNotificationController?.fcm_token ?? "";
       utils.closeLoadingDialog();
     });
     if(fcmToken.value != ""){
       isTokenLoaded.value = true;
     }
  }
   


  getUser() async {
    try {
       userId.value = box.read(USER_ID_KEY);
      
    } catch (e){
     // utils.errorSnackBar("Exception", e.toString());
    }

  }

  


  Future<bool> login() async {
      utils.showLoadingDialog("loading...");
    try {
      Map<String, dynamic> model = {
        apiKeys.feCode: feCode.value.text,
        apiKeys.password: password.value.text,
        apiKeys.deviceToken: box.read(apiKeys.fcmToken) ?? fcmToken,
      };
      var response = await apiProvider
          .postRequest(apiEndPoints.login, model );
      var result = BaseApiResponse.fromJson(response);
      if (result.status_code == 200) {
        userData = UserData.fromJson(result.data);
        box.write(apiKeys.apiToken, userData.apiToken);
        box.write(apiKeys.feCode, userData.code);
        await userRepository.deleteUser();
        await userRepository.saveUser(userData);
        utils.closeLoadingDialog();
        update();
        return true;
      } else {
        utils.closeLoadingDialog();
        utils.errorDialog(result.message.toString());
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


