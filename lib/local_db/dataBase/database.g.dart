// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  UserDao? _userDaoInstance;

  NotificatiosDao? _notificationsDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `UserData` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `roleId` INTEGER, `vendorId` INTEGER, `name` TEXT, `code` TEXT, `email` TEXT, `phone` TEXT, `apiToken` TEXT, `address` TEXT, `active` INTEGER, `avatar` TEXT, `deviceToken` TEXT, `latitude` TEXT, `longitude` TEXT, `emailVerifiedAt` TEXT, `createdAt` TEXT, `updatedAt` TEXT, `isSignedIn` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `LocalNotification` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `body` TEXT, `title` TEXT)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  UserDao get userDao {
    return _userDaoInstance ??= _$UserDao(database, changeListener);
  }

  @override
  NotificatiosDao get notificationsDao {
    return _notificationsDaoInstance ??=
        _$NotificatiosDao(database, changeListener);
  }
}

class _$UserDao extends UserDao {
  _$UserDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _userDataInsertionAdapter = InsertionAdapter(
            database,
            'UserData',
            (UserData item) => <String, Object?>{
                  'id': item.id,
                  'roleId': item.roleId,
                  'vendorId': item.vendorId,
                  'name': item.name,
                  'code': item.code,
                  'email': item.email,
                  'phone': item.phone,
                  'apiToken': item.apiToken,
                  'address': item.address,
                  'active': item.active,
                  'avatar': item.avatar,
                  'deviceToken': item.deviceToken,
                  'latitude': item.latitude,
                  'longitude': item.longitude,
                  'emailVerifiedAt': item.emailVerifiedAt,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt,
                  'isSignedIn': item.isSignedIn
                }),
        _userDataUpdateAdapter = UpdateAdapter(
            database,
            'UserData',
            ['id'],
            (UserData item) => <String, Object?>{
                  'id': item.id,
                  'roleId': item.roleId,
                  'vendorId': item.vendorId,
                  'name': item.name,
                  'code': item.code,
                  'email': item.email,
                  'phone': item.phone,
                  'apiToken': item.apiToken,
                  'address': item.address,
                  'active': item.active,
                  'avatar': item.avatar,
                  'deviceToken': item.deviceToken,
                  'latitude': item.latitude,
                  'longitude': item.longitude,
                  'emailVerifiedAt': item.emailVerifiedAt,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt,
                  'isSignedIn': item.isSignedIn
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<UserData> _userDataInsertionAdapter;

  final UpdateAdapter<UserData> _userDataUpdateAdapter;

  @override
  Future<UserData?> getUser() async {
    return _queryAdapter.query('SELECT * FROM UserData',
        mapper: (Map<String, Object?> row) => UserData(
            id: row['id'] as int?,
            roleId: row['roleId'] as int?,
            vendorId: row['vendorId'] as int?,
            name: row['name'] as String?,
            code: row['code'] as String?,
            email: row['email'] as String?,
            phone: row['phone'] as String?,
            apiToken: row['apiToken'] as String?,
            address: row['address'] as String?,
            active: row['active'] as int?,
            avatar: row['avatar'] as String?,
            deviceToken: row['deviceToken'] as String?,
            latitude: row['latitude'] as String?,
            longitude: row['longitude'] as String?,
            emailVerifiedAt: row['emailVerifiedAt'] as String?,
            createdAt: row['createdAt'] as String?,
            updatedAt: row['updatedAt'] as String?,
            isSignedIn: row['isSignedIn'] as String?));
  }

  @override
  Future<void> deleteUser() async {
    await _queryAdapter.queryNoReturn('DELETE FROM UserData');
  }

  @override
  Future<void> saveUser(UserData user) async {
    await _userDataInsertionAdapter.insert(user, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateEmployee(UserData user) async {
    await _userDataUpdateAdapter.update(user, OnConflictStrategy.abort);
  }
}

class _$NotificatiosDao extends NotificatiosDao {
  _$NotificatiosDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _localNotificationInsertionAdapter = InsertionAdapter(
            database,
            'LocalNotification',
            (LocalNotification item) => <String, Object?>{
                  'id': item.id,
                  'body': item.body,
                  'title': item.title
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<LocalNotification> _localNotificationInsertionAdapter;

  @override
  Future<LocalNotification?> getAllNotifications() async {
    return _queryAdapter.query('SELECT * FROM NotificationModel',
        mapper: (Map<String, Object?> row) => LocalNotification(
            body: row['body'] as String?, title: row['title'] as String?));
  }

  @override
  Future<void> deleteNotifications() async {
    await _queryAdapter.queryNoReturn('DELETE FROM NotificationModel');
  }

  @override
  Future<void> saveNotification(LocalNotification notificationModel) async {
    await _localNotificationInsertionAdapter.insert(
        notificationModel, OnConflictStrategy.replace);
  }
}
