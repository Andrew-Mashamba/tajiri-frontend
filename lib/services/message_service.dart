import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../models/message_models.dart';
import '../config/api_config.dart';
import 'post_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Use Dio for message media larger than this (same pattern as PostService)
const int _largeMessageFileThreshold = 5 * 1024 * 1024; // 5MB

Dio? _messageDio;
Dio _getMessageDio() {
  _messageDio ??= Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(minutes: 2),
    receiveTimeout: const Duration(minutes: 2),
    sendTimeout: const Duration(minutes: 5),
    headers: {'Accept': 'application/json'},
  ));
  return _messageDio!;
}

class MessageService {
  /// Get user's conversations. Handles multiple response shapes: data as List, or data.conversations, or data.data.
  /// [type] optional: 'group' (groups only), 'private' (DMs only), or null (both). Use type=group when loading the Groups tab.
  Future<ConversationListResult> getConversations({
    required int userId,
    int page = 1,
    int perPage = 20,
    String? type,
  }) async {
    try {
      var url = '$_baseUrl/conversations?user_id=$userId&page=$page&per_page=$perPage';
      if (type == 'group' || type == 'private') {
        url += '&type=$type';
      } else {
        url += '&include_groups=1';
      }
      if (kDebugMode) debugPrint('[Messages API] GET $url');
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final success = body['success'] == true;
        if (success) {
          // Backend: GET /conversations returns { "success": true, "data": [ {...}, {...} ], "meta": {...} }
          final data = body['data'];
          final List<dynamic> rawList = data is List ? data : [];
          final conversations = <Conversation>[];
          for (final c in rawList) {
            if (c is Map<String, dynamic>) {
              try {
                conversations.add(Conversation.fromJson(c));
              } catch (e) {
                if (kDebugMode) debugPrint('[MessageService] Skip conversation parse: $e');
              }
            }
          }
          if (kDebugMode) {
            final privateCount = conversations.where((c) => !c.isGroup).length;
            final groupCount = conversations.where((c) => c.isGroup).length;
            debugPrint('[Messages API] Response 200: ${conversations.length} conversations (private=$privateCount, group=$groupCount)');
            if (conversations.isEmpty && rawList.isNotEmpty) {
              debugPrint('[MessageService] All items failed to parse. First item keys: ${(rawList.first as Map).keys.toList()}');
            }
          }
          final meta = body['meta'];
          return ConversationListResult(
            success: true,
            conversations: conversations,
            meta: meta is Map ? PaginationMeta.fromJson(Map<String, dynamic>.from(meta)) : PaginationMeta.fromJson({}),
          );
        }
      }
      String message = 'Failed to load conversations';
      if (response.statusCode == 401) message = 'Please sign in again';
      else if (response.statusCode == 403) message = 'Access denied';
      else if (response.body.isNotEmpty) {
        try {
          final b = jsonDecode(response.body);
          if (b['message'] is String) message = b['message'] as String;
        } catch (_) {}
      }
      if (kDebugMode) debugPrint('[Messages API] Response ${response.statusCode}: $message');
      return ConversationListResult(success: false, message: message);
    } catch (e) {
      if (kDebugMode) debugPrint('[MessageService] getConversations error: $e');
      return ConversationListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get or create a private conversation with another user
  Future<ConversationResult> getPrivateConversation(int userId, int otherUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/private/$otherUserId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ConversationResult(
            success: true,
            conversation: Conversation.fromJson(data['data']),
          );
        }
      }
      return ConversationResult(success: false, message: 'Failed to get conversation');
    } catch (e) {
      return ConversationResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a group conversation. Prefer creating via GroupService.createGroup (POST /groups) so the same group appears in profile (Vikundi) and Messages (MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE). This endpoint may be used when linking a conversation to an existing group.
  Future<ConversationResult> createGroup({
    required int userId,
    required String name,
    required List<int> participantIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'name': name,
          'participant_ids': participantIds,
          'type': 'group',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return ConversationResult(
          success: true,
          conversation: Conversation.fromJson(data['data']),
        );
      }
      return ConversationResult(success: false, message: data['message'] ?? 'Failed to create group');
    } catch (e) {
      return ConversationResult(success: false, message: 'Error: $e');
    }
  }

  /// Get a single conversation
  Future<ConversationResult> getConversation(int conversationId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/$conversationId?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ConversationResult(
            success: true,
            conversation: Conversation.fromJson(data['data']),
          );
        }
      }
      return ConversationResult(success: false, message: 'Conversation not found');
    } catch (e) {
      return ConversationResult(success: false, message: 'Error: $e');
    }
  }

  /// Get messages in a conversation
  Future<MessageListResult> getMessages({
    required int conversationId,
    required int userId,
    int page = 1,
    int perPage = 50,
    int? before,
  }) async {
    try {
      String url = '$_baseUrl/conversations/$conversationId/messages?user_id=$userId&page=$page&per_page=$perPage';
      if (before != null) url += '&before=$before';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final messages = (data['data'] as List)
              .map((m) => Message.fromJson(m))
              .toList();
          return MessageListResult(
            success: true,
            messages: messages,
            meta: PaginationMeta.fromJson(data['meta'] ?? {}),
          );
        }
      }
      return MessageListResult(success: false, message: 'Failed to load messages');
    } catch (e) {
      return MessageListResult(success: false, message: 'Error: $e');
    }
  }

  /// Send a message.
  /// [onProgress] optional callback (0.0 to 1.0) for media uploads; used when file is large (Dio path).
  Future<MessageResult> sendMessage({
    required int conversationId,
    required int userId,
    String? content,
    String messageType = 'text',
    File? media,
    int? replyToId,
    int? forwardMessageId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (media != null) {
        if (!media.existsSync()) {
          return MessageResult(success: false, errorMessage: 'File not found. It may have been moved.');
        }
        final fileSize = media.lengthSync();
        final useDio = fileSize > _largeMessageFileThreshold;
        if (kDebugMode) {
          debugPrint('[MessageService] sendMessage media: ${media.path}, size: ${(fileSize / 1024).toStringAsFixed(1)} KB, useDio: $useDio');
        }

        if (useDio) {
          return await _sendMessageWithDio(
            conversationId: conversationId,
            userId: userId,
            content: content,
            messageType: messageType,
            media: media,
            replyToId: replyToId,
            forwardMessageId: forwardMessageId,
            onProgress: onProgress,
          );
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/conversations/$conversationId/messages'),
        );
        request.headers['Accept'] = 'application/json';
        request.fields['user_id'] = userId.toString();
        if (content != null) request.fields['content'] = content;
        request.fields['message_type'] = messageType;
        if (replyToId != null) request.fields['reply_to_id'] = replyToId.toString();
        if (forwardMessageId != null) request.fields['forward_message_id'] = forwardMessageId.toString();
        request.files.add(await http.MultipartFile.fromPath('media', media.path));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          return MessageResult(success: false, errorMessage: 'Server error. Please try again.');
        }

        if (response.statusCode == 201 && data['success'] == true) {
          return MessageResult(
            success: true,
            message: Message.fromJson(data['data']),
          );
        }
        return MessageResult(success: false, errorMessage: data['message']?.toString() ?? 'Failed to send message');
      } else {
        final response = await http.post(
          Uri.parse('$_baseUrl/conversations/$conversationId/messages'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'content': content,
            'message_type': messageType,
            if (replyToId != null) 'reply_to_id': replyToId,
            if (forwardMessageId != null) 'forward_message_id': forwardMessageId,
          }),
        );

        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          return MessageResult(success: false, errorMessage: 'Server error. Please try again.');
        }

        if (response.statusCode == 201 && data['success'] == true) {
          return MessageResult(
            success: true,
            message: Message.fromJson(data['data']),
          );
        }
        return MessageResult(success: false, errorMessage: data['message']?.toString() ?? 'Failed to send message');
      }
    } catch (e) {
      return MessageResult(success: false, errorMessage: 'Error: $e');
    }
  }

  /// Send message with media using Dio (large files, progress support)
  Future<MessageResult> _sendMessageWithDio({
    required int conversationId,
    required int userId,
    String? content,
    required String messageType,
    required File media,
    int? replyToId,
    int? forwardMessageId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dio = _getMessageDio();
      final formData = FormData.fromMap({
        'user_id': userId.toString(),
        if (content != null) 'content': content,
        'message_type': messageType,
        if (replyToId != null) 'reply_to_id': replyToId.toString(),
        if (forwardMessageId != null) 'forward_message_id': forwardMessageId.toString(),
      });
      formData.files.add(MapEntry(
        'media',
        await MultipartFile.fromFile(media.path, filename: media.path.split(Platform.pathSeparator).last),
      ));

      final response = await dio.post(
        '/conversations/$conversationId/messages',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );

      final data = response.data;
      if (response.statusCode == 201 && data != null && data['success'] == true) {
        return MessageResult(success: true, message: Message.fromJson(data['data']));
      }
      return MessageResult(
        success: false,
        errorMessage: data['message']?.toString() ?? 'Failed to send message',
      );
    } on DioException catch (e) {
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.connectionError:
          errorMessage = 'No internet connection. Please try again.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Upload taking too long. Try a smaller file or better connection.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Server not responding. Please try again.';
          break;
        case DioExceptionType.badResponse:
          final d = e.response?.data;
          errorMessage = (d is Map && d['message'] != null) ? d['message'].toString() : 'Server error.';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Upload cancelled.';
          break;
        default:
          errorMessage = e.message ?? 'Upload failed.';
      }
      return MessageResult(success: false, errorMessage: errorMessage);
    }
  }

  /// Edit a text message (PATCH)
  Future<MessageResult> editMessage({
    required int conversationId,
    required int messageId,
    required int userId,
    required String content,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages/$messageId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'content': content,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return MessageResult(
          success: true,
          message: Message.fromJson(data['data']),
        );
      }
      return MessageResult(
        success: false,
        errorMessage: data['message'] ?? 'Failed to edit message',
      );
    } catch (e) {
      return MessageResult(success: false, errorMessage: 'Error: $e');
    }
  }

  /// Delete (unsend) a message
  Future<bool> deleteMessage({
    required int conversationId,
    required int messageId,
    required int userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages/$messageId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Forward a message to another conversation
  Future<MessageResult> forwardMessage({
    required int targetConversationId,
    required int userId,
    required String content,
    int? forwardFromMessageId,
  }) async {
    return sendMessage(
      conversationId: targetConversationId,
      userId: userId,
      content: content,
      forwardMessageId: forwardFromMessageId,
    );
  }

  /// Mark conversation as read
  Future<bool> markAsRead(int conversationId, int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/conversations/$conversationId/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Leave a conversation
  Future<bool> leaveConversation(int conversationId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/conversations/$conversationId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get total unread message count
  Future<int> getUnreadCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/unread-count?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data']['unread_count'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Start typing indicator
  Future<bool> startTyping(int conversationId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/typing/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Stop typing indicator
  Future<bool> stopTyping(int conversationId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/typing/stop'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Get typing status for a conversation.
  /// Backend can optionally include recording_users (same shape as typing_users) in data.
  Future<TypingStatusResult> getTypingStatus(int conversationId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/$conversationId/typing?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final raw = data['data'] as Map<String, dynamic>?;
          final typingUsers = (raw?['typing_users'] as List?)
              ?.map((u) => TypingUser.fromJson(u))
              .toList() ?? [];
          final recordingUsers = (raw?['recording_users'] as List?)
              ?.map((u) => TypingUser.fromJson(u))
              .toList() ?? [];
          return TypingStatusResult(
            success: true,
            typingUsers: typingUsers,
            recordingUsers: recordingUsers,
          );
        }
      }
      return TypingStatusResult(success: false);
    } catch (e) {
      return TypingStatusResult(success: false);
    }
  }

  /// Notify backend that current user started recording in this conversation.
  /// Backend should store recording state (e.g. with TTL) and return it in GET .../typing as recording_users.
  Future<bool> startRecording(int conversationId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/recording/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Notify backend that current user stopped recording.
  Future<bool> stopRecording(int conversationId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/recording/stop'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Add or toggle reaction on a message. Returns updated message if API supports it.
  Future<MessageResult> addReaction({
    required int conversationId,
    required int messageId,
    required int userId,
    required String emoji,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages/$messageId/reactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'emoji': emoji}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 200 && data != null && data['success'] == true) {
        final msg = data['data'] != null ? Message.fromJson(data['data']) : null;
        return MessageResult(success: true, message: msg);
      }
      return MessageResult(
        success: false,
        errorMessage: data?['message']?.toString() ?? 'Failed to add reaction',
      );
    } catch (e) {
      return MessageResult(success: false, errorMessage: 'Error: $e');
    }
  }

  /// Remove reaction from a message.
  Future<MessageResult> removeReaction({
    required int conversationId,
    required int messageId,
    required int userId,
    required String emoji,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/conversations/$conversationId/messages/$messageId/reactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'emoji': emoji}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 200 && data != null && data['success'] == true) {
        final msg = data['data'] != null ? Message.fromJson(data['data']) : null;
        return MessageResult(success: true, message: msg);
      }
      return MessageResult(
        success: false,
        errorMessage: data?['message']?.toString() ?? 'Failed to remove reaction',
      );
    } catch (e) {
      return MessageResult(success: false, errorMessage: 'Error: $e');
    }
  }
}

