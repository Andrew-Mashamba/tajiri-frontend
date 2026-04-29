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
        id: 'inv_1',
        title: 'Invoice (dup)',
        dueAt: DateTime(2026, 6, 1),
        category: ReminderCategory.invoice,
        isStandalone: false,
      );
      final merged = RemindersAggregator.merge([a, b]);
      expect(merged.length, 1);
    });

    test('merge keeps highest-priority row per invoice canonical id', () {
      final overdue = ReminderItem(
        id: 'inv_99',
        title: 'Overdue',
        dueAt: DateTime(2026, 1, 1),
        category: ReminderCategory.invoice,
        isStandalone: false,
        eventKind: ReminderEventKind.invoiceOverdue,
      );
      final paid = ReminderItem(
        id: 'inv_paid_99',
        title: 'Paid',
        dueAt: DateTime(2026, 4, 1),
        category: ReminderCategory.invoice,
        isStandalone: false,
        eventKind: ReminderEventKind.invoicePaid,
      );
      final merged = RemindersAggregator.merge([paid, overdue]);
      expect(merged.length, 1);
      expect(merged.single.eventKind, ReminderEventKind.invoiceOverdue);
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
