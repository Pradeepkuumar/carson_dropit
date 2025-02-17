import 'dart:async';
import 'package:carson_zyppy/firebase_notifications/notification_model/notification_model.dart';
import 'package:floor/floor.dart';
import '../../firebase_notifications/notification_model/notification.dart';
import '../dao/notificatiosDao.dart';
import '../dao/userDao.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../entity/UserData.dart';
part 'database.g.dart';


@Database(version: 1, entities: [UserData,LocalNotification])
abstract class AppDatabase extends FloorDatabase {
  UserDao get userDao;
  NotificatiosDao get notificationsDao;

}
