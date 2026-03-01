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
import '../../services/call_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/call_signaling_service.dart';
import '../../services/friend_service.dart';
import '../../services/live_update_service.dart';
import '../../services/message_cache_service.dart';
import '../../services/pending_message_store.dart';
import '../../models/friend_models.dart';
import '../../widgets/user_avatar.dart';
import '../calls/call_history_screen.dart';
import '../calls/outgoing_call_flow_screen.dart';
import '../../widgets/cached_media_image.dart';
import '../../services/media_cache_service.dart';
import 'group_call_screen.dart';
import 'group_info_screen.dart';
import '../groups/createevent_screen.dart';
import '../groups/group_events_screen.dart';
import '../../config/api_config.dart';

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
  final CallService _callService = CallService();
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

  /// @mention overlay for groups: show when user types @ (MESSAGES.md: @all mentions).
  bool _showMentionOverlay = false;
  String _mentionQuery = '';

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
        _loadMessages();
      }
    });
    _messageController.addListener(_onTypingChanged);
    _messageController.addListener(_onDraftChanged);
    _messageController.addListener(_onMentionCheck);
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
    _draftSaveTimer?.cancel();
    _voiceRecordingTimer?.cancel();
    _recorderSub?.cancel();
    _voiceRecorder?.closeRecorder();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _typingStatusTimer?.cancel();
    _stopTyping();
    super.dispose();
  }

  Future<void> _initVoiceRecorder() async {
    if (Platform.isMacOS) return;
    _voiceRecorder = FlutterSoundRecorder();
    try {
      await _voiceRecorder!.openRecorder();
      _recorderSub = _voiceRecorder!.onProgress?.listen((e) {
        if (mounted) setState(() => _recordingDurationSec = e.duration.inSeconds);
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
        boxShadow: [BoxShadow(color: _kSecondaryText.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: ListView(
        shrinkWrap: true,
        children: list,
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

  /// Load from cache first (instant UI), then sync from API and merge.
  Future<void> _loadFromCacheAndSync() async {
    setState(() => _isLoading = true);
    final cached = await MessageCacheService.instance.getMessages(widget.conversationId);
    if (mounted && cached.isNotEmpty) {
      setState(() {
        _messages = cached.reversed.toList();
        _isLoading = false;
      });
    }
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (_conversation == null) {
      final convResult = await _messageService.getConversation(
        widget.conversationId,
        widget.currentUserId,
      );
      if (convResult.success) {
        _conversation = convResult.conversation;
      }
    }

    final result = await _messageService.getMessages(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
    );

    if (!mounted) return;
    final byId = <int, Message>{};
    for (final m in _messages) byId[m.id] = m;
    if (result.success) {
      for (final m in result.messages) byId[m.id] = m;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await MessageCacheService.instance.saveMessages(widget.conversationId, merged);
    setState(() {
      _isLoading = false;
      _messages = merged.reversed.toList();
    });
    _scrollToBottom();
  }

  void _cacheMessage(Message message) {
    MessageCacheService.instance.appendMessage(widget.conversationId, message);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
  /// Uses new flow (OutgoingCallFlowScreen + CallSignalingService) when authToken exists.
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

    if (authToken != null && authToken.isNotEmpty) {
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
      return;
    }

    final result = await _callService.initiateCall(
      userId: widget.currentUserId,
      calleeId: calleeId,
      type: type,
    );

    if (!mounted) return;
    if (result.success && result.call != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OutgoingCallScreen(
            currentUserId: widget.currentUserId,
            call: result.call!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kupiga simu')),
      );
    }
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

    final result = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      content: content,
      replyToId: _replyingTo?.id,
    );

    PendingMessageStore.instance.clearPending(widget.conversationId);
    setState(() {
      _isSending = false;
      _replyingTo = null;
      if (result.success && result.message != null) {
        _messages.add(result.message!);
        _cacheMessage(result.message!);
      }
    });

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
    File fileToSend = File(image.path);
    if (!await fileToSend.exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image file not found.')));
      return;
    }
    final compressed = await _compressImage(fileToSend);
    if (compressed != null) fileToSend = compressed;
    await _sendImageFile(fileToSend);
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
    if (!res.success && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to send scan')));
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
    if (!res.success && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to send document')));
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
    if (!res.success && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to share contact')));
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
    if (!res.success && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.errorMessage ?? 'Failed to share location')));
    _scrollToBottom();
  }

  /// Send sticker (emoji as content for now; backend can treat as sticker type).
  Future<void> _sendSticker(String stickerId) async {
    PendingMessageStore.instance.setPending(widget.conversationId, preview: 'Sticker', messageType: 'text');
    final res = await _messageService.sendMessage(
      conversationId: widget.conversationId,
      userId: widget.currentUserId,
      content: '[sticker:$stickerId]',
      messageType: 'text',
    );
    PendingMessageStore.instance.clearPending(widget.conversationId);
    if (!mounted) return;
    if (res.success && res.message != null) {
      _messages.add(res.message!);
      _cacheMessage(res.message!);
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
    _scrollToBottom();
  }

  void _setReplyTo(Message message) {
    setState(() => _replyingTo = message);
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maelezo ya mazungumzo')),
      );
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
                                      calleeName: _conversation!.title ?? 'Group call',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zulia mtumiaji?'),
        content: const Text('Hatuonyeshi tena mazungumzo na ripoti za mtumiaji huyu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ghairi')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mtumiaji amezuliwa')));
            },
            child: const Text('Zulia'),
          ),
        ],
      ),
    );
  }

  void _reportChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ripoti mazungumzo'),
        content: const Text('Utatuma ripoti kwa wasimamizi. Unaweza pia kuzuia mtumiaji baada ya ripoti.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ghairi')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ripoti imetumwa')));
            },
            child: const Text('Tuma ripoti'),
          ),
        ],
      ),
    );
  }

  /// Message reminder: pick time and store (MESSAGES.md: reminders). Optional: flutter_local_notifications for actual notification.
  Future<void> _scheduleReminder(Message message) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute),
    );
    if (time == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final at = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, time.hour, time.minute);
    if (at.isBefore(DateTime.now())) return;
    await prefs.setString(
      'chat_reminder_${widget.conversationId}_${message.id}',
      at.toIso8601String(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder set for ${time.format(context)}')),
      );
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
        }
      });
    }
  }

  /// Other participants currently typing (excludes current user).
  List<TypingUser> get _otherUsersTyping =>
      _typingUsers.where((u) => u.id != widget.currentUserId).toList();

  /// Mock "who's online" count until presence API exists (MESSAGES.md: see who's online in groups).
  int get _onlineCount {
    if (_conversation == null || !_conversation!.isGroup) return 0;
    return _conversation!.participants.length > 1 ? 2 : 0;
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
                      '${_conversation!.participants.length} wanachama • ${_onlineCount} online',
                      style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
              else if (value == 'block') _blockUser();
              else if (value == 'report') _reportChat();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('Maelezo')),
              if (_conversation?.isGroup == true) ...[
                const PopupMenuItem(value: 'group_events', child: Text('Matukio ya kikundi')),
                const PopupMenuItem(value: 'event', child: Text('Tengeneza tukio')),
                const PopupMenuItem(value: 'group_call', child: Text('Simu ya kikundi')),
              ],
              const PopupMenuItem(value: 'search', child: Text('Tafuta')),
              const PopupMenuItem(value: 'mute', child: Text('Nyamazisha')),
              const PopupMenuItem(value: 'block', child: Text('Zulia')),
              const PopupMenuItem(value: 'report', child: Text('Ripoti')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_otherUsersTyping.isNotEmpty) _buildTypingIndicator(_otherUsersTyping),
            if (_replyingTo != null) _buildReplyPreview(),
            if (_uploadProgress != null) _buildUploadProgressBar(),
            if (_showMentionOverlay) _buildMentionOverlay(),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return const Center(child: Text('Anza mazungumzo'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      cacheExtent: 800,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == widget.currentUserId;
        final showAvatar = !isMe &&
            (index == 0 || _messages[index - 1].senderId != message.senderId);

        return _MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMe: isMe,
          showAvatar: showAvatar,
          onReply: () => _setReplyTo(message),
          onEdit: isMe && message.messageType == MessageType.text
              ? () => _editMessage(message)
              : null,
          onDelete: isMe ? () => _deleteMessage(message) : null,
          onForward: () => _forwardMessage(message),
          onReact: (emoji) => _addReaction(message, emoji),
          onRemindMe: () => _scheduleReminder(message),
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kReceiverBubble,
        border: Border(top: BorderSide(color: _kSecondaryText.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: _kSenderBubble,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Kujibu',
                  style: TextStyle(
                    fontSize: 12,
                    color: _kSenderBubble,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _replyingTo?.content ?? _replyingTo?.preview ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: _kPrimaryText),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _cancelReply,
            style: IconButton.styleFrom(minimumSize: const Size(_kMinTouchTarget, _kMinTouchTarget)),
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
            const SizedBox(width: 12),
            Text(
              'Recording... ${_formatRecordingDuration(_recordingDurationSec)}',
              style: const TextStyle(
                fontSize: 14,
                color: _kPrimaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
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
          ],
        ),
      ),
    );
  }

  void _showStickerPicker() {
    const stickers = ['😀', '👍', '❤️', '🎉', '🔥', '😂', '😍', '🙏', '👋', '⭐'];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Stickers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stickers.map((s) => InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _sendSticker(s);
                  },
                  child: Text(s, style: const TextStyle(fontSize: 32)),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGifPicker() {
    const gifs = [
      'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif',
      'https://media.giphy.com/media/26BRv0ThflsHCqQAk/giphy.gif',
      'https://media.giphy.com/media/g9582DNuQppxC/giphy.gif',
    ];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GIF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: gifs.map((url) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _sendGif(url);
                    },
                    child: CachedMediaImage(imageUrl: url, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onForward;
  final void Function(String emoji)? onReact;
  final VoidCallback? onRemindMe;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.onReply,
    this.onEdit,
    this.onDelete,
    required this.onForward,
    this.onReact,
    this.onRemindMe,
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
                    if (message.replyTo != null) _buildReplyPreview(context),
                    if (message.messageType == MessageType.image && message.mediaUrl != null)
                      _buildImage(message.mediaUrl!)
                    else if (message.messageType == MessageType.video && message.mediaUrl != null)
                      _buildVideoThumbnail(message.mediaUrl!)
                    else if (message.messageType == MessageType.audio && message.mediaUrl != null)
                      _buildAudioPlayer(message.mediaUrl!)
                    else if (message.messageType == MessageType.document)
                      _buildDocumentContent()
                    else if (message.messageType == MessageType.location)
                      _buildLocationContent()
                    else if (message.messageType == MessageType.contact)
                      _buildContactContent()
                    else
                      Text(
                        message.content ?? message.preview,
                        style: TextStyle(
                          color: isMe ? Colors.white : _kPrimaryText,
                          fontSize: 14,
                        ),
                      ),
                    if (message.reactions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: message.reactions.map((r) {
                          final count = r.userIds.length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isMe ? Colors.white24 : _kSecondaryText.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${r.emoji}${count > 1 ? count.toString() : ''}', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white70 : _kSecondaryText,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: message.isRead ? Colors.lightBlueAccent : Colors.white70,
                          ),
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

  Widget _buildReplyPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white24 : _kSecondaryText.withOpacity(0.2),
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

  Widget _buildVideoThumbnail(String videoUrl) {
    return InkWell(
      onTap: () {
        // Full-screen video player could be pushed here
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
                  children: _kReactionEmojis.map((emoji) => InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onReact!(emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  )).toList(),
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
    }
    if (mounted) setState(() => _playing = !_playing);
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _togglePlay,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          constraints: const BoxConstraints(minWidth: 120, minHeight: _kMinTouchTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: widget.isMe ? Colors.white : _kPrimaryText,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                _playing ? 'Simama' : 'Sikiliza',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isMe ? Colors.white : _kPrimaryText,
                ),
              ),
            ],
          ),
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
            color: const Color(0xFF999999).withOpacity(0.4 + (_animation.value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
