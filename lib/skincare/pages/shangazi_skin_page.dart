// lib/skincare/pages/shangazi_skin_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/tea_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/tea_service.dart';
import '../../widgets/action_card_widget.dart';
import '../../widgets/shangazi_message_bubble.dart';
import '../../widgets/tea_card_widget.dart';
import '../models/skincare_models.dart';
import '../services/skincare_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSecondary = Color(0xFF666666);

/// Represents a single item in the chat list view.
class _ChatItem {
  final String type; // 'user' | 'text' | 'tea_card' | 'action_card' | 'action_result'
  final String? text;
  final TeaCard? teaCard;
  final ActionCard? actionCard;
  final DateTime timestamp;
  final String? messageId;
  final bool isError;

  _ChatItem({
    required this.type,
    this.text,
    this.teaCard,
    this.actionCard,
    DateTime? timestamp,
    this.messageId,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ShangaziSkinPage extends StatefulWidget {
  final int userId;
  final SkinProfile? profile;
  final List<SkincareRoutine> routines;
  final List<SkinDiaryEntry> recentDiary;
  final bool embedded;

  const ShangaziSkinPage({
    super.key,
    required this.userId,
    this.profile,
    this.routines = const [],
    this.recentDiary = const [],
    this.embedded = false,
  });

  @override
  State<ShangaziSkinPage> createState() => _ShangaziSkinPageState();
}

class _ShangaziSkinPageState extends State<ShangaziSkinPage>
    with SingleTickerProviderStateMixin {
  final _messages = <_ChatItem>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _conversationId;
  bool _isStreaming = false;
  String _streamingText = '';
  bool _isLoading = true;
  StreamSubscription<TeaStreamEvent>? _streamSub;
  late final AnimationController _dotsController;
  bool _showDiaryPrompt = false;
  bool _diaryLogged = false;
  int _messageCount = 0;
  String? _lastUserMessage;
  String? _feedbackGivenForIndex;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _initChat();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _dotsController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isSwahili {
    final strings = AppStringsScope.of(context);
    return strings?.isSwahili ?? false;
  }

  Future<({String token, int? userId})?> _getAuth() async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return null;
    final userId = storage.getUser()?.userId;
    return (token: token, userId: userId);
  }

  String _buildSkinContext() {
    final buf = StringBuffer(
        'IMPORTANT: You are NOW in SKINCARE ADVISOR MODE. '
        'Do NOT respond as the gossip aunt or Tea persona. '
        'You are "Shangazi Ngozi" — a warm, knowledgeable skincare advisor specializing in Tanzanian skin care. '
        'Your role: answer skincare questions, recommend routines, suggest products, explain ingredients, and give practical advice. '
        'Stay focused on skin care topics ONLY. '
        'Give practical, safe, budget-friendly advice considering the Tanzanian climate and locally available products. '
        'NEVER diagnose conditions — always recommend seeing a dermatologist for persistent or serious issues. '
        'Be warm and encouraging like an aunt who knows about skin care. '
    );

    final p = widget.profile;
    if (p != null) {
      buf.write('User skin type: ${p.skinType.name}. ');
      if (p.concerns.isNotEmpty) {
        buf.write(
            'Concerns: ${p.concerns.map((c) => c.name).join(", ")}. ');
      }
      buf.write('Climate: ${p.climateZone.name}. ');
      if (p.budget != null && p.budget!.isNotEmpty) {
        buf.write('Budget level: ${p.budget}. ');
      }
    }
    if (widget.routines.isNotEmpty) {
      buf.write('Current routine has ${widget.routines.length} steps. ');
      for (final r in widget.routines.where((r) => r.isActive).take(2)) {
        buf.write(
            '${r.type.name} routine "${r.name}": ${r.steps.map((s) => s.stepType.name).join(" > ")}. ');
      }
    }
    if (widget.recentDiary.isNotEmpty) {
      final entries = widget.recentDiary.take(7).toList();
      final sum = entries.map((d) => d.mood).reduce((a, b) => a + b);
      final avg = sum / entries.length;
      buf.write(
          'Skin mood trend (last ${entries.length} days avg): ${avg.toStringAsFixed(1)}/5. ');
      // Include recent diary details so Shangazi can reference them
      buf.write('Recent skin diary entries: ');
      for (final entry in entries.take(3)) {
        final date = '${entry.date.day}/${entry.date.month}';
        buf.write('[$date mood:${entry.mood}/5');
        if (entry.tags.isNotEmpty) {
          buf.write(' tags:${entry.tags.join(",")}');
        }
        if (entry.notes != null && entry.notes!.isNotEmpty) {
          buf.write(' notes:"${entry.notes!.length > 50 ? entry.notes!.substring(0, 50) : entry.notes}"');
        }
        buf.write('] ');
      }
      // Check if diary is being used regularly
      final daysSinceLastEntry = DateTime.now().difference(entries.first.date).inDays;
      if (daysSinceLastEntry > 2) {
        buf.write('NOTE: User has not logged their skin diary for $daysSinceLastEntry days. Gently encourage them to log today. ');
      }
    } else {
      buf.write('NOTE: User has never written in their skin diary. Encourage them to start tracking their skin daily for better personalized advice. ');
    }

    // Check language from stored profile since context is not yet available
    final sw = _isSwahiliSync();
    buf.write(sw
        ? 'Jibu kwa Kiswahili kwa ufupi na ushauri wa vitendo.'
        : 'Respond in English with concise, practical advice.');
    return buf.toString();
  }

  bool _isSwahiliSync() {
    try {
      final strings = AppStringsScope.of(context);
      return strings?.isSwahili ?? false;
    } catch (_) {
      return false;
    }
  }

  String get _prefsKey => 'shangazi_skin_conv_${widget.userId}';

  Future<void> _startNewChat() async {
    final auth = await _getAuth();
    if (auth == null || !mounted) return;
    setState(() {
      _messages.clear();
      _conversationId = null;
      _streamingText = '';
      _messageCount = 0;
      _showDiaryPrompt = false;
      _diaryLogged = false;
      _feedbackGivenForIndex = null;
    });
    // Clear saved conversation
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    // Start fresh
    _startFreshConversation(auth);
  }

  Future<void> _saveConversationId(String convId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, convId);
  }

  Future<String?> _getSavedConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  Future<void> _initChat() async {
    final auth = await _getAuth();
    if (auth == null || !mounted) return;

    // Try to resume the last conversation
    final savedConvId = await _getSavedConversationId();
    if (savedConvId != null && savedConvId.isNotEmpty) {
      try {
        final messages = await TeaService.getConversationMessages(auth.token, savedConvId);
        if (mounted && messages.isNotEmpty) {
          _conversationId = savedConvId;
          setState(() {
            _isLoading = false;
            for (final msg in messages) {
              if (msg.isFromShangazi) {
                if (msg.isTeaCard) {
                  _messages.add(_ChatItem(
                    type: 'tea_card',
                    teaCard: TeaCard.fromJson(msg.content),
                    timestamp: msg.createdAt,
                  ));
                } else {
                  _messages.add(_ChatItem(
                    type: 'text',
                    text: msg.textContent,
                    timestamp: msg.createdAt,
                  ));
                }
              } else {
                _messages.add(_ChatItem(
                  type: 'user',
                  text: msg.textContent,
                  timestamp: msg.createdAt,
                ));
              }
            }
            _messageCount = _messages.where((m) => m.type == 'user').length;
          });
          _scrollToBottom();
          return; // Resumed successfully — don't start new
        }
      } catch (_) {
        // Failed to load saved conversation — start fresh
      }
    }

    // No saved conversation or failed to load — start fresh
    _startFreshConversation(auth);
  }

  Future<void> _startFreshConversation(({String token, int? userId}) auth) async {
    final contextMessage = _buildSkinContext();

    setState(() {
      _isLoading = false;
      _isStreaming = true;
    });

    final response = await TeaService.startChat(
      auth.token,
      message: contextMessage,
      userId: auth.userId,
      mode: 'skincare',
    );
    if (response == null || !mounted) {
      setState(() => _isStreaming = false);
      return;
    }
    _conversationId = response.conversationId;
    _saveConversationId(response.conversationId);
    _listenToStream(response.streamUrl, auth.token);
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _controller.text.trim();
    if (text.isEmpty || _isStreaming) return;

    if (overrideText == null) _controller.clear();
    FocusScope.of(context).unfocus();
    _lastUserMessage = text;
    setState(() {
      _messages.add(_ChatItem(type: 'user', text: text));
    });
    _scrollToBottom();

    final auth = await _getAuth();
    if (auth == null || !mounted) return;

    _messageCount++;
    setState(() => _isStreaming = true);

    final response = await TeaService.startChat(
      auth.token,
      message: text,
      conversationId: _conversationId,
      userId: auth.userId,
      mode: 'skincare',
    );

    if (response == null || !mounted) {
      setState(() {
        _isStreaming = false;
        _messages.add(_ChatItem(
          type: 'text',
          text: _isSwahili
              ? 'Samahani, kuna tatizo. Jaribu tena.'
              : 'Sorry, something went wrong. Try again.',
          isError: true,
        ));
      });
      return;
    }

    if (_conversationId == null) {
      _conversationId = response.conversationId;
      _saveConversationId(response.conversationId);
    }
    _listenToStream(response.streamUrl, auth.token);
  }

  void _retryLastMessage() {
    if (_lastUserMessage == null || _isStreaming) return;
    if (_messages.isNotEmpty && _messages.last.isError) {
      setState(() => _messages.removeLast());
    }
    _sendMessage(_lastUserMessage!);
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
          _maybeShowDiaryPrompt();
        }
      },
      onError: (e) {
        debugPrint('[ShangaziSkin] SSE error: $e');
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
        _maybeShowDiaryPrompt();
      },
    );
  }

  void _maybeShowDiaryPrompt() {
    // Show diary prompt after 3+ user messages, only once
    if (_messageCount >= 3 && !_diaryLogged && !_showDiaryPrompt && mounted) {
      setState(() => _showDiaryPrompt = true);
      _scrollToBottom();
    }
  }

  Future<void> _logDiaryMood(int mood) async {
    setState(() {
      _diaryLogged = true;
      _showDiaryPrompt = false;
    });

    final service = SkincareService();
    try {
      await service.logDiaryEntry(
        userId: widget.userId,
        date: DateTime.now(),
        mood: mood,
        tags: const ['shangazi_skin_chat'],
        notes: _isSwahili
            ? 'Ilirekodiwa kupitia Shangazi Skin'
            : 'Logged via Shangazi Skin chat',
      );
      if (!mounted) return;
      final label = _isSwahili
          ? 'Hali ya ngozi imehifadhiwa: $mood/5'
          : 'Skin mood logged: $mood/5';
      setState(() {
        _messages.add(_ChatItem(type: 'action_result', text: label));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatItem(
          type: 'action_result',
          text: _isSwahili
              ? 'Imeshindikana kuhifadhi hali ya ngozi'
              : 'Failed to log skin mood',
        ));
      });
    }
    _scrollToBottom();
  }

  Future<void> _handleActionConfirm(ActionCard card, bool confirmed) async {
    final auth = await _getAuth();
    if (auth == null || !mounted) return;

    final result = await TeaService.confirmAction(
      auth.token,
      card.actionCardId,
      confirmed: confirmed,
    );

    if (!mounted) return;

    if (result != null) {
      final message = result['message']?.toString() ??
          (confirmed
              ? (_isSwahili ? 'Hatua imethibitishwa.' : 'Action confirmed.')
              : (_isSwahili ? 'Hatua imeghairiwa.' : 'Action cancelled.'));
      setState(() {
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
          text: _isSwahili
              ? 'Imeshindikana. Jaribu tena.'
              : 'Failed. Try again.',
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

  // --- Markdown-like formatting ---

  Widget _buildFormattedText(String text) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
      } else if (line.startsWith('## ') || line.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.replaceFirst(RegExp(r'^#{2,3}\s*'), ''),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
              height: 1.4,
            ),
          ),
        ));
      } else if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('\u{2022} ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\u{2022}  ',
                style: TextStyle(fontSize: 14, color: _kPrimary),
              ),
              Expanded(
                child: _buildRichLine(
                  line.replaceFirst(RegExp(r'^\s*[-\u{2022}]\s*'), ''),
                ),
              ),
            ],
          ),
        ));
      } else {
        children.add(_buildRichLine(line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildRichLine(String line) {
    final parts = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        parts.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }
      parts.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < line.length) {
      parts.add(TextSpan(text: line.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: _kPrimary,
          height: 1.4,
        ),
        children: parts.isEmpty ? [TextSpan(text: line)] : parts,
      ),
    );
  }

  // --- Copy/share bottom sheet ---

  void _showMessageActions(String text) {
    final sw = _isSwahili;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: _kPrimary),
              title: Text(sw ? 'Nakili' : 'Copy'),
              minTileHeight: 48,
              onTap: () {
                Clipboard.setData(ClipboardData(text: text));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sw ? 'Imenakiliwa' : 'Copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: _kPrimary),
              title: Text(sw ? 'Shiriki' : 'Share'),
              minTileHeight: 48,
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(ShareParams(text: text));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- Feedback ---

  void _submitFeedback(String type) async {
    final auth = await _getAuth();
    if (auth == null) return;
    final id = _conversationId ?? '';
    await TeaService.submitFeedback(auth.token, id, type);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSwahili ? 'Asante!' : 'Thanks!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildFeedbackRow(int messageIndex) {
    final key = '$messageIndex';
    if (_feedbackGivenForIndex == key) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              icon: const Icon(Icons.thumb_up_outlined, color: Color(0xFF757575)),
              onPressed: () {
                setState(() => _feedbackGivenForIndex = key);
                _submitFeedback('helpful');
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              icon: const Icon(Icons.thumb_down_outlined, color: Color(0xFF757575)),
              onPressed: () {
                setState(() => _feedbackGivenForIndex = key);
                _submitFeedback('harmful');
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Timestamp ---

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:$minute $period';
  }

  Widget _buildTimestamp(DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _formatTime(timestamp),
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  int _lastBotTextIndex() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].type == 'text' && !_messages[i].isError) return i;
    }
    return -1;
  }

  // ─── Conversation History ──────────────────────────────────────

  void _showConversationHistory() async {
    final auth = await _getAuth();
    if (auth == null || !mounted) return;

    final conversations = await TeaService.getConversations(auth.token);
    if (!mounted) return;

    final sw = _isSwahili;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                sw ? 'Mazungumzo ya awali' : 'Past conversations',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: conversations.isEmpty
                  ? Center(
                      child: Text(
                        sw ? 'Hakuna mazungumzo ya awali' : 'No past conversations',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (ctx, i) {
                        final conv = conversations[i];
                        return ListTile(
                          leading: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.spa_rounded, size: 18, color: _kPrimary),
                          ),
                          title: Text(
                            conv.title ?? (sw ? 'Mazungumzo #${i + 1}' : 'Conversation #${i + 1}'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: conv.lastMessagePreview != null
                              ? Text(conv.lastMessagePreview!, style: const TextStyle(fontSize: 12, color: Color(0xFF757575)), maxLines: 2, overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: Text(_formatConvDate(conv.updatedAt), style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                          onTap: () {
                            Navigator.pop(ctx);
                            _loadConversation(conv.id, auth.token);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatConvDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$h:$minute $period';
    } else if (diff.inDays == 1) {
      return _isSwahili ? 'Jana' : 'Yesterday';
    } else if (diff.inDays < 7) {
      const en = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const sw = ['', 'Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
      return _isSwahili ? sw[date.weekday] : en[date.weekday];
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _loadConversation(String convId, String token) async {
    _saveConversationId(convId); // persist so it resumes on next visit
    setState(() {
      _messages.clear();
      _conversationId = convId;
      _isLoading = true;
      _feedbackGivenForIndex = null;
    });

    final messages = await TeaService.getConversationMessages(token, convId);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      for (final msg in messages) {
        if (msg.isFromShangazi) {
          if (msg.isTeaCard) {
            _messages.add(_ChatItem(
              type: 'tea_card',
              teaCard: TeaCard.fromJson(msg.content),
              timestamp: msg.createdAt,
            ));
          } else {
            _messages.add(_ChatItem(
              type: 'text',
              text: msg.textContent,
              timestamp: msg.createdAt,
            ));
          }
        } else {
          _messages.add(_ChatItem(
            type: 'user',
            text: msg.textContent,
            timestamp: msg.createdAt,
          ));
        }
      }
    });
    _scrollToBottom();
  }

  List<_SuggestionChip> _getSuggestionChips() {
    final sw = _isSwahili;
    final topConcern = widget.profile?.concerns.isNotEmpty == true
        ? widget.profile!.concerns.first
        : null;
    final concernLabel = topConcern != null
        ? (sw ? topConcern.displayName : topConcern.name)
        : null;

    return [
      _SuggestionChip(
        label: sw ? 'Ratiba yangu ya asubuhi' : 'My morning routine',
        icon: Icons.wb_sunny_rounded,
      ),
      if (concernLabel != null)
        _SuggestionChip(
          label: sw ? 'Bidhaa ya $concernLabel' : 'Product for $concernLabel',
          icon: Icons.shopping_bag_rounded,
        ),
      _SuggestionChip(
        label: sw ? 'Je niacinamide ni salama?' : 'Is niacinamide safe?',
        icon: Icons.science_rounded,
      ),
      _SuggestionChip(
        label: sw ? 'Kwa nini ninapata chunusi?' : 'Why am I breaking out?',
        icon: Icons.help_outline_rounded,
      ),
      _SuggestionChip(
        label: sw ? 'Ushauri wa mafuta ya jua' : 'Sunscreen advice',
        icon: Icons.wb_sunny_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;

    // When embedded inside SkincareHomePage, skip Scaffold/AppBar.
    if (widget.embedded) {
      return Column(
        children: [
          // Chat controls row
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _startNewChat,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_comment_rounded, size: 13, color: _kSecondary),
                      const SizedBox(width: 3),
                      Text(sw ? 'Mpya' : 'New', style: const TextStyle(fontSize: 10, color: _kSecondary)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showConversationHistory,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.history_rounded, size: 13, color: _kSecondary),
                      const SizedBox(width: 3),
                      Text(sw ? 'Historia' : 'History', style: const TextStyle(fontSize: 10, color: _kSecondary)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildMessageList()),
          if (_showDiaryPrompt && !_diaryLogged) _buildDiaryPrompt(),
          _buildChipsRow(),
          _buildInputBar(),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          sw ? 'Shangazi Ngozi' : 'Shangazi Skin',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: _kPrimary, size: 20),
            onPressed: _startNewChat,
            tooltip: sw ? 'Mazungumzo mapya' : 'New chat',
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: _kPrimary, size: 22),
            onPressed: _showConversationHistory,
            tooltip: sw ? 'Mazungumzo ya awali' : 'Past conversations',
          ),
        ],
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_showDiaryPrompt && !_diaryLogged) _buildDiaryPrompt(),
            _buildChipsRow(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _isSwahili
                  ? 'Shangazi anajiandaa...'
                  : 'Shangazi is getting ready...',
              style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
            ),
          ],
        ),
      );
    }

    final showTypingDots =
        _isStreaming && _streamingText.isEmpty;
    final itemCount = _messages.length +
        (_isStreaming && _streamingText.isNotEmpty ? 1 : 0) +
        (showTypingDots ? 1 : 0);

    if (itemCount == 0 && !_isStreaming) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _isSwahili
                  ? 'Habari! Mimi ni Shangazi wa ngozi.\nNiulize chochote kuhusu ngozi yako.'
                  : 'Hi! I\'m your Skin Shangazi.\nAsk me anything about your skin.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final lastBotIdx = _lastBotTextIndex();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (showTypingDots && index == itemCount - 1) {
          return ShangaziMessageBubble(
            name: _isSwahili ? 'Shangazi Ngozi' : 'Shangazi Skin',
            avatarIcon: Icons.spa_rounded,
            child: _TypingDotsWidget(controller: _dotsController),
          );
        }

        if (index >= _messages.length) {
          return ShangaziMessageBubble(
            name: _isSwahili ? 'Shangazi Ngozi' : 'Shangazi Skin',
            avatarIcon: Icons.spa_rounded,
            onLongPress: () => _showMessageActions(_streamingText),
            child: _buildFormattedText(_streamingText),
          );
        }

        final item = _messages[index];
        final isLastBot = index == lastBotIdx && !_isStreaming;

        switch (item.type) {
          case 'user':
            return _buildUserBubble(item);
          case 'text':
            if (item.isError) {
              return ShangaziMessageBubble(
                name: _isSwahili ? 'Shangazi Ngozi' : 'Shangazi Skin',
                avatarIcon: Icons.spa_rounded,
                onLongPress: () => _showMessageActions(item.text ?? ''),
                footer: _buildTimestamp(item.timestamp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.text ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        onPressed: _retryLastMessage,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          _isSwahili ? 'Jaribu tena' : 'Try again',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return ShangaziMessageBubble(
              name: _isSwahili ? 'Shangazi Ngozi' : 'Shangazi Skin',
              avatarIcon: Icons.spa_rounded,
              onLongPress: () => _showMessageActions(item.text ?? ''),
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLastBot) _buildFeedbackRow(index),
                  _buildTimestamp(item.timestamp),
                ],
              ),
              child: _buildFormattedText(item.text ?? ''),
            );
          case 'tea_card':
            if (item.teaCard == null) return const SizedBox.shrink();
            return ShangaziMessageBubble(
              name: _isSwahili ? 'Shangazi Ngozi' : 'Shangazi Skin',
              avatarIcon: Icons.spa_rounded,
              footer: _buildTimestamp(item.timestamp),
              child: TeaCardWidget(
                card: item.teaCard!,
                onTap: () {},
                onActionTap: (action) => _sendMessage(action),
              ),
            );
          case 'action_card':
            if (item.actionCard == null) return const SizedBox.shrink();
            return ShangaziMessageBubble(
              name: _isSwahili ? 'Shangazi Ngozi' : 'Shangazi Skin',
              avatarIcon: Icons.spa_rounded,
              footer: _buildTimestamp(item.timestamp),
              child: ActionCardWidget(
                actionCard: item.actionCard!,
                onConfirm: () =>
                    _handleActionConfirm(item.actionCard!, true),
                onCancel: () =>
                    _handleActionConfirm(item.actionCard!, false),
              ),
            );
          case 'action_result':
            return ShangaziMessageBubble(
              name: _isSwahili ? 'Shangazi Ngozi' : 'Shangazi Skin',
              avatarIcon: Icons.spa_rounded,
              footer: _buildTimestamp(item.timestamp),
              child: Text(
                item.text ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: _kPrimary,
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

  Widget _buildUserBubble(_ChatItem item) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onLongPress: () => _showMessageActions(item.text ?? ''),
        child: Container(
          margin: const EdgeInsets.only(left: 48, right: 12, top: 4, bottom: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.text ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFAFAFA),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(item.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChipsRow() {
    if (_isStreaming) return const SizedBox.shrink();
    final chips = _getSuggestionChips();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((chip) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(chip.icon, size: 16, color: _kPrimary),
                label: Text(
                  chip.label,
                  style: const TextStyle(fontSize: 12, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(color: _kPrimary.withValues(alpha: 0.15)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () => _sendMessage(chip.label),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDiaryPrompt() {
    final sw = _isSwahili;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sw ? 'Rekodi hali ya ngozi leo?' : 'Log today\'s skin mood?',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final mood = i + 1;
              final icons = [
                Icons.sentiment_very_dissatisfied_rounded,
                Icons.sentiment_dissatisfied_rounded,
                Icons.sentiment_neutral_rounded,
                Icons.sentiment_satisfied_rounded,
                Icons.sentiment_very_satisfied_rounded,
              ];
              return InkWell(
                onTap: () => _logDiaryMood(mood),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i], size: 32, color: _kPrimary),
                      const SizedBox(height: 2),
                      Text(
                        '$mood',
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => _showDiaryPrompt = false),
              child: Text(
                sw ? 'Sio sasa' : 'Not now',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final sw = _isSwahili;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: sw
                    ? 'Uliza kuhusu ngozi yako...'
                    : 'Ask about your skin...',
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
                color: _kPrimary,
              ),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: _isStreaming ? null : () => _sendMessage(),
              icon: Icon(
                Icons.send_rounded,
                color: _isStreaming
                    ? const Color(0xFF9E9E9E)
                    : _kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated typing indicator -- 3 pulsing dots.
class _TypingDotsWidget extends StatelessWidget {
  final AnimationController controller;
  const _TypingDotsWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (controller.value - delay) % 1.0;
            final scale = t < 0.5 ? 1.0 + t : 2.0 - t;
            final opacity = t < 0.5 ? 0.4 + t * 1.2 : 1.0 - (t - 0.5) * 1.2;
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.8, 1.2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF757575),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SuggestionChip {
  final String label;
  final IconData icon;
  const _SuggestionChip({required this.label, required this.icon});
}
