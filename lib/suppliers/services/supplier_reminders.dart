// lib/suppliers/services/supplier_reminders.dart
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../reminders/models/reminder_models.dart';
import '../../reminders/services/reminders_service.dart';

const _uuid = Uuid();
final _nf = NumberFormat('#,###', 'en');

class SupplierReminders {
  static Future<void> scheduleDeliveryReminder({
    required DateTime deliveryDate,
    required String supplierLabel,
    required String token,
    required int userId,
    bool isSwahili = false,
  }) async {
    final due = deliveryDate;
    final reminderDate = due.subtract(const Duration(days: 1));
    if (!reminderDate.isAfter(DateTime.now())) return;
    final label = supplierLabel.isNotEmpty
        ? supplierLabel
        : (isSwahili ? 'Msambazaji' : 'Supplier');
    try {
      await RemindersService.create(
        ReminderItem(
          id: 'po_delivery_${_uuid.v4()}',
          title: isSwahili ? '📦 Pokea Agizo: $label' : '📦 Receive Order: $label',
          subtitle: isSwahili
              ? 'Kukaribia tarehe ya kupokea'
              : 'Delivery date approaching',
          dueAt: reminderDate,
          category: ReminderCategory.purchaseOrder,
          isStandalone: true,
          sourceRoute: '/business',
        ),
        token: token,
        userId: userId,
      );
    } catch (_) {}
  }

  static Future<void> schedulePartialFollowup({
    required String supplierLabel,
    required String token,
    required int userId,
    bool isSwahili = false,
  }) async {
    final label = supplierLabel.isNotEmpty
        ? supplierLabel
        : (isSwahili ? 'Msambazaji' : 'Supplier');
    try {
      await RemindersService.create(
        ReminderItem(
          id: 'po_partial_${_uuid.v4()}',
          title: isSwahili
              ? '📦 Fuatilia Bidhaa: $label'
              : '📦 Follow up delivery: $label',
          subtitle: isSwahili
              ? 'Baadhi ya bidhaa bado hazijafika'
              : 'Some items still pending',
          dueAt: DateTime.now().add(const Duration(days: 3)),
          category: ReminderCategory.purchaseOrder,
          isStandalone: true,
          sourceRoute: '/business',
        ),
        token: token,
        userId: userId,
      );
    } catch (_) {}
  }

  static Future<void> schedulePayableReminders({
    required DateTime dueDate,
    required String supplierLabel,
    required double amount,
    required String token,
    required int userId,
    bool isSwahili = false,
  }) async {
    final now = DateTime.now();
    final amountStr = 'TZS ${_nf.format(amount)}';

    final sevenDaysBefore = dueDate.subtract(const Duration(days: 7));
    if (sevenDaysBefore.isAfter(now)) {
      try {
        await RemindersService.create(
          ReminderItem(
            id: 'payable_7d_${_uuid.v4()}',
            title: isSwahili
                ? '💳 Deni linakaribia: $supplierLabel'
                : '💳 Payment due in 7 days: $supplierLabel',
            subtitle: '$amountStr — ${isSwahili ? "Siku 7" : "7 days"}',
            dueAt: sevenDaysBefore,
            category: ReminderCategory.debt,
            isStandalone: true,
            sourceRoute: '/business',
          ),
          token: token,
          userId: userId,
        );
      } catch (_) {}
    }

    final oneDayBefore = dueDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(now)) {
      try {
        await RemindersService.create(
          ReminderItem(
            id: 'payable_1d_${_uuid.v4()}',
            title: isSwahili
                ? '⚠️ Lipa Kesho: $supplierLabel'
                : '⚠️ Pay Tomorrow: $supplierLabel',
            subtitle: amountStr,
            dueAt: oneDayBefore,
            category: ReminderCategory.debt,
            isStandalone: true,
            sourceRoute: '/business',
          ),
          token: token,
          userId: userId,
        );
      } catch (_) {}
    }
  }
}
