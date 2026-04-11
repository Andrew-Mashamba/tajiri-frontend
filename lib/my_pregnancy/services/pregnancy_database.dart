// lib/my_pregnancy/services/pregnancy_database.dart
// SQLite local cache for pregnancy module — offline-first pattern

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class PregnancyDatabase {
  static PregnancyDatabase? _instance;
  static Database? _database;

  PregnancyDatabase._();

  static PregnancyDatabase get instance {
    _instance ??= PregnancyDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tajiri_pregnancy.db');
    debugPrint('[PregnancyDB] Opening database at $path');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[PregnancyDB] Creating tables (v$version)');

    // ── pregnancy_cache — cached pregnancy data from API ─────────────
    await db.execute('''
      CREATE TABLE pregnancy_cache (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // ── kick_counts_cache — offline-first kick sessions ─────────────
    await db.execute('''
      CREATE TABLE kick_counts_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pregnancy_id INTEGER NOT NULL,
        count INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        date TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        json_data TEXT
      )
    ''');

    // ── anc_visits_cache — cached ANC schedule ──────────────────────
    await db.execute('''
      CREATE TABLE anc_visits_cache (
        id INTEGER PRIMARY KEY,
        pregnancy_id INTEGER NOT NULL,
        visit_number INTEGER,
        scheduled_date TEXT,
        is_done INTEGER NOT NULL DEFAULT 0,
        json_data TEXT NOT NULL
      )
    ''');

    // ── sync_state — track last sync times per entity ───────────────
    await db.execute('''
      CREATE TABLE sync_state (
        entity TEXT PRIMARY KEY,
        last_sync TEXT NOT NULL
      )
    ''');

    // ── pending_queue — mutations to sync when online ───────────────
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

  // ─── Pregnancy Cache ──────────────────────────────────────────────

  Future<void> cachePregnancy(Map<String, dynamic> data, int userId) async {
    final db = await database;
    final id = data['id'] as int? ?? 0;
    await db.insert(
      'pregnancy_cache',
      {
        'id': id,
        'user_id': userId,
        'data': jsonEncode(data),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedPregnancy(int userId) async {
    final db = await database;
    final rows = await db.query(
      'pregnancy_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Kick Counts Cache ────────────────────────────────────────────

  Future<void> cacheKickCount(Map<String, dynamic> kickData) async {
    final db = await database;
    await db.insert('kick_counts_cache', {
      'pregnancy_id': kickData['pregnancy_id'],
      'count': kickData['count'],
      'duration_minutes': kickData['duration_minutes'],
      'start_time': kickData['start_time'],
      'date': kickData['date'] ?? DateTime.now().toIso8601String(),
      'synced': kickData['synced'] ?? 0,
      'json_data': jsonEncode(kickData),
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedKickCounts() async {
    final db = await database;
    return db.query(
      'kick_counts_cache',
      where: 'synced = 0',
      orderBy: 'start_time ASC',
    );
  }

  Future<void> markKickCountSynced(int id) async {
    final db = await database;
    await db.update(
      'kick_counts_cache',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── ANC Visits Cache ─────────────────────────────────────────────

  Future<void> cacheAncVisits(
      List<Map<String, dynamic>> visits, int pregnancyId) async {
    final db = await database;
    final batch = db.batch();
    // Clear old visits for this pregnancy
    batch.delete('anc_visits_cache',
        where: 'pregnancy_id = ?', whereArgs: [pregnancyId]);
    for (final visit in visits) {
      batch.insert('anc_visits_cache', {
        'id': visit['id'],
        'pregnancy_id': pregnancyId,
        'visit_number': visit['visit_number'],
        'scheduled_date': visit['scheduled_date'],
        'is_done': (visit['is_done'] == true || visit['is_done'] == 1) ? 1 : 0,
        'json_data': jsonEncode(visit),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedAncVisits(
      int pregnancyId) async {
    final db = await database;
    final rows = await db.query(
      'anc_visits_cache',
      where: 'pregnancy_id = ?',
      whereArgs: [pregnancyId],
      orderBy: 'visit_number ASC',
    );
    return rows.map((row) {
      try {
        return jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
      } catch (_) {
        return row;
      }
    }).toList();
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
    await db.delete('pregnancy_cache');
    await db.delete('kick_counts_cache');
    await db.delete('anc_visits_cache');
    await db.delete('sync_state');
    await db.delete('pending_queue');
  }
}
