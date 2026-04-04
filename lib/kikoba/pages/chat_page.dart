import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../DataStore.dart';
import '../HttpService.dart';
import '../models/chat/chat_models.dart';
import '../services/firebase_chat_service.dart';

const Color primaryColor = Color(0xFF1A1A1A);
const Color accentColor = Color(0xFF666666);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF1A1A1A);
const Color secondaryTextColor = Color(0xFF666666);

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String recipientName;
  final String recipientId;
  final String? recipientPhone;
  final String? firebasePath;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.recipientName,
    required this.recipientId,
    this.recipientPhone,
    this.firebasePath,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseChatService _firebaseService = FirebaseChatService();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isOtherTyping = false;
  bool _isMuted = false;
  String? _currentUserId;
  String? _currentUserName;
  Timer? _typingTimer;

  // Stream subscriptions
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUserId = DataStore.currentUserId;
    _currentUserName = DataStore.currentUserName;
    _loadMessages();
    _setupRealtimeListeners();
    _markAsRead();
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    // Stop typing when leaving
    if (widget.firebasePath != null && _currentUserId != null) {
      _firebaseService.setTyping(widget.firebasePath!, _currentUserId!, false);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Stop typing when app goes to background
      if (widget.firebasePath != null && _currentUserId != null) {
        _firebaseService.setTyping(widget.firebasePath!, _currentUserId!, false);
      }
    }
  }

  void _setupRealtimeListeners() {
    if (widget.firebasePath == null) return;

    // Listen for messages
    _messagesSubscription = _firebaseService
        .getMessagesStream(widget.firebasePath!)
        .listen((messages) {
      if (mounted) {
        setState(() => _messages = messages);
        _markAsRead();
      }
    });

    // Listen for typing status
    _typingSubscription = _firebaseService
        .getTypingStream(widget.firebasePath!, widget.recipientId)
        .listen((isTyping) {
      if (mounted) {
        setState(() => _isOtherTyping = isTyping);
      }
    });
  }

  void _onTypingChanged() {
    if (widget.firebasePath == null || _currentUserId == null) return;

    final isTyping = _messageController.text.isNotEmpty;

    // Cancel previous timer
    _typingTimer?.cancel();

    if (isTyping) {
      // Set typing status
      _firebaseService.setTyping(widget.firebasePath!, _currentUserId!, true);

      // Auto-stop after 3 seconds of no typing
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && widget.firebasePath != null && _currentUserId != null) {
          _firebaseService.setTyping(widget.firebasePath!, _currentUserId!, false);
        }
      });
    } else {
      _firebaseService.setTyping(widget.firebasePath!, _currentUserId!, false);
    }
  }

  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;

    final data = await HttpService.getMessages(
      conversationId: widget.conversationId,
      userId: _currentUserId!,
    );

    if (!mounted) return;

    final messagesList = data?['messages'] as List<dynamic>? ?? [];
    setState(() {
      _messages = messagesList
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _markAsRead() async {
    if (_currentUserId == null) return;
    await HttpService.markConversationAsRead(
      conversationId: widget.conversationId,
      userId: _currentUserId!,
    );
  }

  Future<void> _sendMessage({
    String? content,
    MessageType messageType = MessageType.text,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    final messageContent = content ?? _messageController.text.trim();
    if (messageContent.isEmpty && attachmentUrl == null) return;
    if (_isSending || _currentUserId == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Stop typing indicator
    if (widget.firebasePath != null) {
      _firebaseService.setTyping(widget.firebasePath!, _currentUserId!, false);
    }

    // Optimistic update
    final tempMessage = ChatMessage.temporary(
      senderId: _currentUserId!,
      senderName: _currentUserName ?? 'Me',
      content: messageContent,
      messageType: messageType,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
    );

    setState(() {
      _messages.add(tempMessage);
    });

    final result = await HttpService.sendMessage(
      conversationId: widget.conversationId,
      senderId: _currentUserId!,
      content: messageContent,
      messageType: messageType.value,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
      // Remove temp message, real one will come from stream
      _messages.removeWhere((m) => m.localId == tempMessage.localId);
    });

    if (result == null) {
      // Show error and re-add as failed
      setState(() {
        _messages.add(tempMessage.copyWith(isSending: false, isFailed: true));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kutuma ujumbe'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      // Show uploading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inapakia picha...')),
      );

      // TODO: Upload image to server and get URL
      // For now, send as text placeholder
      await _sendMessage(
        content: 'Picha: ${image.name}',
        messageType: MessageType.image,
        attachmentName: image.name,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kosa: $e'), backgroundColor: Colors.red),
      );
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

      // Show uploading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inapakia faili...')),
      );

      // TODO: Upload file to server and get URL
      // For now, send as text placeholder
      await _sendMessage(
        content: 'Faili: ${file.name}',
        messageType: MessageType.file,
        attachmentName: file.name,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kosa: $e'), backgroundColor: Colors.red),
      );
    }
  }

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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_rounded,
                    label: 'Picha',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        await _sendMessage(
                          content: 'Picha: ${image.name}',
                          messageType: MessageType.image,
                          attachmentName: image.name,
                        );
                      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessagesList(),
            ),
            // Typing indicator
            if (_isOtherTyping) _buildTypingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: cardColor,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF0F0F0),
            child: Text(
              _getInitials(widget.recipientName),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.recipientPhone != null)
                  Text(
                    widget.recipientPhone!,
                    style: const TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  )
                else if (_isOtherTyping)
                  const Text(
                    'anaandika...',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Popup menu instead of bottom sheet
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: textColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: const [
                  Icon(Icons.person_outline_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Tazama wasifu'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(
                    _isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(_isMuted ? 'Washa arifa' : 'Zima arifa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Zuia mtumiaji', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        // Navigate to profile
        break;
      case 'mute':
        _toggleMute();
        break;
      case 'block':
        _showBlockConfirmation();
        break;
    }
  }

  Future<void> _toggleMute() async {
    if (_currentUserId == null) return;

    final newMuteState = await HttpService.toggleMuteConversation(
      conversationId: widget.conversationId,
      userId: _currentUserId!,
    );

    setState(() => _isMuted = newMuteState);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newMuteState ? 'Arifa zimezimwa' : 'Arifa zimewashwa'),
      ),
    );
  }

  Widget _buildTypingIndicator() {
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
              Icons.chat_bubble_outline_rounded,
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
          Text(
            'Anza mazungumzo na ${widget.recipientName}',
            style: const TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Reverse for auto-scroll to bottom
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        // Reversed index
        final actualIndex = _messages.length - 1 - index;
        final message = _messages[actualIndex];
        final previousMessage = actualIndex > 0 ? _messages[actualIndex - 1] : null;
        final showDateHeader = _shouldShowDateHeader(message, previousMessage);

        return Column(
          children: [
            if (showDateHeader) _buildDateHeader(message.sentAt),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  bool _shouldShowDateHeader(ChatMessage current, ChatMessage? previous) {
    if (previous == null) return true;

    return current.sentAt.day != previous.sentAt.day ||
        current.sentAt.month != previous.sentAt.month ||
        current.sentAt.year != previous.sentAt.year;
  }

  Widget _buildDateHeader(DateTime date) {
    String displayDate;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      displayDate = 'Leo';
    } else if (diff.inDays == 1) {
      displayDate = 'Jana';
    } else if (diff.inDays < 7) {
      const days = ['Jumatatu', 'Jumanne', 'Jumatano', 'Alhamisi', 'Ijumaa', 'Jumamosi', 'Jumapili'];
      displayDate = days[date.weekday - 1];
    } else {
      displayDate = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        displayDate,
        style: const TextStyle(
          fontSize: 12,
          color: secondaryTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isFromMe(_currentUserId ?? '');
    final isDeleted = message.isDeleted;
    final isSystem = message.isSystemMessage;

    // System message
    if (isSystem) {
      return _buildSystemMessage(message);
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDeleted
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
              if (isDeleted)
                Row(
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
                )
              else if (message.messageType == MessageType.image)
                _buildImageMessage(message, isMe)
              else if (message.messageType == MessageType.file)
                _buildFileMessage(message, isMe)
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
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: Colors.red,
                      )
                    else
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? Colors.lightBlueAccent
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(ChatMessage message, bool isMe) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: message.attachmentUrl != null
              ? CachedNetworkImage(
                  imageUrl: message.attachmentUrl!,
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
                )
              : Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white24 : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        size: 40,
                        color: isMe ? Colors.white70 : accentColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message.attachmentName ?? 'Picha',
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
        ),
        if (message.content.isNotEmpty && !message.content.startsWith('Picha:'))
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

  Widget _buildFileMessage(ChatMessage message, bool isMe) {
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
                  message.attachmentName ?? 'Faili',
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

  Widget _buildSystemMessage(ChatMessage message) {
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
          ),
        ),
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
                focusNode: _focusNode,
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

  void _showMessageOptions(ChatMessage message) {
    final isMe = message.isFromMe(_currentUserId ?? '');
    final isDeleted = message.isDeleted;

    if (isDeleted) return; // Don't show options for deleted messages

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
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ujumbe umenakiliwa'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              if (isMe)
                _buildOptionItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Futa',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
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

  Future<void> _deleteMessage(ChatMessage message) async {
    if (_currentUserId == null) return;

    final success = await HttpService.deleteMessage(
      messageId: message.messageId,
      userId: _currentUserId!,
    );

    if (success) {
      setState(() {
        final index = _messages.indexWhere((m) => m.messageId == message.messageId);
        if (index != -1) {
          _messages[index] = message.copyWith(isDeleted: true);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kufuta ujumbe'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Zuia mtumiaji?'),
        content: Text(
          'Hutaweza kupokea ujumbe kutoka kwa ${widget.recipientName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi', style: TextStyle(color: accentColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_currentUserId == null) return;

              final success = await HttpService.blockUser(
                blockerId: _currentUserId!,
                blockedId: widget.recipientId,
              );

              if (success && mounted) {
                Navigator.pop(context); // Go back to conversations
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.recipientName} amezuiwa')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Zuia', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
