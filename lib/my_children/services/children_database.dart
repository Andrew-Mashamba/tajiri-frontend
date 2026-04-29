// lib/my_children/services/children_database.dart
// SQLite local cache for My Children module — offline-first pattern
// Mirrors lib/my_pregnancy/services/pregnancy_database.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class ChildrenDatabase {
  static ChildrenDatabase? _instance;
  static Database? _database;

  ChildrenDatabase._();

  static ChildrenDatabase get instance {
    _instance ??= ChildrenDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tajiri_children.db');
    debugPrint('[ChildrenDB] Opening database at $path');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[ChildrenDB] Creating tables (v$version)');

    // ── children_cache — cached child data from API ─────────────
    await db.execute('''
      CREATE TABLE children_cache (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // ── chores_cache — offline-first chore tracking ─────────────
    await db.execute('''
      CREATE TABLE chores_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── homework_local — local-only homework tracker (no backend) ─
    await db.execute('''
      CREATE TABLE homework_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        subject TEXT,
        description TEXT,
        due_date TEXT,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ── sync_state — track last sync times per entity ───────────
    await db.execute('''
      CREATE TABLE sync_state (
        entity TEXT PRIMARY KEY,
        last_sync TEXT NOT NULL
      )
    ''');

    // ── pending_queue — mutations to sync when online ───────────
    await db.execute('''
      CREATE TABLE pending_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ─── Children Cache ───────────────────────────────────────────────

  Future<void> cacheChildren(
      List<Map<String, dynamic>> children, int userId) async {
    final db = await database;
    final batch = db.batch();
    // Clear old cache for this user
    batch.delete('children_cache',
        where: 'user_id = ?', whereArgs: [userId]);
    final now = DateTime.now().toIso8601String();
    for (final child in children) {
      final id = child['id'] as int? ?? 0;
      batch.insert('children_cache', {
        'id': id,
        'user_id': userId,
        'data': jsonEncode(child),
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>?> getCachedChildren(int userId) async {
    final db = await database;
    final rows = await db.query(
      'children_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) return null;
    try {
      return rows
          .map((row) =>
              jsonDecode(row['data'] as String) as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ─── Homework (local-only CRUD) ───────────────────────────────────

  Future<int> addHomework(
      int childId, String subject, String description, String dueDate) async {
    final db = await database;
    return db.insert('homework_local', {
      'child_id': childId,
      'subject': subject,
      'description': description,
      'due_date': dueDate,
      'is_done': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getHomework(int childId) async {
    final db = await database;
    return db.query(
      'homework_local',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'due_date ASC',
    );
  }

  Future<void> completeHomework(int id) async {
    final db = await database;
    await db.update(
      'homework_local',
      {'is_done': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteHomework(int id) async {
    final db = await database;
    await db.delete('homework_local', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Chores Cache ─────────────────────────────────────────────────

  Future<void> cacheChore(int childId, Map<String, dynamic> choreData) async {
    final db = await database;
    await db.insert('chores_cache', {
      'child_id': childId,
      'data': jsonEncode(choreData),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedChores() async {
    final db = await database;
    return db.query('chores_cache', where: 'synced = 0');
  }

  Future<void> markChoreSynced(int id) async {
    final db = await database;
    await db.update(
      'chores_cache',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Sync State ───────────────────────────────────────────────────

  Future<DateTime?> getLastSyncTime(String entity) async {
    final db = await database;
    final rows = await db.query(
      'sync_state',
      where: 'entity = ?',
      whereArgs: [entity],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['last_sync'] as String? ?? '');
  }

  Future<void> setLastSyncTime(String entity) async {
    final db = await database;
    await db.insert(
      'sync_state',
      {
        'entity': entity,
        'last_sync': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── Pending Queue ────────────────────────────────────────────────

  Future<void> addPending(
      String entity, String action, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('pending_queue', {
      'entity': entity,
      'action': action,
      'payload': jsonEncode(payload),
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    return db.query(
      'pending_queue',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> removePending(int id) async {
    final db = await database;
    await db.delete('pending_queue', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Cleanup ──────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('children_cache');
    await db.delete('chores_cache');
    await db.delete('homework_local');
    await db.delete('sync_state');
    await db.delete('pending_queue');
  }
}
