import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:vicoba/DataStore.dart';

import 'Bank.dart';
import 'Device.dart';
import 'Userx.dart';
import 'loginUser.dart';

class OfflineDatabase {
  static const String DATABASE_NAME = 'vicoba.db';

  late Userx _currentUser;

  late Database _db;

  Userx get currentUser => _currentUser;

  Future<void> open() async {
    _db = await openDatabase(DATABASE_NAME, version: 1, onCreate: _onCreate);
    print("DATABASE OPENED");


    //print("USER "+_currentUser.name);
  }

  static Future<void> delete() {
    return deleteDatabase(DATABASE_NAME);
  }

  /// Truncate all tables (clear data but keep structure)
  static Future<void> truncateAll() async {
    final db = await openDatabase(DATABASE_NAME, version: 1);
    await db.delete('user');
    await db.delete('device');
    await db.delete('bank');
    print("DATABASE TABLES TRUNCATED");
  }

  Future<Userx?> getCurrentUser() async {
    _db = await openDatabase(DATABASE_NAME, version: 1, onCreate: _onCreate);

    final result = await _db.query('user');
    print("THIS IS THE INSERTED USER");
    print(result);
    if(result.isEmpty){
      DataStore.userPresent = false;
      print("DATABASE USER NOT PRESENT");
      return null;
    }else{
      print("DATABASE USER PRESENT");
      _currentUser = Userx.fromMap(result.first);
      DataStore.userPresent = true;
      return _currentUser;
    }

    //return result.length == 0 ? null : Userx.fromMap(result.first);
  }

  Future<Userx> setCurrentUser(loginUser user) async {
    print("INSERT INTO USER DB");
    print(user.name);
    print(user.userId);
    print(user.kikobaId);
    print(user.toMap());
    _db = await openDatabase(DATABASE_NAME, version: 1, onCreate: _onCreate);

    // Delete existing user records first to prevent duplicates
    await _db.delete('user');

    // Insert the new user record
    await _db.insert(
      'user',
      {"phone": user.namba, "name": user.name, "userId": user.userId},
    );

    _currentUser = (await getCurrentUser())!;
    return _currentUser;
  }


  Future<Userx> setCurrentUser2(Userx user) async {
    print("INSERT INTO USER DB");
    print(user.name);
    print(user.userId);
    print(user.toMap());
    _db = await openDatabase(DATABASE_NAME, version: 1, onCreate: _onCreate);

    // Delete existing user records first to prevent duplicates
    await _db.delete('user');

    // Insert the new user record
    await _db.insert(
      'user',
      {
        "phone": user.phone,
        "name": user.name,
        "regdate": user.reg_date,
        "userId": user.userId,
        "userStatus": user.userStatus,
        "udid": user.udid,
        "otp": user.otp,
        "isexpired": user.is_expired,
        "localpostImage": user.localpostImage,
        "remotepostImage": user.remotepostImage,
        "createat": user.create_at
      },
    );

    _currentUser = (await getCurrentUser())!;
    return _currentUser;
  }


  Future<void> deleteCurrentUser() async {
    _db = await openDatabase(DATABASE_NAME, version: 1, onCreate: _onCreate);
    await _db.delete('user');
    //_currentUser = null;
  }


  Future<List<Device>> getDevices() async {
    final result = await _db.query('device');
    return result.map((entry) => Device.fromMap(entry)).toList();
  }

  Future<void> saveDevices(List<Device> devices) async {
    return _db.transaction((txn) {
      final batch = txn.batch();
      batch.delete('device');
      for (var device in devices) {
        batch.insert('device', device.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return batch.commit(noResult: true);
    });
  }


  Future<List<Bank>> getBanks() async {
    final result = await _db.query('bank', where: 'eft_id IS NOT NULL');
    return result.map((entry) => Bank.fromMap(entry)).toList();
  }

  Future<void> saveBanks(List<Bank> banks) async {
    return _db.transaction((txn) {
      final batch = txn.batch();
      batch.delete('bank');
      for (var bank in banks) {
        batch.insert('bank', bank.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return batch.commit(noResult: true);
    });
  }


  void _onCreate(Database db, int version) async {
    final userTable = '''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        phone TEXT NOT NULL,
        name TEXT NOT NULL,
        userId TEXT,
        regdate TEXT,
        userStatus TEXT,
        udid TEXT,
        otp TEXT,
        isexpired TEXT,
        localpostImage TEXT,
        remotepostImage TEXT,
        createat TEXT
  
        )
    ''';


    final deviceTable = '''
      CREATE TABLE device (
        imei TEXT PRIMARY KEY,
        registered_date TEXT,
        subscriber_id TEXT,
        model TEXT
      )
    ''';


    final bankTable = '''
      CREATE TABLE bank (
        bin TEXT PRIMARY KEY,
        name TEXT,
        logo TEXT,
        eft_id TEXT
      )
    ''';

    final batch = db.batch();

    batch.execute(userTable);
    batch.execute(deviceTable);
    batch.execute(bankTable);

    await batch.commit(noResult: true);
  }
}

