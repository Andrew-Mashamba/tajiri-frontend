import 'package:flutter/material.dart';
import '../DataStore.dart';
import '../HttpService.dart';
import '../models/chat/chat_models.dart';
import 'chat_page.dart';

const Color primaryColor = Color(0xFF1A1A1A);
const Color accentColor = Color(0xFF666666);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF1A1A1A);
const Color secondaryTextColor = Color(0xFF666666);

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ChatParticipant> _allMembers = [];
  List<ChatParticipant> _filteredMembers = [];
  bool _isLoading = true;
  bool _isStartingChat = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = DataStore.currentUserId;
      if (userId == null) {
        setState(() {
          _error = 'User ID not found';
          _isLoading = false;
        });
        return;
      }

      final data = await HttpService.getChattableMembers(userId);
      if (!mounted) return;

      if (data == null) {
        setState(() {
          _error = 'Imeshindwa kupata wanachama';
          _isLoading = false;
        });
        return;
      }

      final membersList = data['members'] as List<dynamic>? ?? [];
      final members = membersList
          .map((m) => ChatParticipant.fromJson(m as Map<String, dynamic>))
          .toList();

      // Sort: those with existing conversations first, then alphabetically
      members.sort((a, b) {
        if (a.hasConversation && !b.hasConversation) return -1;
        if (!a.hasConversation && b.hasConversation) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      setState(() {
        _allMembers = members;
        _filteredMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Kosa: $e';
        _isLoading = false;
      });
    }
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _allMembers;
      } else {
        _filteredMembers = _allMembers.where((member) {
          return member.name.toLowerCase().contains(query) ||
              (member.phone?.contains(query) ?? false) ||
              (member.role?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _startConversation(ChatParticipant member) async {
    final currentUserId = DataStore.currentUserId;
    if (currentUserId == null) return;

    // Don't allow chatting with yourself
    if (currentUserId == member.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Huwezi kujitumia ujumbe')),
      );
      return;
    }

    setState(() => _isStartingChat = true);

    try {
      // If conversation already exists, navigate directly
      if (member.hasConversation && member.conversationId != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: member.conversationId!,
              recipientName: member.name,
              recipientId: member.userId,
              recipientPhone: member.phone,
            ),
          ),
        );
        return;
      }

      // Start new conversation
      final result = await HttpService.startConversation(
        senderId: currentUserId,
        recipientId: member.userId,
      );

      if (!mounted) return;

      if (result != null && result['conversation_id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: result['conversation_id'],
              recipientName: member.name,
              recipientId: member.userId,
              recipientPhone: member.phone,
              firebasePath: result['firebase_path'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imeshindwa kuanza mazungumzo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kosa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingChat = false);
      }
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
        title: const Text(
          'Mazungumzo Mapya',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _error != null
                      ? _buildErrorState()
                      : _filteredMembers.isEmpty
                          ? _buildEmptyState()
                          : _buildMembersList(),
            ),
          ],
        ),
      ),
      // Loading overlay when starting chat
      floatingActionButton: _isStartingChat
          ? Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            )
          : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Tafuta mwanachama...',
            hintStyle: const TextStyle(color: accentColor, fontSize: 14),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded, color: accentColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: accentColor),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: accentColor),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Kuna tatizo',
            style: const TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
          const SizedBox(height: 16),
          Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: InkWell(
              onTap: _loadMembers,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: const Text(
                  'Jaribu tena',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
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
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 40,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'Hakuna matokeo' : 'Hakuna wanachama',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Jaribu kutafuta tena'
                : 'Hakuna wanachama wa kuwasiliana nao',
            style: const TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    // Group members: Recent conversations first, then others
    final withConversations = _filteredMembers.where((m) => m.hasConversation).toList();
    final withoutConversations = _filteredMembers.where((m) => !m.hasConversation).toList();

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: primaryColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Recent conversations section
          if (withConversations.isNotEmpty) ...[
            _buildSectionHeader('Mazungumzo ya Hivi Karibuni'),
            ...withConversations.map((m) => _buildMemberTile(m, showConversationBadge: true)),
          ],
          // All members section
          if (withoutConversations.isNotEmpty) ...[
            _buildSectionHeader('Wanachama Wote'),
            ...withoutConversations.map((m) => _buildMemberTile(m)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondaryTextColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMemberTile(ChatParticipant member, {bool showConversationBadge = false}) {
    return InkWell(
      onTap: _isStartingChat ? null : () => _startConversation(member),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: cardColor,
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFF0F0F0),
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                // Online indicator
                if (member.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showConversationBadge && member.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${member.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (member.role != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.role!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (member.phone != null)
                        Text(
                          member.displayPhone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Chat icon with dark background per design guidelines
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
