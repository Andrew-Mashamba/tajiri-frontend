import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../services/http_retry.dart';
import '../../config/api_config.dart';

/// Spec — generic calendar layer for partner_c2b verticals (F2/F4/F5/F6/F7/F8/F9/F10/F12).
/// Reads `/partner-c2b/calendar` populated by `PartnerC2BCalendarService` on the backend.
class PartnerC2BCalendarEvent {
  final int id;
  final String sourceType;
  final int sourceId;
  final String title;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? location;
  final double? lat;
  final double? lng;
  final String status;
  final Map<String, dynamic>? metadata;

  PartnerC2BCalendarEvent({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.description,
    required this.startsAt,
    required this.endsAt,
    required this.location,
    required this.lat,
    required this.lng,
    required this.status,
    required this.metadata,
  });

  factory PartnerC2BCalendarEvent.fromJson(Map<String, dynamic> json) {
    return PartnerC2BCalendarEvent(
      id: json['id'] as int? ?? 0,
      sourceType: json['source_type']?.toString() ?? '',
      sourceId: json['source_id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ?? DateTime.now(),
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.tryParse(json['ends_at'].toString()),
      location: json['location']?.toString(),
      lat: json['lat'] is num ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] is num ? (json['lng'] as num).toDouble() : null,
      status: json['status']?.toString() ?? 'confirmed',
      metadata: json['metadata'] is Map
          ? (json['metadata'] as Map).cast<String, dynamic>()
          : null,
    );
  }
}

class PartnerC2BCalendarListResult {
  final bool success;
  final List<PartnerC2BCalendarEvent> events;
  final String? message;
  PartnerC2BCalendarListResult({required this.success, this.events = const [], this.message});
}

class PartnerC2BCalendarService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<PartnerC2BCalendarListResult> list({
    required int userId,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    final params = <String, String>{'user_id': '$userId'};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('$_baseUrl/partner-c2b/calendar')
        .replace(queryParameters: params);
    debugPrint('[PartnerC2BCalendarService] GET $uri');
    try {
      final res = await httpGetWithRetry(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          final items = (body['data'] as List)
              .whereType<Map>()
              .map((m) => PartnerC2BCalendarEvent.fromJson(m.cast<String, dynamic>()))
              .toList();
          return PartnerC2BCalendarListResult(success: true, events: items);
        }
      }
      return PartnerC2BCalendarListResult(
        success: false,
        message: 'HTTP ${res.statusCode}',
      );
    } catch (e) {
      return PartnerC2BCalendarListResult(success: false, message: 'Kosa: $e');
    }
  }
}
