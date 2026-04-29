# Reminders Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `lib/reminders/` — a unified business reminders module that aggregates 24 notification event types from all business modules plus calendar, with standalone reminder creation, SQLite + remote persistence, and local push notifications.

**Architecture:** Pull-based aggregator: each source module exposes one adapter method returning `List<ReminderItem>`. `RemindersAggregator` calls all adapters in parallel, merges results, and sorts by due date. Standalone reminders persist in SQLite (offline-first) and sync to `/api/reminders`.

**Tech Stack:** Flutter/Dart, `sqflite` (SQLite), `flutter_local_notifications`, `timezone`, `http`, `flutter_slidable`

**Spec:** `docs/superpowers/specs/2026-04-18-reminders-module-design.md`

---

## File Map

**Create:**
- `lib/reminders/models/reminder_models.dart` — ReminderItem, ReminderCategory, ReminderRepeat, result wrappers
- `lib/reminders/services/reminders_db.dart` — SQLite schema and CRUD
- `lib/reminders/services/reminders_service.dart` — CRUD with offline-first sync to `/api/reminders`
- `lib/reminders/services/reminders_aggregator.dart` — parallel aggregation of all 16 adapters
- `lib/reminders/services/reminders_notification_service.dart` — local notification scheduling with timing rules
- `lib/reminders/pages/reminders_home_page.dart` — Leo / Ijayo / Zilizokamilika tabs
- `lib/reminders/pages/add_reminder_page.dart` — create/edit standalone reminder form
- `lib/reminders/widgets/reminder_card.dart` — swipeable card (flutter_slidable)
- `lib/reminders/reminders_module.dart` — entry point StatelessWidget
- `test/reminders/models/reminder_models_test.dart`
- `test/reminders/services/reminders_db_test.dart`
- `test/reminders/services/reminders_aggregator_test.dart`

**Modify:**
- `lib/business/services/business_service.dart` — add 13 adapter static methods
- `lib/calendar/services/calendar_service.dart` — add `getUpcomingWithReminders` instance method
- `lib/tenders/services/tender_service.dart` — add `getUpcomingTenderDeadlines` static method
- `lib/screens/profile/profile_screen.dart` — wire `biz_reminders` case to `RemindersModule`
- `lib/l10n/app_strings.dart` — add Swahili/English strings for reminders module

---

## Task 1: Data Models

**Files:**
- Create: `lib/reminders/models/reminder_models.dart`
- Create: `test/reminders/models/reminder_models_test.dart`

- [ ] **Step 1: Create test file**

```dart
// test/reminders/models/reminder_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/reminders/models/reminder_models.dart';

void main() {
  group('ReminderCategory', () {
    test('all 17 values have displayName, subtitle, and icon', () {
      for (final cat in ReminderCategory.values) {
        expect(cat.displayName, isNotEmpty, reason: '${cat.name} missing displayName');
        expect(cat.subtitle, isNotEmpty, reason: '${cat.name} missing subtitle');
        expect(cat.icon, isNotNull, reason: '${cat.name} missing icon');
      }
    });

    test('fromString returns correct value', () {
      expect(ReminderCategory.fromString('invoice'), ReminderCategory.invoice);
      expect(ReminderCategory.fromString('unknown'), ReminderCategory.general);
      expect(ReminderCategory.fromString(null), ReminderCategory.general);
    });
  });

  group('ReminderRepeat', () {
    test('all values have displayName and subtitle', () {
      for (final r in ReminderRepeat.values) {
        expect(r.displayName, isNotEmpty);
        expect(r.subtitle, isNotEmpty);
      }
    });

    test('fromString returns correct value', () {
      expect(ReminderRepeat.fromString('weekly'), ReminderRepeat.weekly);
      expect(ReminderRepeat.fromString(null), ReminderRepeat.none);
    });
  });

  group('ReminderItem', () {
    test('fromJson parses correctly', () {
      final item = ReminderItem.fromJson({
        'id': 'standalone_abc',
        'title': 'Test reminder',
        'subtitle': 'note',
        'due_at': '2026-05-01T09:00:00.000Z',
        'category': 'invoice',
        'repeat': 'none',
        'is_done': 0,
        'is_standalone': 1,
        'source_route': null,
      });
      expect(item.id, 'standalone_abc');
      expect(item.title, 'Test reminder');
      expect(item.category, ReminderCategory.invoice);
      expect(item.isDone, false);
      expect(item.isStandalone, true);
    });

    test('toJson round-trips correctly', () {
      final item = ReminderItem(
        id: 'standalone_xyz',
        title: 'Payroll due',
        dueAt: DateTime(2026, 5, 10, 8, 0),
        category: ReminderCategory.payroll,
        repeat: ReminderRepeat.monthly,
        isDone: false,
        isStandalone: true,
      );
      final json = item.toJson();
      final restored = ReminderItem.fromJson(json);
      expect(restored.id, item.id);
      expect(restored.category, item.category);
      expect(restored.repeat, item.repeat);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND
flutter test test/reminders/models/reminder_models_test.dart
```
Expected: FAIL — `package:tajiri/reminders/models/reminder_models.dart` not found.

- [ ] **Step 3: Create the models file**

