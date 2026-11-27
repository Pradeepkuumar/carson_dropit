import 'package:carson_zyppy/core/network/qAddressApi.dart';
import 'package:carson_zyppy/core/network/api_service.dart';
import 'package:carson_zyppy/utils/utils.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/api_keys.dart';
import '../core/network/api_urls.dart';
import '../firebase_notifications/notification_model/notification.dart';
import '../local_db/user_repo.dart';


final box = GetStorage();
final utils = Utils();
final ApiServices apiProvider = ApiServices();
final Qaddressapi qaddressapi = Qaddressapi();
final ApiKeys apiKeys = ApiKeys();
final ApiUrls apiEndPoints = ApiUrls();
final ImagePicker imagePicker = ImagePicker();
final UserRepository userRepository = Get.find<UserRepository>();



List<LocalNotification> notifications = [];

void addNotification(LocalNotification notification) {
    notifications.insert(0, notification);
}
