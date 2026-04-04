import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../DataStore.dart';
import '../HttpService.dart';
import '../models/chat/chat_models.dart';
import 'chat_page.dart';
import 'new_chat_screen.dart';

const Color primaryColor = Color(0xFF1A1A1A);
const Color accentColor = Color(0xFF666666);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF1A1A1A);
const Color secondaryTextColor = Color(0xFF666666);

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  int _totalUnread = 0;
  String? _currentUserId;
  StreamSubscription? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _currentUserId = DataStore.currentUserId;
    // Initialize timeago locale
    timeago.setLocaleMessages('sw', SwahiliMessages());
    _loadConversations();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    final kikobaId = DataStore.currentKikobaId;
    if (kikobaId == null) return;

    // Listen for any changes in chat conversations
    // This is a basic implementation - you could make it more granular
    _conversationsSubscription?.cancel();
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) return;

    final data = await HttpService.getConversations(_currentUserId!);

    if (!mounted) return;

    if (data != null) {
      final conversationsList = data['conversations'] as List<dynamic>? ?? [];
      setState(() {
        _conversations = conversationsList
            .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
            .toList();
        _totalUnread = data['total_unread'] ?? 0;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mazungumzo',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_totalUnread > 0)
              Text(
                '$_totalUnread haijasomwa',
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          // Search icon (for future use)
          IconButton(
            icon: const Icon(Icons.search_rounded, color: textColor),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : _conversations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    color: primaryColor,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        return _buildConversationItem(_conversations[index]);
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewChat(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  void _openNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewChatScreen()),
    ).then((_) => _loadConversations());
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
            'Hakuna mazungumzo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anza mazungumzo na mwanachama',
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: InkWell(
              onTap: _openNewChat,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Anza Mazungumzo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildConversationItem(Conversation conversation) {
    final hasUnread = conversation.hasUnread;

    // Get time display using timeago
    String timeDisplay = '';
    if (conversation.lastMessageAt != null) {
      timeDisplay = timeago.format(
        conversation.lastMessageAt!,
        locale: 'sw',
        allowFromNow: true,
      );
    }

    return InkWell(
      onTap: () => _openChat(conversation),
      onLongPress: () => _showConversationOptions(conversation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread ? primaryColor.withValues(alpha: 0.03) : cardColor,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFF0F0F0),
                  child: Text(
                    conversation.otherParticipant.initials,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : '${conversation.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherParticipant.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.isMuted)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.volume_off_rounded,
                            size: 14,
                            color: accentColor,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        timeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread ? primaryColor : secondaryTextColor,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Show read receipt for sent messages
                      if (conversation.isFromMe(_currentUserId ?? '')) ...[
                        Icon(
                          conversation.unreadCount == 0 ? Icons.done_all : Icons.done,
                          size: 14,
                          color: conversation.unreadCount == 0
                              ? Colors.blue
                              : secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                      ],
                      // Message type icon
                      if (conversation.lastMessageType == MessageType.image) ...[
                        const Icon(Icons.image_rounded, size: 14, color: secondaryTextColor),
                        const SizedBox(width: 4),
                      ] else if (conversation.lastMessageType == MessageType.file) ...[
                        const Icon(Icons.insert_drive_file_rounded, size: 14, color: secondaryTextColor),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          conversation.displayLastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? textColor : secondaryTextColor,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversation.conversationId,
          recipientName: conversation.otherParticipant.name,
          recipientId: conversation.otherParticipant.userId,
          recipientPhone: conversation.otherParticipant.phone,
          firebasePath: conversation.firebasePath,
        ),
      ),
    ).then((_) => _loadConversations());
  }

  void _showConversationOptions(Conversation conversation) {
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
                icon: conversation.isMuted
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: conversation.isMuted ? 'Washa arifa' : 'Zima arifa',
                onTap: () async {
                  Navigator.pop(context);
                  await HttpService.toggleMuteConversation(
                    conversationId: conversation.conversationId,
                    userId: _currentUserId ?? '',
                  );
                  _loadConversations();
                },
              ),
              _buildOptionItem(
                icon: conversation.isArchived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
                label: conversation.isArchived ? 'Ondoa kwenye hifadhi' : 'Hifadhi',
                onTap: () async {
                  Navigator.pop(context);
                  await HttpService.archiveConversation(
                    conversationId: conversation.conversationId,
                    userId: _currentUserId ?? '',
                  );
                  _loadConversations();
                },
              ),
              _buildOptionItem(
                icon: Icons.block_rounded,
                label: 'Zuia mtumiaji',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation(conversation);
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

  void _showBlockConfirmation(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Zuia mtumiaji?'),
        content: Text(
          'Hutaweza kupokea ujumbe kutoka kwa ${conversation.otherParticipant.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi', style: TextStyle(color: accentColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await HttpService.blockUser(
                blockerId: _currentUserId ?? '',
                blockedId: conversation.otherParticipant.userId,
              );
              _loadConversations();
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
}

/// Swahili messages for timeago
class SwahiliMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => 'iliyopita';
  @override
  String suffixFromNow() => 'tangu sasa';
  @override
  String lessThanOneMinute(int seconds) => 'sasa hivi';
  @override
  String aboutAMinute(int minutes) => 'dakika 1';
  @override
  String minutes(int minutes) => 'dakika $minutes';
  @override
  String aboutAnHour(int minutes) => 'saa 1';
  @override
  String hours(int hours) => 'masaa $hours';
  @override
  String aDay(int hours) => 'jana';
  @override
  String days(int days) => 'siku $days';
  @override
  String aboutAMonth(int days) => 'mwezi 1';
  @override
  String months(int months) => 'miezi $months';
  @override
  String aboutAYear(int year) => 'mwaka 1';
  @override
  String years(int years) => 'miaka $years';
  @override
  String wordSeparator() => ' ';
}
