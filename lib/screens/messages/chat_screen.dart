import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/message_models.dart';
import '../../services/message_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/call_signaling_service.dart';
import '../../services/friend_service.dart';
import '../../services/live_update_service.dart';
import '../../services/message_database.dart';
import '../../services/message_sync_service.dart';
import '../../services/pending_message_store.dart';
import '../../models/friend_models.dart';
import '../../widgets/user_avatar.dart';
import '../calls/outgoing_call_flow_screen.dart';
import '../../widgets/cached_media_image.dart';
import '../../widgets/poll_vote_widget.dart';
import '../../widgets/live_photo_viewer.dart';
import '../../widgets/video_player_widget.dart';
import '../../services/live_photo_service.dart';
import '../../services/media_cache_service.dart';
import 'group_call_screen.dart';
import 'group_info_screen.dart';
import 'invite_link_screen.dart';
import 'message_info_screen.dart';
import '../groups/createevent_screen.dart';
import '../groups/createpoll_screen.dart';
import '../groups/group_events_screen.dart';
import '../../config/api_config.dart';
import '../../services/link_preview_service.dart';
import '../../services/presence_service.dart';
import '../../widgets/sticker_browser.dart';
import '../../services/sticker_service.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/message_reminder_service.dart';

// Design: DOCS/DESIGN.md — #FAFAFA background, 48dp min touch targets
// Story 39: sender bubble blue, receiver gray; read receipts, timestamps; text, image, video, voice
/// When set (e.g. after a missed call), prompts user to send a voice or video note.
enum ChatPromptAfterCall { voice, video }

/// Quick reaction emojis for long-press (MESSAGES.md: message reactions).
const List<String> _kReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int currentUserId;
  final Conversation? conversation;
  /// If set, shows "Send voice note?" / "Send video note?" after opening (e.g. after missed call).
  final ChatPromptAfterCall? promptAfterCall;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    this.conversation,
    this.promptAfterCall,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// Min touch target per DESIGN.md
const double _kMinTouchTarget = 48.0;

