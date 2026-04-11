// lib/class_chat/services/class_chat_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/class_chat_models.dart';

class ClassChatService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<ChatListResult<ClassChannel>> getChannels(int classId) async {
    try {
      final res = await _dio.get('/education/classes/$classId/channels');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => ClassChannel.fromJson(j))
            .toList();
        return ChatListResult(success: true, items: items);
      }
      return ChatListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return ChatListResult(success: false, message: '$e');
    }
  }

  Future<ChatListResult<ClassChatMessage>> getMessages({
    required int channelId,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get(
        '/education/channels/$channelId/messages',
        queryParameters: {'page': page},
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => ClassChatMessage.fromJson(j))
            .toList();
        return ChatListResult(success: true, items: items);
      }
      return ChatListResult(success: false);
    } catch (e) {
      return ChatListResult(success: false, message: '$e');
    }
  }

  Future<ChatResult<ClassChatMessage>> sendMessage({
    required int channelId,
    required String body,
    String? attachmentUrl,
    String? attachmentType,
    int? replyToId,
    bool isQuestion = false,
  }) async {
    try {
      final res = await _dio.post(
        '/education/channels/$channelId/messages',
        data: {
          'body': body,
          if (attachmentUrl != null) 'attachment_url': attachmentUrl,
          if (attachmentType != null) 'attachment_type': attachmentType,
          if (replyToId != null) 'reply_to_id': replyToId,
          'is_question': isQuestion,
        },
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ChatResult(
          success: true,
          data: ClassChatMessage.fromJson(res.data['data']),
        );
      }
      return ChatResult(success: false, message: 'Imeshindwa kutuma');
    } catch (e) {
      return ChatResult(success: false, message: '$e');
    }
  }

  Future<ChatResult<void>> pinMessage(int messageId) async {
    try {
      final res = await _dio.post('/education/messages/$messageId/pin');
      return ChatResult(success: res.statusCode == 200);
    } catch (e) {
      return ChatResult(success: false, message: '$e');
    }
  }

  Future<ChatResult<ChatPoll>> createPoll({
    required int channelId,
    required String question,
    required List<String> options,
  }) async {
    try {
      final res = await _dio.post('/education/channels/$channelId/polls', data: {
        'question': question,
        'options': options,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return ChatResult(
          success: true,
          data: ChatPoll.fromJson(res.data['data']),
        );
      }
      return ChatResult(success: false, message: 'Imeshindwa kuunda kura');
    } catch (e) {
      return ChatResult(success: false, message: '$e');
    }
  }

  Future<ChatResult<void>> votePoll({
    required int pollId,
    required int optionId,
  }) async {
    try {
      final res = await _dio.post('/education/polls/$pollId/vote', data: {
        'option_id': optionId,
      });
      return ChatResult(success: res.statusCode == 200);
    } catch (e) {
      return ChatResult(success: false, message: '$e');
    }
  }
}