```dart
// lib/reminders/models/reminder_models.dart
import 'package:flutter/material.dart';

// ── Parse helpers ──────────────────────────────────────────────────────────

int _parseInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v == 'true';
  return fallback;
}

// ── ReminderCategory ───────────────────────────────────────────────────────

enum ReminderCategory {
  calendar,
  appointment,
  quote,
  invoice,
  transaction,
  revenue,
  recurring,
  debt,
  document,
  expense,
  tax,
  credit,
  employee,
  payroll,
  purchaseOrder,
  tender,
  general;

  String get displayName {
    switch (this) {
      case ReminderCategory.calendar: return 'Kalenda';
      case ReminderCategory.appointment: return 'Miadi';
      case ReminderCategory.quote: return 'Nukuu';
      case ReminderCategory.invoice: return 'Ankara';
      case ReminderCategory.transaction: return 'Muamala';
      case ReminderCategory.revenue: return 'Mapato';
      case ReminderCategory.recurring: return 'Ya Mara kwa Mara';
      case ReminderCategory.debt: return 'Deni';
      case ReminderCategory.document: return 'Hati';
      case ReminderCategory.expense: return 'Gharama';
      case ReminderCategory.tax: return 'Kodi';
      case ReminderCategory.credit: return 'CRB';
      case ReminderCategory.employee: return 'Mfanyakazi';
      case ReminderCategory.payroll: return 'Mishahara';
      case ReminderCategory.purchaseOrder: return 'Oda ya Ununuzi';
      case ReminderCategory.tender: return 'Zabuni';
      case ReminderCategory.general: return 'Jumla';
    }
  }

  String get subtitle {
    switch (this) {
      case ReminderCategory.calendar: return 'Calendar';
      case ReminderCategory.appointment: return 'Appointment';
      case ReminderCategory.quote: return 'Quote';
      case ReminderCategory.invoice: return 'Invoice';
      case ReminderCategory.transaction: return 'Transaction';
      case ReminderCategory.revenue: return 'Revenue';
      case ReminderCategory.recurring: return 'Recurring';
      case ReminderCategory.debt: return 'Debt';
      case ReminderCategory.document: return 'Document';
      case ReminderCategory.expense: return 'Expense';
      case ReminderCategory.tax: return 'Tax';
      case ReminderCategory.credit: return 'Credit / CRB';
      case ReminderCategory.employee: return 'Employee';
      case ReminderCategory.payroll: return 'Payroll';
      case ReminderCategory.purchaseOrder: return 'Purchase Order';
      case ReminderCategory.tender: return 'Tender';
      case ReminderCategory.general: return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderCategory.calendar: return Icons.calendar_month_rounded;
      case ReminderCategory.appointment: return Icons.event_available_rounded;
      case ReminderCategory.quote: return Icons.request_quote_rounded;
      case ReminderCategory.invoice: return Icons.receipt_long_rounded;
      case ReminderCategory.transaction: return Icons.swap_horiz_rounded;
      case ReminderCategory.revenue: return Icons.trending_up_rounded;
      case ReminderCategory.recurring: return Icons.repeat_rounded;
      case ReminderCategory.debt: return Icons.account_balance_wallet_rounded;
      case ReminderCategory.document: return Icons.folder_rounded;
      case ReminderCategory.expense: return Icons.money_off_rounded;
      case ReminderCategory.tax: return Icons.calculate_rounded;
      case ReminderCategory.credit: return Icons.credit_score_rounded;
      case ReminderCategory.employee: return Icons.badge_rounded;
      case ReminderCategory.payroll: return Icons.payments_rounded;
      case ReminderCategory.purchaseOrder: return Icons.shopping_cart_rounded;
      case ReminderCategory.tender: return Icons.gavel_rounded;
      case ReminderCategory.general: return Icons.notifications_rounded;
    }
  }

  static ReminderCategory fromString(String? s) {
    if (s == null) return ReminderCategory.general;
    return ReminderCategory.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ReminderCategory.general,
    );
  }
}

// ── ReminderRepeat ─────────────────────────────────────────────────────────

enum ReminderRepeat {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case ReminderRepeat.none: return 'Hakuna';
      case ReminderRepeat.daily: return 'Kila Siku';
      case ReminderRepeat.weekly: return 'Kila Wiki';
      case ReminderRepeat.monthly: return 'Kila Mwezi';
      case ReminderRepeat.yearly: return 'Kila Mwaka';
    }
  }

  String get subtitle {
    switch (this) {
      case ReminderRepeat.none: return 'None';
      case ReminderRepeat.daily: return 'Daily';
      case ReminderRepeat.weekly: return 'Weekly';
      case ReminderRepeat.monthly: return 'Monthly';
      case ReminderRepeat.yearly: return 'Yearly';
    }
  }

  static ReminderRepeat fromString(String? s) {
    if (s == null) return ReminderRepeat.none;
    return ReminderRepeat.values.firstWhere(
      (v) => v.name == s,
      orElse: () => ReminderRepeat.none,
    );
  }
}

// ── ReminderItem ───────────────────────────────────────────────────────────

class ReminderItem {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime dueAt;
  final ReminderCategory category;
  final ReminderRepeat repeat;
  final bool isDone;
  final bool isStandalone;
  final String? sourceRoute;

  const ReminderItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.dueAt,
    required this.category,
    this.repeat = ReminderRepeat.none,
    this.isDone = false,
    required this.isStandalone,
    this.sourceRoute,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      dueAt: DateTime.tryParse(json['due_at']?.toString() ?? '') ?? DateTime.now(),
      category: ReminderCategory.fromString(json['category']?.toString()),
      repeat: ReminderRepeat.fromString(json['repeat']?.toString()),
      isDone: _parseBool(json['is_done']),
      isStandalone: _parseBool(json['is_standalone']),
      sourceRoute: json['source_route']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'due_at': dueAt.toIso8601String(),
    'category': category.name,
    'repeat': repeat.name,
    'is_done': isDone ? 1 : 0,
    'is_standalone': isStandalone ? 1 : 0,
    'source_route': sourceRoute,
  };

  ReminderItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    DateTime? dueAt,
    ReminderCategory? category,
    ReminderRepeat? repeat,
    bool? isDone,
    bool? isStandalone,
    String? sourceRoute,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      dueAt: dueAt ?? this.dueAt,
      category: category ?? this.category,
      repeat: repeat ?? this.repeat,
      isDone: isDone ?? this.isDone,
      isStandalone: isStandalone ?? this.isStandalone,
      sourceRoute: sourceRoute ?? this.sourceRoute,
    );
  }
}

// ── Result wrappers ────────────────────────────────────────────────────────

class ReminderResult<T> {
  final bool success;
  final T? data;
  final String? message;
  ReminderResult({required this.success, this.data, this.message});
}

class ReminderListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  ReminderListResult({required this.success, this.items = const [], this.message});
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/reminders/models/reminder_models_test.dart
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/reminders/models/reminder_models.dart test/reminders/models/reminder_models_test.dart
git commit -m "feat(reminders): add data models — ReminderItem, ReminderCategory, ReminderRepeat"
```

---

## Task 2: SQLite Database Layer

**Files:**
- Create: `lib/reminders/services/reminders_db.dart`
- Create: `test/reminders/services/reminders_db_test.dart`

- [ ] **Step 1: Create test file**

```dart
// test/reminders/services/reminders_db_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tajiri/reminders/models/reminder_models.dart';
import 'package:tajiri/reminders/services/reminders_db.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late RemindersDb db;

  setUp(() async {
    db = RemindersDb();
    await db.open(inMemory: true);
  });

  tearDown(() async {
    await db.close();
  });

  group('RemindersDb', () {
    ReminderItem _item({String id = 'test_1'}) => ReminderItem(
          id: id,
          title: 'Test reminder',
          dueAt: DateTime(2026, 6, 1, 9, 0),
          category: ReminderCategory.invoice,
          isStandalone: true,
        );

    test('insert and getAll returns item', () async {
      await db.insert(_item());
      final items = await db.getAll(userId: 1);
      expect(items.length, 1);
      expect(items.first.id, 'test_1');
    });

    test('update modifies fields', () async {
      await db.insert(_item());
      await db.update(_item(id: 'test_1').copyWith(title: 'Updated'));
      final items = await db.getAll(userId: 1);
      expect(items.first.title, 'Updated');
    });

    test('delete removes item', () async {
      await db.insert(_item());
      await db.delete('test_1');
      final items = await db.getAll(userId: 1);
      expect(items, isEmpty);
    });

    test('markDone sets is_done = true', () async {
      await db.insert(_item());
      await db.markDone('test_1');
      final items = await db.getAll(userId: 1);
      expect(items.first.isDone, true);
    });

    test('getPendingSync returns rows with synced_at null', () async {
      await db.insert(_item());
      final pending = await db.getPendingSync(userId: 1);
      expect(pending.length, 1);
    });
  });
}
```

- [ ] **Step 2: Add `sqflite_common_ffi` to dev dependencies (for desktop/CI testing)**