// Result classes
class ConversationListResult {
  final bool success;
  final List<Conversation> conversations;
  final PaginationMeta? meta;
  final String? message;

  ConversationListResult({
    required this.success,
    this.conversations = const [],
    this.meta,
    this.message,
  });
}

class ConversationResult {
  final bool success;
  final Conversation? conversation;
  final String? message;

  ConversationResult({required this.success, this.conversation, this.message});
}

class MessageListResult {
  final bool success;
  final List<Message> messages;
  final PaginationMeta? meta;
  final String? message;

  MessageListResult({
    required this.success,
    this.messages = const [],
    this.meta,
    this.message,
  });
}

class MessageResult {
  final bool success;
  final Message? message;
  final String? errorMessage;

  MessageResult({required this.success, this.message, this.errorMessage});
}

class TypingStatusResult {
  final bool success;
  final List<TypingUser> typingUsers;
  final List<TypingUser> recordingUsers;

  TypingStatusResult({
    required this.success,
    this.typingUsers = const [],
    this.recordingUsers = const [],
  });
}

class TypingUser {
  final int id;
  final String firstName;
  final String lastName;

  TypingUser({required this.id, required this.firstName, required this.lastName});

  factory TypingUser.fromJson(Map<String, dynamic> json) {
    return TypingUser(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
}
