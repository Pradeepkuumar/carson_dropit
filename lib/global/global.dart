import 'package:carson_zyppy/utils/utils.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../apis/api_end_points.dart';
import '../apis/base_api_provider.dart';


// Global packages initialize them once and then user anyWhere in app.
final box = GetStorage();
final utils = Utils();
final ApiProvider apiProvider = ApiProvider();
final ApiEndPoints apiEndPoints = ApiEndPoints();
final ImagePicker imagePicker = ImagePicker();
//final LoadingController loadingDialog = Get.find<LoadingController>();




// List<LocalNotification> notifications = [];
//
// void addNotification(LocalNotification notification) {
//     notifications.insert(0, notification);
// }