Open `pubspec.yaml` and add under `dev_dependencies`:
```yaml
  sqflite_common_ffi: ^2.3.4
```

Then run:
```bash
flutter pub get
```

- [ ] **Step 3: Run test to verify it fails**

```bash
flutter test test/reminders/services/reminders_db_test.dart
```
Expected: FAIL — `RemindersDb` not found.

- [ ] **Step 4: Create reminders_db.dart**

```dart
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
            id          TEXT PRIMARY KEY,
            user_id     INTEGER NOT NULL DEFAULT 0,
            title       TEXT NOT NULL,
            subtitle    TEXT,
            due_at      TEXT NOT NULL,
            category    TEXT NOT NULL DEFAULT 'general',
            repeat      TEXT NOT NULL DEFAULT 'none',
            is_done     INTEGER NOT NULL DEFAULT 0,
            source_route TEXT,
            synced_at   TEXT,
            server_id   INTEGER
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
        {'synced_at': DateTime.now().toIso8601String(), 'server_id': serverId},
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

  ReminderItem _rowToItem(Map<String, dynamic> row) {
    return ReminderItem.fromJson(row);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/reminders/services/reminders_db_test.dart
```
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/reminders/services/reminders_db.dart test/reminders/services/reminders_db_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(reminders): add SQLite database layer"
```

---

## Task 3: RemindersService (CRUD + API Sync)

**Files:**
- Create: `lib/reminders/services/reminders_service.dart`

- [ ] **Step 1: Create reminders_service.dart**

```dart
// lib/reminders/services/reminders_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../config/api_config.dart';
import '../models/reminder_models.dart';
import 'reminders_db.dart';

String get _baseUrl => ApiConfig.baseUrl;
const _uuid = Uuid();

void _log(String msg) => debugPrint('[RemindersService] $msg');

class RemindersService {
  static final RemindersDb _db = RemindersDb();
  static bool _dbOpened = false;

  static Future<void> _ensureDb() async {
    if (!_dbOpened) {
      await _db.open();
      _dbOpened = true;
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  static Future<ReminderResult<ReminderItem>> create(
    ReminderItem item, {
    required String token,
    required int userId,
  }) async {
    await _ensureDb();
    final withId = item.copyWith(id: 'standalone_${_uuid.v4()}');
    await _db.insert(withId, userId: userId);
    _syncCreate(withId, token: token, userId: userId);
    return ReminderResult(success: true, data: withId);
  }

  static Future<ReminderResult<ReminderItem>> update(
    ReminderItem item, {
    required String token,
  }) async {
    await _ensureDb();
    await _db.update(item);
    _syncUpdate(item, token: token);
    return ReminderResult(success: true, data: item);
  }

  static Future<ReminderResult<void>> delete(
    String id, {
    required String token,
  }) async {
    await _ensureDb();
    await _db.delete(id);
    _syncDelete(id, token: token);
    return ReminderResult(success: true);
  }

  static Future<ReminderResult<void>> markDone(
    String id, {
    required String token,
  }) async {
    await _ensureDb();
    await _db.markDone(id);
    _syncMarkDone(id, token: token);
    return ReminderResult(success: true);
  }

  static Future<List<ReminderItem>> getAll({
    required int userId,
    required String token,
  }) async {
    await _ensureDb();
    await _fetchAndReconcile(userId: userId, token: token);
    return _db.getAll(userId: userId);
  }

  // ── API sync (fire-and-forget) ─────────────────────────────────────────

  static Future<void> _fetchAndReconcile({
    required int userId,
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/reminders?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = (data['data'] as List? ?? [])
            .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final item in items) {
          await _db.insert(item, userId: userId);
        }
      }
    } catch (e) {
      _log('_fetchAndReconcile failed (offline?): $e');
    }
    // Sync any pending local rows to API
    final pending = await _db.getPendingSync(userId: userId);
    for (final item in pending) {
      await _syncCreate(item, token: token, userId: userId);
    }
  }

  static Future<void> _syncCreate(
    ReminderItem item, {
    required String token,
    required int userId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/reminders'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({...item.toJson(), 'user_id': userId}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final serverId = data['data']?['id'] as int?;
        if (serverId != null) await _db.markSynced(item.id, serverId);
      }
    } catch (e) {
      _log('_syncCreate failed (will retry): $e');
    }
  }

  static Future<void> _syncUpdate(ReminderItem item, {required String token}) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/reminders/${item.id}'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode(item.toJson()),
      );
    } catch (e) {
      _log('_syncUpdate failed: $e');
    }
  }

  static Future<void> _syncDelete(String id, {required String token}) async {
    try {
      await http.delete(
        Uri.parse('$_baseUrl/reminders/$id'),
        headers: ApiConfig.authHeaders(token),
      );
    } catch (e) {
      _log('_syncDelete failed: $e');
    }
  }

  static Future<void> _syncMarkDone(String id, {required String token}) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/reminders/$id'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'is_done': 1}),
      );
    } catch (e) {
      _log('_syncMarkDone failed: $e');
    }
  }
}
```

- [ ] **Step 2: Verify the file compiles**

```bash
flutter analyze lib/reminders/services/reminders_service.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/reminders/services/reminders_service.dart
git commit -m "feat(reminders): add RemindersService with offline-first SQLite + API sync"
```

---

## Task 4: BusinessService Adapter Methods

**Files:**
- Modify: `lib/business/services/business_service.dart` (append at end of class)

These 13 static methods are new adapter methods that return `Future<List<ReminderItem>>` for the aggregator. Each calls a backend endpoint and maps results to `ReminderItem`. All failures return empty list so the aggregator never crashes.

Add this import at the top of `business_service.dart` (after existing imports):
```dart
import '../reminders/models/reminder_models.dart';
```

- [ ] **Step 1: Add the `// ── Reminders adapters ──` section at the end of the `BusinessService` class body**

