import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec line 1018 — quote-bidding broadcast model + service. Customer posts
/// an RFQ; matched partners submit bids; customer awards one inside the
/// auction window (default 24h).
class EventQuoteRequest {
  final int id;
  final int customerUserId;
  final String skillCategory;
  final String eventKind;
  final String eventTitle;
  final DateTime eventStartsAt;
  final DateTime? eventEndsAt;
  final String? eventAddress;
  final double? eventLat;
  final double? eventLng;
  final int partySize;
  final int? budgetMinTzs;
  final int? budgetMaxTzs;
  final String? description;
  final List<String> photos;
  final String status;
  final DateTime expiresAt;
  final int? awardedQuoteId;
  final DateTime? awardedAt;
  final List<EventQuoteBid> bids;
  EventQuoteRequest({
    required this.id,
    required this.customerUserId,
    required this.skillCategory,
    required this.eventKind,
    required this.eventTitle,
    required this.eventStartsAt,
    required this.eventEndsAt,
    required this.eventAddress,
    required this.eventLat,
    required this.eventLng,
    required this.partySize,
    required this.budgetMinTzs,
    required this.budgetMaxTzs,
    required this.description,
    required this.photos,
    required this.status,
    required this.expiresAt,
    required this.awardedQuoteId,
    required this.awardedAt,
    this.bids = const [],
  });
  factory EventQuoteRequest.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    int? p(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    double? f(dynamic v) =>
        v == null ? null : (v is double ? v : (v is num ? v.toDouble() : double.tryParse(v.toString())));
    return EventQuoteRequest(
      id: p(json['id']) ?? 0,
      customerUserId: p(json['customer_user_id']) ?? 0,
      skillCategory: json['skill_category']?.toString() ?? '',
      eventKind: json['event_kind']?.toString() ?? '',
      eventTitle: json['event_title']?.toString() ?? '',
      eventStartsAt: d(json['event_starts_at']) ?? DateTime.now(),
      eventEndsAt: d(json['event_ends_at']),
      eventAddress: json['event_address']?.toString(),
      eventLat: f(json['event_lat']),
      eventLng: f(json['event_lng']),
      partySize: p(json['party_size']) ?? 1,
      budgetMinTzs: p(json['budget_min_tzs']),
      budgetMaxTzs: p(json['budget_max_tzs']),
      description: json['description']?.toString(),
      photos: (json['photos'] is List)
          ? (json['photos'] as List).map((e) => e.toString()).toList()
          : const [],
      status: json['status']?.toString() ?? 'open',
      expiresAt: d(json['expires_at']) ?? DateTime.now(),
      awardedQuoteId: p(json['awarded_quote_id']),
      awardedAt: d(json['awarded_at']),
      bids: (json['bids'] is List)
          ? (json['bids'] as List)
              .whereType<Map>()
              .map((m) => EventQuoteBid.fromJson(m.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }
}

class EventQuoteBid {
  final int id;
  final int partnerUserId;
  final String? partnerName;
  final int bidTotalTzs;
  final int? bidDepositTzs;
  final String? pitch;
  final Map<String, dynamic>? package;
  final String status;
  final DateTime? submittedAt;
  final DateTime? decidedAt;
  EventQuoteBid({
    required this.id,
    required this.partnerUserId,
    required this.partnerName,
    required this.bidTotalTzs,
    required this.bidDepositTzs,
    required this.pitch,
    required this.package,
    required this.status,
    required this.submittedAt,
    required this.decidedAt,
  });
  factory EventQuoteBid.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    int? p(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return EventQuoteBid(
      id: p(json['id']) ?? 0,
      partnerUserId: p(json['partner_user_id']) ?? 0,
      partnerName: json['partner_name']?.toString(),
      bidTotalTzs: p(json['bid_total_tzs']) ?? 0,
      bidDepositTzs: p(json['bid_deposit_tzs']),
      pitch: json['pitch']?.toString(),
      package: json['package'] is Map ? (json['package'] as Map).cast<String, dynamic>() : null,
      status: json['status']?.toString() ?? 'submitted',
      submittedAt: d(json['submitted_at']),
      decidedAt: d(json['decided_at']),
    );
  }
}

class EventQuoteRequestService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<List<EventQuoteRequest>> list({required int userId, required String role, String? status}) async {
    final params = <String, String>{'user_id': '$userId', 'role': role};
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$_baseUrl/event-quotes').replace(queryParameters: params);
    debugPrint('[EventQuoteRequestService] GET $uri');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          return (body['data'] as List)
              .whereType<Map>()
              .map((m) => EventQuoteRequest.fromJson(m.cast<String, dynamic>()))
              .toList();
        }
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  static Future<EventQuoteRequest?> create({
    required int customerUserId,
    required String skillCategory,
    required String eventKind,
    required String eventTitle,
    required DateTime eventStartsAt,
    DateTime? eventEndsAt,
    String? eventAddress,
    double? eventLat,
    double? eventLng,
    int partySize = 1,
    int? budgetMinTzs,
    int? budgetMaxTzs,
    String? description,
    List<String>? photos,
    int auctionHours = 24,
  }) async {
    final body = <String, dynamic>{
      'customer_user_id': customerUserId,
      'skill_category': skillCategory,
      'event_kind': eventKind,
      'event_title': eventTitle,
      'event_starts_at': eventStartsAt.toUtc().toIso8601String(),
      'party_size': partySize,
      'auction_hours': auctionHours,
    };
    if (eventEndsAt != null) body['event_ends_at'] = eventEndsAt.toUtc().toIso8601String();
    if (eventAddress != null) body['event_address'] = eventAddress;
    if (eventLat != null) body['event_lat'] = eventLat;
    if (eventLng != null) body['event_lng'] = eventLng;
    if (budgetMinTzs != null) body['budget_min_tzs'] = budgetMinTzs;
    if (budgetMaxTzs != null) body['budget_max_tzs'] = budgetMaxTzs;
    if (description != null) body['description'] = description;
    if (photos != null && photos.isNotEmpty) body['photos'] = photos;
    final uri = Uri.parse('$_baseUrl/event-quotes');
    try {
      final res = await http.post(uri, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if (res.statusCode == 200) {
        final r = jsonDecode(res.body);
        if (r['success'] == true && r['data'] is Map) {
          return EventQuoteRequest.fromJson((r['data'] as Map).cast<String, dynamic>());
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<EventQuoteRequest?> show(int id) async {
    final uri = Uri.parse('$_baseUrl/event-quotes/$id');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final r = jsonDecode(res.body);
        if (r['success'] == true && r['data'] is Map) {
          return EventQuoteRequest.fromJson((r['data'] as Map).cast<String, dynamic>());
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> bid({
    required int requestId,
    required int partnerUserId,
    required int bidTotalTzs,
    int? bidDepositTzs,
    String? pitch,
    Map<String, dynamic>? package,
  }) async {
    final body = <String, dynamic>{
      'partner_user_id': partnerUserId,
      'bid_total_tzs': bidTotalTzs,
    };
    if (bidDepositTzs != null) body['bid_deposit_tzs'] = bidDepositTzs;
    if (pitch != null) body['pitch'] = pitch;
    if (package != null) body['package'] = package;
    final uri = Uri.parse('$_baseUrl/event-quotes/$requestId/bid');
    try {
      final res = await http.post(uri, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> award({required int requestId, required int userId, required int bidId}) async {
    final uri = Uri.parse('$_baseUrl/event-quotes/$requestId/award');
    try {
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'bid_id': bidId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancel({required int requestId, required int userId}) async {
    final uri = Uri.parse('$_baseUrl/event-quotes/$requestId/cancel');
    try {
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
