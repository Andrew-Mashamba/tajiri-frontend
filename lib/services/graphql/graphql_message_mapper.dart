import '../../config/api_config.dart';
import '../../models/message_models.dart';

/// Maps greenfield GraphQL messaging shapes → legacy REST JSON for [Conversation]/[Message].fromJson.
class GraphqlMessageMapper {
  static String? _mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConfig.graphqlStorageUrl}/${path.replaceFirst(RegExp(r'^/'), '')}';
  }

  static String _convType(dynamic raw) {
    final s = raw?.toString().toLowerCase() ?? 'private';
    if (s.contains('group')) return 'group';
    return 'private';
  }

  static int _int(dynamic v) =>
      v is int ? v : (v != null ? int.tryParse(v.toString()) ?? 0 : 0);

  static Map<String, dynamic> conversationToLegacy(Map<String, dynamic> gql) {
    final last = gql['lastMessage'] as Map<String, dynamic>?;
    final now = DateTime.now().toIso8601String();
    return {
      'id': _int(gql['id']),
      'type': _convType(gql['type']),
      'name': gql['name'],
      'created_by': _int(gql['createdBy']),
      'last_message_at': gql['lastMessageAt'] ?? now,
      'created_at': gql['lastMessageAt'] ?? now,
      'updated_at': gql['lastMessageAt'] ?? now,
      'unread_count': gql['unreadCount'] ?? 0,
      if (last != null) 'last_message': messageToLegacy(last),
    };
  }

  static Conversation conversationFromGraphql(Map<String, dynamic> gql) {
    return Conversation.fromJson(conversationToLegacy(gql));
  }

  static Map<String, dynamic> messageToLegacy(Map<String, dynamic> gql) {
    final sender = gql['sender'] as Map<String, dynamic>?;
    final displayName = sender?['displayName']?.toString() ?? '';
    final parts = displayName.split(' ');
    return {
      'id': _int(gql['id']),
      'conversation_id': _int(gql['conversationId']),
      'sender_id': _int(gql['senderId']),
      'content': gql['content'],
      'message_type': gql['messageType'] ?? 'text',
      'media_path': _mediaUrl(gql['mediaPath']?.toString()),
      'media_type': gql['mediaType'],
      'reply_to_id':
          gql['replyToId'] != null ? _int(gql['replyToId']) : null,
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': gql['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      if (sender != null)
        'sender': {
          'id': _int(sender['id']),
          'first_name': parts.isNotEmpty ? parts.first : displayName,
          'last_name': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'username': sender['username'],
          'profile_photo_url': sender['avatarUrl'],
        },
    };
  }

  static Message messageFromGraphql(Map<String, dynamic> gql) {
    return Message.fromJson(messageToLegacy(gql));
  }
}
