import 'dart:core';
import 'package:floor/floor.dart';
import '../entity/UserData.dart';


@dao
abstract class UserDao {
  @Query('SELECT * FROM UserData')
  Future<UserData?> getUser();

  @Query('DELETE FROM UserData')
  Future<void> deleteUser();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> saveUser(UserData user);

  @update
  Future<void> updateEmployee(UserData user);
}
