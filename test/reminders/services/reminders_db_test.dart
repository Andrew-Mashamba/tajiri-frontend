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

  ReminderItem _item({String id = 'test_1'}) => ReminderItem(
        id: id,
        title: 'Test reminder',
        dueAt: DateTime(2026, 6, 1, 9, 0),
        category: ReminderCategory.invoice,
        isStandalone: true,
      );

  group('RemindersDb', () {
    test('insert and getAll returns item', () async {
      await db.insert(_item(), userId: 1);
      final items = await db.getAll(userId: 1);
      expect(items.length, 1);
      expect(items.first.id, 'test_1');
    });

    test('update modifies title', () async {
      await db.insert(_item(), userId: 1);
      await db.update(_item().copyWith(title: 'Updated'));
      final items = await db.getAll(userId: 1);
      expect(items.first.title, 'Updated');
    });

    test('delete removes item', () async {
      await db.insert(_item(), userId: 1);
      await db.delete('test_1');
      final items = await db.getAll(userId: 1);
      expect(items, isEmpty);
    });

    test('markDone sets isDone = true', () async {
      await db.insert(_item(), userId: 1);
      await db.markDone('test_1');
      final items = await db.getAll(userId: 1);
      expect(items.first.isDone, true);
    });

    test('getPendingSync returns rows with synced_at null', () async {
      await db.insert(_item(), userId: 1);
      final pending = await db.getPendingSync(userId: 1);
      expect(pending.length, 1);
    });

    test('markSynced clears from pending sync', () async {
      await db.insert(_item(), userId: 1);
      await db.markSynced('test_1', 99);
      final pending = await db.getPendingSync(userId: 1);
      expect(pending, isEmpty);
    });

    test('getAll only returns items for given userId', () async {
      await db.insert(_item(id: 'u1'), userId: 1);
      await db.insert(_item(id: 'u2'), userId: 2);
      final items = await db.getAll(userId: 1);
      expect(items.length, 1);
      expect(items.first.id, 'u1');
    });
  });
}
