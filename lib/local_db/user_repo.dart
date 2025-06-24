
import '../firebase_notifications/notification_model/notification.dart';
import 'entity/UserData.dart';

abstract class UserRepository {
  Future<void> saveUser(UserData userData);

  Future<void> updateUser(UserData userData);
  
  Future<UserData?> getUser();

  Future<void> deleteUser();

  Future<void>  saveNotification(LocalNotification notificationModel);

  Future<void>  deleteNotification();

  Future<LocalNotification?> getAllNotification();


}
