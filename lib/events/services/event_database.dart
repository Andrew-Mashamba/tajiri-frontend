// lib/events/services/event_database.dart
// SQLite local-first storage for events module.
// Pattern: lib/services/message_database.dart
// json_data TEXT column for lossless model reconstruction.
// Indexed columns for fast queries.
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/event.dart';
import '../models/event_ticket.dart';
import '../models/contribution.dart';
import '../models/budget.dart';
import '../models/guest.dart';

class EventDatabase {
  static final EventDatabase instance = EventDatabase._();
  EventDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tajiri_events.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT,
        start_date TEXT,
        status TEXT,
        template_type TEXT,
        json_data TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_events_start_date ON events(start_date)');
    await db.execute('CREATE INDEX idx_events_category ON events(category)');
    await db.execute('CREATE INDEX idx_events_status ON events(status)');

    await db.execute('''
      CREATE TABLE tickets (
        id INTEGER PRIMARY KEY,
        event_id INTEGER NOT NULL,
        ticket_number TEXT,
        status TEXT,
        qr_code_data TEXT,
        json_data TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_tickets_event ON tickets(event_id)');
    await db.execute('CREATE INDEX idx_tickets_status ON tickets(status)');

    await db.execute('''
      CREATE TABLE contributions (
        id INTEGER PRIMARY KEY,
        event_id INTEGER NOT NULL,
        user_id INTEGER,
        amount_pledged REAL DEFAULT 0,
        amount_paid REAL DEFAULT 0,
        status TEXT,
        category TEXT,
        json_data TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_contributions_event ON contributions(event_id)');
    await db.execute('CREATE INDEX idx_contributions_status ON contributions(status)');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY,
        event_id INTEGER NOT NULL,
        category_name TEXT,
        amount REAL DEFAULT 0,
        sub_committee_id INTEGER,
        status TEXT,
        json_data TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_event ON expenses(event_id)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category_name)');

    await db.execute('''
      CREATE TABLE committee_members (
        id INTEGER PRIMARY KEY,
        event_id INTEGER NOT NULL,
        committee_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role TEXT,
        json_data TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_committee_event ON committee_members(event_id)');

    await db.execute('''
      CREATE TABLE guests (
        id INTEGER PRIMARY KEY,
        event_id INTEGER NOT NULL,
        user_id INTEGER,
        category TEXT,
        rsvp_status TEXT,
        card_status TEXT,
        json_data TEXT NOT NULL,
        synced_at TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_guests_event ON guests(event_id)');
    await db.execute('CREATE INDEX idx_guests_rsvp ON guests(rsvp_status)');

    await db.execute('''
      CREATE TABLE sync_state (
        entity_type TEXT PRIMARY KEY,
        last_synced_id INTEGER,
        last_sync_timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ── Events ──

  Future<void> upsertEvents(List<Event> events) async {
    final db = await database;
    final batch = db.batch();
    for (final event in events) {
      batch.insert('events', {
        'id': event.id,
        'name': event.name,
        'category': event.category.name,
        'start_date': event.startDate.toIso8601String(),
        'status': event.status.name,
        'json_data': jsonEncode(event.toJson()),
        'synced_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Event>> getUpcomingEvents({int limit = 20}) async {
    final db = await database;
    final rows = await db.query('events',
      where: 'start_date > ? AND status = ?',
      whereArgs: [DateTime.now().toIso8601String(), 'published'],
      orderBy: 'start_date ASC',
      limit: limit,
    );
    return rows.map((r) => Event.fromJson(jsonDecode(r['json_data'] as String))).toList();
  }

  Future<List<Event>> getEventsByCategory(String category, {int limit = 20}) async {
    final db = await database;
    final rows = await db.query('events',
      where: 'category = ? AND status = ?',
      whereArgs: [category, 'published'],
      orderBy: 'start_date ASC',
      limit: limit,
    );
    return rows.map((r) => Event.fromJson(jsonDecode(r['json_data'] as String))).toList();
  }

  Future<Event?> getEvent(int eventId) async {
    final db = await database;
    final rows = await db.query('events', where: 'id = ?', whereArgs: [eventId], limit: 1);
    if (rows.isEmpty) return null;
    return Event.fromJson(jsonDecode(rows.first['json_data'] as String));
  }

  // ── Tickets ──

  Future<void> upsertTickets(List<EventTicket> tickets) async {
    final db = await database;
    final batch = db.batch();
    for (final t in tickets) {
      batch.insert('tickets', {
        'id': t.id,
        'event_id': t.eventId,
        'ticket_number': t.ticketNumber,
        'status': t.status.name,
        'qr_code_data': t.qrCodeData,
        'json_data': jsonEncode({
          'id': t.id, 'event_id': t.eventId, 'user_id': t.userId,
          'ticket_number': t.ticketNumber, 'qr_code_data': t.qrCodeData,
          'status': t.status.name, 'purchase_date': t.purchaseDate.toIso8601String(),
          'price_paid': t.pricePaid, 'currency': t.currency,
          'payment_method': t.paymentMethod, 'guest_name': t.guestName,
        }),
        'synced_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<EventTicket>> getMyActiveTickets() async {
    final db = await database;
    final rows = await db.query('tickets',
      where: 'status = ?', whereArgs: ['active'],
      orderBy: 'id DESC',
    );
    return rows.map((r) => EventTicket.fromJson(jsonDecode(r['json_data'] as String))).toList();
  }

  Future<void> cacheTicketQR(int ticketId, String qrData) async {
    final db = await database;
    await db.update('tickets', {'qr_code_data': qrData}, where: 'id = ?', whereArgs: [ticketId]);
  }

  Future<String?> getCachedTicketQR(int ticketId) async {
    final db = await database;
    final rows = await db.query('tickets', columns: ['qr_code_data'], where: 'id = ?', whereArgs: [ticketId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['qr_code_data'] as String?;
  }

  // ── Contributions ──

  Future<void> upsertContributions(int eventId, List<Contribution> contributions) async {
    final db = await database;
    final batch = db.batch();
    for (final c in contributions) {
      batch.insert('contributions', {
        'id': c.id,
        'event_id': c.eventId,
        'user_id': c.userId,
        'amount_pledged': c.amountPledged,
        'amount_paid': c.amountPaid,
        'status': c.status.name,
        'category': c.category.name,
        'json_data': jsonEncode(c.toJson()),
        'synced_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<double> getTotalContributions(int eventId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount_paid) as total FROM contributions WHERE event_id = ?', [eventId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalPledged(int eventId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount_pledged) as total FROM contributions WHERE event_id = ?', [eventId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> getContributorCount(int eventId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM contributions WHERE event_id = ?', [eventId]);
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<Map<String, double>> getContributionsByCategory(int eventId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT category, SUM(amount_paid) as total FROM contributions WHERE event_id = ? GROUP BY category',
      [eventId],
    );
    return {for (final r in result) (r['category'] as String? ?? ''): (r['total'] as num?)?.toDouble() ?? 0};
  }

  // ── Expenses ──

  Future<void> upsertExpenses(int eventId, List<Expense> expenses) async {
    final db = await database;
    final batch = db.batch();
    for (final e in expenses) {
      batch.insert('expenses', {
        'id': e.id,
        'event_id': e.eventId,
        'category_name': e.categoryName,
        'amount': e.amount,
        'sub_committee_id': e.subCommitteeId,
        'status': e.status,
        'json_data': jsonEncode(e.toJson()),
        'synced_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<double> getTotalExpenses(int eventId) async {
    final db = await database;
    final result = await db.rawQuery("SELECT SUM(amount) as total FROM expenses WHERE event_id = ? AND status = 'approved'", [eventId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<Map<String, double>> getExpensesByCategory(int eventId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT category_name, SUM(amount) as total FROM expenses WHERE event_id = ? AND status = 'approved' GROUP BY category_name",
      [eventId],
    );
    return {for (final r in result) (r['category_name'] as String? ?? ''): (r['total'] as num?)?.toDouble() ?? 0};
  }

  // ── Guests ──

  Future<void> upsertGuests(int eventId, List<EventGuest> guests) async {
    final db = await database;
    final batch = db.batch();
    for (final g in guests) {
      batch.insert('guests', {
        'id': g.id,
        'event_id': g.eventId,
        'user_id': g.userId,
        'category': g.category.name,
        'rsvp_status': g.rsvpStatus,
        'card_status': g.cardStatus.name,
        'json_data': jsonEncode(g.toJson()),
        'synced_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<int> getGuestCount(int eventId, {String? rsvpStatus}) async {
    final db = await database;
    if (rsvpStatus != null) {
      final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM guests WHERE event_id = ? AND rsvp_status = ?', [eventId, rsvpStatus]);
      return (result.first['cnt'] as int?) ?? 0;
    }
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM guests WHERE event_id = ?', [eventId]);
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── Sync State ──

  Future<DateTime?> getLastSyncTimestamp(String entityType) async {
    final db = await database;
    final rows = await db.query('sync_state', where: 'entity_type = ?', whereArgs: [entityType], limit: 1);
    if (rows.isEmpty || rows.first['last_sync_timestamp'] == null) return null;
    return DateTime.tryParse(rows.first['last_sync_timestamp'] as String);
  }

  Future<void> updateSyncTimestamp(String entityType) async {
    final db = await database;
    await db.insert('sync_state', {
      'entity_type': entityType,
      'last_sync_timestamp': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  bool isStale(String entityType, {Duration threshold = const Duration(minutes: 15), DateTime? lastSync}) {
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > threshold;
  }

  // ── Pending Queue (Offline Mutations) ──

  Future<void> addPendingAction({
    required String entityType,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert('pending_queue', {
      'entity_type': entityType,
      'action': action,
      'payload': jsonEncode(payload),
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final db = await database;
    return await db.query('pending_queue', orderBy: 'created_at ASC');
  }

  Future<void> removePendingAction(int id) async {
    final db = await database;
    await db.delete('pending_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetry(int id) async {
    final db = await database;
    await db.rawUpdate('UPDATE pending_queue SET retry_count = retry_count + 1 WHERE id = ?', [id]);
  }

  // ── Clear ──

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('events');
    await db.delete('tickets');
    await db.delete('contributions');
    await db.delete('expenses');
    await db.delete('committee_members');
    await db.delete('guests');
    await db.delete('sync_state');
    await db.delete('pending_queue');
  }
}
