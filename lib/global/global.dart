import 'package:carson_zyppy/apis/qAddressApi.dart';
import 'package:carson_zyppy/utils/utils.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../apis/api_end_points.dart';
import '../apis/api_keys.dart';
import '../apis/base_api_provider.dart';
import '../firebase_notifications/notification_model/notification.dart';
import '../local_db/user_repo.dart';


final box = GetStorage();
final utils = Utils();
final ApiProvider apiProvider = ApiProvider();
final Qaddressapi qaddressapi = Qaddressapi();
final ApiKeys apiKeys = ApiKeys();
final ApiEndPoints apiEndPoints = ApiEndPoints();
final ImagePicker imagePicker = ImagePicker();
final UserRepository userRepository = Get.find<UserRepository>();



List<LocalNotification> notifications = [];

void addNotification(LocalNotification notification) {
    notifications.insert(0, notification);
}
