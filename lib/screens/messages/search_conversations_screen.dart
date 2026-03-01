// Smart search across chats and group names (MESSAGES.md).
import 'package:flutter/material.dart';
import '../../models/message_models.dart';
import '../../services/message_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _queryController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _queryController.removeListener(_applyFilter);
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() { _loading = true; _error = null; });
    final result = await _messageService.getConversations(
      userId: widget.currentUserId,
      perPage: 100,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _all = result.conversations;
        _applyFilter();
      } else {
        _error = result.message;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _queryController.text.isEmpty
                            ? (s?.noConversations ?? 'No conversations')
                            : 'No results for "${_queryController.text}"',
                        style: const TextStyle(color: Color(0xFF666666)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final c = _filtered[index];
                        return ListTile(
                          leading: UserAvatar(
                            photoUrl: c.avatarUrl,
                            name: c.title,
                            radius: 24,
                          ),
                          title: Text(c.title),
                          subtitle: c.isGroup
                              ? Text('${c.participants.length} members')
                              : null,
                          onTap: () => _openChat(c),
                        );
                      },
                    ),
    );
  }
}
