import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/tea_models.dart';

/// Service for Shangazi Tea — AI gossip partner.
/// Handles chat initiation, SSE streaming, conversation history, and action confirmation.
class TeaService {
  /// Start or continue a conversation with Shangazi.
  /// Returns a [TeaChatResponse] with conversation_id and stream_url.
  static Future<TeaChatResponse?> startChat(
    String token, {
    String? message,
    String? conversationId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (message != null) body['message'] = message;
      if (conversationId != null) body['conversation_id'] = conversationId;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tea/chat'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TeaChatResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Connect to SSE stream and yield [TeaStreamEvent]s.
  /// Uses raw http.Client.send() with StreamedResponse — no SSE library needed.
  static Stream<TeaStreamEvent> streamResponse(
    String streamUrl,
    String token,
  ) async* {
    final request = http.Request('GET', Uri.parse(streamUrl));
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';

    final client = http.Client();
    try {
      final response = await client.send(request);
      String currentEvent = 'message';
      String buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        // Keep incomplete last line in buffer
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('event: ')) {
            currentEvent = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6)) as Map<String, dynamic>;
              yield TeaStreamEvent(eventType: currentEvent, data: data);
            } catch (_) {
              // Skip malformed JSON
            }
          }
          // Empty line resets event type
          if (line.isEmpty) {
            currentEvent = 'message';
          }
        }
      }
    } finally {
      client.close();
    }
  }

  /// List past conversations.
  static Future<List<TeaConversation>> getConversations(
    String token, {
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tea/conversations?limit=$limit'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['conversations'] as List<dynamic>? ?? [];
        return list
            .map((e) => TeaConversation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Load conversation history.
  static Future<List<TeaMessage>> getConversationMessages(
    String token,
    String conversationId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tea/conversations/$conversationId'),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['messages'] as List<dynamic>? ?? [];
        return list
            .map((e) => TeaMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Delete a conversation.
  static Future<bool> deleteConversation(
    String token,
    String conversationId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/tea/conversations/$conversationId'),
        headers: ApiConfig.authHeaders(token),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Confirm or reject a pending action.
  static Future<Map<String, dynamic>?> confirmAction(
    String token,
    String actionCardId, {
    required bool confirmed,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tea/action/confirm'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'action_card_id': actionCardId,
          'confirmed': confirmed,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Submit feedback on a tea message.
  static Future<bool> submitFeedback(
    String token,
    String messageId,
    String type, // 'helpful' | 'harmful' | 'inaccurate'
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tea/feedback'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'message_id': messageId,
          'type': type,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
