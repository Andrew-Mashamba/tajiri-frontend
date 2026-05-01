// lib/reminders/services/reminders_db.dart
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reminder_models.dart';

const _kTable = 'reminders';
const _kVersion = 1;

class RemindersDb {
  Database? _db;

  Future<void> open({bool inMemory = false}) async {
    final path = inMemory
        ? inMemoryDatabasePath
        : join(await getDatabasesPath(), 'reminders.db');

    _db = await openDatabase(
      path,
      version: _kVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_kTable (
            id           TEXT PRIMARY KEY,
            user_id      INTEGER NOT NULL DEFAULT 0,
            title        TEXT NOT NULL,
            subtitle     TEXT,
            due_at       TEXT NOT NULL,
            category     TEXT NOT NULL DEFAULT 'general',
            repeat       TEXT NOT NULL DEFAULT 'none',
            is_done      INTEGER NOT NULL DEFAULT 0,
            is_standalone INTEGER NOT NULL DEFAULT 1,
            source_route TEXT,
            synced_at    TEXT,
            server_id    INTEGER
          )
        ''');
      },
    );
  }

  Future<void> close() async => _db?.close();

  Database get _database {
    assert(_db != null, 'RemindersDb.open() must be called first');
    return _db!;
  }

  Future<void> insert(ReminderItem item, {int userId = 0}) async {
    try {
      await _database.insert(
        _kTable,
        {...item.toJson(), 'user_id': userId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('[RemindersDb] insert error: $e');
    }
  }

  Future<void> update(ReminderItem item) async {
    try {
      await _database.update(
        _kTable,
        item.toJson(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (e) {
      debugPrint('[RemindersDb] update error: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _database.delete(_kTable, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[RemindersDb] delete error: $e');
    }
  }

  Future<void> markDone(String id) async {
    try {
      await _database.update(
        _kTable,
        {'is_done': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('[RemindersDb] markDone error: $e');
    }
  }

  Future<void> markSynced(String id, int serverId) async {
    try {
      await _database.update(
        _kTable,
        {
          'synced_at': DateTime.now().toIso8601String(),
          'server_id': serverId,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('[RemindersDb] markSynced error: $e');
    }
  }

  Future<List<ReminderItem>> getAll({int userId = 0}) async {
    try {
      final rows = await _database.query(
        _kTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'due_at ASC',
      );
      return rows.map(_rowToItem).toList();
    } catch (e) {
      debugPrint('[RemindersDb] getAll error: $e');
      return [];
    }
  }

  Future<List<ReminderItem>> getPendingSync({int userId = 0}) async {
    try {
      final rows = await _database.query(
        _kTable,
        where: 'user_id = ? AND synced_at IS NULL',
        whereArgs: [userId],
      );
      return rows.map(_rowToItem).toList();
    } catch (e) {
      debugPrint('[RemindersDb] getPendingSync error: $e');
      return [];
    }
  }

  ReminderItem _rowToItem(Map<String, dynamic> row) => ReminderItem.fromJson(row);

  // STUB — used by RemindersService when reconciling remote rows. No-op until
  // a real upsert implementation lands.
  Future<void> upsertFromRemoteFetch(ReminderItem item, {required int userId}) async {}
}