// Bubble colors per Story 39: sender right (blue), receiver left (gray)
const Color _kSenderBubble = Color(0xFF2196F3);
const Color _kReceiverBubble = Color(0xFFE0E0E0);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final FriendService _friendService = FriendService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<Message> _messages = [];
  Conversation? _conversation;
  bool _isLoading = true;
  bool _isSending = false;
  Message? _replyingTo;

  // Typing indicators
  List<TypingUser> _typingUsers = [];
  Timer? _typingTimer;
  Timer? _typingStatusTimer;
  bool _isTyping = false;

  // Draft: auto-save per conversation
  static const String _draftKeyPrefix = 'chat_draft_';
  static const Duration _draftDebounce = Duration(milliseconds: 800);
  Timer? _draftSaveTimer;

  // Voice recording (in-chat). flutter_sound not available on macOS.
  FlutterSoundRecorder? _voiceRecorder;
  bool _isVoiceRecorderReady = false;
  bool _isRecordingVoice = false;
  int _recordingDurationSec = 0;
  String? _recordedVoicePath;
  Timer? _voiceRecordingTimer;
  StreamSubscription<RecordingDisposition>? _recorderSub;

  /// Upload progress 0.0..1.0 when sending media; null when not uploading.
  double? _uploadProgress;
  static const int _minVoiceRecordingSec = 3;

  // Feature 2: Recording waveform bars
  List<double> _waveformBars = [];

  // Feature 4: Voice transcript expanded state (keyed by message.id)
  final Set<int> _expandedTranscripts = {};

  /// @mention overlay for groups: show when user types @ (MESSAGES.md: @all mentions).
  bool _showMentionOverlay = false;
  String _mentionQuery = '';

  // Phase 4: In-chat message search
  bool _showChatSearch = false;
  List<Message> _chatSearchResults = [];
  int _chatSearchIndex = 0;
  final TextEditingController _chatSearchController = TextEditingController();

  // Phase 5: Link preview detection
  LinkPreviewData? _linkPreview;
  Timer? _linkPreviewDebounce;

  // Presence for 1:1 partner / group members
  Map<int, PresenceInfo> _presences = {};

  StreamSubscription<LiveUpdateEvent>? _liveUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _loadFromCacheAndSync();
    _loadDraft();
    _markAsRead();
    _startTypingStatusPolling();
    _liveUpdateSubscription = LiveUpdateService.instance.stream.listen((event) {
      if (event is MessagesUpdateEvent &&
          (event.conversationId == null || event.conversationId == widget.conversationId) &&
          mounted) {
        _onLiveMessageUpdate();
      }
    });
    _messageController.addListener(_onTypingChanged);
    _messageController.addListener(_onDraftChanged);
    _messageController.addListener(_onMentionCheck);
    _messageController.addListener(_checkForLinks);
    _initVoiceRecorder();
    if (widget.promptAfterCall != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPromptAfterCall());
    }
  }

  @override
  void dispose() {
    if (_isRecordingVoice) {
      _messageService.stopRecording(widget.conversationId, widget.currentUserId);
    }
    _liveUpdateSubscription?.cancel();
    _messageController.removeListener(_onTypingChanged);
    _messageController.removeListener(_onDraftChanged);
    _messageController.removeListener(_onMentionCheck);
    _messageController.removeListener(_checkForLinks);
    _draftSaveTimer?.cancel();
    _voiceRecordingTimer?.cancel();
    _recorderSub?.cancel();
    _voiceRecorder?.closeRecorder();
    _messageController.dispose();
    _scrollController.dispose();
    _chatSearchController.dispose();
    _typingTimer?.cancel();
    _typingStatusTimer?.cancel();
    _linkPreviewDebounce?.cancel();
    _stopTyping();
    super.dispose();
  }

  Future<void> _initVoiceRecorder() async {
    if (Platform.isMacOS) return;
    _voiceRecorder = FlutterSoundRecorder();
    try {
      await _voiceRecorder!.openRecorder();
      _recorderSub = _voiceRecorder!.onProgress?.listen((e) {
        if (mounted) {
          final db = e.decibels ?? -50;
          final normalized = ((db + 50) / 50).clamp(0.1, 1.0);
          setState(() {
            _recordingDurationSec = e.duration.inSeconds;
            _waveformBars.add(normalized);
          });
        }
      });
      await _voiceRecorder!.setSubscriptionDuration(const Duration(milliseconds: 500));
      if (mounted) setState(() => _isVoiceRecorderReady = true);
    } catch (e) {
      debugPrint('[Chat] Voice recorder init failed: $e');
    }
  }

  void _showPromptAfterCall() {
    if (!mounted || widget.promptAfterCall == null) return;
    final isVoice = widget.promptAfterCall == ChatPromptAfterCall.voice;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVoice ? 'Send voice note?' : 'Send video note?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (isVoice) {
                        _startVoiceRecording();
                      } else {
                        _recordVideoMessage();
                      }
                    },
                    child: Text(isVoice ? 'Voice note' : 'Video note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startVoiceRecording() async {
    if (Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice recording is not available on this device')),
      );
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required to record')),
        );
      }
      return;
    }
    if (!_isVoiceRecorderReady || _voiceRecorder == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recorder not ready. Try again.')),
        );
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      _recordedVoicePath = '${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _voiceRecorder!.startRecorder(
        toFile: _recordedVoicePath,
        codec: Codec.aacADTS,
      );
      if (mounted) {
        setState(() {
          _isRecordingVoice = true;
          _recordingDurationSec = 0;
        });
      }
      await _messageService.startRecording(widget.conversationId, widget.currentUserId);
      _voiceRecordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingDurationSec += 1);
      });
    } catch (e) {
      debugPrint('[Chat] Start voice recording failed: $e');
      if (mounted) {
        setState(() => _isRecordingVoice = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording({bool cancel = false}) async {
    if (!_isRecordingVoice || _voiceRecorder == null) return;
    final duration = _recordingDurationSec;
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
    await _messageService.stopRecording(widget.conversationId, widget.currentUserId);
    try {
      await _voiceRecorder!.stopRecorder();
    } catch (_) {}
    final path = _recordedVoicePath;
    if (mounted) {
      setState(() {
        _isRecordingVoice = false;
        _recordingDurationSec = 0;
        _recordedVoicePath = null;
        _waveformBars = [];
      });
    }
    if (!cancel && path != null && path.isNotEmpty) {
      if (duration < _minVoiceRecordingSec) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Record at least $_minVoiceRecordingSec second${_minVoiceRecordingSec > 1 ? 's' : ''} to send')),
          );
        }
        return;
      }
      final file = File(path);
      if (await file.exists()) await _sendVoiceFile(file);
    }
  }

  Future<void> _sendVoiceFile(File file) async {
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Voice message', messageType: 'audio');
    setState(() {
      _isSending = true;
      _uploadProgress = null;
    });
    final result = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'audio',
      media: file,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      },
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _uploadProgress = null;
      if (result.success && result.message != null) {
        _messages.add(result.message!);
        _cacheMessage(result.message!);
      }
    });
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to send voice message')),
      );
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': 'Voice message',
        'message_type': 'audio',
        'media_path': file.path,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  Future<void> _recordVideoMessage() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video == null || !mounted) return;
    final file = File(video.path);
    if (!await file.exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recording failed. File not found.')));
      return;
    }
    if (!mounted) return;
    setState(() {
      _isSending = true;
      _uploadProgress = null;
    });
    final result = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'video',
      media: file,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      },
    );
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _uploadProgress = null;
      if (result.success && result.message != null) {
        _messages.add(result.message!);
        _cacheMessage(result.message!);
      }
    });
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to send video')),
      );
    }
    _scrollToBottom();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_draftKeyPrefix${widget.conversationId}';
    final draft = prefs.getString(key);
    if (draft != null && draft.isNotEmpty && mounted) {
      _messageController.text = draft;
    }
  }

  /// Detect URLs in message text and fetch link preview with debounce.
  void _checkForLinks() {
    _linkPreviewDebounce?.cancel();
    final text = _messageController.text;
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(text);
    if (match == null) {
      if (_linkPreview != null) setState(() => _linkPreview = null);
      return;
    }
    final url = match.group(0)!;
    if (_linkPreview?.url == url) return;
    _linkPreviewDebounce = Timer(const Duration(milliseconds: 600), () async {
      final preview = await LinkPreviewService.fetchPreview(url);
      if (mounted && _messageController.text.contains(url)) {
        setState(() => _linkPreview = preview);
      }
    });
  }

  void _onDraftChanged() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(_draftDebounce, () async {
      final text = _messageController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      final key = '$_draftKeyPrefix${widget.conversationId}';
      if (text.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, _messageController.text);
      }
    });
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_draftKeyPrefix${widget.conversationId}');
  }

  void _onTypingChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _startTyping();
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _stopTyping();
    });
  }

  void _onMentionCheck() {
    if (_conversation?.isGroup != true) {
      if (_showMentionOverlay) setState(() => _showMentionOverlay = false);
      return;
    }
    final text = _messageController.text;
    final lastAt = text.lastIndexOf('@');
    if (lastAt < 0) {
      if (_showMentionOverlay) setState(() => _showMentionOverlay = false);
      return;
    }
    final afterAt = text.substring(lastAt + 1);
    if (afterAt.contains(' ') || afterAt.contains('\n')) {
      if (_showMentionOverlay) setState(() => _showMentionOverlay = false);
      return;
    }
    setState(() {
      _showMentionOverlay = true;
      _mentionQuery = afterAt.toLowerCase();
    });
  }

  void _insertMention(String replacement) {
    final text = _messageController.text;
    final lastAt = text.lastIndexOf('@');
    if (lastAt < 0) return;
    final newText = text.substring(0, lastAt) + replacement + ' ';
    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(offset: newText.length);
    setState(() => _showMentionOverlay = false);
  }

  Widget _buildMentionOverlay() {
    if (!_showMentionOverlay || _conversation == null) return const SizedBox.shrink();
    final participants = _conversation!.participants
        .where((p) => p.userId != widget.currentUserId)
        .toList();
    final query = _mentionQuery;
    final matches = query.isEmpty
        ? participants
        : participants.where((p) {
            final name = (p.user?.fullName ?? '').toLowerCase();
            return name.contains(query);
          }).toList();
    const maxItems = 6;
    final list = <Widget>[
      ListTile(
        leading: const Icon(Icons.group, size: 20, color: _kSecondaryText),
        title: const Text('@all', style: TextStyle(fontWeight: FontWeight.w600)),
        onTap: () => _insertMention('@all'),
      ),
    ];
    for (final p in matches.take(maxItems - 1)) {
      final name = p.user?.fullName ?? 'Member';
      list.add(ListTile(
        leading: UserAvatar(photoUrl: p.user?.profilePhotoUrl, name: name, radius: 16),
        title: Text(name),
        onTap: () => _insertMention('@$name'),
      ));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: _kSecondaryText.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: ListView(
        shrinkWrap: true,
        children: list,
      ),
    );
  }

  // --- Phase 4: In-chat message search ---

  void _performChatSearch(String query) async {
    if (query.length < 2) {
      setState(() { _chatSearchResults = []; _chatSearchIndex = 0; });
      return;
    }
    // Step 1: Search SQLite for locally cached messages (broader than in-memory _messages)
    final localResults = await MessageDatabase.instance.searchMessages(
      query,
      conversationId: widget.conversationId,
    );
    if (!mounted) return;
    setState(() {
      _chatSearchResults = localResults;
      _chatSearchIndex = 0;
    });
    // Step 2: Also search API for completeness
    final apiResult = await MessageService.searchMessages(
      userId: widget.currentUserId,
      query: query,
      conversationId: widget.conversationId,
    );
    if (apiResult.success && mounted) {
      final allIds = <int>{};
      final merged = <Message>[];
      for (final m in [...localResults, ...apiResult.messages]) {
        if (allIds.add(m.id)) merged.add(m);
      }
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() { _chatSearchResults = merged; });
    }
  }

  Widget _buildChatSearchBar() {
    if (!_showChatSearch) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatSearchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tafuta katika mazungumzo...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
              ),
              onChanged: _performChatSearch,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (_chatSearchResults.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text('${_chatSearchIndex + 1}/${_chatSearchResults.length}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              onPressed: () {
                if (_chatSearchIndex > 0) {
                  setState(() => _chatSearchIndex--);
                  _scrollToSearchResult();
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              onPressed: () {
                if (_chatSearchIndex < _chatSearchResults.length - 1) {
                  setState(() => _chatSearchIndex++);
                  _scrollToSearchResult();
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => setState(() {
              _showChatSearch = false;
              _chatSearchResults = [];
              _chatSearchIndex = 0;
              _chatSearchController.clear();
            }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  void _scrollToSearchResult() {
    if (_chatSearchResults.isEmpty) return;
    final targetMsg = _chatSearchResults[_chatSearchIndex];
    final idx = _messages.indexWhere((m) => m.id == targetMsg.id);
    if (idx >= 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        idx * 80.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- Phase 5: Link preview card above input bar ---

  Widget _buildLinkPreviewCard() {
    if (_linkPreview == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_linkPreview!.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(_linkPreview!.image!, width: 48, height: 48, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48)),
            ),
          if (_linkPreview!.image != null) const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_linkPreview!.title != null)
                Text(_linkPreview!.title!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (_linkPreview!.domain != null)
                Text(_linkPreview!.domain!, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF999999)),
            onPressed: () => setState(() => _linkPreview = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Future<void> _startTyping() async {
    if (_isTyping) return;
    _isTyping = true;
    await _messageService.startTyping(widget.conversationId, widget.currentUserId);
  }

  Future<void> _stopTyping() async {
    if (!_isTyping) return;
    _isTyping = false;
    await _messageService.stopTyping(widget.conversationId, widget.currentUserId);
  }

  void _startTypingStatusPolling() {
    _typingStatusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final result = await _messageService.getTypingStatus(
        widget.conversationId,
        widget.currentUserId,
      );
      if (result.success && mounted) {
        setState(() => _typingUsers = result.typingUsers);
      }
    });
  }

  /// Load from local SQLite first (instant UI), then delta-sync from server.
  Future<void> _loadFromCacheAndSync() async {
    setState(() => _isLoading = true);

    // 1. Load from local SQLite (instant, no network)
    final localMessages = await MessageDatabase.instance.getMessages(
      widget.conversationId,
      limit: 50,
    );
    if (mounted && localMessages.isNotEmpty) {
      setState(() {
        // getMessages returns newest-first (DESC); reverse for chat display (oldest at top, newest at bottom)
        _messages = localMessages.reversed.toList();
        _isLoading = false;
      });
      // No scroll needed — reverse ListView starts at bottom naturally
    }

    // 2. Background sync from server
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    // Only show spinner if we have no cached messages to display
    if (_messages.isEmpty) {
      setState(() => _isLoading = true);
    }

    if (_conversation == null) {
      final convResult = await _messageService.getConversation(
        widget.conversationId,
        widget.currentUserId,
      );
      if (convResult.success) {
        _conversation = convResult.conversation;
      }
    }

    // Delta-sync: check sync state to decide initial vs incremental
    try {
      final syncState = await MessageDatabase.instance.getSyncState(widget.conversationId);
      if (syncState == null || syncState['full_sync_complete'] != 1) {
        // First time: full fetch from server, stored into SQLite
        await MessageSyncService.instance.initialSync(
          widget.conversationId,
          widget.currentUserId,
        );
      } else {
        // Incremental: only new/edited/deleted since last sync
        await MessageSyncService.instance.syncConversation(
          widget.conversationId,
          widget.currentUserId,
        );
      }
    } catch (e) {
      debugPrint('[ChatScreen] Sync error (using local data): $e');
    }

    if (!mounted) return;

    // Reload merged list from SQLite (single source of truth)
    final updatedMessages = await MessageDatabase.instance.getMessages(
      widget.conversationId,
      limit: 50,
    );

    // Reverse: DB returns newest-first, chat needs oldest-first (newest at bottom)
    final chronological = updatedMessages.reversed.toList();
    setState(() {
      _isLoading = false;
      _messages = chronological;
    });
    // No scroll needed — reverse ListView starts at bottom naturally
    _fetchPresence();
    _markReceivedAsDelivered(chronological);
  }

  /// Lightweight handler for real-time message notifications — delta sync only.
  Future<void> _onLiveMessageUpdate() async {
    try {
      final newMessages = await MessageSyncService.instance.syncConversation(
        widget.conversationId,
        widget.currentUserId,
      );
      if (mounted && newMessages.isNotEmpty) {
        final updatedMessages = await MessageDatabase.instance.getMessages(
          widget.conversationId,
          limit: 50,
        );
        final chronological = updatedMessages.reversed.toList();
        setState(() => _messages = chronological);
        _scrollToBottom(animate: true);
        _markReceivedAsDelivered(chronological);
      }
    } catch (e) {
      debugPrint('[ChatScreen] Live update sync error: $e');
    }
  }

  /// Mark received messages as delivered (sender sees ✓✓).
  void _markReceivedAsDelivered(List<Message> messages) {
    for (final msg in messages) {
      if (msg.senderId != widget.currentUserId && msg.status == MessageStatus.sent) {
        MessageService.markDelivered(widget.conversationId, msg.id, widget.currentUserId);
      }
    }
  }

  Future<void> _fetchPresence() async {
    if (_conversation == null) return;
    final otherIds = _conversation!.participants
        .where((p) => p.userId != widget.currentUserId)
        .map((p) => p.userId)
        .toList();
    if (otherIds.isEmpty) return;
    final result = await PresenceService.batchPresence(otherIds);
    if (mounted && result.isNotEmpty) setState(() => _presences = result);
  }

  void _cacheMessage(Message message) {
    // Store sent/received message into local SQLite
    MessageDatabase.instance.upsertMessage(message);
  }

  /// With reverse: true on ListView, position 0.0 is the bottom (newest).
  /// Only needed when new messages are added while user has scrolled up.
  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels > 0) {
        if (animate) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(0.0);
        }
      }
    });
  }

  Future<void> _markAsRead() async {
    await _messageService.markAsRead(widget.conversationId, widget.currentUserId);
  }

  /// Other participant's user ID (1:1 only). Null for group or no other user.
  int? get _otherParticipantUserId {
    if (_conversation == null || _conversation!.isGroup) return null;
    final other = _conversation!.participants
        .where((p) => p.userId != widget.currentUserId)
        .firstOrNull;
    return other?.userId;
  }

  /// Open group call screen. Story 60: Home → Messages → Group chat → Group call.
  void _openGroupCall() {
    final conv = _conversation;
    if (conv == null || !conv.isGroup) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupCallScreen(
          conversationId: widget.conversationId,
          currentUserId: widget.currentUserId,
          conversation: conv,
        ),
      ),
    );
  }

  /// Initiate voice or video call. Story 59: Home → Messages → Chat → Call icon.
  Future<void> _initiateCall(String type) async {
    final calleeId = _otherParticipantUserId;
    if (calleeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simu inapatikana kwa mazungumzo ya mtu mmoja tu'),
          ),
        );
      }
      return;
    }

    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();
    final conv = _conversation;
    final calleeName = conv?.displayName ?? conv?.title ?? 'User';
    final calleeAvatarUrl = conv?.avatarUrl;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OutgoingCallFlowScreen(
          currentUserId: widget.currentUserId,
          authToken: authToken,
          calleeId: calleeId,
          calleeName: calleeName,
          calleeAvatarUrl: calleeAvatarUrl,
          type: type,
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();
    _clearDraft();
    _typingTimer?.cancel();
    _stopTyping();

    PendingMessageStore.instance.setPending(
      widget.conversationId,
      preview: content,
      messageType: 'text',
    );

    // Capture link preview before clearing
    final previewToSend = _linkPreview;

    final result = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      content: content,
      replyToId: _replyingTo?.id,
      linkPreviewUrl: previewToSend?.url,
      linkPreviewTitle: previewToSend?.title,
      linkPreviewDescription: previewToSend?.description,
      linkPreviewImage: previewToSend?.image,
      linkPreviewDomain: previewToSend?.domain,
    );

    PendingMessageStore.instance.clearPending(widget.conversationId);
    setState(() {
      _isSending = false;
      _replyingTo = null;
      _linkPreview = null;
      if (result.success && result.message != null) {
        _messages.add(result.message!);
        _cacheMessage(result.message!);
      }
    });

    if (!result.success) {
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': content,
        'message_type': 'text',
        'reply_to_id': _replyingTo?.id,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }

    _scrollToBottom();
  }

  /// Compress image for low bandwidth (Story 39). Max 800px, quality 85.
  static Future<File?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      const maxSize = 800;
      img.Image resized = decoded;
      if (decoded.width > maxSize || decoded.height > maxSize) {
        resized = img.copyResize(decoded, width: decoded.width > decoded.height ? maxSize : null, height: decoded.height > decoded.width ? maxSize : null);
      }
      final jpeg = img.encodeJpg(resized, quality: 85);
      if (jpeg.isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final out = File('${dir.path}/chat_img_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await out.writeAsBytes(jpeg);
      return out;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    // Check for Live Photo / Motion Photo
    final liveResult = await LivePhotoService.processPickedImage(image);

    if (liveResult.isLivePhoto && liveResult.videoComponent != null) {
      await _sendLivePhoto(liveResult.stillImage, liveResult.videoComponent!);
    } else {
      File fileToSend = liveResult.stillImage;
      if (!await fileToSend.exists()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image file not found.')));
        return;
      }
      final compressed = await _compressImage(fileToSend);
      if (compressed != null) fileToSend = compressed;
      await _sendImageFile(fileToSend);
    }
  }

  Future<void> _sendLivePhoto(File stillImage, File videoComponent) async {
    PendingMessageStore.instance.setPending(
      widget.conversationId,
      preview: 'Live Photo',
      messageType: 'live_photo',
    );
    setState(() {
      _isSending = true;
      _uploadProgress = null;
    });

    // Compress the still image before upload
    File imageToSend = stillImage;
    final compressed = await _compressImage(stillImage);
    if (compressed != null) imageToSend = compressed;

    final result = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'live_photo',
      media: imageToSend,
      videoMedia: videoComponent,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      },
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _uploadProgress = null;
      if (result.success && result.message != null) {
        _messages.add(result.message!);
        _cacheMessage(result.message!);
      }
    });
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to send Live Photo')),
      );
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': 'Live Photo',
        'message_type': 'live_photo',
        'media_path': imageToSend.path,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendImageFile(File fileToSend) async {
    PendingMessageStore.instance.setPending(
      widget.conversationId,
      preview: 'Photo',
      messageType: 'image',
    );
    setState(() {
      _isSending = true;
      _uploadProgress = null;
    });
    final result = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'image',
      media: fileToSend,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      },
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _uploadProgress = null;
      if (result.success && result.message != null) {
        _messages.add(result.message!);
        _cacheMessage(result.message!);
      }
    });
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to send image')),
      );
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': 'Photo',
        'message_type': 'image',
        'media_path': fileToSend.path,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null || !mounted) return;

    final file = File(video.path);
    if (!await file.exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video file not found.')));
      return;
    }
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Video', messageType: 'video');
    setState(() {
      _isSending = true;
      _uploadProgress = null;
    });
    final result = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'video',
      media: file,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      },
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _uploadProgress = null;
      if (result.success && result.message != null) {
        _messages.add(result.message!);
        _cacheMessage(result.message!);
      }
    });
    if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to send video')),
      );
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': 'Video',
        'message_type': 'video',
        'media_path': file.path,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendVoice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null || !mounted) return;

    final file = File(result.files.single.path!);
    if (!await file.exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio file not found.')));
      return;
    }
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Voice message', messageType: 'audio');
    setState(() {
      _isSending = true;
      _uploadProgress = null;
    });
    final sendResult = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'audio',
      media: file,
      onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      },
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _uploadProgress = null;
      if (sendResult.success && sendResult.message != null) {
        _messages.add(sendResult.message!);
        _cacheMessage(sendResult.message!);
      }
    });
    if (!sendResult.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sendResult.errorMessage ?? 'Failed to send audio')),
      );
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': 'Voice message',
        'message_type': 'audio',
        'media_path': file.path,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  /// Scan document: camera then send as document (MESSAGES.md: document scanning).
  Future<void> _scanDocument() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null || !mounted) return;
    final file = File(image.path);
    if (!await file.exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capture failed')));
      return;
    }
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Document', messageType: 'document');
    setState(() { _isSending = true; _uploadProgress = null; });
    final res = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'document',
      media: file,
      onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    setState(() { _isSending = false; _uploadProgress = null; });
    if (res.success && res.message != null) {
      _messages.add(res.message!);
      _cacheMessage(res.message!);
    }
    if (!res.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to send scan')));
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': 'Document',
        'message_type': 'document',
        'media_path': file.path,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  /// Send document (PDF, DOCX, etc.) — MESSAGES.md: document send.
  Future<void> _sendDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.single.path == null || !mounted) return;
    final file = File(result.files.single.path!);
    if (!await file.exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found.')));
      return;
    }
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Document', messageType: 'document');
    setState(() { _isSending = true; _uploadProgress = null; });
    final res = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'document',
      media: file,
      onProgress: (p) { if (mounted) setState(() => _uploadProgress = p); },
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    setState(() { _isSending = false; _uploadProgress = null; });
    if (res.success && res.message != null) {
      _messages.add(res.message!);
      _cacheMessage(res.message!);
    }
    if (!res.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to send document')));
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': 'Document',
        'message_type': 'document',
        'media_path': file.path,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  /// Share contact — pick from friends, send as contact message.
  Future<void> _shareContact() async {
    final friendsResult = await _friendService.getFriends(userId: widget.currentUserId, perPage: 50);
    if (!friendsResult.success || friendsResult.friends.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No contacts to share')));
      return;
    }
    final selected = await showModalBottomSheet<UserProfile>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Share contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: friendsResult.friends.length,
                itemBuilder: (context, index) {
                  final u = friendsResult.friends[index];
                  return ListTile(
                    leading: UserAvatar(photoUrl: u.profilePhotoUrl, name: u.fullName, radius: 24),
                    title: Text(u.fullName),
                    onTap: () => Navigator.pop(context, u),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final content = jsonEncode({'name': selected.fullName, 'user_id': selected.id});
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Contact', messageType: 'contact');
    final res = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'contact',
      content: content,
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    if (res.success && res.message != null) {
      _messages.add(res.message!);
      _cacheMessage(res.message!);
    }
    if (!res.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to share contact')));
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': content,
        'message_type': 'contact',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  /// Share current location — MESSAGES.md: location share.
  Future<void> _shareLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled')));
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission required')));
      return;
    }
    setState(() => _isSending = true);
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      setState(() => _isSending = false);
      return;
    }
    if (!mounted) return;
    final content = jsonEncode({'lat': position.latitude, 'lng': position.longitude});
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Location', messageType: 'location');
    final res = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      messageType: 'location',
      content: content,
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    setState(() => _isSending = false);
    if (res.success && res.message != null) {
      _messages.add(res.message!);
      _cacheMessage(res.message!);
    }
    if (!res.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to share location')));
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': content,
        'message_type': 'location',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  /// Send sticker from the StickerBrowser. Sends image URL for real stickers
  /// or the emoji character for fallback emoji stickers.
  Future<void> _sendSticker(Sticker sticker) async {
    final isEmoji = sticker.emoji != null && sticker.emoji!.isNotEmpty && sticker.imageUrl.isEmpty;
    final content = isEmoji ? sticker.emoji! : sticker.imageUrl;
    final messageType = isEmoji ? 'text' : 'sticker';
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Sticker', messageType: messageType);
    final res = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      content: content,
      messageType: messageType,
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    if (res.success && res.message != null) {
      _messages.add(res.message!);
      _cacheMessage(res.message!);
    }
    if (!res.success) {
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': content,
        'message_type': messageType,
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  /// Send GIF (URL as content or image; backend may store as image).
  Future<void> _sendGif(String gifUrl) async {
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'GIF', messageType: 'text');
    final res = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      content: gifUrl,
      messageType: 'text',
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    if (res.success && res.message != null) {
      _messages.add(res.message!);
      _cacheMessage(res.message!);
    }
    if (!res.success) {
      // Queue for offline retry
      await MessageDatabase.instance.addPendingMessage({
        'local_id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'conversation_id': widget.conversationId,
        'sender_id': widget.currentUserId,
        'content': gifUrl,
        'message_type': 'text',
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });
    }
    _scrollToBottom();
  }

  void _setReplyTo(Message message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _toggleStar(Message message) async {
    // Optimistic update
    final idx = _messages.indexWhere((m) => m.id == message.id);
    if (idx >= 0) {
      setState(() {
        _messages[idx] = _messages[idx].copyWith(isStarred: !message.isStarred);
      });
    }
    final success = await MessageService.toggleStar(
      widget.conversationId, message.id, widget.currentUserId,
    );
    if (success) {
      // Persist star state to SQLite
      await MessageDatabase.instance.toggleMessageStar(message.id, !message.isStarred);
    }
    if (!success && mounted) {
      // Revert on failure
      final revertIdx = _messages.indexWhere((m) => m.id == message.id);
      if (revertIdx >= 0) {
        setState(() {
          _messages[revertIdx] = _messages[revertIdx].copyWith(isStarred: message.isStarred);
        });
      }
    }
  }

  void _showCustomNotificationsSheet() {
    // Load current values from the participant settings
    final myParticipant = _conversation?.participants
        .where((p) => p.userId == widget.currentUserId)
        .firstOrNull;
    bool customTone = myParticipant?.customTone ?? false;
    bool customVibrate = myParticipant?.customVibrate ?? false;
    bool customPopup = myParticipant?.customPopup ?? false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arifa maalum',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Sauti maalum', style: TextStyle(fontSize: 15, color: _kPrimaryText)),
                  subtitle: const Text('Tumia sauti tofauti kwa mazungumzo haya', style: TextStyle(fontSize: 12, color: _kSecondaryText)),
                  value: customTone,
                  activeColor: _kPrimaryText,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    setSheetState(() => customTone = v);
                    if (_conversation != null) {
                      MessageService.updateConversationSettings(
                        conversationId: _conversation!.id,
                        userId: widget.currentUserId,
                        customTone: v,
                      );
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Mtetemo maalum', style: TextStyle(fontSize: 15, color: _kPrimaryText)),
                  subtitle: const Text('Tumia mtetemo tofauti kwa mazungumzo haya', style: TextStyle(fontSize: 12, color: _kSecondaryText)),
                  value: customVibrate,
                  activeColor: _kPrimaryText,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    setSheetState(() => customVibrate = v);
                    if (_conversation != null) {
                      MessageService.updateConversationSettings(
                        conversationId: _conversation!.id,
                        userId: widget.currentUserId,
                        customVibrate: v,
                      );
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text('Arifa za popup', style: TextStyle(fontSize: 15, color: _kPrimaryText)),
                  subtitle: const Text('Onyesha arifa za popup kwa mazungumzo haya', style: TextStyle(fontSize: 12, color: _kSecondaryText)),
                  value: customPopup,
                  activeColor: _kPrimaryText,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) {
                    setSheetState(() => customPopup = v);
                    if (_conversation != null) {
                      MessageService.updateConversationSettings(
                        conversationId: _conversation!.id,
                        userId: widget.currentUserId,
                        customPopup: v,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDisappearingMessagesSheet() async {
    final currentTimer = _conversation?.disappearingTimer ?? 0;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ujumbe unaopotea',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimaryText),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ujumbe mpya utapotea baada ya muda uliochaguliwa',
                style: TextStyle(fontSize: 13, color: _kSecondaryText),
              ),
              const SizedBox(height: 16),
              _buildTimerOption(ctx, 'Zima', 0, currentTimer),
              _buildTimerOption(ctx, 'Saa 24', 86400, currentTimer),
              _buildTimerOption(ctx, 'Siku 7', 604800, currentTimer),
              _buildTimerOption(ctx, 'Siku 90', 7776000, currentTimer),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final timerValue = selected == 0 ? null : selected;
    final success = await MessageService.setDisappearingTimer(
      widget.conversationId, widget.currentUserId, timerValue,
    );
    if (!mounted) return;
    if (success) {
      // Update local conversation state
      if (_conversation != null) {
        _conversation = Conversation.fromJson({
          ..._conversation!.toJson(),
          'disappearing_timer': timerValue,
        });
      }
      String label;
      if (timerValue == null) {
        label = 'Ujumbe unaopotea umezimwa';
      } else if (timerValue <= 86400) {
        label = 'Ujumbe utapotea baada ya saa 24';
      } else if (timerValue <= 604800) {
        label = 'Ujumbe utapotea baada ya siku 7';
      } else {
        label = 'Ujumbe utapotea baada ya siku 90';
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindikana kubadilisha muda wa ujumbe unaopotea')),
      );
    }
  }

  Widget _buildTimerOption(BuildContext ctx, String label, int seconds, int currentTimer) {
    final isSelected = currentTimer == seconds;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(ctx, seconds),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: _kPrimaryText,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kPrimaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editMessage(Message message) async {
    final content = message.content ?? message.preview;
    if (content.isEmpty) return;

    final controller = TextEditingController(text: content);
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit message'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Message',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (submitted != true || !mounted) return;
    final newContent = controller.text.trim();
    if (newContent.isEmpty) return;

    final result = await _messageService.editMessage(
      conversationId: widget.conversationId,
      messageId: message.id,
      userId: widget.currentUserId,
      content: newContent,
    );

    if (!mounted) return;
    if (result.success && result.message != null) {
      setState(() {
        final i = _messages.indexWhere((m) => m.id == message.id);
        if (i >= 0) _messages[i] = result.message!;
      });
      _cacheMessage(result.message!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to edit')),
      );
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be removed for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final ok = await _messageService.deleteMessage(
      conversationId: widget.conversationId,
      messageId: message.id,
      userId: widget.currentUserId,
    );

    if (!mounted) return;
    if (ok) {
      setState(() => _messages.removeWhere((m) => m.id == message.id));
      // Remove from SQLite so it doesn't reappear on next cache load
      MessageDatabase.instance.deleteMessages([message.id]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete message')),
      );
    }
  }

  Future<void> _forwardMessage(Message message) async {
    final conversationsResult = await _messageService.getConversations(
      userId: widget.currentUserId,
      perPage: 50,
    );
    if (!conversationsResult.success || !mounted) return;

    final list = conversationsResult.conversations
        .where((c) => c.id != widget.conversationId)
        .toList();
    if (list.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other conversations to forward to')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Conversation>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Forward to', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final c = list[index];
                  return ListTile(
                    leading: UserAvatar(
                      photoUrl: c.avatarUrl,
                      name: c.title,
                      radius: 24,
                    ),
                    title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    final content = message.content ?? message.preview;
    final result = await _messageService.forwardMessage(
      targetConversationId: selected.id,
      userId: widget.currentUserId,
      content: content,
      forwardFromMessageId: message.id,
    );

    if (!mounted) return;
    if (result.success) {
      // Cache forwarded message in target conversation's SQLite
      if (result.message != null) {
        MessageDatabase.instance.upsertMessage(result.message!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Forwarded to ${selected.title}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to forward')),
      );
    }
  }

  void _openChatInfo() {
    if (_conversation == null) return;
    if (_conversation!.isGroup) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GroupInfoScreen(
            conversation: _conversation!,
            currentUserId: widget.currentUserId,
          ),
        ),
      );
    } else {
      // 1:1 conversation — navigate to the other user's profile
      final otherUserId = _otherParticipantUserId;
      if (otherUserId != null) {
        Navigator.pushNamed(context, '/profile/$otherUserId');
      }
    }
  }

  /// Start group call (new API): select members → createGroupCall → OutgoingCallFlowScreen.
  Future<void> _startGroupCall() async {
    if (_conversation == null || !_conversation!.isGroup) return;
    final storage = await LocalStorageService.getInstance();
    final authToken = storage.getAuthToken();
    if (authToken == null || authToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tafadhali ingia kwenye akaunti kuanza simu ya kikundi')),
        );
      }
      return;
    }
    final groupId = _conversation!.groupId ?? widget.conversationId;
    final participants = _conversation!.participants
        .where((p) => p.userId != widget.currentUserId)
        .toList();
    if (participants.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hakuna washiriki wa kualika')),
        );
      }
      return;
    }
    final selectedIds = <int>[];
    String type = 'voice';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Chagua washiriki', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'voice', label: Text('Sauti')),
                      ButtonSegment(value: 'video', label: Text('Video')),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) => setModalState(() => type = s.first),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: participants.length,
                      itemBuilder: (ctx, i) {
                        final p = participants[i];
                        final name = p.user?.firstName ?? 'User ${p.userId}';
                        final selected = selectedIds.contains(p.userId);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (v) {
                            setModalState(() {
                              if (v == true) {
                                selectedIds.add(p.userId);
                              } else {
                                selectedIds.remove(p.userId);
                              }
                            });
                          },
                          title: Text(name),
                          secondary: UserAvatar(
                            photoUrl: p.user?.profilePhotoUrl,
                            name: name,
                            radius: 20,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              final signaling = CallSignalingService();
                              final resp = await signaling.createGroupCall(
                                groupId: groupId,
                                invitedUserIds: selectedIds,
                                type: type,
                                authToken: authToken,
                                userId: widget.currentUserId,
                              );
                              if (!mounted) return;
                              if (resp.success && resp.callId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OutgoingCallFlowScreen(
                                      currentUserId: widget.currentUserId,
                                      authToken: authToken,
                                      calleeId: 0,
                                      calleeName: _conversation!.title,
                                      type: type,
                                      existingCallId: resp.callId,
                                      existingIceServers: resp.iceServers,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(resp.message ?? 'Imeshindwa kuanzisha simu')),
                                );
                              }
                            },
                      child: const Text('Anzisha simu'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openGroupEvents() {
    if (_conversation == null || !_conversation!.isGroup) return;
    // Prefer group_id from backend (profile group); fallback to conversation id (backend can resolve).
    final groupId = _conversation!.groupId ?? widget.conversationId;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GroupEventsScreen(
          groupId: groupId,
          currentUserId: widget.currentUserId,
          groupName: _conversation!.title,
        ),
      ),
    );
  }

  void _openCreateEvent() {
    // Prefer group_id when in group chat (MESSAGES_BACKEND_IMPLEMENTATION_DIRECTIVE: events.group_id = groups.id).
    final groupId = _conversation?.isGroup == true
        ? (_conversation!.groupId ?? widget.conversationId)
        : null;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CreateEventScreen(
          creatorId: widget.currentUserId,
          groupId: groupId,
        ),
      ),
    );
  }

  void _blockUser() {
    final otherUserId = _otherParticipantUserId;
    if (otherUserId == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zulia mtumiaji?'),
        content: const Text('Hatuonyeshi tena mazungumzo na ripoti za mtumiaji huyu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await FriendService().blockUser(widget.currentUserId, otherUserId);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mtumiaji amezuliwa')));
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imeshindwa kuzuia mtumiaji')));
              }
            },
            child: const Text('Zulia'),
          ),
        ],
      ),
    );
  }

  void _reportChat() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ripoti mazungumzo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Utatuma ripoti kwa wasimamizi. Unaweza pia kuzuia mtumiaji baada ya ripoti.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Sababu ya ripoti',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          FilledButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final success = await _messageService.reportConversation(
                widget.conversationId,
                widget.currentUserId,
                reason,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Ripoti imetumwa' : 'Imeshindwa kutuma ripoti')),
              );
            },
            child: const Text('Tuma ripoti'),
          ),
        ],
      ),
    );
  }

  /// Toggle mute/unmute conversation via the API.
  Future<void> _toggleMuteConversation() async {
    final isMuted = _conversation?.participants
        .any((p) => p.userId == widget.currentUserId && p.isMuted) ?? false;
    // If currently muted, pass null to unmute; otherwise mute for 1 year.
    final mutedUntil = isMuted
        ? null
        : DateTime.now().add(const Duration(days: 365)).toIso8601String();
    final success = await MessageService.updateConversationSettings(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      mutedUntil: mutedUntil,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isMuted ? 'Mazungumzo yamewashwa' : 'Mazungumzo yamenyamazishwa')),
      );
      // Refresh conversation to pick up new mute state
      _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kubadilisha hali ya unyamavu')),
      );
    }
  }

  /// Message reminder: show bottom sheet with preset times, then schedule via
  /// [MessageReminderService] which uses zonedSchedule for reliable delivery.
  Future<void> _scheduleReminder(Message message) async {
    final senderName = message.sender?.fullName ?? 'User';
    final preview = message.content ?? message.preview;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weka kikumbusho',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined, color: Color(0xFF1A1A1A)),
                title: const Text('Dakika 15'),
                onTap: () {
                  Navigator.pop(ctx);
                  _doScheduleReminder(message, senderName, preview, DateTime.now().add(const Duration(minutes: 15)));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined, color: Color(0xFF1A1A1A)),
                title: const Text('Saa 1'),
                onTap: () {
                  Navigator.pop(ctx);
                  _doScheduleReminder(message, senderName, preview, DateTime.now().add(const Duration(hours: 1)));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined, color: Color(0xFF1A1A1A)),
                title: const Text('Saa 3'),
                onTap: () {
                  Navigator.pop(ctx);
                  _doScheduleReminder(message, senderName, preview, DateTime.now().add(const Duration(hours: 3)));
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined, color: Color(0xFF1A1A1A)),
                title: const Text('Kesho asubuhi'),
                onTap: () {
                  Navigator.pop(ctx);
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  final morning = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
                  _doScheduleReminder(message, senderName, preview, morning);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doScheduleReminder(Message message, String senderName, String preview, DateTime remindAt) async {
    try {
      await MessageReminderService.scheduleReminder(
        messageId: message.id,
        conversationId: widget.conversationId,
        messagePreview: preview,
        senderName: senderName,
        remindAt: remindAt,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kikumbusho kimewekwa')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa kuweka kikumbusho: \$e')),
        );
      }
    }
  }

  /// Add or toggle reaction (MESSAGES.md: message reactions).
  Future<void> _addReaction(Message message, String emoji) async {
    final existingList = message.reactions.where((r) => r.emoji == emoji).toList();
    final existing = existingList.isEmpty ? null : existingList.first;
    final hasMe = existing?.userIds.contains(widget.currentUserId) ?? false;
    final result = hasMe
        ? await _messageService.removeReaction(
            conversationId: widget.conversationId,
            messageId: message.id,
            userId: widget.currentUserId,
            emoji: emoji,
          )
        : await _messageService.addReaction(
            conversationId: widget.conversationId,
            messageId: message.id,
            userId: widget.currentUserId,
            emoji: emoji,
          );
    if (!mounted) return;
    if (result.success && result.message != null) {
      setState(() {
        final i = _messages.indexWhere((m) => m.id == message.id);
        if (i >= 0) _messages[i] = result.message!;
      });
      _cacheMessage(result.message!);
    } else {
      // Optimistic: toggle locally so UI updates even if API not implemented
      setState(() {
        final i = _messages.indexWhere((m) => m.id == message.id);
        if (i >= 0) {
          final m = _messages[i];
          List<MessageReaction> next = List.from(m.reactions);
          final idx = next.indexWhere((r) => r.emoji == emoji);
          if (hasMe && idx >= 0) {
            next[idx] = next[idx].copyWith(
              userIds: next[idx].userIds.where((id) => id != widget.currentUserId).toList(),
            );
            if (next[idx].userIds.isEmpty) next.removeAt(idx);
          } else if (!hasMe) {
            if (idx >= 0) {
              next[idx] = next[idx].copyWith(
                userIds: [...next[idx].userIds, widget.currentUserId],
              );
            } else {
              next.add(MessageReaction(emoji: emoji, userIds: [widget.currentUserId]));
            }
          }
          _messages[i] = m.copyWith(reactions: next);
          // Cache optimistic reaction to SQLite
          _cacheMessage(_messages[i]);
        }
      });
    }
  }

  /// Other participants currently typing (excludes current user).
  List<TypingUser> get _otherUsersTyping =>
      _typingUsers.where((u) => u.id != widget.currentUserId).toList();

  /// Count of online participants from real presence data.
  int get _onlineCount {
    if (_conversation == null || !_conversation!.isGroup) return 0;
    return _presences.values.where((p) => p.isOnline).length;
  }

  /// For 1:1 chats, subtitle showing online status or last seen.
  String? get _partnerPresenceLabel {
    if (_conversation == null || _conversation!.isGroup) return null;
    final other = _conversation!.participants
        .where((p) => p.userId != widget.currentUserId)
        .firstOrNull;
    if (other == null) return null;
    final info = _presences[other.userId];
    if (info == null) return null;
    return info.lastSeenLabel;
  }

  String get _chatTitle {
    if (_conversation == null) return 'Mazungumzo';
    if (_conversation!.isGroup) return _conversation!.name ?? 'Kikundi';

    final otherUser = _conversation!.participants.firstWhere(
      (p) => p.userId != widget.currentUserId,
      orElse: () => _conversation!.participants.first,
    );
    return otherUser.user?.fullName ?? 'Mtumiaji';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimaryText,
        elevation: 0,
        title: Row(
          children: [
            if (_conversation != null) ...[
              UserAvatar(
                photoUrl: _getAvatarUrl(),
                name: _chatTitle,
                radius: 18,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(_chatTitle, style: const TextStyle(fontSize: 16, color: _kPrimaryText), overflow: TextOverflow.ellipsis)),
                      if (_conversation?.isGroup == true && _conversation!.participants.any((p) => p.isAdmin))
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Tooltip(
                            message: 'Admin',
                            child: Icon(Icons.admin_panel_settings_rounded, size: 14, color: _kSecondaryText),
                          ),
                        ),
                    ],
                  ),
                  if (_conversation?.isGroup == true)
                    Text(
                      '${_conversation!.participants.length} wanachama${_onlineCount > 0 ? ' • $_onlineCount online' : ''}'
                      '${_conversation!.hasDisappearingMessages ? ' • ${_conversation!.disappearingLabel}' : ''}',
                      style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                    )
                  else if (_partnerPresenceLabel != null && _partnerPresenceLabel!.isNotEmpty)
                    Text(
                      '$_partnerPresenceLabel'
                      '${_conversation?.hasDisappearingMessages == true ? ' • ${_conversation!.disappearingLabel}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _partnerPresenceLabel == 'Online'
                            ? const Color(0xFF4CAF50)
                            : _kSecondaryText,
                      ),
                    )
                  else if (_conversation?.hasDisappearingMessages == true)
                    Text(
                      _conversation!.disappearingLabel,
                      style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_conversation?.hasDisappearingMessages == true)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.timer, size: 18, color: _kSecondaryText),
            ),
          IconButton(
            icon: const Icon(Icons.phone, color: _kPrimaryText),
            onPressed: _otherParticipantUserId != null ? () => _initiateCall('voice') : null,
            style: IconButton.styleFrom(minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget)),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: _kPrimaryText),
            onPressed: _conversation?.isGroup == true
                ? _openGroupCall
                : (_otherParticipantUserId != null ? () => _initiateCall('video') : null),
            style: IconButton.styleFrom(minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _kPrimaryText),
            onSelected: (value) {
              if (value == 'info') _openChatInfo();
              else if (value == 'group_events') _openGroupEvents();
              else if (value == 'event') _openCreateEvent();
              else if (value == 'group_call') _startGroupCall();
              else if (value == 'invite_link') {
                showInviteLinkSheet(context, widget.conversationId);
              }
              else if (value == 'disappearing') _showDisappearingMessagesSheet();
              else if (value == 'custom_notifications') _showCustomNotificationsSheet();
              else if (value == 'search') {
                setState(() => _showChatSearch = true);
              }
              else if (value == 'mute') {
                _toggleMuteConversation();
              }
              else if (value == 'block') _blockUser();
              else if (value == 'report') _reportChat();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('Maelezo')),
              if (_conversation?.isGroup == true) ...[
                const PopupMenuItem(value: 'group_events', child: Text('Matukio ya kikundi')),
                const PopupMenuItem(value: 'event', child: Text('Tengeneza tukio')),
                const PopupMenuItem(value: 'group_call', child: Text('Simu ya kikundi')),
                const PopupMenuItem(value: 'invite_link', child: Text('Kiungo cha mwaliko')),
              ],
              PopupMenuItem(
                value: 'disappearing',
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 20, color: _kSecondaryText),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _conversation?.hasDisappearingMessages == true
                            ? 'Ujumbe unaopotea (${_conversation!.disappearingLabel})'
                            : 'Ujumbe unaopotea',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(value: 'custom_notifications', child: Text('Arifa maalum')),
              const PopupMenuItem(value: 'search', child: Text('Tafuta')),
              PopupMenuItem(
                value: 'mute',
                child: Text(
                  _conversation?.participants.any((p) => p.userId == widget.currentUserId && p.isMuted) == true
                      ? 'Washa sauti'
                      : 'Nyamazisha',
                ),
              ),
              const PopupMenuItem(value: 'block', child: Text('Zulia')),
              const PopupMenuItem(value: 'report', child: Text('Ripoti')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildChatSearchBar(),
            Expanded(child: _buildMessageList()),
            if (_otherUsersTyping.isNotEmpty) _buildTypingIndicator(_otherUsersTyping),
            if (_replyingTo != null) _buildReplyPreview(),
            if (_uploadProgress != null) _buildUploadProgressBar(),
            if (_showMentionOverlay) _buildMentionOverlay(),
            _buildLinkPreviewCard(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(List<TypingUser> users) {
    String typingText;
    if (users.length == 1) {
      typingText = '${users.first.firstName} anaandika...';
    } else if (users.length == 2) {
      typingText = '${users[0].firstName} na ${users[1].firstName} wanaandika...';
    } else {
      typingText = '${users.length} wanaandika...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: List.generate(3, (i) => _TypingDot(delay: i * 200)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            typingText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String? _getAvatarUrl() {
    if (_conversation == null) return null;
    if (_conversation!.isGroup) return _conversation!.avatarUrl;

    final otherUser = _conversation!.participants.firstWhere(
      (p) => p.userId != widget.currentUserId,
      orElse: () => _conversation!.participants.first,
    );
    return otherUser.user?.profilePhotoUrl;
  }

  Widget _buildMessageList() {
    // Only show full-screen spinner when loading AND no cached messages
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return const Center(child: Text('Anza mazungumzo'));
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      cacheExtent: 800,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        // reverse: true flips the render order — index 0 is at the bottom.
        // _messages is chronological (oldest first), so we read from the end.
        final reversedIndex = _messages.length - 1 - index;
        final message = _messages[reversedIndex];
        final isMe = message.senderId == widget.currentUserId;
        final showAvatar = !isMe &&
            (reversedIndex == 0 || _messages[reversedIndex - 1].senderId != message.senderId);

        return _MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          currentUserId: widget.currentUserId,
          conversationId: widget.conversationId,
          isGroup: _conversation?.isGroup == true,
          onReply: () => _setReplyTo(message),
          onEdit: isMe && message.messageType == MessageType.text
              ? () => _editMessage(message)
              : null,
          onDelete: isMe ? () => _deleteMessage(message) : null,
          onForward: () => _forwardMessage(message),
          onReact: (emoji) => _addReaction(message, emoji),
          onRemindMe: () => _scheduleReminder(message),
          onStar: () => _toggleStar(message),
          isTranscriptExpanded: _expandedTranscripts.contains(message.id),
          onToggleTranscript: message.transcript != null && message.transcript!.isNotEmpty
              ? () {
                  setState(() {
                    if (_expandedTranscripts.contains(message.id)) {
                      _expandedTranscripts.remove(message.id);
                    } else {
                      _expandedTranscripts.add(message.id);
                    }
                  });
                }
              : null,
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();
    final isMyMessage = _replyingTo!.senderId == widget.currentUserId;
    final barColor = isMyMessage ? const Color(0xFF2196F3) : const Color(0xFF25D366);
    final senderName = isMyMessage ? 'You' : (_replyingTo!.sender?.firstName ?? 'User');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(senderName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: barColor)),
              const SizedBox(height: 2),
              Text(
                _replyingTo!.content ?? _replyingTo!.preview,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF999999)),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _formatRecordingDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildUploadProgressBar() {
    final progress = _uploadProgress ?? 0.0;
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: progress > 0 && progress < 1 ? progress : null,
        backgroundColor: _kReceiverBubble,
        valueColor: const AlwaysStoppedAnimation<Color>(_kSenderBubble),
      ),
    );
  }

  Widget _buildInputBar() {
    if (_isRecordingVoice) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _kSecondaryText.withValues(alpha: 0.15),
              offset: const Offset(0, -1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.mic_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(
              _formatRecordingDuration(_recordingDurationSec),
              style: const TextStyle(
                fontSize: 14,
                color: _kPrimaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 30,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  itemCount: _waveformBars.length,
                  itemBuilder: (context, index) {
                    final barIndex = _waveformBars.length - 1 - index;
                    final value = _waveformBars[barIndex];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 2,
                        height: (value * 26).clamp(4.0, 30.0),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            TextButton(
              onPressed: () => _stopVoiceRecording(cancel: true),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: _kSenderBubble),
              onPressed: () => _stopVoiceRecording(cancel: false),
              style: IconButton.styleFrom(
                minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _kSecondaryText.withValues(alpha: 0.15),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: _kPrimaryText),
            onPressed: _showAttachmentOptions,
            style: IconButton.styleFrom(minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget)),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Andika ujumbe...',
                hintStyle: const TextStyle(color: _kSecondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _kReceiverBubble,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: _kPrimaryText),
            onPressed: _startVoiceRecording,
            style: IconButton.styleFrom(minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget)),
          ),
          const SizedBox(width: 4),
          _isSending
              ? const SizedBox(
                  width: _kMinTouchTarget,
                  height: _kMinTouchTarget,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded, color: _kSenderBubble),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget)),
                ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_rounded, color: _kPrimaryText),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _sendImage();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _kPrimaryText),
              title: const Text('Take photo'),
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                final image = await _picker.pickImage(source: ImageSource.camera);
                if (image == null || !mounted) return;
                File fileToSend = File(image.path);
                if (!await fileToSend.exists()) {
                  messenger.showSnackBar(const SnackBar(content: Text('Photo not found.')));
                  return;
                }
                final compressed = await _compressImage(fileToSend);
                if (compressed != null) fileToSend = compressed;
                await _sendImageFile(fileToSend);
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: _kPrimaryText),
              title: const Text('Video from gallery'),
              onTap: () {
                Navigator.pop(context);
                _sendVideo();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: _kPrimaryText),
              title: const Text('Record video'),
              subtitle: const Text('Short video message'),
              onTap: () {
                Navigator.pop(context);
                _recordVideoMessage();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.mic_rounded, color: _kPrimaryText),
              title: const Text('Record voice note'),
              subtitle: const Text('Hold to record in chat'),
              onTap: () {
                Navigator.pop(context);
                _startVoiceRecording();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.audio_file_rounded, color: _kPrimaryText),
              title: const Text('Audio file'),
              onTap: () {
                Navigator.pop(context);
                _sendVoice();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_rounded, color: _kPrimaryText),
              title: const Text('Document'),
              subtitle: const Text('PDF, DOCX, etc.'),
              onTap: () {
                Navigator.pop(context);
                _sendDocument();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_rounded, color: _kPrimaryText),
              title: const Text('Scan document'),
              onTap: () {
                Navigator.pop(context);
                _scanDocument();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: _kPrimaryText),
              title: const Text('Contact'),
              onTap: () {
                Navigator.pop(context);
                _shareContact();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.location_on_rounded, color: _kPrimaryText),
              title: const Text('Location'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_rounded, color: _kPrimaryText),
              title: const Text('Sticker'),
              onTap: () {
                Navigator.pop(context);
                _showStickerPicker();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.gif_rounded, color: _kPrimaryText),
              title: const Text('GIF'),
              onTap: () {
                Navigator.pop(context);
                _showGifPicker();
              },
              minVerticalPadding: 12,
            ),
            ListTile(
              leading: const Icon(Icons.poll_rounded, color: _kPrimaryText),
              title: const Text('Poll'),
              onTap: () {
                Navigator.pop(context);
                _createAndSendPoll();
              },
              minVerticalPadding: 12,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAndSendPoll() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CreatePollScreen(
          creatorId: widget.currentUserId,
        ),
      ),
    );
    if (result != true || !mounted) return;
    // Poll was created successfully — send a poll message to the conversation
    final res = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      content: 'Poll created',
      messageType: 'poll',
    );
    if (!mounted) return;
    if (res.success && res.message != null) {
      setState(() {
        _messages.add(res.message!);
        _cacheMessage(res.message!);
      });
    }
    _scrollToBottom();
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: StickerBrowser(
          height: 320,
          onStickerTap: (sticker) {
            Navigator.pop(sheetContext);
            _sendSticker(sticker);
          },
        ),
      ),
    );
  }

  void _showGifPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _GifPickerContent(
          scrollController: scrollController,
          onGifSelected: (url) {
            Navigator.pop(context);
            _sendGif(url);
          },
        ),
      ),
    );
  }
}

