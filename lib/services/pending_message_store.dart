import 'package:flutter/foundation.dart';

/// Optimistic "sending" state for the conversation list.
/// When the user sends a message from [ChatScreen], we register a pending preview
/// here so the list can show a clock icon and "Sending..." (or preview) until the API responds.
class PendingMessage {
  final String preview;
  final String messageType;

  PendingMessage({required this.preview, this.messageType = 'text'});
}

class PendingMessageStore extends ChangeNotifier {
  PendingMessageStore._();
  static final PendingMessageStore instance = PendingMessageStore._();

  final Map<int, PendingMessage> _pending = {};

  PendingMessage? getPending(int conversationId) => _pending[conversationId];
  bool hasPending(int conversationId) => _pending.containsKey(conversationId);

  void setPending(int conversationId, {required String preview, String messageType = 'text'}) {
    _pending[conversationId] = PendingMessage(preview: preview, messageType: messageType);
    notifyListeners();
  }

  void clearPending(int conversationId) {
    if (_pending.remove(conversationId) != null) notifyListeners();
  }
}
