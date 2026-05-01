import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec F6 #41 — Recurring appointment series.
enum SeriesCadence { daily, weekly, biweekly, monthly }

extension SeriesCadenceX on SeriesCadence {
  String get apiValue {
    switch (this) {
      case SeriesCadence.daily:
        return 'daily';
      case SeriesCadence.weekly:
        return 'weekly';
      case SeriesCadence.biweekly:
        return 'biweekly';
      case SeriesCadence.monthly:
        return 'monthly';
    }
  }

  String get labelEn {
    switch (this) {
      case SeriesCadence.daily:
        return 'Daily';
      case SeriesCadence.weekly:
        return 'Weekly';
      case SeriesCadence.biweekly:
        return 'Every 2 weeks';
      case SeriesCadence.monthly:
        return 'Monthly';
    }
  }

  String get labelSw {
    switch (this) {
      case SeriesCadence.daily:
        return 'Kila siku';
      case SeriesCadence.weekly:
        return 'Kila wiki';
      case SeriesCadence.biweekly:
        return 'Kila wiki 2';
      case SeriesCadence.monthly:
        return 'Kila mwezi';
    }
  }
}

class AppointmentSeries {
  final int id;
  final int templateAppointmentId;
  final SeriesCadence cadence;
  final List<DateTime> skipDates;
  final DateTime? untilDate;
  final bool isActive;

  const AppointmentSeries({
    required this.id,
    required this.templateAppointmentId,
    required this.cadence,
    required this.skipDates,
    this.untilDate,
    required this.isActive,
  });

  factory AppointmentSeries.fromJson(Map<String, dynamic> json) {
    SeriesCadence parseCadence(String? s) {
      switch (s) {
        case 'daily':
          return SeriesCadence.daily;
        case 'biweekly':
          return SeriesCadence.biweekly;
        case 'monthly':
          return SeriesCadence.monthly;
        default:
          return SeriesCadence.weekly;
      }
    }
    final raw = json['skip_dates_json'];
    final list = raw is String ? jsonDecode(raw) : raw;
    final skips = <DateTime>[];
    if (list is List) {
      for (final v in list) {
        try {
          skips.add(DateTime.parse(v.toString()).toLocal());
        } catch (_) {}
      }
    }
    DateTime? until;
    if (json['until_date'] != null) {
      try {
        until = DateTime.parse(json['until_date'].toString()).toLocal();
      } catch (_) {}
    }
    return AppointmentSeries(
      id: (json['id'] as num?)?.toInt() ?? 0,
      templateAppointmentId: (json['template_appointment_id'] as num?)?.toInt() ?? 0,
      cadence: parseCadence(json['cadence']?.toString()),
      skipDates: skips,
      untilDate: until,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

class AppointmentSeriesService {
  static Future<int?> create({
    required int userId,
    required int templateAppointmentId,
    int? partnerUserId,
    required SeriesCadence cadence,
    DateTime? untilDate,
    List<DateTime> skipDates = const [],
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/appointment-series')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'template_appointment_id': templateAppointmentId,
        if (partnerUserId != null) 'partner_user_id': partnerUserId,
        'cadence': cadence.apiValue,
        if (untilDate != null)
          'until_date': untilDate.toIso8601String().substring(0, 10),
        if (skipDates.isNotEmpty)
          'skip_dates': skipDates.map((d) => d.toIso8601String().substring(0, 10)).toList(),
      }),
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['ok'] == true) {
      final id = body['series_id'];
      if (id is num) return id.toInt();
    }
    return null;
  }

  static Future<List<AppointmentSeries>> mine({required int userId}) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/appointment-series/mine?user_id=$userId')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['series'] is List) {
      return (body['series'] as List)
          .whereType<Map>()
          .map((m) => AppointmentSeries.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static Future<bool> skipDate({
    required int userId,
    required int seriesId,
    required DateTime date,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/appointment-series/$seriesId/skip')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'date': date.toIso8601String().substring(0, 10),
      }),
    );
    return res.statusCode == 200;
  }

  static Future<bool> cancel({
    required int userId,
    required int seriesId,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/appointment-series/$seriesId/cancel')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    return res.statusCode == 200;
  }
}
