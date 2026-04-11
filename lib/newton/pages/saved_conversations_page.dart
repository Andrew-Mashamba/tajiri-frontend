// lib/newton/pages/saved_conversations_page.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';
import '../services/newton_service.dart';
import '../widgets/subject_chip.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SavedConversationsPage extends StatefulWidget {
  final int userId;
  final bool isSwahili;
  const SavedConversationsPage({
    super.key,
    required this.userId,
    this.isSwahili = false,
  });
  @override
  State<SavedConversationsPage> createState() =>
      _SavedConversationsPageState();
}

class _SavedConversationsPageState extends State<SavedConversationsPage> {
  final NewtonService _service = NewtonService();
  List<NewtonConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result =
        await _service.getConversations(bookmarkedOnly: true);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _conversations = result.items;
    });
  }

  Future<void> _unbookmark(NewtonConversation conv) async {
    await _service.bookmarkConversation(conv.id, bookmark: false);
    if (!mounted) return;
    setState(() {
      _conversations.removeWhere((c) => c.id == conv.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isSwahili
            ? 'Alama imeondolewa'
            : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openConversation(NewtonConversation conv) async {
    final result = await _service.getMessages(conv.id);
    if (!mounted) return;
    if (result.success && result.items.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _SavedConversationDetail(
            conversation: conv,
            messages: result.items,
            isSwahili: widget.isSwahili,
          ),
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
          sw ? 'Zilizohifadhiwa' : 'Saved conversations',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_border_rounded,
                          size: 48, color: _kSecondary),
                      const SizedBox(height: 8),
                      Text(
                        sw
                            ? 'Hakuna mazungumzo yaliyohifadhiwa'
                            : 'No saved conversations',
                        style: const TextStyle(color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sw
                            ? 'Bonyeza alama ya hifadhi kwenye mazungumzo kuyahifadhi'
                            : 'Bookmark conversations to save them here',
                        style:
                            const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (_, i) {
                      final c = _conversations[i];
                      return Dismissible(
                        key: ValueKey(c.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          child:
                              const Icon(Icons.bookmark_remove_rounded,
                                  color: Colors.red),
                        ),
                        onDismissed: (_) => _unbookmark(c),
                        child: Container(
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
                            trailing: Icon(Icons.bookmark_rounded,
                                size: 18, color: Colors.amber.shade700),
                            onTap: () => _openConversation(c),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _SavedConversationDetail extends StatelessWidget {
  final NewtonConversation conversation;
  final List<NewtonMessage> messages;
  final bool isSwahili;

  const _SavedConversationDetail({
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
        title: Text(conversation.title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
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
              child: SelectableText(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  color: msg.isUser ? Colors.white : _kPrimary,
                  height: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
