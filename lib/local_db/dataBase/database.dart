import 'dart:async';
import 'package:floor/floor.dart';
import '../dao/userDao.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import '../entity/UserData.dart';
part 'database.g.dart';


@Database(version: 1, entities: [UserData])
abstract class AppDatabase extends FloorDatabase {
  UserDao get userDao;

}
