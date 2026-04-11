// lib/newton/pages/conversation_history_page.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';
import '../services/newton_service.dart';
import '../widgets/subject_chip.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ConversationHistoryPage extends StatefulWidget {
  final int userId;
  final bool isSwahili;
  const ConversationHistoryPage({
    super.key,
    required this.userId,
    this.isSwahili = false,
  });
  @override
  State<ConversationHistoryPage> createState() =>
      _ConversationHistoryPageState();
}

class _ConversationHistoryPageState extends State<ConversationHistoryPage> {
  final NewtonService _service = NewtonService();
  final _searchC = TextEditingController();
  List<NewtonConversation> _conversations = [];
  List<NewtonConversation> _filtered = [];
  bool _isLoading = true;
  SubjectMode? _filterSubject;

  @override
  void initState() {
    super.initState();
    _load();
    _searchC.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getConversations(subject: _filterSubject);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _conversations = result.items;
        _applyFilter();
      }
    });
  }

  void _applyFilter() {
    final query = _searchC.text.trim().toLowerCase();
    setState(() {
      _filtered = _conversations.where((c) {
        final matchesSearch =
            query.isEmpty || c.title.toLowerCase().contains(query);
        final matchesSubject =
            _filterSubject == null || c.subject == _filterSubject;
        return matchesSearch && matchesSubject;
      }).toList();
    });
  }

  Future<void> _deleteConversation(NewtonConversation conv) async {
    final sw = widget.isSwahili;
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          sw ? 'Futa mazungumzo?' : 'Delete conversation?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          sw
              ? 'Mazungumzo haya yatafutwa kabisa.'
              : 'This conversation will be permanently deleted.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await _service.deleteConversation(conv.id);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _conversations.removeWhere((c) => c.id == conv.id);
        _applyFilter();
      });
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Imefutwa' : 'Deleted'),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  Future<void> _toggleBookmark(NewtonConversation conv) async {
    final sw = widget.isSwahili;
    final newVal = !conv.isBookmarked;
    try {
      final result = await _service.bookmarkConversation(conv.id, bookmark: newVal);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          final idx = _conversations.indexWhere((c) => c.id == conv.id);
          if (idx != -1) {
            _conversations[idx] =
                _conversations[idx].copyWith(isBookmarked: newVal);
            _applyFilter();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sw
                ? 'Imeshindwa kuhifadhi. Jaribu tena.'
                : 'Failed to bookmark. Please try again.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sw
              ? 'Hitilafu imetokea. Jaribu tena.'
              : 'An error occurred. Please try again.'),
        ),
      );
    }
  }

  void _openConversation(NewtonConversation conv) async {
    final result = await _service.getMessages(conv.id);
    if (!mounted) return;
    if (result.success && result.items.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ConversationDetailPage(
            conversation: conv,
            messages: result.items,
            isSwahili: widget.isSwahili,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSwahili
              ? 'Hakuna ujumbe'
              : 'No messages found'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Historia ya mazungumzo' : 'Conversation history',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchC,
              decoration: InputDecoration(
                hintText: sw ? 'Tafuta...' : 'Search...',
                hintStyle: const TextStyle(fontSize: 14, color: _kSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: _kSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // Subject filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(sw ? 'Zote' : 'All',
                        style: TextStyle(
                            fontSize: 11,
                            color: _filterSubject == null
                                ? Colors.white
                                : _kPrimary)),
                    selected: _filterSubject == null,
                    selectedColor: _kPrimary,
                    onSelected: (_) {
                      setState(() => _filterSubject = null);
                      _applyFilter();
                    },
                  ),
                ),
                ...SubjectMode.values.map((s) => SubjectChip(
                      subject: s,
                      selected: _filterSubject == s,
                      isSwahili: sw,
                      onSelected: (v) {
                        setState(() => _filterSubject = v);
                        _applyFilter();
                      },
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_rounded,
                                size: 48, color: _kSecondary),
                            const SizedBox(height: 8),
                            Text(
                              sw ? 'Hakuna mazungumzo' : 'No conversations',
                              style: const TextStyle(color: _kSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final c = _filtered[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _kPrimary.withValues(alpha: 0.08),
                                  child: Icon(subjectIcon(c.subject),
                                      color: _kPrimary, size: 20),
                                ),
                                title: Text(
                                  c.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${sw ? c.subject.displayNameSw : c.subject.displayName} · ${c.messageCount} ${sw ? "ujumbe" : "messages"}',
                                  style: const TextStyle(
                                      fontSize: 12, color: _kSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (c.isBookmarked)
                                      Icon(Icons.bookmark_rounded,
                                          size: 16,
                                          color: Colors.amber.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${c.lastMessageAt.day}/${c.lastMessageAt.month}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _kSecondary),
                                    ),
                                  ],
                                ),
                                onTap: () => _openConversation(c),
                                onLongPress: () => _showActions(c),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showActions(NewtonConversation conv) {
    final sw = widget.isSwahili;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                conv.isBookmarked
                    ? Icons.bookmark_remove_rounded
                    : Icons.bookmark_add_rounded,
                color: _kPrimary,
              ),
              title: Text(
                conv.isBookmarked
                    ? (sw ? 'Ondoa alama' : 'Remove bookmark')
                    : (sw ? 'Hifadhi' : 'Bookmark'),
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _toggleBookmark(conv);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(
                sw ? 'Futa' : 'Delete',
                style: const TextStyle(fontSize: 14, color: Colors.red),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _deleteConversation(conv);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Conversation detail (read-only view) ────────────────────

class _ConversationDetailPage extends StatelessWidget {
  final NewtonConversation conversation;
  final List<NewtonMessage> messages;
  final bool isSwahili;

  const _ConversationDetailPage({
    required this.conversation,
    required this.messages,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          conversation.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (_, i) {
          final msg = messages[i];
          return Align(
            alignment:
                msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8),
              decoration: BoxDecoration(
                color: msg.isUser ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: msg.isUser ? Radius.zero : null,
                  bottomLeft: !msg.isUser ? Radius.zero : null,
                ),
                border: msg.isUser
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!msg.isUser) ...[
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 6),
                        Text('Newton',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  SelectableText(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: msg.isUser ? Colors.white : _kPrimary,
                      height: 1.5,
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
}
