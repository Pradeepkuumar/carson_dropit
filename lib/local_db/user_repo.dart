import 'entity/UserData.dart';

abstract class UserRepository {
  Future<void> saveUser(UserData userData);

  Future<void> updateUser(UserData userData);
  
  Future<UserData?> getUser();

  Future<void> deleteUser();


}
