

import '../../../firebase_notifications/notification_model/notification.dart';
import '../../dataBase/database.dart';
import '../../entity/UserData.dart';
import '../../user_repo.dart';

class FloorUserRepository implements UserRepository {
  final AppDatabase _db;
  FloorUserRepository(this._db);

  @override
  Future<void> saveUser(UserData user) async {
    await _db.userDao.saveUser(user);
  }

  @override
  Future<UserData?> getUser() async {
    return await _db.userDao.getUser();
  }

  @override
  Future<void> deleteUser() async {
    return await _db.userDao.deleteUser();
  }

  @override
  Future<void> updateUser(UserData UserData) async {
    return await _db.userDao.updateEmployee(UserData);
  }

  @override
  Future<void> deleteNotification() async {
   return await _db.notificationsDao.deleteNotifications();
  }

  @override
  Future<void> saveNotification(LocalNotification notificationModel) async {
    return await _db.notificationsDao.saveNotification(notificationModel);
  }

  @override
  Future<LocalNotification?> getAllNotification() async {
    return await _db.notificationsDao.getAllNotifications();
  }


}
