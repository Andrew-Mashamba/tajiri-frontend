import '../models/message_models.dart';
import 'post_service.dart';

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
