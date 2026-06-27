import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../config/api_config.dart';
import '../../models/message_models.dart';
import '../message_api_results.dart';
import '../post_service.dart';
import 'graphql_media_service.dart';
import 'graphql_message_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL messaging — replaces REST /conversations/* when [ApiConfig.useGraphqlBackend].
class GraphqlMessagingService {
  static const _uuid = Uuid();
  static final Map<String, String?> _conversationCursors = {};
  static final Map<int, String?> _messageCursors = {};

  static const _conversationsQuery = r'''
    query Conversations($cursor: String, $type: ConversationType) {
      conversations(cursor: $cursor, type: $type) {
        items {
          id
          type
          name
          createdBy
          lastMessageAt
          unreadCount
          lastMessage {
            id
            conversationId
            senderId
            content
            messageType
            createdAt
            updatedAt
            sender {
              id
              username
              displayName
              avatarUrl
            }
          }
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _conversationQuery = r'''
    query Conversation($id: ID!) {
      conversation(id: $id) {
        id
        type
        name
        createdBy
        lastMessageAt
        unreadCount
        lastMessage {
          id
          conversationId
          senderId
          content
          messageType
          createdAt
          updatedAt
        }
      }
    }
  ''';

  static const _messagesQuery = r'''
    query Messages($conversationId: ID!, $cursor: String, $sinceId: Int) {
      messages(conversationId: $conversationId, cursor: $cursor, sinceId: $sinceId) {
        items {
          id
          conversationId
          senderId
          clientMessageId
          content
          messageType
          replyToId
          createdAt
          updatedAt
          sender {
            id
            username
            displayName
            avatarUrl
          }
        }
        nextCursor
        hasMore
      }
    }
  ''';

  static const _unreadQuery = r'''
    query UnreadMessageCount {
      unreadMessageCount {
        count
      }
    }
  ''';

  static const _startPrivateMutation = r'''
    mutation StartPrivateConversation($userId: ID!) {
      startPrivateConversation(userId: $userId) {
        id
        type
        name
        createdBy
        lastMessageAt
        unreadCount
      }
    }
  ''';

  static const _createGroupMutation = r'''
    mutation CreateGroupConversation($name: String!, $participantIds: [ID!]!) {
      createGroupConversation(name: $name, participantIds: $participantIds) {
        id
        type
        name
        createdBy
        lastMessageAt
        unreadCount
      }
    }
  ''';

  static const _sendMessageMutation = r'''
    mutation SendMessage(
      $conversationId: ID!
      $content: String
      $messageType: String
      $clientMessageId: String
      $replyToId: ID
    ) {
      sendMessage(
        conversationId: $conversationId
        content: $content
        messageType: $messageType
        clientMessageId: $clientMessageId
        replyToId: $replyToId
        mediaPath: $mediaPath
        mediaType: $mediaType
      ) {
        id
        conversationId
        senderId
        clientMessageId
        content
        messageType
        mediaPath
        mediaType
        replyToId
        createdAt
        updatedAt
        sender {
          id
          username
          displayName
          avatarUrl
        }
      }
    }
  ''';

  static const _markReadMutation = r'''
    mutation MarkConversationRead($conversationId: ID!) {
      markConversationRead(conversationId: $conversationId)
    }
  ''';

  static Future<ConversationListResult> getConversations({
    int page = 1,
    int perPage = 20,
    String? type,
  }) async {
    try {
      final cursorKey = 'page_$type';
      String? cursor;
      if (page > 1) {
        cursor = _conversationCursors[cursorKey];
        if (cursor == null) {
          return ConversationListResult(success: true, conversations: const []);
        }
      }

      final data = await TajiriGraphqlClient.instance.query(
        _conversationsQuery,
        variables: {
          if (cursor != null) 'cursor': cursor,
          if (type == 'group') 'type': 'GROUP',
          if (type == 'private') 'type': 'PRIVATE',
        },
      );
      final conn = data['conversations'] as Map<String, dynamic>? ?? {};
      final items = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlMessageMapper.conversationFromGraphql)
          .where((c) {
            if (type == 'group') return c.isGroup;
            if (type == 'private') return c.isPrivate;
            return true;
          })
          .toList();

      _conversationCursors[cursorKey] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;

      return ConversationListResult(
        success: true,
        conversations: items,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : (page - 1) * perPage + items.length,
          lastPage: hasMore ? page + 1 : page,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlMessagingService] getConversations: $e');
      return ConversationListResult(success: false, message: e.toString());
    }
  }

  static Future<ConversationResult> getPrivateConversation(int otherUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _startPrivateMutation,
        variables: {'userId': otherUserId.toString()},
        auth: true,
      );
      final conv = data['startPrivateConversation'] as Map<String, dynamic>?;
      if (conv == null) {
        return ConversationResult(success: false, message: 'Failed to get conversation');
      }
      return ConversationResult(
        success: true,
        conversation: GraphqlMessageMapper.conversationFromGraphql(conv),
      );
    } catch (e) {
      return ConversationResult(success: false, message: e.toString());
    }
  }

  static Future<ConversationResult> createGroup({
    required String name,
    required List<int> participantIds,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _createGroupMutation,
        variables: {
          'name': name,
          'participantIds': participantIds.map((id) => id.toString()).toList(),
        },
        auth: true,
      );
      final conv = data['createGroupConversation'] as Map<String, dynamic>?;
      if (conv == null) {
        return ConversationResult(success: false, message: 'Failed to create group');
      }
      return ConversationResult(
        success: true,
        conversation: GraphqlMessageMapper.conversationFromGraphql(conv),
      );
    } catch (e) {
      return ConversationResult(success: false, message: e.toString());
    }
  }

  static Future<ConversationResult> getConversation(int conversationId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _conversationQuery,
        variables: {'id': conversationId.toString()},
      );
      final conv = data['conversation'] as Map<String, dynamic>?;
      if (conv == null) {
        return ConversationResult(success: false, message: 'Conversation not found');
      }
      return ConversationResult(
        success: true,
        conversation: GraphqlMessageMapper.conversationFromGraphql(conv),
      );
    } catch (e) {
      return ConversationResult(success: false, message: e.toString());
    }
  }

  static Future<MessageListResult> getMessages({
    required int conversationId,
    int page = 1,
    int perPage = 50,
    int? before,
  }) async {
    try {
      String? cursor;
      if (before != null) {
        cursor = before.toString();
      } else if (page > 1) {
        cursor = _messageCursors[conversationId];
        if (cursor == null) {
          return MessageListResult(success: true, messages: const []);
        }
      }

      final data = await TajiriGraphqlClient.instance.query(
        _messagesQuery,
        variables: {
          'conversationId': conversationId.toString(),
          if (cursor != null) 'cursor': cursor,
        },
      );
      final conn = data['messages'] as Map<String, dynamic>? ?? {};
      final messages = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlMessageMapper.messageFromGraphql)
          .toList();

      _messageCursors[conversationId] = conn['nextCursor']?.toString();
      final hasMore = conn['hasMore'] == true;

      return MessageListResult(
        success: true,
        messages: messages,
        meta: PaginationMeta(
          currentPage: page,
          perPage: perPage,
          total: hasMore ? page * perPage + 1 : messages.length,
          lastPage: hasMore ? page + 1 : page,
        ),
      );
    } catch (e) {
      return MessageListResult(success: false, message: e.toString());
    }
  }

  /// Delta sync: fetch messages with id > [sinceId].
  static Future<({List<Message> messages, bool hasMore})> syncMessages({
    required int conversationId,
    required int sinceId,
    int limit = 50,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _messagesQuery,
        variables: {
          'conversationId': conversationId.toString(),
          'sinceId': sinceId,
        },
      );
      final conn = data['messages'] as Map<String, dynamic>? ?? {};
      final messages = (conn['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlMessageMapper.messageFromGraphql)
          .toList();
      return (messages: messages, hasMore: conn['hasMore'] == true);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlMessagingService] syncMessages: $e');
      return (messages: <Message>[], hasMore: false);
    }
  }

  static Future<MessageResult> sendMessage({
    required int conversationId,
    String? content,
    String messageType = 'text',
    int? replyToId,
    String? clientMessageId,
    File? media,
  }) async {
    String? mediaPath;
    String? resolvedMediaType;
    if (media != null) {
      final uploaded = await GraphqlMediaService.uploadFile(
        media,
        mediaType: messageType == 'video' ? 'video' : 'image',
      );
      if (uploaded == null) {
        return MessageResult(success: false, errorMessage: 'Failed to upload media');
      }
      mediaPath = uploaded['file_path']?.toString();
      resolvedMediaType = uploaded['media_type']?.toString();
    }
    final clientId = clientMessageId ?? _uuid.v4();
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _sendMessageMutation,
        variables: {
          'conversationId': conversationId.toString(),
          'content': content,
          'messageType': mediaPath != null ? messageType : messageType,
          'clientMessageId': clientId,
          if (replyToId != null) 'replyToId': replyToId.toString(),
          if (mediaPath != null) 'mediaPath': mediaPath,
          if (resolvedMediaType != null) 'mediaType': resolvedMediaType,
        },
        auth: true,
      );
      final msg = data['sendMessage'] as Map<String, dynamic>?;
      if (msg == null) {
        return MessageResult(success: false, errorMessage: 'Failed to send message');
      }
      return MessageResult(
        success: true,
        message: GraphqlMessageMapper.messageFromGraphql(msg),
      );
    } catch (e) {
      return MessageResult(success: false, errorMessage: e.toString());
    }
  }

  static Future<bool> markAsRead(int conversationId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _markReadMutation,
        variables: {'conversationId': conversationId.toString()},
        auth: true,
      );
      return data['markConversationRead'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlMessagingService] markAsRead: $e');
      return false;
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(_unreadQuery);
      final payload = data['unreadMessageCount'] as Map<String, dynamic>?;
      return payload?['count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