```dart
  // ═══════════════════════════════════════════════════════════════════════
  // Reminders adapters — each returns List<ReminderItem> for the aggregator
  // ═══════════════════════════════════════════════════════════════════════

  static Future<List<ReminderItem>> getExpiringDocuments(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/documents/expiring?user_id=$userId&days=30'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final doc = e as Map<String, dynamic>;
          final expiry = DateTime.tryParse(doc['expiry_date']?.toString() ?? '');
          return ReminderItem(
            id: 'doc_${doc['id']}',
            title: doc['name']?.toString() ?? 'Document expiring',
            subtitle: doc['business_name']?.toString(),
            dueAt: expiry ?? DateTime.now().add(const Duration(days: 7)),
            category: ReminderCategory.document,
            isStandalone: false,
            sourceRoute: '/biz_docs',
          );
        }).toList();
      }
    } catch (e) {
      _log('getExpiringDocuments error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getUpcomingQuotesForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/quotes/upcoming?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final q = e as Map<String, dynamic>;
          final validUntil = DateTime.tryParse(q['valid_until']?.toString() ?? '');
          return ReminderItem(
            id: 'quote_${q['id']}',
            title: 'Quote #${q['quote_number'] ?? q['id']}',
            subtitle: q['customer_name']?.toString(),
            dueAt: validUntil ?? DateTime.now().add(const Duration(days: 3)),
            category: ReminderCategory.quote,
            isStandalone: false,
            sourceRoute: '/biz_quotes',
          );
        }).toList();
      }
    } catch (e) {
      _log('getUpcomingQuotesForReminders error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getUpcomingInvoicesForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/invoices/upcoming?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final inv = e as Map<String, dynamic>;
          final due = DateTime.tryParse(inv['due_date']?.toString() ?? '');
          return ReminderItem(
            id: 'inv_${inv['id']}',
            title: 'Invoice #${inv['invoice_number'] ?? inv['id']}',
            subtitle: inv['customer_name']?.toString(),
            dueAt: due ?? DateTime.now(),
            category: ReminderCategory.invoice,
            isStandalone: false,
            sourceRoute: '/biz_invoices',
          );
        }).toList();
      }
    } catch (e) {
      _log('getUpcomingInvoicesForReminders error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getFailedTransactionsForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/transactions?user_id=$userId&status=failed&limit=10'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final txn = e as Map<String, dynamic>;
          return ReminderItem(
            id: 'txn_${txn['id'] ?? txn['trace_id']}',
            title: 'Muamala umeshindwa',
            subtitle: 'TZS ${txn['amount'] ?? 0}',
            dueAt: DateTime.tryParse(txn['failed_at']?.toString() ?? '') ?? DateTime.now(),
            category: ReminderCategory.transaction,
            isStandalone: false,
            sourceRoute: '/biz_transactions',
          );
        }).toList();
      }
    } catch (e) {
      _log('getFailedTransactionsForReminders error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getRevenueSummaryDigest(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/revenue/digest?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final nextDigest = DateTime.tryParse(
            data['data']?['next_digest']?.toString() ?? '');
        if (nextDigest != null) {
          return [
            ReminderItem(
              id: 'revenue_digest_${nextDigest.millisecondsSinceEpoch}',
              title: 'Muhtasari wa Mapato',
              subtitle: data['data']?['period']?.toString(),
              dueAt: nextDigest,
              category: ReminderCategory.revenue,
              isStandalone: false,
              sourceRoute: '/biz_revenue',
            ),
          ];
        }
      }
    } catch (e) {
      _log('getRevenueSummaryDigest error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getUpcomingRecurringForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/recurring/upcoming?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final r = e as Map<String, dynamic>;
          final nextDate = DateTime.tryParse(r['next_date']?.toString() ?? '');
          return ReminderItem(
            id: 'recurring_${r['id']}',
            title: r['title']?.toString() ?? 'Ankara ya mara kwa mara',
            subtitle: r['customer_name']?.toString(),
            dueAt: nextDate ?? DateTime.now().add(const Duration(days: 1)),
            category: ReminderCategory.recurring,
            isStandalone: false,
            sourceRoute: '/biz_recurring',
          );
        }).toList();
      }
    } catch (e) {
      _log('getUpcomingRecurringForReminders error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getUpcomingDebtsForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/debts/upcoming?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final d = e as Map<String, dynamic>;
          final due = DateTime.tryParse(d['due_date']?.toString() ?? '');
          return ReminderItem(
            id: 'debt_${d['id']}',
            title: d['customer_name']?.toString() ?? 'Deni',
            subtitle: 'TZS ${d['amount'] ?? 0}',
            dueAt: due ?? DateTime.now(),
            category: ReminderCategory.debt,
            isStandalone: false,
            sourceRoute: '/biz_debts',
          );
        }).toList();
      }
    } catch (e) {
      _log('getUpcomingDebtsForReminders error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getUpcomingExpensesForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/expenses/upcoming?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final exp = e as Map<String, dynamic>;
          final due = DateTime.tryParse(exp['due_date']?.toString() ?? '');
          return ReminderItem(
            id: 'expense_${exp['id']}',
            title: exp['description']?.toString() ?? 'Gharama',
            subtitle: 'TZS ${exp['amount'] ?? 0}',
            dueAt: due ?? DateTime.now().add(const Duration(days: 1)),
            category: ReminderCategory.expense,
            isStandalone: false,
            sourceRoute: '/biz_expenses',
          );
        }).toList();
      }
    } catch (e) {
      _log('getUpcomingExpensesForReminders error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getTaxDeadlines(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/tax/deadlines?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final t = e as Map<String, dynamic>;
          final deadline = DateTime.tryParse(t['deadline']?.toString() ?? '');
          return ReminderItem(
            id: 'tax_${t['id']}',
            title: t['title']?.toString() ?? 'Muda wa Kodi',
            subtitle: t['type']?.toString(),
            dueAt: deadline ?? DateTime.now().add(const Duration(days: 30)),
            category: ReminderCategory.tax,
            isStandalone: false,
            sourceRoute: '/biz_tax',
          );
        }).toList();
      }
    } catch (e) {
      _log('getTaxDeadlines error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getCrbPastDueEntries(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/debts/crb/past-due?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final entry = e as Map<String, dynamic>;
          return ReminderItem(
            id: 'crb_${entry['id'] ?? entry['external_ref']}',
            title: 'CRB: ${entry['lender_label'] ?? 'Mkopo umechelewa'}',
            subtitle: '${entry['past_due_days'] ?? 0} siku zimepita',
            dueAt: DateTime.now(),
            category: ReminderCategory.credit,
            isStandalone: false,
            sourceRoute: '/biz_credit',
          );
        }).toList();
      }
    } catch (e) {
      _log('getCrbPastDueEntries error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getExpiringEmployeeContracts(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/employees/expiring?user_id=$userId&days=30'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final emp = e as Map<String, dynamic>;
          final contractEnd = DateTime.tryParse(emp['contract_end']?.toString() ?? '');
          return ReminderItem(
            id: 'emp_${emp['id']}',
            title: '${emp['name'] ?? 'Mfanyakazi'}: mkataba unaisha',
            subtitle: emp['position']?.toString(),
            dueAt: contractEnd ?? DateTime.now().add(const Duration(days: 30)),
            category: ReminderCategory.employee,
            isStandalone: false,
            sourceRoute: '/biz_employees',
          );
        }).toList();
      }
    } catch (e) {
      _log('getExpiringEmployeeContracts error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getUpcomingPayrollForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/payroll/upcoming?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final p = e as Map<String, dynamic>;
          final payDate = DateTime.tryParse(p['pay_date']?.toString() ?? '');
          return ReminderItem(
            id: 'payroll_${p['id']}',
            title: 'Mishahara: ${p['period'] ?? ''}',
            subtitle: p['status']?.toString(),
            dueAt: payDate ?? DateTime.now(),
            category: ReminderCategory.payroll,
            isStandalone: false,
            sourceRoute: '/biz_payroll',
          );
        }).toList();
      }
    } catch (e) {
      _log('getUpcomingPayrollForReminders error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getUpcomingPurchaseOrdersForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/purchase-orders/upcoming?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final po = e as Map<String, dynamic>;
          final delivery = DateTime.tryParse(po['expected_delivery_date']?.toString() ?? '');
          return ReminderItem(
            id: 'po_${po['id']}',
            title: 'PO #${po['po_number'] ?? po['id']}',
            subtitle: po['supplier_name']?.toString(),
            dueAt: delivery ?? DateTime.now().add(const Duration(days: 1)),
            category: ReminderCategory.purchaseOrder,
            isStandalone: false,
            sourceRoute: '/biz_po',
          );
        }).toList();
      }
    } catch (e) {
      _log('getUpcomingPurchaseOrdersForReminders error: $e');
    }
    return [];
  }

  static Future<List<ReminderItem>> getUpcomingAppointmentsForReminders(
      String token, int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/appointments/upcoming?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['data'] as List? ?? []).map((e) {
          final apt = e as Map<String, dynamic>;
          final date = DateTime.tryParse(
              '${apt['date'] ?? ''}T${apt['start_time'] ?? '00:00'}');
          return ReminderItem(
            id: 'apt_${apt['id']}',
            title: apt['title']?.toString() ?? 'Miadi',
            subtitle: apt['customer_name']?.toString(),
            dueAt: date ?? DateTime.now(),
            category: ReminderCategory.appointment,
            isStandalone: false,
            sourceRoute: '/biz_appointments',
          );
        }).toList();
      }
    } catch (e) {
      _log('getUpcomingAppointmentsForReminders error: $e');
    }
    return [];
  }
```

