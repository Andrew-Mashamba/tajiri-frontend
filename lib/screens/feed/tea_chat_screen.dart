import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/tea_models.dart';
import '../../services/tea_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/event_tracking_service.dart';
import '../../widgets/shangazi_message_bubble.dart';
import '../../widgets/tea_card_widget.dart';
import '../../widgets/action_card_widget.dart';

/// Represents a single item in the chat list view.
class _ChatItem {
  final String type; // 'user' | 'text' | 'tea_card' | 'action_card' | 'action_result' | 'loading'
  final String? text;
  final TeaCard? teaCard;
  final ActionCard? actionCard;

  _ChatItem({
    required this.type,
    this.text,
    this.teaCard,
    this.actionCard,
  });
}

class TeaChatScreen extends StatefulWidget {
  const TeaChatScreen({super.key});

  @override
  State<TeaChatScreen> createState() => _TeaChatScreenState();
}

class _TeaChatScreenState extends State<TeaChatScreen> {
  final _messages = <_ChatItem>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _conversationId;
  bool _isStreaming = false;
  String _streamingText = '';
  bool _isLoading = true;
  StreamSubscription<TeaStreamEvent>? _streamSub;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  Future<void> _initChat() async {
    final token = await _getToken();
    if (token == null || !mounted) return;

    final response = await TeaService.startChat(token);
    if (response == null || !mounted) {
      setState(() => _isLoading = false);
      return;
    }

    _conversationId = response.conversationId;
    setState(() => _isLoading = false);
    _listenToStream(response.streamUrl, token);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isStreaming) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatItem(type: 'user', text: text));
    });
    _scrollToBottom();

    final token = await _getToken();
    if (token == null || !mounted) return;

    EventTrackingService.getInstance().then((t) => t.trackTeaQuestionAsked(text));

    setState(() => _isStreaming = true);

    final response = await TeaService.startChat(
      token,
      message: text,
      conversationId: _conversationId,
    );

    if (response == null || !mounted) {
      setState(() {
        _isStreaming = false;
        _messages.add(_ChatItem(
          type: 'text',
          text: 'Samahani, kuna tatizo. Jaribu tena.',
        ));
      });
      return;
    }

    _conversationId ??= response.conversationId;
    _listenToStream(response.streamUrl, token);
  }

  void _listenToStream(String streamUrl, String token) {
    _streamSub?.cancel();
    setState(() {
      _isStreaming = true;
      _streamingText = '';
    });

    _streamSub = TeaService.streamResponse(streamUrl, token).listen(
      (event) {
        if (!mounted) return;

        if (event.isText) {
          setState(() {
            _streamingText += event.textChunk;
          });
          _scrollToBottom();

          if (event.textDone) {
            setState(() {
              _messages.add(_ChatItem(type: 'text', text: _streamingText));
              _streamingText = '';
            });
          }
        } else if (event.isTeaCard) {
          final card = TeaCard.fromJson(event.data);
          setState(() {
            // Flush any pending streaming text first
            if (_streamingText.isNotEmpty) {
              _messages.add(_ChatItem(type: 'text', text: _streamingText));
              _streamingText = '';
            }
            _messages.add(_ChatItem(type: 'tea_card', teaCard: card));
          });
          _scrollToBottom();
        } else if (event.isActionCard) {
          final card = ActionCard.fromJson(event.data);
          setState(() {
            if (_streamingText.isNotEmpty) {
              _messages.add(_ChatItem(type: 'text', text: _streamingText));
              _streamingText = '';
            }
            _messages.add(_ChatItem(type: 'action_card', actionCard: card));
          });
          _scrollToBottom();
        } else if (event.isDone) {
          setState(() {
            if (_streamingText.isNotEmpty) {
              _messages.add(_ChatItem(type: 'text', text: _streamingText));
              _streamingText = '';
            }
            _isStreaming = false;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          if (_streamingText.isNotEmpty) {
            _messages.add(_ChatItem(type: 'text', text: _streamingText));
            _streamingText = '';
          }
          _isStreaming = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          if (_streamingText.isNotEmpty) {
            _messages.add(_ChatItem(type: 'text', text: _streamingText));
            _streamingText = '';
          }
          _isStreaming = false;
        });
      },
    );
  }

  Future<void> _handleActionConfirm(ActionCard card, bool confirmed) async {
    final token = await _getToken();
    if (token == null || !mounted) return;

    if (confirmed) {
      EventTrackingService.getInstance().then(
          (t) => t.trackTeaActionConfirmed(card.action, card.actionCardId));
    } else {
      EventTrackingService.getInstance().then(
          (t) => t.trackTeaActionRejected(card.action, card.actionCardId));
    }

    final result = await TeaService.confirmAction(
      token,
      card.actionCardId,
      confirmed: confirmed,
    );

    if (!mounted) return;

    if (result != null) {
      final message = result['message']?.toString() ?? (confirmed
          ? 'Hatua imethibitishwa.'
          : 'Hatua imeghairiwa.');
      setState(() {
        // Update the original action card to reflect new status
        final idx = _messages.indexWhere((m) =>
          m.type == 'action_card' &&
          m.actionCard?.actionCardId == card.actionCardId);
        if (idx != -1) {
          _messages[idx] = _ChatItem(
            type: 'action_card',
            actionCard: ActionCard(
              actionCardId: card.actionCardId,
              action: card.action,
              preview: card.preview,
              confirmPrompt: card.confirmPrompt,
              status: confirmed ? 'confirmed' : 'rejected',
            ),
          );
        }
        _messages.add(_ChatItem(
          type: 'action_result',
          text: '${confirmed ? '\u{2705}' : '\u{274C}'} $message',
        ));
      });
    } else {
      setState(() {
        _messages.add(_ChatItem(
          type: 'action_result',
          text: '\u{26A0}\u{FE0F} Imeshindikana. Jaribu tena.',
        ));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u{1FAD6} Shangazi Tea',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1FAD6}', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Shangazi anapika chai...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      );
    }

    // Total items = messages + streaming preview (if active)
    final itemCount = _messages.length + (_isStreaming && _streamingText.isNotEmpty ? 1 : 0);

    if (itemCount == 0 && !_isStreaming) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1FAD6}', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Habari! Mimi ni Shangazi.\nNiulize chochote.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Streaming preview at end
        if (index >= _messages.length) {
          return ShangaziMessageBubble(
            child: Text(
              _streamingText,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
                height: 1.4,
              ),
            ),
          );
        }

        final item = _messages[index];

        switch (item.type) {
          case 'user':
            return _buildUserBubble(item.text ?? '');
          case 'text':
            return ShangaziMessageBubble(
              child: Text(
                item.text ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            );
          case 'tea_card':
            if (item.teaCard == null) return const SizedBox.shrink();
            return ShangaziMessageBubble(
              child: TeaCardWidget(
                card: item.teaCard!,
                onTap: () {
                  EventTrackingService.getInstance().then((t) => t.trackTeaCardTapped(
                    int.tryParse(item.teaCard!.id) ?? 0,
                    item.teaCard!.urgency,
                  ));
                },
                onActionTap: (action) {
                  _sendActionMessage(action);
                },
              ),
            );
          case 'action_card':
            if (item.actionCard == null) return const SizedBox.shrink();
            return ShangaziMessageBubble(
              child: ActionCardWidget(
                actionCard: item.actionCard!,
                onConfirm: () => _handleActionConfirm(item.actionCard!, true),
                onCancel: () => _handleActionConfirm(item.actionCard!, false),
              ),
            );
          case 'action_result':
            return ShangaziMessageBubble(
              child: Text(
                item.text ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildUserBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 48, right: 12, top: 4, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFFAFAFA),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Uliza Shangazi...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: _isStreaming ? null : _sendMessage,
              icon: Icon(
                Icons.send_rounded,
                color: _isStreaming
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendActionMessage(String action) {
    _controller.text = action;
    _sendMessage();
  }
}
