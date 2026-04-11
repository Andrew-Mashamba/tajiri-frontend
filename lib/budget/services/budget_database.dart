// lib/budget/services/budget_database.dart
// SQLite local cache for budget module — offline-first pattern
// Database: tajiri_budget_v2.db (separate from legacy tajiri_budget.db)

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/budget_models.dart';

class BudgetDatabase {
  static BudgetDatabase? _instance;
  static Database? _database;

  BudgetDatabase._();

  static BudgetDatabase get instance {
    _instance ??= BudgetDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tajiri_budget_v2.db');
    debugPrint('[BudgetDB] Opening database at $path');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[BudgetDB] Creating tables (v$version)');

    // ── envelope_defaults — cached templates from API ──────────────────
    await db.execute('''
      CREATE TABLE envelope_defaults (
        id INTEGER PRIMARY KEY,
        name_en TEXT NOT NULL,
        name_sw TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'category',
        color TEXT NOT NULL DEFAULT '1A1A1A',
        sort_order INTEGER NOT NULL DEFAULT 0,
        group_name TEXT,
        module_tag TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        json_data TEXT
      )
    ''');

    // ── envelopes — user's budget envelopes ────────────────────────────
    await db.execute('''
      CREATE TABLE envelopes (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        default_id INTEGER,
        name_en TEXT NOT NULL,
        name_sw TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'category',
        color TEXT NOT NULL DEFAULT '1A1A1A',
        sort_order INTEGER NOT NULL DEFAULT 0,
        module_tag TEXT,
        allocated_amount REAL NOT NULL DEFAULT 0,
        is_visible INTEGER NOT NULL DEFAULT 1,
        rollover INTEGER NOT NULL DEFAULT 0,
        rolled_over_amount REAL NOT NULL DEFAULT 0,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        json_data TEXT
      )
    ''');

    // ── income_records — cached income ─────────────────────────────────
    await db.execute('''
      CREATE TABLE income_records (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        source_module TEXT,
        description TEXT NOT NULL DEFAULT '',
        reference_id TEXT UNIQUE,
        date TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        json_data TEXT
      )
    ''');

    // ── expenditure_records — cached expenditures ──────────────────────
    await db.execute('''
      CREATE TABLE expenditure_records (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'other',
        source_module TEXT,
        description TEXT NOT NULL DEFAULT '',
        reference_id TEXT UNIQUE,
        envelope_tag TEXT,
        date TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        json_data TEXT
      )
    ''');

    // ── goals — cached savings goals ───────────────────────────────────
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'flag',
        target_amount REAL NOT NULL DEFAULT 0,
        saved_amount REAL NOT NULL DEFAULT 0,
        deadline TEXT,
        json_data TEXT
      )
    ''');

    // ── periods — cached monthly period summaries ──────────────────────
    await db.execute('''
      CREATE TABLE periods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        total_income REAL NOT NULL DEFAULT 0,
        total_allocated REAL NOT NULL DEFAULT 0,
        total_spent REAL NOT NULL DEFAULT 0,
        wallet_balance REAL NOT NULL DEFAULT 0,
        savings_rate REAL NOT NULL DEFAULT 0,
        json_data TEXT,
        UNIQUE(user_id, year, month)
      )
    ''');

    // ── sync_state — tracks last sync per entity ───────────────────────
    await db.execute('''
      CREATE TABLE sync_state (
        entity TEXT PRIMARY KEY,
        last_synced_id INTEGER DEFAULT 0,
        last_sync_timestamp TEXT
      )
    ''');

    // ── pending_queue — offline mutations ───────────────────────────────
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

    // ── Indexes ────────────────────────────────────────────────────────
    // income_records
    await db.execute('CREATE INDEX idx_income_user ON income_records(user_id)');
    await db.execute('CREATE INDEX idx_income_date ON income_records(date)');
    await db.execute('CREATE INDEX idx_income_source ON income_records(source)');
    await db.execute('CREATE INDEX idx_income_ref ON income_records(reference_id)');

    // expenditure_records
    await db.execute('CREATE INDEX idx_exp_user ON expenditure_records(user_id)');
    await db.execute('CREATE INDEX idx_exp_date ON expenditure_records(date)');
    await db.execute('CREATE INDEX idx_exp_category ON expenditure_records(category)');
    await db.execute('CREATE INDEX idx_exp_ref ON expenditure_records(reference_id)');
    await db.execute('CREATE INDEX idx_exp_envelope ON expenditure_records(envelope_tag)');

    // envelopes
    await db.execute('CREATE INDEX idx_env_user ON envelopes(user_id)');
    await db.execute('CREATE INDEX idx_env_period ON envelopes(year, month)');

    // goals
    await db.execute('CREATE INDEX idx_goals_user ON goals(user_id)');

    debugPrint('[BudgetDB] All tables and indexes created');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENVELOPE DEFAULTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache envelope defaults from API (replaces all existing)
  Future<void> cacheEnvelopeDefaults(List<EnvelopeDefault> defaults) async {
    if (defaults.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final d in defaults) {
      batch.insert(
        'envelope_defaults',
        {
          'id': d.id,
          'name_en': d.nameEn,
          'name_sw': d.nameSw,
          'icon': d.icon,
          'color': d.color,
          'sort_order': d.sortOrder,
          'group_name': d.groupName,
          'module_tag': d.moduleTag,
          'is_active': d.isActive ? 1 : 0,
          'json_data': jsonEncode(d.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[BudgetDB] Cached ${defaults.length} envelope defaults');
  }

  /// Get all cached envelope defaults
  Future<List<EnvelopeDefault>> getCachedEnvelopeDefaults() async {
    final db = await database;
    final rows = await db.query(
      'envelope_defaults',
      orderBy: 'sort_order ASC',
    );
    return rows.map((row) {
      if (row['json_data'] != null) {
        try {
          final json =
              jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
          return EnvelopeDefault.fromJson(json);
        } catch (_) {
          // Fall through to column-based
        }
      }
      return EnvelopeDefault.fromJson(row);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENVELOPES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache envelopes from API
  Future<void> cacheEnvelopes(List<BudgetEnvelope> envelopes) async {
    if (envelopes.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final e in envelopes) {
      batch.insert(
        'envelopes',
        {
          'id': e.id,
          'user_id': e.userId,
          'default_id': e.defaultId,
          'name_en': e.nameEn,
          'name_sw': e.nameSw,
          'icon': e.icon,
          'color': e.color,
          'sort_order': e.sortOrder,
          'module_tag': e.moduleTag,
          'allocated_amount': e.allocatedAmount,
          'is_visible': e.isVisible ? 1 : 0,
          'rollover': e.rollover ? 1 : 0,
          'rolled_over_amount': e.rolledOverAmount,
          'year': e.year,
          'month': e.month,
          'json_data': jsonEncode(e.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[BudgetDB] Cached ${envelopes.length} envelopes');
  }

  /// Get cached envelopes for a user/period
  Future<List<BudgetEnvelope>> getCachedEnvelopes(
      int userId, int year, int month) async {
    final db = await database;
    final rows = await db.query(
      'envelopes',
      where: 'user_id = ? AND year = ? AND month = ?',
      whereArgs: [userId, year, month],
      orderBy: 'sort_order ASC',
    );
    return rows.map((row) {
      if (row['json_data'] != null) {
        try {
          final json =
              jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
          return BudgetEnvelope.fromJson(json);
        } catch (_) {
          // Fall through
        }
      }
      return BudgetEnvelope.fromJson(row);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INCOME RECORDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache income records from API
  Future<void> cacheIncomeRecords(List<IncomeRecord> records) async {
    if (records.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final r in records) {
      batch.insert(
        'income_records',
        {
          'id': r.id,
          'user_id': r.userId,
          'amount': r.amount,
          'source': r.source,
          'source_module': r.sourceModule,
          'description': r.description,
          'reference_id': r.referenceId,
          'date': r.date.toIso8601String(),
          'is_recurring': r.isRecurring ? 1 : 0,
          'json_data': jsonEncode(r.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[BudgetDB] Cached ${records.length} income records');
  }

  /// Get cached income records for a user, optionally filtered by date range
  Future<List<IncomeRecord>> getCachedIncome(int userId,
      {DateTime? from, DateTime? to}) async {
    final db = await database;
    final where = <String>['user_id = ?'];
    final args = <dynamic>[userId];

    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }

    final rows = await db.query(
      'income_records',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC',
    );
    return rows.map((row) {
      if (row['json_data'] != null) {
        try {
          final json =
              jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
          return IncomeRecord.fromJson(json);
        } catch (_) {
          // Fall through
        }
      }
      return IncomeRecord.fromJson(row);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPENDITURE RECORDS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache expenditure records from API
  Future<void> cacheExpenditureRecords(List<ExpenditureRecord> records) async {
    if (records.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final r in records) {
      batch.insert(
        'expenditure_records',
        {
          'id': r.id,
          'user_id': r.userId,
          'amount': r.amount,
          'category': r.category,
          'source_module': r.sourceModule,
          'description': r.description,
          'reference_id': r.referenceId,
          'envelope_tag': r.envelopeTag,
          'date': r.date.toIso8601String(),
          'is_recurring': r.isRecurring ? 1 : 0,
          'json_data': jsonEncode(r.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[BudgetDB] Cached ${records.length} expenditure records');
  }

  /// Get cached expenditure records with optional filters
  Future<List<ExpenditureRecord>> getCachedExpenditures(int userId,
      {String? category, DateTime? from, DateTime? to}) async {
    final db = await database;
    final where = <String>['user_id = ?'];
    final args = <dynamic>[userId];

    if (category != null) {
      where.add('category = ?');
      args.add(category);
    }
    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }

    final rows = await db.query(
      'expenditure_records',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC',
    );
    return rows.map((row) {
      if (row['json_data'] != null) {
        try {
          final json =
              jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
          return ExpenditureRecord.fromJson(json);
        } catch (_) {
          // Fall through
        }
      }
      return ExpenditureRecord.fromJson(row);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOALS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache goals from API
  Future<void> cacheGoals(List<BudgetGoal> goals) async {
    if (goals.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final g in goals) {
      batch.insert(
        'goals',
        {
          'id': g.id,
          'user_id': g.userId,
          'name': g.name,
          'icon': g.icon,
          'target_amount': g.targetAmount,
          'saved_amount': g.savedAmount,
          'deadline': g.deadline?.toIso8601String(),
          'json_data': jsonEncode(g.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    debugPrint('[BudgetDB] Cached ${goals.length} goals');
  }

  /// Get cached goals for a user
  Future<List<BudgetGoal>> getCachedGoals(int userId) async {
    final db = await database;
    final rows = await db.query(
      'goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map((row) {
      if (row['json_data'] != null) {
        try {
          final json =
              jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
          return BudgetGoal.fromJson(json);
        } catch (_) {
          // Fall through
        }
      }
      return BudgetGoal.fromJson(row);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERIODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cache a period summary from API
  Future<void> cachePeriod(BudgetPeriod period) async {
    final db = await database;
    await db.insert(
      'periods',
      {
        'user_id': period.userId,
        'year': period.year,
        'month': period.month,
        'total_income': period.totalIncome,
        'total_allocated': period.totalAllocated,
        'total_spent': period.totalSpent,
        'wallet_balance': period.walletBalance,
        'savings_rate': period.savingsRate,
        'json_data': jsonEncode(period.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached period summary for a user/month
  Future<BudgetPeriod?> getCachedPeriod(
      int userId, int year, int month) async {
    final db = await database;
    final rows = await db.query(
      'periods',
      where: 'user_id = ? AND year = ? AND month = ?',
      whereArgs: [userId, year, month],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    if (row['json_data'] != null) {
      try {
        final json =
            jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
        return BudgetPeriod.fromJson(json);
      } catch (_) {
        // Fall through
      }
    }
    return BudgetPeriod.fromJson(row);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC STATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the last sync time for a given entity type
  Future<DateTime?> getLastSyncTime(String entity) async {
    final db = await database;
    final rows = await db.query(
      'sync_state',
      where: 'entity = ?',
      whereArgs: [entity],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final ts = rows.first['last_sync_timestamp'] as String?;
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  /// Set the last sync time for a given entity type
  Future<void> setLastSyncTime(String entity, DateTime time) async {
    final db = await database;
    await db.insert(
      'sync_state',
      {
        'entity': entity,
        'last_sync_timestamp': time.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PENDING QUEUE (offline mutations)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Add an action to the offline pending queue
  Future<void> addPendingAction(
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

  /// Get all pending actions (oldest first)
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    final rows = await db.query(
      'pending_queue',
      orderBy: 'created_at ASC',
    );
    return rows.map((row) {
      final result = Map<String, dynamic>.from(row);
      // Decode the payload JSON string back to a map
      if (result['payload'] is String) {
        try {
          result['payload'] = jsonDecode(result['payload'] as String);
        } catch (_) {
          // Keep as string if decode fails
        }
      }
      return result;
    }).toList();
  }

  /// Remove a pending action after successful sync
  Future<void> removePendingAction(int id) async {
    final db = await database;
    await db.delete('pending_queue', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEAR / CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clear all data (called on logout)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('envelope_defaults');
    await db.delete('envelopes');
    await db.delete('income_records');
    await db.delete('expenditure_records');
    await db.delete('goals');
    await db.delete('periods');
    await db.delete('sync_state');
    await db.delete('pending_queue');
    debugPrint('[BudgetDB] All data cleared');
  }

  /// Clear data for a specific user
  Future<void> clearUserData(int userId) async {
    final db = await database;
    await db.delete('envelopes', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('income_records',
        where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('expenditure_records',
        where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('goals', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('periods', where: 'user_id = ?', whereArgs: [userId]);
    debugPrint('[BudgetDB] Cleared data for user $userId');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
