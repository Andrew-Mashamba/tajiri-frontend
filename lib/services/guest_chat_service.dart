// Guest Chat Service — invite links for conversations (MESSAGES.md: guest chats).
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'local_storage_service.dart';

class InviteLink {
  final String token;
  final String url;
  final int conversationId;
  final DateTime expiresAt;
  final int? maxUses;
  final int currentUses;

  InviteLink({
    required this.token,
    required this.url,
    required this.conversationId,
    required this.expiresAt,
    this.maxUses,
    this.currentUses = 0,
  });

  factory InviteLink.fromJson(Map<String, dynamic> json) => InviteLink(
        token: json['token'] as String? ?? '',
        url: json['url'] as String? ?? '',
        conversationId: _parseInt(json['conversation_id']),
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
            DateTime.now(),
        maxUses: json['max_uses'] as int?,
        currentUses: _parseInt(json['current_uses']),
      );

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get expiresLabel {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Imekwisha';
    if (diff.inDays > 0) return 'Siku ${diff.inDays}';
    if (diff.inHours > 0) return 'Masaa ${diff.inHours}';
    return 'Dakika ${diff.inMinutes}';
  }

  String get usesLabel {
    if (maxUses == null) return '$currentUses matumizi';
    return '$currentUses / $maxUses matumizi';
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class GuestChatService {
  /// Create an invite link for a conversation.
  static Future<InviteLink?> createInviteLink({
    required int conversationId,
    int? maxUses,
    int expiresInHours = 72,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/conversations/$conversationId/invite-link'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'max_uses': maxUses,
          'expires_in_hours': expiresInHours,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final linkData = data['data'] ?? data['invite_link'] ?? data;
        if (linkData is Map<String, dynamic>) {
          return InviteLink.fromJson(linkData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get active invite links for a conversation.
  static Future<List<InviteLink>> getInviteLinks(int conversationId) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/conversations/$conversationId/invite-links'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] ?? data['invite_links'] ?? []) as List;
        return list
            .map((l) => InviteLink.fromJson(l as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Revoke an invite link.
  static Future<bool> revokeInviteLink(
      int conversationId, String linkToken) async {
    try {
      final authToken = await _getToken();
      if (authToken == null) return false;

      final response = await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}/conversations/$conversationId/invite-links/$linkToken'),
        headers: ApiConfig.authHeaders(authToken),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Join a conversation as guest via invite token (no auth required).
  static Future<Map<String, dynamic>?> joinAsGuest({
    required String inviteToken,
    required String displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/guest/join'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'invite_token': inviteToken,
          'display_name': displayName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }
}
