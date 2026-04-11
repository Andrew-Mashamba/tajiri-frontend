// lib/my_circle/services/my_circle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/my_circle_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class MyCircleService {
  // ─── Check Notifications (fire-and-forget) ───────────────────

  Future<void> checkNotifications(int userId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/my-circle/check-notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
    } catch (_) {}
  }

  // ─── Log Cycle Day ────────────────────────────────────────────

  Future<CircleResult<CycleDay>> logCycleDay({
    required int userId,
    required DateTime date,
    required FlowIntensity flowIntensity,
    List<Symptom> symptoms = const [],
    Mood? mood,
    String? notes,
  }) async {
    try {
      final body = CycleDay(
        userId: userId,
        date: date,
        flowIntensity: flowIntensity,
        symptoms: symptoms,
        mood: mood,
        notes: notes,
      ).toJson();

      final response = await http.post(
        Uri.parse('$_baseUrl/my-circle/cycle-days'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final result = CircleResult(success: true, data: CycleDay.fromJson(data['data']));
        // Backend auto-recalculates predictions on every log;
        // fire-and-forget refresh so callers get fresh data next time
        getPredictions(userId);
        return result;
      }
      return CircleResult(success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi');
    } catch (e) {
      return CircleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Cycle Days ───────────────────────────────────────────

  Future<CircleListResult<CycleDay>> getCycleDays({
    required int userId,
    required int month,
    required int year,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/my-circle/cycle-days').replace(
        queryParameters: {
          'user_id': '$userId',
          'month': '$month',
          'year': '$year',
        },
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CircleListResult(
            success: true,
            items: (data['data'] as List).map((j) => CycleDay.fromJson(j)).toList(),
          );
        }
      }
      return CircleListResult(success: false, message: 'Imeshindwa kupakia siku');
    } catch (e) {
      return CircleListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Predictions ──────────────────────────────────────────

  Future<CircleResult<CyclePrediction>> getPredictions(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/my-circle/predictions?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CircleResult(success: true, data: CyclePrediction.fromJson(data['data']));
        }
      }
      return CircleResult(success: false, message: 'Imeshindwa kupakia utabiri');
    } catch (e) {
      return CircleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Stats ────────────────────────────────────────────────

  Future<CircleResult<CycleStats>> getStats(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/my-circle/stats?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CircleResult(success: true, data: CycleStats.fromJson(data['data']));
        }
      }
      return CircleResult(success: false, message: 'Imeshindwa kupakia takwimu');
    } catch (e) {
      return CircleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Set Contraception Reminder ───────────────────────────────

  Future<CircleResult<ContraceptionReminder>> setContraceptionReminder({
    required int userId,
    required ContraceptionType type,
    required DateTime startDate,
    required int intervalDays,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-circle/contraception-reminders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'type': type.name,
          'start_date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
          'interval_days': intervalDays,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CircleResult(success: true, data: ContraceptionReminder.fromJson(data['data']));
      }
      return CircleResult(success: false, message: data['message'] ?? 'Imeshindwa kuhifadhi');
    } catch (e) {
      return CircleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Cycle Settings ───────────────────────────────────────

  Future<CircleResult<Map<String, dynamic>>> getSettings(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/my-circle/settings?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CircleResult(success: true, data: Map<String, dynamic>.from(data['data']));
        }
      }
      return CircleResult(success: false);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  // ─── Save Cycle Settings ────────────────────────────────────────

  Future<CircleResult<CyclePrediction>> saveSettings({
    required int userId,
    int? cycleLength,
    int? periodLength,
    String? lastPeriodDate,
  }) async {
    try {
      final body = <String, dynamic>{'user_id': userId};
      if (cycleLength != null) body['cycle_length'] = cycleLength;
      if (periodLength != null) body['period_length'] = periodLength;
      if (lastPeriodDate != null) body['last_period_date'] = lastPeriodDate;

      final response = await http.post(
        Uri.parse('$_baseUrl/my-circle/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        return CircleResult(success: true, data: CyclePrediction.fromJson(data['data']));
      }
      return CircleResult(success: false, message: data['message'] ?? 'Failed');
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  // ─── Partner Sharing ─────────────────────────────────────────

  Future<CircleResult<Map<String, dynamic>>> invitePartner(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-circle/partner/invite'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CircleResult(success: true, data: Map<String, dynamic>.from(data['data']));
      }
      return CircleResult(success: false, message: data['message']);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  Future<CircleResult<Map<String, dynamic>>> acceptPartnerInvite(int userId, String inviteCode) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-circle/partner/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'invite_code': inviteCode}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CircleResult(success: true, data: Map<String, dynamic>.from(data['data']));
      }
      return CircleResult(success: false, message: data['message']);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  Future<CircleResult<Map<String, dynamic>>> viewPartnerCycle(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/my-circle/partner/view?user_id=$userId'));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CircleResult(success: true, data: Map<String, dynamic>.from(data['data']));
      }
      return CircleResult(success: false, message: data['message']);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  Future<CircleResult<void>> revokePartnerAccess(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-circle/partner/revoke'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(response.body);
      return CircleResult(success: data['success'] == true);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  Future<CircleResult<void>> updatePartnerPrivacy(int userId, Map<String, bool> settings) async {
    try {
      final body = <String, dynamic>{'user_id': userId};
      body.addAll(settings);
      final response = await http.put(
        Uri.parse('$_baseUrl/my-circle/partner/privacy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return CircleResult(success: data['success'] == true);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  Future<CircleResult<Map<String, dynamic>?>> getPartnerStatus(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/my-circle/partner/status?user_id=$userId'));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CircleResult(success: true, data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null);
      }
      return CircleResult(success: false);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  // ─── Stop Tracking ────────────────────────────────────────────

  Future<CircleResult<Map<String, dynamic>>> stopTracking(int userId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-circle/stop-tracking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'reason': reason}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return CircleResult(success: true, data: Map<String, dynamic>.from(data['data']));
      }
      return CircleResult(success: false, message: data['message']);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  // ─── Resume Tracking ─────────────────────────────────────────

  Future<CircleResult<void>> resumeTracking(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/my-circle/resume-tracking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(response.body);
      return CircleResult(success: data['success'] == true);
    } catch (e) {
      return CircleResult(success: false, message: '$e');
    }
  }

  // ─── AI Summary (for Shangazi Tea context) ────────────────────

  /// Returns structured cycle data for Shangazi AI to interpret.
  Future<Map<String, dynamic>> getCycleSummaryForAI(int userId) async {
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        getPredictions(userId),
        getCycleDays(userId: userId, month: now.month, year: now.year),
        getSettings(userId),
      ]);

      final predResult = results[0] as CircleResult<CyclePrediction>;
      final daysResult = results[1] as CircleListResult<CycleDay>;
      final settingsResult = results[2] as CircleResult<Map<String, dynamic>>;

      final pred = predResult.data;
      final days = daysResult.items;
      final settings = settingsResult.data;

      // Count symptoms this month
      final symptomCounts = <String, int>{};
      for (final day in days) {
        for (final s in day.symptoms) {
          symptomCounts[s.name] = (symptomCounts[s.name] ?? 0) + 1;
        }
      }

      // Mood summary
      final moodCounts = <String, int>{};
      for (final day in days) {
        if (day.mood != null) {
          moodCounts[day.mood!.name] = (moodCounts[day.mood!.name] ?? 0) + 1;
        }
      }

      return {
        'has_data': pred?.hasData ?? false,
        'cycle_length': pred?.cycleLength ?? settings?['cycle_length'] ?? 28,
        'period_length': pred?.periodLength ?? settings?['period_length'] ?? 5,
        'next_period_date': pred?.nextPeriodDate?.toIso8601String(),
        'days_until_period': pred?.daysUntilNextPeriod ?? -1,
        'is_fertile_today': pred?.isFertileToday ?? false,
        'ovulation_date': pred?.ovulationDate?.toIso8601String(),
        'fertile_window_start': pred?.fertileWindowStart?.toIso8601String(),
        'fertile_window_end': pred?.fertileWindowEnd?.toIso8601String(),
        'is_tracking': settings?['is_tracking'] ?? true,
        'stop_reason': settings?['stop_reason'],
        'days_logged_this_month': days.length,
        'period_days_this_month': days.where((d) => d.hasPeriod).length,
        'top_symptoms': symptomCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
        'mood_summary': moodCounts,
      };
    } catch (e) {
      return {'error': 'Failed to load cycle data', 'has_data': false};
    }
  }

  // ─── Women's Health Community ─────────────────────────────────

  /// Fire-and-forget: auto-join the user to women's health groups
  Future<void> autoJoinWomensHealthGroups(int userId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/groups/auto-join-womens-health'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
    } catch (_) {}
  }

  /// Get the user's women's health group (regional or national fallback)
  Future<Map<String, dynamic>?> getWomensHealthGroup(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/groups/womens-health?user_id=$userId'),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Get Contraception Reminders ──────────────────────────────

  Future<CircleListResult<ContraceptionReminder>> getContraceptionReminders(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/my-circle/contraception-reminders?user_id=$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CircleListResult(
            success: true,
            items: (data['data'] as List).map((j) => ContraceptionReminder.fromJson(j)).toList(),
          );
        }
      }
      return CircleListResult(success: false, message: 'Imeshindwa kupakia vikumbusho');
    } catch (e) {
      return CircleListResult(success: false, message: 'Kosa: $e');
    }
  }
}