- [ ] **Step 2: Verify compilation**

```bash
flutter analyze lib/business/services/business_service.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/business/services/business_service.dart
git commit -m "feat(reminders): add 14 adapter methods to BusinessService"
```

---

## Task 5: CalendarService and TenderService Adapters

**Files:**
- Modify: `lib/calendar/services/calendar_service.dart` (add instance method)
- Modify: `lib/tenders/services/tender_service.dart` (add static method)

- [ ] **Step 1: Add import to calendar_service.dart**

At the top of `lib/calendar/services/calendar_service.dart`, after existing imports, add:
```dart
import '../../reminders/models/reminder_models.dart';
```

- [ ] **Step 2: Add `getUpcomingWithReminders` to CalendarService class**

```dart
  // ── Reminders adapter ──────────────────────────────────────────

  Future<List<ReminderItem>> getUpcomingWithReminders({
    required int userId,
    required String token,
    int lookAheadDays = 30,
  }) async {
    try {
      final now = DateTime.now();
      final uri = Uri.parse('$_baseUrl/calendar/events').replace(
        queryParameters: {
          'user_id': userId.toString(),
          'year': now.year.toString(),
          'month': now.month.toString(),
          'with_reminders': '1',
        },
      );
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final events = (data['data'] as List? ?? [])
            .map((j) => CalendarEvent.fromJson(j as Map<String, dynamic>))
            .toList();
        return events
            .where((e) => e.reminder != EventReminder.none)
            .map((e) => ReminderItem(
                  id: 'cal_${e.id}',
                  title: e.title,
                  dueAt: _reminderDateTime(e),
                  category: ReminderCategory.calendar,
                  isStandalone: false,
                  sourceRoute: '/calendar',
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('[CalendarService] getUpcomingWithReminders error: $e');
    }
    return [];
  }

  DateTime _reminderDateTime(CalendarEvent event) {
    final base = event.startTime != null
        ? DateTime.tryParse('${_dateStr(event.date)}T${event.startTime}') ??
            event.date
        : event.date;
    switch (event.reminder) {
      case EventReminder.min5:
        return base.subtract(const Duration(minutes: 5));
      case EventReminder.min15:
        return base.subtract(const Duration(minutes: 15));
      case EventReminder.min30:
        return base.subtract(const Duration(minutes: 30));
      case EventReminder.hour1:
        return base.subtract(const Duration(hours: 1));
      case EventReminder.day1:
        return base.subtract(const Duration(days: 1));
      case EventReminder.none:
        return base;
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
```

- [ ] **Step 3: Add import to tender_service.dart**

At the top of `lib/tenders/services/tender_service.dart`, after existing imports, add:
```dart
import '../../reminders/models/reminder_models.dart';
```

- [ ] **Step 4: Add `getUpcomingTenderDeadlines` to TenderService class**

```dart
  // ── Reminders adapter ──────────────────────────────────────────

  static Future<List<ReminderItem>> getUpcomingTenderDeadlines(int userId) async {
    try {
      final tenderToken = await _getToken();
      if (tenderToken == null) return [];
      final res = await http.get(
        Uri.parse('$_tendersBaseUrl/tenders?status=active&closing_soon=true'),
        headers: {'Authorization': 'Bearer $tenderToken'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final items = <ReminderItem>[];
        for (final e in (data['data'] as List? ?? [])) {
          final t = e as Map<String, dynamic>;
          final closing = DateTime.tryParse(t['closing_date']?.toString() ?? '');
          if (closing != null) {
            items.add(ReminderItem(
              id: 'tender_close_${t['id']}',
              title: t['title']?.toString() ?? 'Zabuni',
              subtitle: 'Inafungwa: ${_formatDate(closing)}',
              dueAt: closing,
              category: ReminderCategory.tender,
              isStandalone: false,
              sourceRoute: '/biz_tenders',
            ));
          }
          final deadline = DateTime.tryParse(t['deadline']?.toString() ?? '');
          if (deadline != null) {
            items.add(ReminderItem(
              id: 'tender_apply_${t['id']}',
              title: 'Ombi: ${t['title'] ?? 'Zabuni'}',
              subtitle: 'Deadline: ${_formatDate(deadline)}',
              dueAt: deadline,
              category: ReminderCategory.tender,
              isStandalone: false,
              sourceRoute: '/biz_tenders',
            ));
          }
        }
        return items;
      }
    } catch (e) {
      _logError('getUpcomingTenderDeadlines', e);
    }
    return [];
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
```

- [ ] **Step 5: Verify compilation**

```bash
flutter analyze lib/calendar/services/calendar_service.dart lib/tenders/services/tender_service.dart
```
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/calendar/services/calendar_service.dart lib/tenders/services/tender_service.dart
git commit -m "feat(reminders): add reminder adapter methods to CalendarService and TenderService"
```

---

## Task 6: RemindersAggregator

**Files:**
- Create: `lib/reminders/services/reminders_aggregator.dart`
- Create: `test/reminders/services/reminders_aggregator_test.dart`

- [ ] **Step 1: Create test file**

```dart
// test/reminders/services/reminders_aggregator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/reminders/models/reminder_models.dart';
import 'package:tajiri/reminders/services/reminders_aggregator.dart';

