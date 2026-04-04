import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:vicoba/DataStore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../imagePicker.dart';
import 'HttpService.dart';
import 'services/baraza_cache_service.dart';

// Minimalist monochrome color palette from design guidelines
const Color primaryColor = Color(0xFF1A1A1A);
const Color accentColor = Color(0xFF666666);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF1A1A1A);
const Color secondaryTextColor = Color(0xFF666666);

/// Group message model for optimistic updates
class GroupMessage {
  final String messageId;
  final String senderId;
  final String senderName;
  final String senderNumber;
  final String content;
  final String messageType; // text, image, file, audio, system
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? audioUrl;
  final int? audioDuration;
  final DateTime sentAt;
  final bool isDeleted;
  final bool isEdited;

  // Local state for optimistic updates
  final bool isSending;
  final bool isFailed;
  final String? localId;
  final double? uploadProgress;

  GroupMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.senderNumber,
    required this.content,
    this.messageType = 'text',
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.audioUrl,
    this.audioDuration,
    required this.sentAt,
    this.isDeleted = false,
    this.isEdited = false,
    this.isSending = false,
    this.isFailed = false,
    this.localId,
    this.uploadProgress,
  });

  factory GroupMessage.fromFirestore(Map<String, dynamic> data) {
    DateTime parsedTime;
    try {
      if (data['postTime'] is Timestamp) {
        parsedTime = (data['postTime'] as Timestamp).toDate();
      } else if (data['postTime'] is String) {
        parsedTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(data['postTime']);
      } else {
        parsedTime = DateTime.now();
      }
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return GroupMessage(
      messageId: data['postId'] ?? '',
      senderId: data['posterId']?.toString() ?? '',
      senderName: data['posterName'] ?? 'Unknown',
      senderNumber: data['posterNumber']?.toString() ?? '',
      content: data['postComment'] ?? '',
      messageType: data['postType'] ?? 'text',
      imageUrl: data['remotepostImage'] ?? data['postImage'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      sentAt: parsedTime,
      isDeleted: data['isDeleted'] ?? false,
      isEdited: data['isEdited'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': messageId,
      'posterId': senderId,
      'posterName': senderName,
      'posterNumber': senderNumber,
      'posterPhoto': '',
      'postComment': content,
      'postType': messageType,
      'postImage': imageUrl ?? '',
      'remotepostImage': imageUrl ?? '',
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'postTime': DateFormat("yyyy-MM-dd HH:mm:ss").format(sentAt),
      'kikobaId': DataStore.currentKikobaId,
      'isDeleted': isDeleted,
      'isEdited': isEdited,
    };
  }

  factory GroupMessage.temporary({
    required String senderId,
    required String senderName,
    required String senderNumber,
    required String content,
    String messageType = 'text',
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? audioUrl,
    int? audioDuration,
  }) {
    final localId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    return GroupMessage(
      messageId: localId,
      senderId: senderId,
      senderName: senderName,
      senderNumber: senderNumber,
      content: content,
      messageType: messageType,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      sentAt: DateTime.now(),
      isSending: true,
      localId: localId,
    );
  }

  GroupMessage copyWith({
    String? messageId,
    String? senderId,
    String? senderName,
    String? senderNumber,
    String? content,
    String? messageType,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? audioUrl,
    int? audioDuration,
    DateTime? sentAt,
    bool? isDeleted,
    bool? isEdited,
    bool? isSending,
    bool? isFailed,
    String? localId,
    double? uploadProgress,
  }) {
    return GroupMessage(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderNumber: senderNumber ?? this.senderNumber,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      sentAt: sentAt ?? this.sentAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      isSending: isSending ?? this.isSending,
      isFailed: isFailed ?? this.isFailed,
      localId: localId ?? this.localId,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  bool isFromMe(String myNumber) => senderNumber == myNumber;

  String get timeDisplay {
    return '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  bool get isSystemMessage => messageType == 'taarifaYamualiko' || messageType == 'taarifaYakujiunga' || messageType == 'system';

  bool get isMembershipRequest => messageType == 'maombiyakujiunga';
}

/// Typing user model
class TypingUser {
  final String oderId;
  final String name;
  final DateTime timestamp;

  TypingUser({required this.oderId, required this.name, required this.timestamp});

  factory TypingUser.fromFirestore(Map<String, dynamic> data) {
    return TypingUser(
      oderId: data['userId'] ?? '',
      name: data['name'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class baraza extends StatefulWidget {
  const baraza({Key? key}) : super(key: key);

  @override
  BarazaChatState createState() => BarazaChatState();
}

class BarazaChatState extends State<baraza>
    with AutomaticKeepAliveClientMixin<baraza>, WidgetsBindingObserver {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  // Data
  List<GroupMessage> _messages = [];
  List<GroupMessage> _pendingMessages = []; // For optimistic updates
  bool _isLoading = true;
  bool _isFirstLoad = true; // Track first load for auto-scroll
  int _previousMessageCount = 0; // Track message count for new message detection

  // Cache and connectivity state
  bool _hasCachedData = false;
  bool _isRefreshing = false;

  // User info
  String get _kikobaId => DataStore.currentKikobaId;
  String get _userNumber => DataStore.userNumber;
  String get _userName => DataStore.currentUserName;
  String get _userId => DataStore.currentUserId;

  // Typing indicators
  List<TypingUser> _typingUsers = [];
  Timer? _typingTimer;
  bool _isTyping = false;

  // Audio recording
  late AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String? _audioPath;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  String? _playingMessageId;

  // State
  bool _isSending = false;
  String? _draftMessage;

  // Stream subscriptions
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger.i('Initializing BarazaChat');
    _loadCachedData(); // Load cached messages first for instant display
    _initializeFirebase();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    // Stop typing when leaving
    _setTyping(false);
    _logger.i('Disposing BarazaChat resources');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _setTyping(false);
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _audioPosition = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _audioPosition = Duration.zero;
          _playingMessageId = null;
        });
      }
    });
  }

  /// Load cached messages for instant display
  Future<void> _loadCachedData() async {
    if (_kikobaId.isEmpty) return;

    try {
      final cachedMessages = await BarazaCacheService.getMessages(_kikobaId);
      if (cachedMessages != null && cachedMessages.isNotEmpty && mounted) {
        final messages = cachedMessages
            .map((json) => GroupMessage.fromFirestore(json))
            .toList();
        setState(() {
          _messages = messages;
          _hasCachedData = true;
          _previousMessageCount = messages.length;
        });
        _logger.d('[BarazaChat] Loaded ${messages.length} messages from cache');
        // Jump to bottom after loading cached data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpToBottom();
        });
      }
    } catch (e) {
      _logger.e('[BarazaChat] Error loading cached data: $e');
    }
  }

  /// Save messages to cache
  Future<void> _saveToCache(List<GroupMessage> messages) async {
    if (_kikobaId.isEmpty || messages.isEmpty) return;

    try {
      final jsonMessages = messages.map((m) => m.toFirestore()).toList();
      await BarazaCacheService.saveMessages(_kikobaId, jsonMessages);
    } catch (e) {
      _logger.e('[BarazaChat] Error saving to cache: $e');
    }
  }

  /// Check internet connectivity
  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      _logger.e('[BarazaChat] Connectivity check failed: $e');
      return true; // Assume connected on error
    }
  }

  /// Show connectivity snackbar
  void _showConnectivitySnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Hakuna mtandao. Unaona taarifa zilizohifadhiwa.'),
          ],
        ),
        backgroundColor: const Color(0xFF424242),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      _showConnectivitySnackbar();
      return;
    }

    setState(() => _isRefreshing = true);

    // The Firestore stream will automatically update with fresh data
    // We just need to wait a bit for visual feedback
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      _logger.d('Initializing Firebase');
      await Firebase.initializeApp();
      _setupStreams();
    } catch (e, stackTrace) {
      _logger.e('Firebase initialization failed', error: e, stackTrace: stackTrace);
    }
  }

  void _setupStreams() {
    _logger.d('Setting up streams for Kikoba: $_kikobaId');

    // Messages stream
    _messagesSubscription = FirebaseFirestore.instance
        .collection("${_kikobaId}barazaMessages")
        .orderBy('postTime', descending: false)
        .limitToLast(200)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final messages = snapshot.docs
            .map((doc) => GroupMessage.fromFirestore(doc.data()))
            .toList();

        final hasNewMessages = messages.length > _previousMessageCount;
        final isNearBottom = _isNearBottom();

        setState(() {
          _messages = messages;
          _isLoading = false;
          _isRefreshing = false;
          _previousMessageCount = messages.length;
          // Remove confirmed messages from pending
          _pendingMessages.removeWhere((pending) =>
            messages.any((m) => m.messageId == pending.messageId));
        });

        // Save to cache for offline access
        _saveToCache(messages);

        // Auto-scroll on first load or when new messages arrive (if near bottom)
        if (_isFirstLoad) {
          _isFirstLoad = false;
          // Use instant jump on first load so user sees messages at bottom immediately
          _jumpToBottom();
        } else if (hasNewMessages && isNearBottom) {
          // Animate scroll for new messages
          _scrollToBottom();
        }
      }
    }, onError: (e) {
      _logger.e('Messages stream error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          // If we have cached data, show offline message
          if (_hasCachedData) {
            _showConnectivitySnackbar();
          }
        });
      }
    });

    // Typing indicators stream
    _typingSubscription = FirebaseFirestore.instance
        .collection("${_kikobaId}barazaTyping")
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final now = DateTime.now();
        final typingUsers = snapshot.docs
            .map((doc) => TypingUser.fromFirestore(doc.data()))
            .where((user) =>
                user.oderId != _userId &&
                now.difference(user.timestamp).inSeconds < 10)
            .toList();

        setState(() => _typingUsers = typingUsers);
      }
    });
  }

  void _onTypingChanged() {
    final isTyping = _messageController.text.isNotEmpty;

    _typingTimer?.cancel();

    if (isTyping) {
      if (!_isTyping) {
        _setTyping(true);
      }
      // Auto-stop after 3 seconds of no typing
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _setTyping(false);
      });
    } else {
      _setTyping(false);
    }
  }

  Future<void> _setTyping(bool isTyping) async {
    if (_isTyping == isTyping) return;
    _isTyping = isTyping;

    try {
      final docRef = FirebaseFirestore.instance
          .collection("${_kikobaId}barazaTyping")
          .doc(_userId);

      if (isTyping) {
        await docRef.set({
          'userId': _userId,
          'name': _userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.delete();
      }
    } catch (e) {
      _logger.w('Error updating typing status: $e');
    }
  }

  /// Check if user is near the bottom of the chat (within 150 pixels)
  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return (maxScroll - currentScroll) < 150;
  }

  /// Scroll to the bottom of the chat
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  /// Force scroll to bottom (used after layout changes)
  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      // Secondary scroll after a short delay to ensure layout is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
  }

  List<GroupMessage> get _allMessages {
    // Combine confirmed messages with pending messages
    final all = [..._messages, ..._pendingMessages];
    all.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return all;
  }

  Future<void> _sendMessage({
    String? content,
    String messageType = 'text',
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? audioUrl,
    int? audioDuration,
  }) async {
    final messageContent = content ?? _messageController.text.trim();
    if (messageContent.isEmpty && imageUrl == null && fileUrl == null && audioUrl == null) return;
    if (_isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();
    _setTyping(false);

    final uuid = const Uuid().v4();

    // Create optimistic message
    final tempMessage = GroupMessage.temporary(
      senderId: _userId,
      senderName: _userName,
      senderNumber: _userNumber,
      content: messageContent,
      messageType: messageType,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
    ).copyWith(messageId: uuid);

    // Add to pending for optimistic update
    setState(() {
      _pendingMessages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      await FirebaseFirestore.instance
          .collection('${_kikobaId}barazaMessages')
          .add(tempMessage.toFirestore());

      _logger.i('Message sent successfully');

      setState(() {
        _isSending = false;
        _audioPath = null;
        // Remove from pending (will be added from stream)
        _pendingMessages.removeWhere((m) => m.messageId == uuid);
      });
    } catch (e, stackTrace) {
      _logger.e('Error sending message', error: e, stackTrace: stackTrace);

      // Mark as failed
      setState(() {
        _isSending = false;
        final index = _pendingMessages.indexWhere((m) => m.messageId == uuid);
        if (index != -1) {
          _pendingMessages[index] = _pendingMessages[index].copyWith(
            isSending: false,
            isFailed: true,
          );
        }
      });

      _showErrorSnackbar('Imeshindwa kutuma ujumbe');
    }
  }

  Future<void> _retrySendMessage(GroupMessage message) async {
    // Remove failed message
    setState(() {
      _pendingMessages.removeWhere((m) => m.messageId == message.messageId);
    });

    // Resend
    await _sendMessage(
      content: message.content,
      messageType: message.messageType,
      imageUrl: message.imageUrl,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      fileSize: message.fileSize,
      audioUrl: message.audioUrl,
      audioDuration: message.audioDuration,
    );
  }

  Future<void> _deleteMessage(GroupMessage message) async {
    try {
      // Find and update the document
      final querySnapshot = await FirebaseFirestore.instance
          .collection('${_kikobaId}barazaMessages')
          .where('postId', isEqualTo: message.messageId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'isDeleted': true,
          'postComment': '',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ujumbe umefutwa')),
        );
      }
    } catch (e) {
      _logger.e('Error deleting message: $e');
      _showErrorSnackbar('Imeshindwa kufuta ujumbe');
    }
  }

  void _copyMessage(GroupMessage message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ujumbe umenakiliwa'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ==================== Attachments ====================

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_rounded,
                    label: 'Picha',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Faili',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFile();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inapakia picha...')),
      );

      // Upload to Firebase Storage
      final imageUrl = await _uploadFile(File(image.path), 'images');

      if (imageUrl != null) {
        await _sendMessage(
          content: _messageController.text.trim(),
          messageType: 'textImage',
          imageUrl: imageUrl,
        );
      }
    } catch (e) {
      _logger.e('Error picking image: $e');
      _showErrorSnackbar('Imeshindwa kupakia picha');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inapakia faili...')),
      );

      final fileUrl = await _uploadFile(File(file.path!), 'files');

      if (fileUrl != null) {
        await _sendMessage(
          content: file.name,
          messageType: 'file',
          fileUrl: fileUrl,
          fileName: file.name,
          fileSize: file.size,
        );
      }
    } catch (e) {
      _logger.e('Error picking file: $e');
      _showErrorSnackbar('Imeshindwa kupakia faili');
    }
  }

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('baraza/$_kikobaId/$folder/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');

      final uploadTask = ref.putFile(file);

      // Show upload progress
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        _logger.d('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      _logger.e('Error uploading file: $e');
      _showErrorSnackbar('Imeshindwa kupakia');
      return null;
    }
  }

  // ==================== Audio Recording ====================

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
      }
    } catch (e) {
      _logger.e('Error starting recording: $e');
      _showErrorSnackbar('Imeshindwa kurekodi');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _audioPath = path;
        });
      }
    } catch (e) {
      _logger.e('Error stopping recording: $e');
      _showErrorSnackbar('Kosa la kurekodi');
    }
  }

  Future<void> _sendAudioMessage() async {
    if (_audioPath == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inapakia sauti...')),
      );

      final audioUrl = await _uploadFile(File(_audioPath!), 'audio');

      if (audioUrl != null) {
        await _sendMessage(
          messageType: 'audio',
          audioUrl: audioUrl,
          audioDuration: _audioDuration.inSeconds,
        );
      }

      setState(() {
        _audioPath = null;
        _audioDuration = Duration.zero;
      });
    } catch (e) {
      _logger.e('Error sending audio: $e');
      _showErrorSnackbar('Imeshindwa kutuma sauti');
    }
  }

  void _cancelAudioRecording() {
    setState(() {
      _audioPath = null;
      _audioDuration = Duration.zero;
      _audioPosition = Duration.zero;
    });
  }

  Future<void> _playAudioMessage(String url, String messageId) async {
    if (_playingMessageId == messageId && _isPlaying) {
      await _audioPlayer.pause();
    } else {
      setState(() => _playingMessageId = messageId);
      await _audioPlayer.play(UrlSource(url));
    }
  }

  // ==================== Membership Request Voting ====================

  // Track which requests the user has voted on (request_id -> vote)
  final Map<String, String> _userVotes = {};
  // Track vote counts per request (request_id -> {yes: n, no: n})
  final Map<String, Map<String, int>> _voteCounts = {};
  // Track request statuses (request_id -> status)
  final Map<String, String> _requestStatuses = {};
  // Track loading states for voting
  final Set<String> _votingInProgress = {};
  // Track dismissed/hidden membership requests (user chose to skip)
  final Set<String> _dismissedRequests = {};

  void _dismissMembershipRequest(String requestId) {
    setState(() {
      _dismissedRequests.add(requestId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Ombi limefichwa. Litaonekana tena ukiingia upya.'),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Rejesha',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _dismissedRequests.remove(requestId);
            });
          },
        ),
      ),
    );
  }

  Future<void> _castVote(String requestId, String vote) async {
    if (_votingInProgress.contains(requestId)) return;

    setState(() => _votingInProgress.add(requestId));

    try {
      final response = await http.post(
        Uri.parse("${HttpService.baseUrl}membership-request/$requestId/vote"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'voterId': _userId,
          'kikobaId': _kikobaId,
          'vote': vote, // 'yes' or 'no'
        }),
      ).timeout(const Duration(seconds: 10));

      _logger.d('Vote response: ${response.body}');

      final data = json.decode(response.body);
      final code = data['code']?.toString() ?? '';

      // Handle REQUEST_NOT_FOUND - delete stale record and refresh
      if (code == 'REQUEST_NOT_FOUND') {
        _logger.w('Request $requestId not found, removing from local database');
        await _removeStaleRequest(requestId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ombi hili halipo tena'),
              backgroundColor: accentColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _userVotes[requestId] = vote;
          _voteCounts[requestId] = {
            'yes': data['data']['yes_votes'] ?? 0,
            'no': data['data']['no_votes'] ?? 0,
          };

          // Check if auto-processed
          if (data['data']['auto_processed'] == true) {
            _requestStatuses[requestId] = data['data']['auto_result'] ?? 'processed';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vote == 'yes' ? 'Umekubali ombi' : 'Umekataa ombi'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        _showErrorSnackbar(data['message'] ?? 'Imeshindwa kupiga kura');
      }
    } catch (e, stackTrace) {
      _logger.e('Error casting vote', error: e, stackTrace: stackTrace);
      _showErrorSnackbar('Imeshindwa kupiga kura');
    } finally {
      if (mounted) {
        setState(() => _votingInProgress.remove(requestId));
      }
    }
  }

  /// Remove stale membership request from Firestore and local state
  Future<void> _removeStaleRequest(String requestId) async {
    try {
      // Find and delete from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('${_kikobaId}barazaMessages')
          .where('postId', isEqualTo: requestId)
          .where('postType', isEqualTo: 'maombiyakujiunga')
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        _logger.i('Deleted stale request document: ${doc.id}');
      }

      // Remove from local state
      if (mounted) {
        setState(() {
          _messages.removeWhere((msg) =>
            msg.messageType == 'maombiyakujiunga' && msg.messageId == requestId
          );
          _userVotes.remove(requestId);
          _voteCounts.remove(requestId);
          _requestStatuses.remove(requestId);
        });
      }
    } catch (e, stackTrace) {
      _logger.e('Error removing stale request', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _loadRequestStatus(String requestId) async {
    // This could be called to refresh vote counts for a specific request
    // For now, we'll rely on the initial data from Firebase
  }

  // ==================== Build Methods ====================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar refresh indicator
            if (_isRefreshing)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                minHeight: 2,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: primaryColor,
                child: _isLoading && !_hasCachedData
                    ? _buildSkeletonLoading()
                    : _allMessages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessagesList(),
              ),
            ),
            // Typing indicator
            if (_typingUsers.isNotEmpty) _buildTypingIndicator(),
            // Audio preview
            if (_audioPath != null && !_isRecording) _buildAudioPreview(),
            // Recording indicator
            if (_isRecording) _buildRecordingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.forum_rounded,
              size: 40,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hakuna ujumbe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anza mazungumzo na wanachama',
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build skeleton loading for chat messages
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) {
        // Alternate between left and right aligned messages
        final isFromMe = index % 3 == 0;
        return _buildSkeletonMessage(isFromMe: isFromMe);
      },
    );
  }

  /// Build a single skeleton message bubble
  Widget _buildSkeletonMessage({required bool isFromMe}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isFromMe ? const Color(0xFFE8E8E8) : cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isFromMe ? 16 : 4),
                bottomRight: Radius.circular(isFromMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name skeleton (only for received messages)
                if (!isFromMe)
                  Container(
                    width: 80,
                    height: 10,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                // Message content skeleton (multiple lines)
                Container(
                  width: 180,
                  height: 12,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Time skeleton
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: 40,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _allMessages.length,
        itemBuilder: (context, index) {
          final message = _allMessages[index];
          final previousMessage = index > 0 ? _allMessages[index - 1] : null;
          final showDateHeader = _shouldShowDateHeader(message, previousMessage);

          return Column(
            children: [
              if (showDateHeader) _buildDateHeader(message.sentAt),
              _buildMessageBubble(message),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowDateHeader(GroupMessage current, GroupMessage? previous) {
    if (previous == null) return true;
    return current.sentAt.day != previous.sentAt.day ||
        current.sentAt.month != previous.sentAt.month ||
        current.sentAt.year != previous.sentAt.year;
  }

  Widget _buildDateHeader(DateTime date) {
    String displayDate;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0 && now.day == date.day) {
      displayDate = 'Leo';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      displayDate = 'Jana';
    } else if (diff.inDays < 7) {
      const days = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
      displayDate = days[date.weekday - 1];
    } else {
      displayDate = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            displayDate,
            style: const TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GroupMessage message) {
    final isMe = message.isFromMe(_userNumber);

    // System message
    if (message.isSystemMessage) {
      return _buildSystemMessage(message);
    }

    // Membership request message
    if (message.isMembershipRequest) {
      return _buildMembershipRequestCard(message);
    }

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMe ? 60 : 0,
            right: isMe ? 0 : 60,
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Sender name (for group chat, show for others)
              if (!isMe && !message.isDeleted)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              // Message bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isDeleted
                      ? (isMe ? primaryColor.withValues(alpha: 0.5) : const Color(0xFFE5E5E5))
                      : (isMe ? primaryColor : cardColor),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Message content
                    if (message.isDeleted)
                      _buildDeletedMessage(isMe)
                    else if (message.messageType == 'textImage')
                      _buildImageMessage(message, isMe)
                    else if (message.messageType == 'file')
                      _buildFileMessage(message, isMe)
                    else if (message.messageType == 'audio')
                      _buildAudioMessageContent(message, isMe)
                    else
                      Text(
                        message.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMe ? Colors.white : textColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Time and status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isEdited) ...[
                          Text(
                            'imehaririwa',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : secondaryTextColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          message.timeDisplay,
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : secondaryTextColor,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          if (message.isSending)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            )
                          else if (message.isFailed)
                            GestureDetector(
                              onTap: () => _retrySendMessage(message),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                size: 14,
                                color: Colors.red,
                              ),
                            )
                          else
                            Icon(
                              Icons.done,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedMessage(bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.block_rounded,
          size: 14,
          color: isMe ? Colors.white70 : secondaryTextColor,
        ),
        const SizedBox(width: 4),
        Text(
          'Ujumbe huu umefutwa',
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: isMe ? Colors.white70 : secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage(GroupMessage message, bool isMe) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
          GestureDetector(
            onTap: () => _showFullScreenImage(message.imageUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: message.imageUrl!,
                width: 200,
                height: 150,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 150,
                  color: const Color(0xFFF0F0F0),
                  child: const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 150,
                  color: const Color(0xFFF0F0F0),
                  child: const Icon(Icons.broken_image_rounded, color: accentColor),
                ),
              ),
            ),
          ),
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : textColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileMessage(GroupMessage message, bool isMe) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white24 : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMe ? Colors.white24 : cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file_rounded,
              color: isMe ? Colors.white : primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Faili',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isMe ? Colors.white : textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.formattedFileSize.isNotEmpty)
                  Text(
                    message.formattedFileSize,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : secondaryTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMessageContent(GroupMessage message, bool isMe) {
    final isThisPlaying = _playingMessageId == message.messageId && _isPlaying;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white24 : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => message.audioUrl != null
                ? _playAudioMessage(message.audioUrl!, message.messageId)
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isMe ? Colors.white24 : primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isMe ? Colors.white : Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: isThisPlaying && _audioDuration.inSeconds > 0
                      ? _audioPosition.inSeconds / _audioDuration.inSeconds
                      : 0,
                  backgroundColor: isMe ? Colors.white30 : const Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMe ? Colors.white : primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.audioDuration != null
                      ? '${message.audioDuration! ~/ 60}:${(message.audioDuration! % 60).toString().padLeft(2, '0')}'
                      : '0:00',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(GroupMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipRequestCard(GroupMessage message) {
    // Use postId as the request identifier (this should match the API request_id)
    final requestId = message.messageId;

    // Check if user dismissed this request
    if (_dismissedRequests.contains(requestId)) {
      return const SizedBox.shrink();
    }

    final hasVoted = _userVotes.containsKey(requestId);
    final userVote = _userVotes[requestId];
    final votes = _voteCounts[requestId] ?? {'yes': 0, 'no': 0};
    final status = _requestStatuses[requestId];
    final isVoting = _votingInProgress.contains(requestId);
    final isMyRequest = message.senderId == _userId;

    // Parse requester name from the message content
    String requesterName = message.senderName;
    if (message.content.contains('Ndugu ')) {
      final match = RegExp(r'Ndugu (.+?) anaomba').firstMatch(message.content);
      if (match != null) {
        requesterName = match.group(1) ?? message.senderName;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ombi la Kujiunga',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    message.timeDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  // Close button - only show if not voted and not processed
                  if (!hasVoted && status == null && !isMyRequest) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _dismissMembershipRequest(requestId),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Requester info
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requesterName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Anaomba kujiunga na kikundi',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status or Voting section
                  if (status == 'approved') ...[
                    _buildStatusBadge('Amekubaliwa', Icons.check_circle_rounded, const Color(0xFF4CAF50)),
                  ] else if (status == 'rejected') ...[
                    _buildStatusBadge('Amekataliwa', Icons.cancel_rounded, const Color(0xFFF44336)),
                  ] else if (isMyRequest) ...[
                    _buildStatusBadge('Ombi Lako - Linasubiri', Icons.hourglass_top_rounded, accentColor),
                  ] else if (hasVoted) ...[
                    // Show vote status and counts
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                userVote == 'yes' ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                                color: userVote == 'yes' ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userVote == 'yes' ? 'Umekubali' : 'Umekataa',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: userVote == 'yes' ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildVoteProgress(votes['yes']!, votes['no']!),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Voting buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildVoteButton(
                            label: 'Kubali',
                            icon: Icons.check_rounded,
                            color: const Color(0xFF4CAF50),
                            isLoading: isVoting,
                            onTap: () => _castVote(requestId, 'yes'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildVoteButton(
                            label: 'Kataa',
                            icon: Icons.close_rounded,
                            color: const Color(0xFFF44336),
                            isLoading: isVoting,
                            onTap: () => _castVote(requestId, 'no'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Later/Skip button
                    GestureDetector(
                      onTap: () => _dismissMembershipRequest(requestId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.access_time_rounded,
                              color: accentColor,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Baadae',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ombi litakubaliwa kiotomatiki likipata kura za kutosha',
                      style: TextStyle(
                        fontSize: 10,
                        color: accentColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: isLoading
                ? [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ]
                : [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteProgress(int yesVotes, int noVotes) {
    final total = yesVotes + noVotes;
    final yesPercent = total > 0 ? (yesVotes / total) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kubali: $yesVotes',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Kataa: $noVotes',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFF44336),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: yesPercent,
            backgroundColor: const Color(0xFFF44336).withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Jumla: $total kura',
          style: const TextStyle(
            fontSize: 10,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(GroupMessage message) {
    if (message.isDeleted) return;

    final isMe = message.isFromMe(_userNumber);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionItem(
                icon: Icons.copy_rounded,
                label: 'Nakili',
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage(message);
                },
              ),
              if (isMe)
                _buildOptionItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Futa',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(message);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? primaryColor, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color ?? textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(GroupMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Futa ujumbe?'),
        content: const Text('Ujumbe huu utafutwa kwa wote.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi', style: TextStyle(color: accentColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Futa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final names = _typingUsers.map((u) => u.name.split(' ').first).take(3).join(', ');
    final text = _typingUsers.length == 1
        ? '$names anaandika...'
        : '$names wanaandika...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.3 + (0.7 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildAudioPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () async {
                if (_isPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.play(DeviceFileSource(_audioPath!));
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                    thumbColor: primaryColor,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _audioPosition.inSeconds.toDouble(),
                    min: 0,
                    max: _audioDuration.inSeconds.toDouble().clamp(0.1, double.infinity),
                    onChanged: (value) async {
                      await _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_audioPosition.inMinutes}:${(_audioPosition.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                    Text(
                      '${_audioDuration.inMinutes}:${(_audioDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: secondaryTextColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: secondaryTextColor),
            onPressed: _cancelAudioRecording,
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: primaryColor),
            onPressed: _sendAudioMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Inarekodi...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.stop_rounded, color: Colors.red),
            onPressed: _stopRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: accentColor),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Andika ujumbe...',
                  hintStyle: TextStyle(color: accentColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Mic button
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: _isRecording ? Colors.red : accentColor,
            ),
            onPressed: () async {
              if (_isRecording) {
                await _stopRecording();
              } else {
                await _startRecording();
              }
            },
          ),
          // Send button
          GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
