
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


}