void main() {
  group('RemindersAggregator', () {
    test('merge deduplicates by id', () {
      final a = ReminderItem(
        id: 'inv_1',
        title: 'Invoice',
        dueAt: DateTime(2026, 6, 1),
        category: ReminderCategory.invoice,
        isStandalone: false,
      );
      final b = ReminderItem(
        id: 'inv_1', // duplicate
        title: 'Invoice (dup)',
        dueAt: DateTime(2026, 6, 1),
        category: ReminderCategory.invoice,
        isStandalone: false,
      );
      final merged = RemindersAggregator.merge([a, b]);
      expect(merged.length, 1);
    });

    test('merge sorts by dueAt ascending', () {
      final later = ReminderItem(
        id: 'a',
        title: 'Later',
        dueAt: DateTime(2026, 7, 1),
        category: ReminderCategory.general,
        isStandalone: false,
      );
      final sooner = ReminderItem(
        id: 'b',
        title: 'Sooner',
        dueAt: DateTime(2026, 5, 1),
        category: ReminderCategory.general,
        isStandalone: false,
      );
      final merged = RemindersAggregator.merge([later, sooner]);
      expect(merged.first.id, 'b');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/reminders/services/reminders_aggregator_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create reminders_aggregator.dart**

```dart
// lib/reminders/services/reminders_aggregator.dart
import 'package:flutter/foundation.dart';
import '../../business/services/business_service.dart';
import '../../calendar/services/calendar_service.dart';
import '../../tenders/services/tender_service.dart';
import '../models/reminder_models.dart';
import 'reminders_service.dart';

class RemindersAggregator {
  static Future<List<ReminderItem>> _safe(Future<List<ReminderItem>> f) =>
      f.catchError((Object e) {
        debugPrint('[RemindersAggregator] source error: $e');
        return <ReminderItem>[];
      });

  /// Fetch from all 16 sources in parallel, merge, deduplicate, sort.
  static Future<List<ReminderItem>> getAll({
    required String token,
    required int userId,
  }) async {
    final results = await Future.wait([
      _safe(CalendarService().getUpcomingWithReminders(userId: userId, token: token)),
      _safe(BusinessService.getUpcomingAppointmentsForReminders(token, userId)),
      _safe(BusinessService.getExpiringDocuments(token, userId)),
      _safe(BusinessService.getUpcomingQuotesForReminders(token, userId)),
      _safe(BusinessService.getUpcomingInvoicesForReminders(token, userId)),
      _safe(BusinessService.getFailedTransactionsForReminders(token, userId)),
      _safe(BusinessService.getRevenueSummaryDigest(token, userId)),
      _safe(BusinessService.getUpcomingRecurringForReminders(token, userId)),
      _safe(BusinessService.getUpcomingDebtsForReminders(token, userId)),
      _safe(BusinessService.getUpcomingExpensesForReminders(token, userId)),
      _safe(BusinessService.getTaxDeadlines(token, userId)),
      _safe(BusinessService.getCrbPastDueEntries(token, userId)),
      _safe(BusinessService.getExpiringEmployeeContracts(token, userId)),
      _safe(BusinessService.getUpcomingPayrollForReminders(token, userId)),
      _safe(BusinessService.getUpcomingPurchaseOrdersForReminders(token, userId)),
      _safe(TenderService.getUpcomingTenderDeadlines(userId)),
      _safe(RemindersService.getAll(userId: userId, token: token)),
    ]);

    final all = results.expand((list) => list).toList();
    return merge(all);
  }

  /// Deduplicate by id, sort by dueAt ascending.
  static List<ReminderItem> merge(List<ReminderItem> items) {
    final seen = <String>{};
    final unique = <ReminderItem>[];
    for (final item in items) {
      if (seen.add(item.id)) unique.add(item);
    }
    unique.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return unique;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/reminders/services/reminders_aggregator_test.dart
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/reminders/services/reminders_aggregator.dart test/reminders/services/reminders_aggregator_test.dart
git commit -m "feat(reminders): add RemindersAggregator with parallel fetch and dedup"
```

---

## Task 7: RemindersNotificationService

**Files:**
- Create: `lib/reminders/services/reminders_notification_service.dart`

- [ ] **Step 1: Create reminders_notification_service.dart**

```dart
// lib/reminders/services/reminders_notification_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder_models.dart';

class RemindersNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'reminders';
  static const _channelName = 'Vikumbusho';
  static const _channelDesc = 'Vikumbusho vya biashara';

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Schedule notifications for a list of items.
  /// Cancels notifications for IDs no longer in the list.
  static Future<void> scheduleAll(List<ReminderItem> items) async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.map((r) => r.id).toSet();
    final newIds = <int>{};

    for (final item in items) {
      if (item.isDone) continue;
      final fireTimes = _fireTimes(item);
      for (int i = 0; i < fireTimes.length; i++) {
        final fireTime = fireTimes[i];
        if (fireTime.isBefore(DateTime.now())) continue;
        final notifId = _notifId(item.id, i);
        newIds.add(notifId);
        await _scheduleOne(
          id: notifId,
          title: item.category.displayName,
          body: item.title,
          fireAt: fireTime,
          payload: jsonEncode({'type': 'reminder', 'id': item.id}),
        );
      }
    }

    // Cancel notifications no longer needed
    for (final oldId in pendingIds.difference(newIds)) {
      await _plugin.cancel(oldId);
    }
  }

  static Future<void> cancel(String itemId) async {
    await init();
    // Cancel all lead-time slots (max 3)
    for (int i = 0; i < 3; i++) {
      await _plugin.cancel(_notifId(itemId, i));
    }
  }

  // ── Lead time calculation by category ─────────────────────────────────

  static List<DateTime> _fireTimes(ReminderItem item) {
    final due = item.dueAt;
    switch (item.category) {
      case ReminderCategory.document:
      case ReminderCategory.tax:
        return [
          due.subtract(const Duration(days: 30)),
          due.subtract(const Duration(days: 7)),
          due.subtract(const Duration(days: 1)),
        ];
      case ReminderCategory.invoice:
      case ReminderCategory.debt:
        return [
          due.subtract(const Duration(days: 7)),
          due.subtract(const Duration(days: 3)),
          due.subtract(const Duration(days: 1)),
        ];
      case ReminderCategory.quote:
      case ReminderCategory.tender:
        return [
          due.subtract(const Duration(days: 7)),
          due.subtract(const Duration(days: 3)),
          due.subtract(const Duration(days: 1)),
        ];
      case ReminderCategory.employee:
        return [
          due.subtract(const Duration(days: 30)),
          due.subtract(const Duration(days: 7)),
        ];
      case ReminderCategory.appointment:
        return [
          due.subtract(const Duration(hours: 24)),
          due.subtract(const Duration(hours: 1)),
        ];
      case ReminderCategory.purchaseOrder:
      case ReminderCategory.recurring:
      case ReminderCategory.expense:
        return [due.subtract(const Duration(days: 1))];
      case ReminderCategory.payroll:
      case ReminderCategory.transaction:
      case ReminderCategory.credit:
      case ReminderCategory.revenue:
        return [due];
      case ReminderCategory.calendar:
      case ReminderCategory.general:
        return [due];
    }
  }

  static int _notifId(String itemId, int slot) =>
      '${itemId}_$slot'.hashCode.abs() % 2147483647;

  static Future<void> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(fireAt, tz.local),
        NotificationDetails(
          android: const AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[RemindersNotificationService] schedule error: $e');
    }
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
flutter analyze lib/reminders/services/reminders_notification_service.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/reminders/services/reminders_notification_service.dart
git commit -m "feat(reminders): add RemindersNotificationService with per-category timing rules"
```

---

## Task 8: ReminderCard Widget

**Files:**
- Create: `lib/reminders/widgets/reminder_card.dart`

- [ ] **Step 1: Create reminder_card.dart**

```dart
// lib/reminders/widgets/reminder_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/reminder_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFFFFFF);

class ReminderCard extends StatelessWidget {
  final ReminderItem item;
  final VoidCallback onTap;
  final VoidCallback onDone;
  final VoidCallback onUndoDone;
  final void Function(Duration snooze) onSnooze;
  final VoidCallback? onDelete; // null for aggregated items

  const ReminderCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDone,
    required this.onUndoDone,
    required this.onSnooze,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => item.isDone ? onUndoDone() : onDone(),
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            icon: item.isDone ? Icons.undo_rounded : Icons.check_rounded,
            label: item.isDone ? 'Rejesha' : 'Imekamilika',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showSnoozeSheet(context),
            backgroundColor: const Color(0xFF555555),
            foregroundColor: Colors.white,
            icon: Icons.snooze_rounded,
            label: 'Ahirisha',
          ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Futa',
            ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: _kBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _CategoryDot(category: item.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.isDone ? _kSecondary : _kPrimary,
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDue(item.dueAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: _isOverdue(item) ? Colors.red.shade700 : _kSecondary,
                            fontWeight: _isOverdue(item)
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (!item.isStandalone) ...[
                          const SizedBox(width: 6),
                          _SourceBadge(category: item.category),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(item.category.icon, size: 18, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOverdue(ReminderItem item) =>
      !item.isDone && item.dueAt.isBefore(DateTime.now());

  String _formatDue(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diff = itemDay.difference(today).inDays;
    if (diff == 0) return 'Leo ${DateFormat('HH:mm').format(dt)}';
    if (diff == 1) return 'Kesho ${DateFormat('HH:mm').format(dt)}';
    if (diff == -1) return 'Jana';
    if (diff < 0) return 'Imechelewa ${-diff} siku';
    if (diff < 7) return 'Baada ya siku $diff';
    return DateFormat('d MMM yyyy').format(dt);
  }

  void _showSnoozeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Ahirisha',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Dakika 15'),
              onTap: () {
                Navigator.pop(context);
                onSnooze(const Duration(minutes: 15));
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule_rounded),
              title: const Text('Saa 1'),
              onTap: () {
                Navigator.pop(context);
                onSnooze(const Duration(hours: 1));
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Kesho'),
              onTap: () {
                Navigator.pop(context);
                onSnooze(const Duration(days: 1));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final ReminderCategory category;
  const _CategoryDot({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(category.icon, size: 18, color: const Color(0xFF1A1A1A)),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final ReminderCategory category;
  const _SourceBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.07),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.displayName,
        style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
flutter analyze lib/reminders/widgets/reminder_card.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/reminders/widgets/reminder_card.dart
git commit -m "feat(reminders): add ReminderCard swipeable widget"
```

---

## Task 9: AddReminderPage

**Files:**
- Create: `lib/reminders/pages/add_reminder_page.dart`

- [ ] **Step 1: Create add_reminder_page.dart**

```dart
// lib/reminders/pages/add_reminder_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/local_storage_service.dart';
import '../models/reminder_models.dart';
import '../services/reminders_service.dart';
import '../services/reminders_notification_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AddReminderPage extends StatefulWidget {
  final int userId;
  final ReminderItem? existing; // non-null = edit mode

  const AddReminderPage({super.key, required this.userId, this.existing});

  @override
  State<AddReminderPage> createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _dueAt = DateTime.now().add(const Duration(hours: 1));
  ReminderCategory _category = ReminderCategory.general;
  ReminderRepeat _repeat = ReminderRepeat.none;
  bool _notify = true;
  bool _saving = false;
  String? _token;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final s = await LocalStorageService.getInstance();
    _token = s.getAuthToken();
    if (_isEdit) {
      final e = widget.existing!;
      _titleCtrl.text = e.title;
      _noteCtrl.text = e.subtitle ?? '';
      _dueAt = e.dueAt;
      _category = e.category;
      _repeat = e.repeat;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (_token == null) return;
    setState(() => _saving = true);

    final item = ReminderItem(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      subtitle: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      dueAt: _dueAt,
      category: _category,
      repeat: _repeat,
      isDone: false,
      isStandalone: true,
    );

    ReminderResult<ReminderItem> result;
    if (_isEdit) {
      result = await RemindersService.update(item, token: _token!);
    } else {
      result = await RemindersService.create(item,
          token: _token!, userId: widget.userId);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success && result.data != null && _notify) {
      await RemindersNotificationService.scheduleAll([result.data!]);
    }

    if (result.success && mounted) {
      Navigator.pop(context, result.data);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuhifadhi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
          _isEdit ? 'Hariri Kikumbusho' : 'Kikumbusho Kipya',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Hifadhi',
                    style: TextStyle(
                        color: _kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Kichwa *',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            // Note
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Maelezo (hiari)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Date & time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded, color: _kPrimary),
              title: Text(
                DateFormat('EEE, d MMM yyyy • HH:mm').format(_dueAt),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Tarehe na muda'),
              onTap: _pickDateTime,
              tileColor: Colors.transparent,
            ),
            const Divider(),
            // Category
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aina',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSecondary)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReminderCategory.values
                  .where((c) => c != ReminderCategory.calendar)
                  .map((c) => ChoiceChip(
                        label: Text(c.displayName,
                            style: const TextStyle(fontSize: 12)),
                        avatar: Icon(c.icon, size: 14),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: _kPrimary.withOpacity(0.12),
                        checkmarkColor: _kPrimary,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // Repeat
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Marudio',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kSecondary)),
            ),
            DropdownButtonFormField<ReminderRepeat>(
              value: _repeat,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ReminderRepeat.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.displayName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _repeat = v ?? ReminderRepeat.none),
            ),
            const SizedBox(height: 16),
            // Notify toggle
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tuma arifa'),
              subtitle: const Text('Pokea taarifa kabla ya muda'),
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
              activeColor: _kPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
flutter analyze lib/reminders/pages/add_reminder_page.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/reminders/pages/add_reminder_page.dart
git commit -m "feat(reminders): add AddReminderPage create/edit form"
```

---

## Task 10: RemindersHomePage

**Files:**
- Create: `lib/reminders/pages/reminders_home_page.dart`

- [ ] **Step 1: Create reminders_home_page.dart**

```dart
// lib/reminders/pages/reminders_home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/local_storage_service.dart';
import '../models/reminder_models.dart';
import '../services/reminders_aggregator.dart';
import '../services/reminders_notification_service.dart';
import '../services/reminders_service.dart';
import '../widgets/reminder_card.dart';
import 'add_reminder_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RemindersHomePage extends StatefulWidget {
  final int userId;
  const RemindersHomePage({super.key, required this.userId});

  @override
  State<RemindersHomePage> createState() => _RemindersHomePageState();
}

class _RemindersHomePageState extends State<RemindersHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _token;
  bool _loading = true;
  String? _error;
  List<ReminderItem> _all = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final s = await LocalStorageService.getInstance();
    _token = s.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await RemindersAggregator.getAll(
        token: _token!,
        userId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _all = items;
        _loading = false;
      });
      await RemindersNotificationService.scheduleAll(items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Imeshindwa kupakia vikumbusho';
        _loading = false;
      });
    }
  }

  List<ReminderItem> get _today {
    final today = DateTime.now();
    return _all
        .where((i) =>
            !i.isDone &&
            i.dueAt.year == today.year &&
            i.dueAt.month == today.month &&
            i.dueAt.day == today.day)
        .toList();
  }

  List<ReminderItem> get _upcoming {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    return _all
        .where((i) =>
            !i.isDone &&
            DateTime(i.dueAt.year, i.dueAt.month, i.dueAt.day)
                .isAtSameMomentAs(tomorrowStart) ||
            (!i.isDone &&
                DateTime(i.dueAt.year, i.dueAt.month, i.dueAt.day)
                    .isAfter(tomorrowStart)))
        .toList();
  }

  List<ReminderItem> get _done => _all.where((i) => i.isDone).toList();

  Future<void> _markDone(ReminderItem item) async {
    if (_token == null) return;
    await RemindersService.markDone(item.id, token: _token!);
    await RemindersNotificationService.cancel(item.id);
    setState(() {
      _all = _all
          .map((i) => i.id == item.id ? i.copyWith(isDone: true) : i)
          .toList();
    });
  }

  Future<void> _undoDone(ReminderItem item) async {
    if (_token == null) return;
    final updated = item.copyWith(isDone: false);
    await RemindersService.update(updated, token: _token!);
    setState(() {
      _all = _all.map((i) => i.id == item.id ? updated : i).toList();
    });
    await RemindersNotificationService.scheduleAll([updated]);
  }

  Future<void> _snooze(ReminderItem item, Duration by) async {
    if (_token == null) return;
    final snoozed = item.copyWith(dueAt: DateTime.now().add(by));
    await RemindersService.update(snoozed, token: _token!);
    setState(() {
      _all = _all.map((i) => i.id == item.id ? snoozed : i).toList();
    });
    await RemindersNotificationService.scheduleAll([snoozed]);
  }

  Future<void> _delete(ReminderItem item) async {
    if (_token == null) return;
    await RemindersService.delete(item.id, token: _token!);
    await RemindersNotificationService.cancel(item.id);
    setState(() => _all.removeWhere((i) => i.id == item.id));
  }

  void _openItem(ReminderItem item) {
    if (item.isStandalone) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AddReminderPage(userId: widget.userId, existing: item),
        ),
      ).then((_) => _load());
    } else if (item.sourceRoute != null) {
      Navigator.pushNamed(context, item.sourceRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: const Text(
          'Vikumbusho',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kPrimary),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          tabs: [
            Tab(text: 'Leo (${_today.length})'),
            Tab(text: 'Ijayo (${_upcoming.length})'),
            Tab(text: 'Zilizokamilika (${_done.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddReminderPage(userId: widget.userId),
          ),
        ).then((_) => _load()),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildList(_today),
                      _buildGroupedList(_upcoming),
                      _buildList(_done),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: _kSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Jaribu tena')),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ReminderItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Hakuna vikumbusho',
            style: TextStyle(color: _kSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (_, i) => _buildCard(items[i]),
    );
  }

  Widget _buildGroupedList(List<ReminderItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Hakuna vikumbusho vijavyo',
            style: TextStyle(color: _kSecondary)),
      );
    }
    // Group by date
    final Map<String, List<ReminderItem>> grouped = {};
    for (final item in items) {
      final key = DateFormat('EEEE, d MMMM yyyy').format(item.dueAt);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final sections = grouped.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sections.length,
      itemBuilder: (_, i) {
        final section = sections[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                section.key,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kSecondary),
              ),
            ),
            ...section.value.map(_buildCard),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ],
        );
      },
    );
  }

  Widget _buildCard(ReminderItem item) {
    return ReminderCard(
      item: item,
      onTap: () => _openItem(item),
      onDone: () => _markDone(item),
      onUndoDone: () => _undoDone(item),
      onSnooze: (d) => _snooze(item, d),
      onDelete: item.isStandalone ? () => _delete(item) : null,
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
flutter analyze lib/reminders/pages/reminders_home_page.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/reminders/pages/reminders_home_page.dart
git commit -m "feat(reminders): add RemindersHomePage with Leo/Ijayo/Zilizokamilika tabs"
```

---

## Task 11: RemindersModule, Profile Wiring, and l10n

**Files:**
- Create: `lib/reminders/reminders_module.dart`
- Modify: `lib/screens/profile/profile_screen.dart`
- Modify: `lib/l10n/app_strings.dart`

- [ ] **Step 1: Create reminders_module.dart**

```dart
// lib/reminders/reminders_module.dart
import 'package:flutter/material.dart';
import 'pages/reminders_home_page.dart';

class RemindersModule extends StatelessWidget {
  final int userId;
  const RemindersModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return RemindersHomePage(userId: userId);
  }
}
```

- [ ] **Step 2: Add import to profile_screen.dart**

Open `lib/screens/profile/profile_screen.dart`. After the existing business-related imports (around line 89), add:
```dart
import '../../reminders/reminders_module.dart';
```

- [ ] **Step 3: Replace biz_reminders case in profile_screen.dart**

Find this block (around line 2242):
```dart
      case 'biz_reminders':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? ReminderSettingsPage(businessId: fId) : const SizedBox.shrink());
```

Replace with:
```dart
      case 'biz_reminders':
        return RemindersModule(userId: userId);
```

- [ ] **Step 4: Add l10n strings to app_strings.dart**

Find the `case 'biz_profile':` block in `lib/l10n/app_strings.dart` (around the business section). Add the following case alongside the other business module cases:

```dart
      case 'biz_reminders': return isSwahili ? 'Vikumbusho' : 'Reminders';
```

- [ ] **Step 5: Verify full compilation**

```bash
flutter analyze lib/
```
Expected: No errors.

- [ ] **Step 6: Run all reminders tests**

```bash
flutter test test/reminders/
```
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/reminders/reminders_module.dart lib/screens/profile/profile_screen.dart lib/l10n/app_strings.dart
git commit -m "feat(reminders): wire RemindersModule into profile biz_reminders tab"
```

---

## Final Verification

- [ ] **Run the app and navigate to Profile → BUSINESS → Reminders**

```bash
flutter run
```

Verify:
1. `biz_reminders` tile opens `RemindersHomePage` (3 tabs visible)
2. FAB opens `AddReminderPage` — create a test reminder and save
3. New reminder appears in Leo or Ijayo tab
4. Swipe right to mark done → moves to Zilizokamilika tab
5. Swipe left to snooze → time updates
6. Swipe left → delete (standalone only) → removed from list
7. Aggregated items show source badge and navigate to source route on tap

- [ ] **Final commit**

```bash
git add -A
git commit -m "feat(reminders): complete reminders module — 24 notification sources, SQLite sync, local notifications"
```
