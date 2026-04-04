// Smart search across chats and group names (MESSAGES.md).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message_models.dart';
import '../../services/message_service.dart';
import '../../services/message_database.dart';
import '../../widgets/user_avatar.dart';
import '../../l10n/app_strings_scope.dart';

class SearchConversationsScreen extends StatefulWidget {
  final int currentUserId;

  const SearchConversationsScreen({super.key, required this.currentUserId});

  @override
  State<SearchConversationsScreen> createState() => _SearchConversationsScreenState();
}

class _SearchConversationsScreenState extends State<SearchConversationsScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _queryController = TextEditingController();

  List<Conversation> _all = [];
  List<Conversation> _filtered = [];
  bool _loading = true;
  String? _error;

  // Content filter for message search
  String _contentFilter = 'all'; // all | image | video | links | document | audio
  List<Message> _messageResults = [];
  bool _searchingMessages = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _applyFilter();
    _searchMessages();
  }

  void _setContentFilter(String filter) {
    if (_contentFilter == filter) return;
    setState(() => _contentFilter = filter);
    _searchMessages();
  }

  Future<void> _searchMessages() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) {
      if (_messageResults.isNotEmpty) {
        setState(() => _messageResults = []);
      }
      return;
    }

    setState(() => _searchingMessages = true);

    final msgType = _contentFilter == 'all' ? null : _contentFilter;

    // Search locally first
    try {
      final localResults = await MessageDatabase.instance.searchMessages(q);
      if (mounted && localResults.isNotEmpty) {
        setState(() {
          _messageResults = _filterMessagesByType(localResults, msgType);
        });
      }
    } catch (_) {}

    // Then search API for completeness
    try {
      final apiResult = await MessageService.searchMessages(
        userId: widget.currentUserId,
        query: q,
        messageType: msgType,
      );
      if (!mounted) return;
      if (apiResult.success && apiResult.messages.isNotEmpty) {
        // Cache API search results to SQLite for future offline searches
        MessageDatabase.instance.upsertMessages(apiResult.messages);
        // Merge: API results take priority, dedupe by id
        final existingIds = <int>{};
        final merged = <Message>[];
        for (final m in apiResult.messages) {
          if (existingIds.add(m.id)) merged.add(m);
        }
        for (final m in _messageResults) {
          if (existingIds.add(m.id)) merged.add(m);
        }
        setState(() {
          _messageResults = merged;
          _searchingMessages = false;
        });
      } else {
        setState(() => _searchingMessages = false);
      }
    } catch (_) {
      if (mounted) setState(() => _searchingMessages = false);
    }
  }

  List<Message> _filterMessagesByType(List<Message> messages, String? type) {
    if (type == null) return messages;
    return messages.where((m) {
      switch (type) {
        case 'image':
          return m.messageType == MessageType.image ||
              (m.mediaType != null && m.mediaType!.startsWith('image/'));
        case 'video':
          return m.messageType == MessageType.video ||
              (m.mediaType != null && m.mediaType!.startsWith('video/'));
        case 'audio':
          return m.messageType == MessageType.audio ||
              (m.mediaType != null && m.mediaType!.startsWith('audio/'));
        case 'document':
          return m.messageType == MessageType.document;
        case 'links':
          return (m.content != null && (m.content!.contains('http://') || m.content!.contains('https://'))) ||
              m.linkPreviewUrl != null;
        default:
          return true;
      }
    }).toList();
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(time);
    if (diff.inDays < 7) return DateFormat('EEE HH:mm').format(time);
    return DateFormat('MMM d, HH:mm').format(time);
  }

  Future<void> _loadConversations() async {
    setState(() { _loading = true; _error = null; });

    // Step 1: Load from SQLite instantly
    try {
      final cached = await MessageDatabase.instance.getConversations();
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _all = cached;
          _loading = false;
          _applyFilter();
        });
      }
    } catch (_) {}

    // Step 2: Fetch from API for completeness
    try {
      final result = await _messageService.getConversations(
        userId: widget.currentUserId,
        perPage: 100,
      );
      if (!mounted) return;
      // Cache API results back to SQLite
      if (result.success && result.conversations.isNotEmpty) {
        MessageDatabase.instance.upsertConversations(result.conversations);
      }
      setState(() {
        _loading = false;
        if (result.success) {
          _all = result.conversations;
          _applyFilter();
        } else if (_all.isEmpty) {
          _error = result.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (_all.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Failed to load conversations: $e';
        });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  void _applyFilter() {
    final q = _queryController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List.from(_all));
      return;
    }
    setState(() {
      _filtered = _all.where((c) {
        final name = (c.title).toLowerCase();
        final matchName = name.contains(q);
        if (matchName) return true;
        if (c.isGroup && c.name != null) {
          if (c.name!.toLowerCase().contains(q)) return true;
        }
        for (final p in c.participants) {
          final fn = p.user?.fullName ?? '';
          if (fn.toLowerCase().contains(q)) return true;
        }
        return false;
      }).toList();
    });
  }

  void _openChat(Conversation c) {
    Navigator.pushNamed(
      context,
      '/chat/${c.id}',
      arguments: c,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isActive = _contentFilter == value;
    return GestureDetector(
      onTap: () => _setContentFilter(value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final hasQuery = _queryController.text.trim().isNotEmpty;
    final hasConversations = _filtered.isNotEmpty;
    final hasMessages = _messageResults.isNotEmpty;
    final isEmpty = !hasConversations && !hasMessages && !_loading && !_searchingMessages;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: TextField(
          controller: _queryController,
          decoration: InputDecoration(
            hintText: s?.search ?? 'Search chats and groups',
            border: InputBorder.none,
          ),
          autofocus: true,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Zote', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Picha', 'image'),
                const SizedBox(width: 8),
                _buildFilterChip('Video', 'video'),
                const SizedBox(width: 8),
                _buildFilterChip('Viungo', 'links'),
                const SizedBox(width: 8),
                _buildFilterChip('Hati', 'document'),
                const SizedBox(width: 8),
                _buildFilterChip('Sauti', 'audio'),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && !hasConversations && !hasMessages
                    ? Center(child: Text(_error!, textAlign: TextAlign.center))
                    : isEmpty
                        ? Center(
                            child: Text(
                              !hasQuery
                                  ? (s?.noConversations ?? 'No conversations')
                                  : 'No results for "${_queryController.text}"',
                              style: const TextStyle(color: Color(0xFF666666)),
                            ),
                          )
                        : ListView(
                            children: [
                              // Conversations section
                              if (hasConversations && _contentFilter == 'all') ...[
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Text(
                                    'Mazungumzo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                                ..._filtered.map((c) => ListTile(
                                      leading: UserAvatar(
                                        photoUrl: c.avatarUrl,
                                        name: c.title,
                                        radius: 24,
                                      ),
                                      title: Text(
                                        c.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: c.isGroup
                                          ? Text('${c.participants.length} members')
                                          : null,
                                      onTap: () => _openChat(c),
                                    )),
                              ],
                              // Messages section
                              if (hasMessages) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Ujumbe',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (_searchingMessages)
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 1.5),
                                        ),
                                    ],
                                  ),
                                ),
                                ..._messageResults.map((m) => ListTile(
                                      leading: UserAvatar(
                                        photoUrl: m.sender?.profilePhotoUrl,
                                        name: m.sender?.fullName ?? 'User',
                                        radius: 24,
                                      ),
                                      title: Text(
                                        m.sender?.fullName ?? 'User',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        m.content ?? _messageTypeLabel(m.messageType),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF666666),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Text(
                                        _formatMessageTime(m.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/chat/${m.conversationId}',
                                        );
                                      },
                                    )),
                              ],
                              // Loading indicator for message search
                              if (_searchingMessages && !hasMessages)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  String _messageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'Picha';
      case MessageType.video:
        return 'Video';
      case MessageType.audio:
        return 'Sauti';
      case MessageType.document:
        return 'Hati';
      default:
        return 'Ujumbe';
    }
  }
}