/// GIF picker with Giphy search (trending + search).
class _GifPickerContent extends StatefulWidget {
  final ScrollController scrollController;
  final void Function(String gifUrl) onGifSelected;

  const _GifPickerContent({required this.scrollController, required this.onGifSelected});

  @override
  State<_GifPickerContent> createState() => _GifPickerContentState();
}

class _GifPickerContentState extends State<_GifPickerContent> {
  static const _apiKey = 'dc6zaTOxFJmzC'; // Giphy public beta key
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<String> _gifUrls = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse('https://api.giphy.com/v1/gifs/trending?api_key=$_apiKey&limit=30&rating=g');
      final response = await http.get(uri);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final urls = <String>[];
        for (final item in (data['data'] as List)) {
          final url = item['images']?['fixed_width']?['url'] as String?;
          if (url != null) urls.add(url);
        }
        setState(() { _gifUrls = urls; _loading = false; });
      } else {
        setState(() { _error = 'Imeshindwa kupakia GIF'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Hakuna mtandao'; _loading = false; });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) { _loadTrending(); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final uri = Uri.parse('https://api.giphy.com/v1/gifs/search?api_key=$_apiKey&q=${Uri.encodeComponent(query)}&limit=30&rating=g');
      final response = await http.get(uri);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final urls = <String>[];
        for (final item in (data['data'] as List)) {
          final url = item['images']?['fixed_width']?['url'] as String?;
          if (url != null) urls.add(url);
        }
        setState(() { _gifUrls = urls; _loading = false; });
      } else {
        setState(() { _error = 'Tafuta imeshindwa'; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Hakuna mtandao'; _loading = false; });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tafuta GIF...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: Colors.grey.shade600)))
                    : _gifUrls.isEmpty
                        ? Center(child: Text('Hakuna GIF', style: TextStyle(color: Colors.grey.shade600)))
                        : GridView.builder(
                            controller: widget.scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemCount: _gifUrls.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () => widget.onGifSelected(_gifUrls[index]),
                                borderRadius: BorderRadius.circular(8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _gifUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final int currentUserId;
  final int conversationId;
  final bool isGroup;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onForward;
  final void Function(String emoji)? onReact;
  final VoidCallback? onRemindMe;
  final VoidCallback? onStar;
  final bool isTranscriptExpanded;
  final VoidCallback? onToggleTranscript;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.currentUserId,
    required this.conversationId,
    required this.isGroup,
    required this.onReply,
    this.onEdit,
    this.onDelete,
    required this.onForward,
    this.onReact,
    this.onRemindMe,
    this.onStar,
    this.isTranscriptExpanded = false,
    this.onToggleTranscript,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UserAvatar(
                photoUrl: message.sender?.profilePhotoUrl,
                name: message.sender?.fullName,
                radius: 16,
              ),
            )
          else if (!isMe)
            const SizedBox(width: 40),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? _kSenderBubble : _kReceiverBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Forwarded label
                    if (message.isForwarded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shortcut, size: 13, color: isMe ? Colors.white70 : const Color(0xFF999999)),
                            const SizedBox(width: 4),
                            Text('Forwarded', style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : const Color(0xFF999999), fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    if (message.replyTo != null) _buildReplyPreview(context),
                    if (message.messageType == MessageType.sharedPost)
                      _buildSharedPostContent(context)
                    else if (message.messageType == MessageType.poll)
                      _buildPollContent(context)
                    else if (message.messageType == MessageType.livePhoto && message.mediaUrl != null)
                      LivePhotoViewer(
                        imageUrl: message.mediaUrl!,
                        videoUrl: message.content,
                        width: 200,
                        height: 150,
                      )
                    else if (message.messageType == MessageType.image && message.mediaUrl != null)
                      _buildImage(message.mediaUrl!)
                    else if (message.messageType == MessageType.video && message.mediaUrl != null)
                      _buildVideoThumbnail(context, message.mediaUrl!)
                    else if (message.messageType == MessageType.audio && message.mediaUrl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAudioPlayer(message.mediaUrl!),
                          if (message.transcript != null && message.transcript!.isNotEmpty)
                            _buildTranscriptSection(),
                        ],
                      )
                    else if (message.messageType == MessageType.document)
                      _buildDocumentContent()
                    else if (message.messageType == MessageType.location)
                      _buildLocationContent()
                    else if (message.messageType == MessageType.contact)
                      _buildContactContent()
                    else if (_isGifUrl(message.content))
                      _buildGifContent(context, message.content!)
                    else
                      Text(
                        message.content ?? message.preview,
                        style: TextStyle(
                          color: isMe ? Colors.white : _kPrimaryText,
                          fontSize: 14,
                        ),
                      ),
                    if (message.hasLinkPreview) ...[
                      const SizedBox(height: 6),
                      _buildMessageLinkPreview(context),
                    ],
                    if (message.reactions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: message.reactions.map((r) {
                          final count = r.userIds.length;
                          return GestureDetector(
                            onTap: () => _showWhoReactedSheet(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isMe ? Colors.white24 : _kSecondaryText.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${r.emoji}${count > 1 ? count.toString() : ''}', style: const TextStyle(fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edited label
                        if (message.editedAt != null)
                          Text('Edited ', style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : const Color(0xFF999999), fontStyle: FontStyle.italic)),
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : _kSecondaryText,
                          ),
                        ),
                        // Disappearing message indicator
                        if (message.expiresAt != null) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.timer_outlined, size: 12, color: isMe ? Colors.white70 : const Color(0xFF999999)),
                        ],
                        // Star indicator
                        if (message.isStarred) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 12, color: isMe ? Colors.white70 : const Color(0xFF999999)),
                        ],
                        // Message status icons
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.pending:
        return const Icon(Icons.access_time, size: 14, color: Colors.white70);
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF2196F3));
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Colors.red);
    }
  }

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white24 : _kSecondaryText.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.replyTo?.content ?? message.replyTo?.preview ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: isMe ? Colors.white70 : _kPrimaryText,
        ),
      ),
    );
  }

  Widget _buildSharedPostContent(BuildContext context) {
    try {
      final data = jsonDecode(message.content ?? '{}') as Map<String, dynamic>;
      final postId = data['post_id'];
      final userName = data['user_name'] ?? '';
      final userPhoto = data['user_photo'];
      final content = data['content'] ?? '';
      final mediaList = data['media'] as List? ?? [];
      final coverImageUrl = data['cover_image_url'];
      final likesCount = data['likes_count'] ?? 0;
      final commentsCount = data['comments_count'] ?? 0;

      // Resolve the first media image URL for preview
      String? previewImageUrl;
      if (mediaList.isNotEmpty) {
        final first = mediaList.first as Map<String, dynamic>;
        final type = first['media_type'] ?? 'image';
        if (type == 'video') {
          previewImageUrl = first['thumbnail_url'];
        } else {
          previewImageUrl = first['file_url'];
        }
      }
      previewImageUrl ??= coverImageUrl;

      return GestureDetector(
        onTap: () {
          if (postId != null) {
            Navigator.pushNamed(context, '/post/$postId');
          }
        },
        child: Container(
          width: 240,
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media preview
              if (previewImageUrl != null)
                Stack(
                  children: [
                    CachedMediaImage(
                      imageUrl: previewImageUrl.startsWith('http')
                          ? previewImageUrl
                          : '${ApiConfig.storageUrl}/$previewImageUrl',
                      width: 240,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                    // Video play icon overlay
                    if (mediaList.isNotEmpty &&
                        (mediaList.first as Map<String, dynamic>)['media_type'] == 'video')
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    // Multi-media indicator
                    if (mediaList.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '1/${mediaList.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              // Post info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row
                    Row(
                      children: [
                        if (userPhoto != null)
                          ClipOval(
                            child: CachedMediaImage(
                              imageUrl: userPhoto.startsWith('http')
                                  ? userPhoto
                                  : '${ApiConfig.storageUrl}/$userPhoto',
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const Icon(Icons.account_circle, size: 20, color: Color(0xFF999999)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: TextStyle(
                          fontSize: 13,
                          color: isMe ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF333333),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Engagement row
                    Row(
                      children: [
                        Icon(Icons.favorite_border, size: 14,
                            color: isMe ? Colors.white70 : const Color(0xFF999999)),
                        const SizedBox(width: 2),
                        Text('$likesCount',
                            style: TextStyle(fontSize: 11,
                                color: isMe ? Colors.white70 : const Color(0xFF999999))),
                        const SizedBox(width: 10),
                        Icon(Icons.chat_bubble_outline, size: 14,
                            color: isMe ? Colors.white70 : const Color(0xFF999999)),
                        const SizedBox(width: 2),
                        Text('$commentsCount',
                            style: TextStyle(fontSize: 11,
                                color: isMe ? Colors.white70 : const Color(0xFF999999))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      // Fallback: render content as plain text
      return Text(
        message.content ?? message.preview,
        style: TextStyle(
          color: isMe ? Colors.white : _kPrimaryText,
          fontSize: 14,
        ),
      );
    }
  }

  Widget _buildImage(String imageUrl) {
    final url = imageUrl.startsWith('http') ? imageUrl : '${ApiConfig.storageUrl}/$imageUrl';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedMediaImage(
        imageUrl: url,
        width: 200,
        height: 150,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildVideoThumbnail(BuildContext context, String videoUrl) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: VideoPlayerWidget(
                videoUrl: videoUrl,
                showControls: true,
                showBufferIndicator: true,
              ),
            ),
          ),
        ));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: _kReceiverBubble,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.videocam, size: 48, color: _kSecondaryText),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(String audioUrl) {
    return _VoiceMessagePlayer(audioUrl: audioUrl, isMe: isMe);
  }

  Widget _buildDocumentContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file_rounded, size: 20, color: isMe ? Colors.white70 : _kSecondaryText),
        const SizedBox(width: 8),
        Text(message.content ?? 'Document', style: TextStyle(fontSize: 14, color: isMe ? Colors.white : _kPrimaryText)),
      ],
    );
  }

  Widget _buildLocationContent() {
    try {
      final map = jsonDecode(message.content ?? '{}') as Map<String, dynamic>;
      final lat = map['lat']?.toString() ?? '';
      final lng = map['lng']?.toString() ?? '';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 20, color: isMe ? Colors.white70 : _kSecondaryText),
          const SizedBox(width: 8),
          Text('$lat, $lng', style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : _kSecondaryText)),
        ],
      );
    } catch (_) {
      return Text('Location', style: TextStyle(fontSize: 14, color: isMe ? Colors.white : _kPrimaryText));
    }
  }

  Widget _buildContactContent() {
    try {
      final map = jsonDecode(message.content ?? '{}') as Map<String, dynamic>;
      final name = map['name']?.toString() ?? 'Contact';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_rounded, size: 20, color: isMe ? Colors.white70 : _kSecondaryText),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : _kPrimaryText)),
        ],
      );
    } catch (_) {
      return Text('Contact', style: TextStyle(fontSize: 14, color: isMe ? Colors.white : _kPrimaryText));
    }
  }

  Widget _buildMessageLinkPreview(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final url = message.linkPreviewUrl;
        if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.linkPreviewImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  message.linkPreviewImage!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (message.linkPreviewTitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  message.linkPreviewTitle!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isMe ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (message.linkPreviewDescription != null)
              Text(
                message.linkPreviewDescription!,
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : const Color(0xFF666666),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (message.linkPreviewDomain != null)
              Text(
                message.linkPreviewDomain!,
                style: TextStyle(
                  fontSize: 11,
                  color: isMe ? Colors.white54 : const Color(0xFF999999),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Feature 1: GIF URL detection
  static final RegExp _gifUrlRegex = RegExp(
    r'^https?://\S+\.(gif)(\?\S*)?$',
    caseSensitive: false,
  );

  bool _isGifUrl(String? content) {
    if (content == null || content.isEmpty) return false;
    final trimmed = content.trim();
    if (_gifUrlRegex.hasMatch(trimmed)) return true;
    if (trimmed.contains('giphy.com') || trimmed.contains('tenor.com')) {
      return RegExp(r'^https?://\S+$').hasMatch(trimmed);
    }
    return false;
  }

  Widget _buildGifContent(BuildContext context, String url) {
    final trimmed = url.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(trimmed), mode: LaunchMode.externalApplication),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                trimmed,
                gaplessPlayback: true,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  trimmed,
                  style: TextStyle(
                    color: isMe ? Colors.white : _kPrimaryText,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          trimmed,
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white54 : const Color(0xFF999999),
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Feature 3: Inline poll card — uses PollVoteWidget for interactive voting
  Widget _buildPollContent(BuildContext context) {
    final pollId = message.pollId;

    // If we have a pollId, render the full interactive poll widget
    if (pollId != null) {
      return SizedBox(
        width: 260,
        child: PollVoteWidget(
          pollId: pollId,
          currentUserId: currentUserId,
        ),
      );
    }

    // Fallback: static poll card when pollId is missing
    final question = message.content ?? 'Poll';
    return Container(
      width: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll_rounded, size: 18, color: isMe ? Colors.white70 : const Color(0xFF999999)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Poll',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.white70 : const Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isMe ? Colors.white : _kPrimaryText,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Poll details unavailable',
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white54 : const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // Feature 4: Collapsible voice transcript
  Widget _buildTranscriptSection() {
    return GestureDetector(
      onTap: onToggleTranscript,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.subtitles, size: 12, color: isMe ? Colors.white54 : const Color(0xFF999999)),
                const SizedBox(width: 4),
                Text(
                  isTranscriptExpanded ? 'Hide transcript' : 'Show transcript',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white54 : const Color(0xFF999999),
                  ),
                ),
              ],
            ),
            if (isTranscriptExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  message.transcript!,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isMe ? Colors.white.withValues(alpha: 0.85) : _kPrimaryText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final copyText = message.content ?? message.preview;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReact != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ..._kReactionEmojis.map((emoji) => InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onReact!(emoji);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    )),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _showFullEmojiPicker(context, onReact!);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        child: const Icon(Icons.add, size: 20, color: _kPrimaryText),
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                if (copyText.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: copyText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward_rounded),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                onForward();
              },
            ),
            if (onStar != null)
              ListTile(
                leading: Icon(message.isStarred ? Icons.star : Icons.star_border),
                title: Text(message.isStarred ? 'Unstar' : 'Star'),
                onTap: () {
                  Navigator.pop(context);
                  onStar!();
                },
              ),
            if (isMe && isGroup)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Info'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MessageInfoScreen(
                      conversationId: conversationId,
                      messageId: message.id,
                      currentUserId: currentUserId,
                      message: message,
                    ),
                  ));
                },
              ),
            if (onRemindMe != null)
              ListTile(
                leading: const Icon(Icons.notifications_none_rounded),
                title: const Text('Remind me'),
                onTap: () {
                  Navigator.pop(context);
                  onRemindMe!();
                },
              ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Shows a bottom sheet listing who reacted with each emoji.
  void _showWhoReactedSheet(BuildContext context) {
    if (message.reactions.isEmpty) return;

    // Build a lookup of userId -> sender info from the message itself.
    // In a group chat the sender field may vary per message, so we use
    // what we have available.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Waliojibu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimaryText),
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: message.reactions.length,
                itemBuilder: (ctx, index) {
                  final reaction = message.reactions[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            Text(reaction.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text(
                              '${reaction.userIds.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...reaction.userIds.map((userId) {
                        final isCurrentUser = userId == currentUserId;
                        final label = isCurrentUser ? 'Wewe' : 'Mtumiaji #$userId';
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              label.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText),
                            ),
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              color: _kPrimaryText,
                              fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isCurrentUser && onReact != null
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onReact!(reaction.emoji);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Ondoa',
                                      style: TextStyle(fontSize: 12, color: _kSecondaryText, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                )
                              : null,
                        );
                      }),
                      if (index < message.reactions.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullEmojiPicker(BuildContext context, void Function(String emoji) onReact) {
    const smileys = [
      '😀','😃','😄','😁','😆','😅','🤣','😂','🙂','🙃','😉','😊','😇','🥰','😍','🤩',
      '😘','😗','😚','😋','😛','😜','🤪','😝','🤑','🤗','🤭','🤫','🤔','🤐','🤨','😐',
      '😑','😶','😏','😒','🙄','😬','🤥','😌','😔','😪','🤤','😴','😷','🤒','🤕','🤢',
      '🤮','🤧','🥵','🥶','🥴','😵','🤯','🤠','🥳','🥸','😎','🤓','🧐','😕','😟','🙁',
      '😮','😯','😲','😳','🥺','😦','😧','😨','😰','😥','😢','😭','😱','😖','😣','😞',
      '😓','😩','😫','🥱','😤','😡','😠','🤬',
    ];
    const gestures = [
      '👍','👎','👊','✊','🤛','🤜','👏','🙌','👐','🤲','🤝','🙏','💪','🦾','🖕','✌️',
      '🤞','🤟','🤘','🤙','👈','👉','👆','👇','☝️','✋','🤚','🖐','🖖','👋','🤏','✍️','🤳',
    ];
    const hearts = [
      '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝',
    ];
    const objects = [
      '🔥','⭐','💯','✅','❌','🎉','🎊','🎯','💡','🔔','🏆','🎵','🎶',
    ];

    final categories = <String, List<String>>{
      'Smileys': smileys,
      'Gestures': gestures,
      'Hearts': hearts,
      'Objects': objects,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (ctx, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Choose Reaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimaryText)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: categories.length,
                itemBuilder: (ctx, catIndex) {
                  final catName = categories.keys.elementAt(catIndex);
                  final emojis = categories[catName]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(catName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondaryText)),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: emojis.length,
                        itemBuilder: (ctx, i) => InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.pop(ctx);
                            onReact(emojis[i]);
                          },
                          child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 24))),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Lazy-loaded voice message playback (Story 39).
