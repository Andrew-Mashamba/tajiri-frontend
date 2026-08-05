import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';

/// Spec F7 #69 — Engagement dispute mediation thread.
class DisputeMessage {
  final int id;
  final int senderUserId;
  final String senderRole;
  final String body;
  final String? attachmentUrl;
  final DateTime? createdAt;

  const DisputeMessage({
    required this.id,
    required this.senderUserId,
    required this.senderRole,
    required this.body,
    this.attachmentUrl,
    this.createdAt,
  });

  factory DisputeMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }
    return DisputeMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      senderUserId: (json['sender_user_id'] as num?)?.toInt() ?? 0,
      senderRole: json['sender_role']?.toString() ?? 'customer',
      body: json['body']?.toString() ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: parseDt(json['created_at']),
    );
  }
}

class DisputeThread {
  final List<DisputeMessage> messages;
  final DateTime? windowStartedAt;
  final DateTime? escalatedAt;
  final String? releaseTo;

  const DisputeThread({
    required this.messages,
    this.windowStartedAt,
    this.escalatedAt,
    this.releaseTo,
  });
}

class DisputeService {
  static Future<DisputeThread> thread(int engagementId) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagements/$engagementId/dispute/thread')!;
    final res = await httpGetWithRetry(Uri.parse(url));
    if (res.statusCode != 200) return const DisputeThread(messages: []);
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      final eng = body['engagement'] is Map ? body['engagement'] as Map : const {};
      DateTime? parseDt(dynamic v) {
        if (v == null) return null;
        try {
          return DateTime.parse(v.toString()).toLocal();
        } catch (_) {
          return null;
        }
      }
      final list = (body['messages'] as List?)
              ?.whereType<Map>()
              .map((m) => DisputeMessage.fromJson(m.cast<String, dynamic>()))
              .toList() ??
          const <DisputeMessage>[];
      return DisputeThread(
        messages: list,
        windowStartedAt: parseDt(eng['dispute_window_started_at']),
        escalatedAt: parseDt(eng['dispute_escalated_at']),
        releaseTo: eng['dispute_release_to'] as String?,
      );
    }
    return const DisputeThread(messages: []);
  }

  static Future<bool> open({
    required int userId,
    required int engagementId,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagements/$engagementId/dispute/open')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> escalate({
    required int userId,
    required int engagementId,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagements/$engagementId/dispute/escalate')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> send({
    required int userId,
    required int engagementId,
    required String role,
    required String body,
    String? attachmentUrl,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagements/$engagementId/dispute/send')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'role': role,
        'body': body,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      }),
    );
    return res.statusCode == 200;
  }
}
