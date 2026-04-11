// lib/class_chat/pages/class_chat_home_page.dart
import 'package:flutter/material.dart';
import '../models/class_chat_models.dart';
import '../services/class_chat_service.dart';
import 'channel_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ClassChatHomePage extends StatefulWidget {
  final int userId;
  final int? classId;
  const ClassChatHomePage({super.key, required this.userId, this.classId});
  @override
  State<ClassChatHomePage> createState() => _ClassChatHomePageState();
}

class _ClassChatHomePageState extends State<ClassChatHomePage> {
  final ClassChatService _service = ClassChatService();
  List<ClassChannel> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.classId != null) _loadChannels();
    else setState(() => _isLoading = false);
  }

  Future<void> _loadChannels() async {
    setState(() => _isLoading = true);
    final result = await _service.getChannels(widget.classId!);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _channels = result.items;
      });
    }
  }

  IconData _channelIcon(ChannelType type) {
    switch (type) {
      case ChannelType.general: return Icons.chat_rounded;
      case ChannelType.announcements: return Icons.campaign_rounded;
      case ChannelType.subject: return Icons.book_rounded;
      case ChannelType.qa: return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : widget.classId == null
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.forum_rounded, size: 48, color: _kSecondary),
                    SizedBox(height: 8),
                    Text('Chagua darasa kwanza', style: TextStyle(color: _kSecondary, fontSize: 14)),
                    Text('Select a class first', style: TextStyle(color: _kSecondary, fontSize: 12)),
                  ]))
                : RefreshIndicator(
                    onRefresh: _loadChannels,
                    color: _kPrimary,
                    child: ListView(padding: const EdgeInsets.all(16), children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
                        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.forum_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text('Gumzo la Darasa', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ]),
                          SizedBox(height: 6),
                          Text('Class Chat — channels & discussions', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      if (_channels.isEmpty)
                        Container(padding: const EdgeInsets.all(48), alignment: Alignment.center,
                          child: const Column(children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: _kSecondary),
                            SizedBox(height: 8),
                            Text('Hakuna channel bado / No channels yet', style: TextStyle(color: _kSecondary)),
                          ]),
                        )
                      else
                        ..._channels.map((ch) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: CircleAvatar(backgroundColor: _kPrimary.withValues(alpha: 0.08), child: Icon(_channelIcon(ch.type), color: _kPrimary, size: 20)),
                            title: Text(ch.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(ch.lastMessage ?? ch.type.subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: ch.unreadCount > 0 ? CircleAvatar(radius: 10, backgroundColor: _kPrimary, child: Text('${ch.unreadCount}', style: const TextStyle(fontSize: 10, color: Colors.white))) : null,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChannelPage(channel: ch, userId: widget.userId))),
                          ),
                        )),
                    ]),
                  ),
      ),
    );
  }
}