class _VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const _VoiceMessagePlayer({required this.audioUrl, required this.isMe});

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  double _playbackSpeed = 1.0;

  static const List<double> _speedOptions = [1.0, 1.5, 2.0];

  String get _url {
    return widget.audioUrl.startsWith('http')
        ? widget.audioUrl
        : '${ApiConfig.storageUrl}/${widget.audioUrl}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      final cached = await MediaCacheService().getCachedMediaPath(_url);
      if (cached != null) {
        await _player.play(DeviceFileSource(cached));
      } else {
        await _player.play(UrlSource(_url));
      }
      await _player.setPlaybackRate(_playbackSpeed);
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  void _cycleSpeed() {
    final currentIndex = _speedOptions.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % _speedOptions.length;
    setState(() => _playbackSpeed = _speedOptions[nextIndex]);
    _player.setPlaybackRate(_playbackSpeed);
  }

  String get _speedLabel {
    if (_playbackSpeed == 1.0) return '1x';
    if (_playbackSpeed == 1.5) return '1.5x';
    return '2x';
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isMe ? Colors.white : _kPrimaryText;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(minWidth: 120, minHeight: _kMinTouchTarget),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _togglePlay,
              borderRadius: BorderRadius.circular(16),
              child: Icon(
                _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: textColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _playing ? 'Simama' : 'Sikiliza',
              style: TextStyle(fontSize: 13, color: textColor),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _cycleSpeed,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: widget.isMe ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                ),
                child: Text(
                  _speedLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF999999).withValues(alpha: 0.4 + (_animation.value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
