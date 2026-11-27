import 'package:carson_zyppy/firebase_notifications/firebase_notifiction_controller.dart';
import 'package:carson_zyppy/global/consts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/network/base_api_response.dart';
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

  Future<String?> getFireBaseToken() async {
    try {
      firebaseNotificationController ??= Get.find<FirebaseMessagingController>();
      await firebaseNotificationController!.getFCMTokenWithRetry()
          .timeout(const Duration(seconds: 18));
      final token = firebaseNotificationController!.fcm_token;
      fcmToken.value = token ?? "";
      isTokenLoaded.value = token != null && token.isNotEmpty;
      return isTokenLoaded.value ? token : null;
    } catch (e) {
      fcmToken.value = "";
      isTokenLoaded.value = false;
      return null;
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
    if (kDebugMode) debugPrint('[FCM_LIFECYCLE] Login flow started');
    utils.showLoadingDialog("Signing in...");
    try {
      final token = await getFireBaseToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('[FCM_LIFECYCLE] Login blocked: FCM token unavailable');
        }
        utils.closeLoadingDialog();
        utils.errorSnackBar(
          "Notifications unavailable",
          "Could not get a device token. Check your connection and retry.",
        );
        return false;
      }

      if (kDebugMode) {
        debugPrint('[FCM_LIFECYCLE] FCM token available for login registration');
      }
      final model = <String, dynamic>{
        apiKeys.feCode: feCode.text.trim(),
        apiKeys.password: password.text,
        apiKeys.deviceToken: token,
      };
      if (kDebugMode) {
        debugPrint(
          '[FCM_LIFECYCLE] Submitting device token through ${apiEndPoints.login}: fingerprint=${token.hashCode}',
        );
      }
      final response = await apiProvider.postRequest(apiEndPoints.login, model)
          .timeout(const Duration(seconds: 25));
      final result = BaseApiResponse.fromJson(response);
      if (kDebugMode) {
        debugPrint(
          '[FCM_LIFECYCLE] Login response status=${result.status_code}',
        );
      }
      if (result.status_code == 200) {
        userData = UserData.fromJson(result.data);
        if (kDebugMode) {
          final returnedTokenMatches = userData.deviceToken == token;
          debugPrint(
            '[FCM_LIFECYCLE] Backend rider registration: riderId=${userData.id}; returned device token present=${(userData.deviceToken ?? '').isNotEmpty}; returned token matches submitted=${returnedTokenMatches}',
          );
        }
        box.write(apiKeys.apiToken, userData.apiToken);
        box.write(apiKeys.feCode, userData.code);
        box.write('fcm_registered_token', token);
        await userRepository.deleteUser();
        await userRepository.saveUser(userData);
        if (kDebugMode) {
          debugPrint(
            '[FCM_LIFECYCLE] Login succeeded; submitted token fingerprint=${token.hashCode}; local registration marker saved; api token available=${(box.read(apiKeys.apiToken) ?? '').toString().isNotEmpty}',
          );
        }
        utils.closeLoadingDialog();
        return true;
      }

      if (kDebugMode) {
        debugPrint('[FCM_LIFECYCLE] Login failed: status=${result.status_code}');
      }
      utils.closeLoadingDialog();
      utils.errorDialog(result.message.toString());
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM_LIFECYCLE] Login exception: $e');
      utils.closeLoadingDialog();
      utils.errorSnackBar(
        "Login failed",
        "Unable to complete sign in. Check your connection and retry.",
      );
      return false;
    }
  }

  @override
  void onClose() {}
}


