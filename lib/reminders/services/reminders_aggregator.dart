// lib/reminders/services/reminders_aggregator.dart
import 'package:flutter/foundation.dart';

import '../../business/services/business_service.dart';
import '../../calendar/services/calendar_service.dart';
import '../../crb/services/crb_service.dart';
import '../../team/services/team_service.dart';
import '../../tenders/services/tender_service.dart';
import '../models/reminder_event_kind.dart';
import '../models/reminder_models.dart';
import '../reminders_source_exception.dart';
import 'reminders_service.dart';

class RemindersAggregator {
  static Future<List<ReminderItem>> _safe(Future<List<ReminderItem>> f) =>
      f.catchError((Object e, StackTrace st) {
        debugPrint('[RemindersAggregator] source error: $e');
        return <ReminderItem>[];
      });

  /// Best-effort: failed sources become empty lists (UI still loads).
  static Future<List<ReminderItem>> getAll({
    required String token,
    required int userId,
  }) =>
      _getAllMerged(lenient: true, token: token, userId: userId);

  /// All sources must succeed (HTTP 200 / tenders success). Used before
  /// [RemindersNotificationService.scheduleAll] so we never cancel notifications
  /// based on a partial feed.
  static Future<List<ReminderItem>> getAllStrict({
    required String token,
    required int userId,
  }) =>
      _getAllMerged(lenient: false, token: token, userId: userId);

  /// [getAllStrict] with exponential backoff — no partial reschedule.
  ///
  /// Retries only **transient** failures (network, 5xx, 408, 429). Does **not**
  /// retry 401/403/404 and other 4xx from [RemindersSourceException] — those
  /// match backend auth/routing and will not succeed by repeating.
  static Future<List<ReminderItem>> getAllStrictWithRetries({
    required String token,
    required int userId,
    int maxAttempts = 5,
  }) async {
    Object? lastError;
    StackTrace? lastSt;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await getAllStrict(token: token, userId: userId);
      } catch (e, st) {
        lastError = e;
        lastSt = st;
        debugPrint(
            '[RemindersAggregator] strict fetch attempt ${attempt + 1}/$maxAttempts failed: $e');
        if (!_shouldRetryStrictFailure(e)) {
          Error.throwWithStackTrace(e, st);
        }
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(Duration(milliseconds: 200 * (1 << attempt)));
        }
      }
    }
    Error.throwWithStackTrace(lastError!, lastSt ?? StackTrace.empty);
  }

  /// Whether repeating the parallel fetch may help (aligned with Laravel Vikumbusho routes).
  static bool _shouldRetryStrictFailure(Object e) {
    if (e is RemindersSourceException) {
      final c = e.statusCode;
      if (c >= 500 && c < 600) return true;
      if (c == 408 || c == 429) return true;
      if (c == 0) return true;
      if (c >= 400 && c < 500) return false;
      return false;
    }
    return true;
  }

  static Future<List<ReminderItem>> _getAllMerged({
    required bool lenient,
    required String token,
    required int userId,
  }) async {
    Future<List<ReminderItem>> wrap(Future<List<ReminderItem>> f) =>
        lenient ? _safe(f) : f;

    final results = await Future.wait([
      wrap(CalendarService().getUpcomingWithReminders(
        userId: userId,
        token: token,
        strict: !lenient,
      )),
      wrap(BusinessService.getUpcomingAppointmentsForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getExpiringDocuments(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getUpcomingQuotesForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getUpcomingInvoicesForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getFailedTransactionsForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getRevenueSummaryDigest(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getUpcomingRecurringForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getUpcomingDebtsForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getUpcomingExpensesForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getTaxDeadlinesForReminders(token, userId, strict: !lenient)),
      wrap(CrbService.getCrbPastDueEntries(token, userId,
          strict: !lenient)),
      wrap(TeamService.getExpiringEmployeeContracts(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getUpcomingPayrollForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getUpcomingPurchaseOrdersForReminders(token, userId,
          strict: !lenient)),
      wrap(BusinessService.getIncomingPurchaseOrdersForReminders(token, userId,
          strict: !lenient)),
      wrap(TenderService.getAllTenderRemindersForAggregator(userId,
          strict: !lenient)),
      wrap(RemindersService.getAll(
          userId: userId, token: token, strict: !lenient)),
    ]);

    final all = results.expand((list) => list).toList();
    return merge(all);
  }

  /// Deduplicate by id, then merge overlapping business keys (invoice / quote / PO).
  static List<ReminderItem> merge(List<ReminderItem> items) {
    final seen = <String>{};
    final unique = <ReminderItem>[];
    for (final item in items) {
      if (seen.add(item.id)) unique.add(item);
    }
    final deduped = _dedupeByCanonicalBusinessKey(unique);
    deduped.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return deduped;
  }

  /// Prefer higher-priority [eventKind] when multiple feeds surface the same entity.
  static List<ReminderItem> _dedupeByCanonicalBusinessKey(List<ReminderItem> items) {
    final best = <String, ReminderItem>{};
    for (final item in items) {
      final key = _canonicalMergeKey(item) ?? item.id;
      final existing = best[key];
      if (existing == null || _mergePriority(item) > _mergePriority(existing)) {
        best[key] = item;
      }
    }
    return best.values.toList();
  }

  static String? _canonicalMergeKey(ReminderItem i) {
    final id = i.id;
    if (id.startsWith('inv_paid_evt_')) {
      return 'inv:${id.substring('inv_paid_evt_'.length)}';
    }
    if (id.startsWith('inv_paid_')) {
      return 'inv:${id.substring('inv_paid_'.length)}';
    }
    if (id.startsWith('inv_')) {
      return 'inv:${id.substring('inv_'.length)}';
    }
    if (id.startsWith('quote_evt_')) {
      return 'quote:${id.substring('quote_evt_'.length)}';
    }
    if (id.startsWith('quote_status_')) {
      return 'quote:${id.substring('quote_status_'.length)}';
    }
    if (id.startsWith('quote_')) {
      return 'quote:${id.substring('quote_'.length)}';
    }
    if (id.startsWith('po_evt_')) {
      return 'po:${id.substring('po_evt_'.length)}';
    }
    if (id.startsWith('po_status_')) {
      return 'po:${id.substring('po_status_'.length)}';
    }
    if (id.startsWith('po_')) {
      return 'po:${id.substring('po_'.length)}';
    }
    return null;
  }

  static int _mergePriority(ReminderItem i) {
    final k = i.eventKind ?? '';
    switch (k) {
      case ReminderEventKind.invoiceOverdue:
      case ReminderEventKind.debtOverdue:
        return 400;
      case ReminderEventKind.quoteStatus:
      case ReminderEventKind.poStatus:
      case ReminderEventKind.tenderOutcome:
        return 350;
      case ReminderEventKind.invoiceUpcoming:
      case ReminderEventKind.debtUpcoming:
      case ReminderEventKind.quoteValidUntil:
      case ReminderEventKind.tenderClosing:
      case ReminderEventKind.tenderApplication:
        return 300;
      case ReminderEventKind.poDelivery:
        return 280;
      case ReminderEventKind.invoicePaid:
        return 200;
      case ReminderEventKind.failedTransaction:
      case ReminderEventKind.crbPastDue:
      case ReminderEventKind.immediate:
        return 320;
      default:
        return 100;
    }
  }
}
