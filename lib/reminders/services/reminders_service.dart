// lib/reminders/services/reminders_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import 'package:uuid/uuid.dart';

import '../../config/api_config.dart';
import '../models/reminder_models.dart';
import '../reminders_source_exception.dart';
import 'reminders_db.dart';

String get _baseUrl => ApiConfig.baseUrl;
const _uuid = Uuid();

void _log(String msg) => debugPrint('[RemindersService] $msg');

/// Maps API JSON to [ReminderItem] and fills [serverId] when the backend sends
/// numeric PK only in `id` or omits [server_id] for legacy rows.
ReminderItem _normalizeApiReminder(Map<String, dynamic> e) {
  var item = ReminderItem.fromJson(e);
  if (item.serverId == null) {
    final sid = e['server_id'];
    if (sid != null) {
      item = item.copyWith(serverId: int.tryParse(sid.toString()));
    } else {
      final idStr = item.id;
      if (RegExp(r'^\d+$').hasMatch(idStr)) {
        item = item.copyWith(serverId: int.tryParse(idStr));
      }
    }
  }
  return item;
}

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
    unawaited(_syncCreate(withId, token: token, userId: userId));
    return ReminderResult(success: true, data: withId);
  }

  static Future<ReminderResult<ReminderItem>> update(
    ReminderItem item, {
    required String token,
  }) async {
    await _ensureDb();
    await _db.update(item);
    unawaited(_syncUpdate(item, token: token));
    return ReminderResult(success: true, data: item);
  }

  static Future<ReminderResult<void>> delete(
    String id, {
    required String token,
  }) async {
    await _ensureDb();
    await _db.delete(id);
    unawaited(_syncDelete(id, token: token));
    return ReminderResult(success: true);
  }

  static Future<ReminderResult<void>> markDone(
    String id, {
    required String token,
  }) async {
    await _ensureDb();
    await _db.markDone(id);
    unawaited(_syncMarkDone(id, token: token));
    return ReminderResult(success: true);
  }

  static Future<List<ReminderItem>> getAll({
    required int userId,
    required String token,
    bool strict = false,
  }) async {
    await _ensureDb();
    await _fetchAndReconcile(userId: userId, token: token, strict: strict);
    return _db.getAll(userId: userId);
  }

  // ── API sync ─────────────────────────────────────────────────────────────

  static Future<void> _fetchAndReconcile({
    required int userId,
    required String token,
    bool strict = false,
  }) async {
    try {
      final res = await httpGetWithRetry(
        Uri.parse('$_baseUrl/reminders?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final raw = decoded is Map<String, dynamic> ? decoded['data'] : null;
        final list = raw is List ? raw : <dynamic>[];
        for (final e in list) {
          if (e is Map<String, dynamic>) {
            final item = _normalizeApiReminder(e);
            await _db.upsertFromRemoteFetch(item, userId: userId);
          }
        }
      } else if (strict && !reminderStrictSkipHttpStatus(res.statusCode)) {
        throw RemindersSourceException('standalone_reminders', res.statusCode);
      }
    } catch (e, st) {
      if (strict) {
        if (e is RemindersSourceException) rethrow;
        Error.throwWithStackTrace(
          RemindersSourceException('standalone_reminders', 0, cause: e),
          st,
        );
      }
      _log('_fetchAndReconcile failed (offline?): $e');
    }
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
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({...item.toJson(), 'user_id': userId}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final payload = decoded is Map<String, dynamic> ? decoded['data'] : null;
        final sid = payload is Map<String, dynamic> ? payload['id'] : decoded is Map<String, dynamic> ? decoded['id'] : null;
        final serverId = sid is int ? sid : int.tryParse(sid?.toString() ?? '');
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
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
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
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_done': 1}),
      );
    } catch (e) {
      _log('_syncMarkDone failed: $e');
    }
  }
}
