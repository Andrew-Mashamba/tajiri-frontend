// lib/services/budget_database.dart
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
    final path = p.join(dbPath, 'tajiri_budget.db');
    debugPrint('[BudgetDB] Opening database at $path');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[BudgetDB] Creating tables (v$version)');

    await db.execute('''
      CREATE TABLE budget_envelopes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'circle',
        allocated_amount REAL NOT NULL DEFAULT 0,
        color TEXT NOT NULL DEFAULT '1A1A1A',
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        envelope_id INTEGER,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        source TEXT NOT NULL DEFAULT 'manual',
        description TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        tajiri_ref_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (envelope_id) REFERENCES budget_envelopes(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'flag',
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        deadline TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Indexes for fast queries
    await db.execute('CREATE INDEX idx_txn_date ON budget_transactions(date)');
    await db.execute('CREATE INDEX idx_txn_envelope ON budget_transactions(envelope_id)');
    await db.execute('CREATE INDEX idx_txn_type ON budget_transactions(type)');
    await db.execute('CREATE INDEX idx_txn_ref ON budget_transactions(tajiri_ref_id)');

    // Seed default envelopes
    for (final env in BudgetDefaults.defaultEnvelopes) {
      await db.insert('budget_envelopes', {
        ...env,
        'allocated_amount': 0.0,
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    debugPrint('[BudgetDB] Seeded ${BudgetDefaults.defaultEnvelopes.length} default envelopes');
  }

  // ── Envelope CRUD ─────────────────────────────────────────────────────

  Future<List<BudgetEnvelope>> getEnvelopes() async {
    final db = await database;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

    final rows = await db.rawQuery('''
      SELECT e.*,
        COALESCE((
          SELECT SUM(t.amount) FROM budget_transactions t
          WHERE t.envelope_id = e.id
            AND t.type = 'expense'
            AND t.date >= ? AND t.date <= ?
        ), 0) AS spent_amount
      FROM budget_envelopes e
      ORDER BY e.sort_order ASC
    ''', [monthStart, monthEnd]);

    return rows.map((r) => BudgetEnvelope.fromJson(r)).toList();
  }

  Future<int> insertEnvelope(BudgetEnvelope envelope) async {
    final db = await database;
    return db.insert('budget_envelopes', envelope.toJson());
  }

  Future<void> updateEnvelope(BudgetEnvelope envelope) async {
    final db = await database;
    await db.update(
      'budget_envelopes',
      envelope.toJson(),
      where: 'id = ?',
      whereArgs: [envelope.id],
    );
  }

  Future<void> deleteEnvelope(int id) async {
    final db = await database;
    await db.delete('budget_envelopes', where: 'id = ?', whereArgs: [id]);
  }

  // ── Transaction CRUD ──────────────────────────────────────────────────

  Future<List<BudgetTransaction>> getTransactions({
    int? envelopeId,
    BudgetTransactionType? type,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (envelopeId != null) {
      where.add('envelope_id = ?');
      args.add(envelopeId);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type.name);
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
      'budget_transactions',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((r) => BudgetTransaction.fromJson(r)).toList();
  }

  Future<int> insertTransaction(BudgetTransaction txn) async {
    final db = await database;
    return db.insert('budget_transactions', txn.toJson());
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('budget_transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Check if a TAJIRI auto-tracked transaction already exists
  Future<bool> hasTransaction(String tajiriRefId) async {
    final db = await database;
    final rows = await db.query(
      'budget_transactions',
      where: 'tajiri_ref_id = ?',
      whereArgs: [tajiriRefId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ── Period Summary ────────────────────────────────────────────────────

  Future<BudgetPeriod> getPeriodSummary(int year, int month) async {
    final db = await database;
    final monthStart = DateTime(year, month, 1).toIso8601String();
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final incomeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM budget_transactions
      WHERE type = 'income' AND date >= ? AND date <= ?
    ''', [monthStart, monthEnd]);

    final expenseResult = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM budget_transactions
      WHERE type = 'expense' AND date >= ? AND date <= ?
    ''', [monthStart, monthEnd]);

    final allocResult = await db.rawQuery('''
      SELECT COALESCE(SUM(allocated_amount), 0) AS total
      FROM budget_envelopes
    ''');

    return BudgetPeriod(
      year: year,
      month: month,
      totalIncome: (incomeResult.first['total'] as num).toDouble(),
      totalAllocated: (allocResult.first['total'] as num).toDouble(),
      totalSpent: (expenseResult.first['total'] as num).toDouble(),
    );
  }

  /// Income breakdown by source for current month
  Future<Map<BudgetSource, double>> getIncomeBySource(int year, int month) async {
    final db = await database;
    final monthStart = DateTime(year, month, 1).toIso8601String();
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final rows = await db.rawQuery('''
      SELECT source, SUM(amount) AS total
      FROM budget_transactions
      WHERE type = 'income' AND date >= ? AND date <= ?
      GROUP BY source
    ''', [monthStart, monthEnd]);

    final result = <BudgetSource, double>{};
    for (final row in rows) {
      final source = BudgetSource.values.firstWhere(
        (s) => s.name == row['source'],
        orElse: () => BudgetSource.manual,
      );
      result[source] = (row['total'] as num).toDouble();
    }
    return result;
  }

  // ── Goals CRUD ────────────────────────────────────────────────────────

  Future<List<BudgetGoal>> getGoals() async {
    final db = await database;
    final rows = await db.query('budget_goals', orderBy: 'created_at DESC');
    return rows.map((r) => BudgetGoal.fromJson(r)).toList();
  }

  Future<int> insertGoal(BudgetGoal goal) async {
    final db = await database;
    return db.insert('budget_goals', goal.toJson());
  }

  Future<void> updateGoal(BudgetGoal goal) async {
    final db = await database;
    await db.update(
      'budget_goals',
      goal.toJson(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoal(int id) async {
    final db = await database;
    await db.delete('budget_goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addToGoal(int goalId, double amount) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE budget_goals SET saved_amount = saved_amount + ? WHERE id = ?
    ''', [amount, goalId]);
  }
}
