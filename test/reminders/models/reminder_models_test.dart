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
