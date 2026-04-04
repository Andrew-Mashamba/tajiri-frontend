// Chat Interoperability Service — bridge adapter for external chat platforms
// (Matrix, RCS, SMS, Email). Backend manages protocol bridges; this service
// handles the frontend API layer for connecting/disconnecting bridges and
// managing bridged conversations.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'local_storage_service.dart';

/// Supported bridge protocol types.
enum BridgeType {
  matrix('matrix'),
  rcs('rcs'),
  email('email'),
  sms('sms');

  final String value;
  const BridgeType(this.value);

  static BridgeType fromString(String value) {
    return BridgeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BridgeType.matrix,
    );
  }
}

/// A conversation linked to an external chat platform via a bridge.
class BridgedConversation {
  final int conversationId;
  final String bridgeType;
  final String externalId;
  final String? externalDisplayName;
  final String? externalAvatarUrl;
  final String status; // active, paused, disconnected
  final DateTime connectedAt;

  BridgedConversation({
    required this.conversationId,
    required this.bridgeType,
    required this.externalId,
    this.externalDisplayName,
    this.externalAvatarUrl,
    required this.status,
    required this.connectedAt,
  });

  factory BridgedConversation.fromJson(Map<String, dynamic> json) {
    return BridgedConversation(
      conversationId: json['conversation_id'] is int
          ? json['conversation_id'] as int
          : int.tryParse(json['conversation_id']?.toString() ?? '0') ?? 0,
      bridgeType: json['bridge_type'] as String? ?? '',
      externalId: json['external_id'] as String? ?? '',
      externalDisplayName: json['external_display_name'] as String?,
      externalAvatarUrl: json['external_avatar_url'] as String?,
      status: json['status'] as String? ?? 'active',
      connectedAt: json['connected_at'] != null
          ? DateTime.tryParse(json['connected_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'bridge_type': bridgeType,
    'external_id': externalId,
    'external_display_name': externalDisplayName,
    'external_avatar_url': externalAvatarUrl,
    'status': status,
    'connected_at': connectedAt.toIso8601String(),
  };

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isDisconnected => status == 'disconnected';
}

/// Info about an available bridge and whether the current user has it connected.
class BridgeInfo {
  final String bridgeType;
  final String displayName;
  final bool isConnected;
  final String? externalUserId;
  final String status; // available, connected, paused, disconnected

  BridgeInfo({
    required this.bridgeType,
    required this.displayName,
    required this.isConnected,
    this.externalUserId,
    required this.status,
  });

  factory BridgeInfo.fromJson(Map<String, dynamic> json) {
    return BridgeInfo(
      bridgeType: json['bridge_type'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      isConnected: json['is_connected'] == true,
      externalUserId: json['external_user_id'] as String?,
      status: json['status'] as String? ?? 'available',
    );
  }
}

/// Service for managing chat bridge connections and bridged conversations.
/// Static-method class following project conventions.
class ChatInteropService {
  static Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  /// Get available bridge types and the user's connection status for each.
  static Future<List<BridgeInfo>> getAvailableBridges() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chat-bridges'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] ?? data['bridges'] ?? []) as List;
        return list
            .map((b) => BridgeInfo.fromJson(b as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Connect a bridge (e.g., link Matrix account with homeserver + credentials).
  static Future<bool> connectBridge({
    required String bridgeType,
    required Map<String, dynamic> credentials,
  }) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chat-bridges/connect'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bridge_type': bridgeType,
          'credentials': credentials,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Disconnect a bridge — sets status to disconnected on backend.
  static Future<bool> disconnectBridge(String bridgeType) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/chat-bridges/$bridgeType'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get all bridged conversations for the current user.
  static Future<List<BridgedConversation>> getBridgedConversations() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chat-bridges/conversations'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] ?? data['conversations'] ?? []) as List;
        return list
            .map((c) => BridgedConversation.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Start a new bridged conversation with an external contact.
  /// Returns the Tajiri conversation ID if successful.
  static Future<int?> startBridgedConversation({
    required String bridgeType,
    required String externalContactId,
  }) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/chat-bridges/conversations'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bridge_type': bridgeType,
          'external_contact_id': externalContactId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (data['data']?['conversation_id'] ??
                data['conversation_id']) as int?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
