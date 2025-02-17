import 'dart:core';
import 'package:floor/floor.dart';

import '../../firebase_notifications/notification_model/notification.dart';


@dao
abstract class NotificatiosDao {
  @Query('SELECT * FROM NotificationModel')
  Future<LocalNotification?> getAllNotifications();

  @Query('DELETE FROM NotificationModel')
  Future<void> deleteNotifications();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> saveNotification(LocalNotification notificationModel);

}
