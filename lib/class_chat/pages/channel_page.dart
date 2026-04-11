// lib/class_chat/pages/channel_page.dart
import 'package:flutter/material.dart';
import '../models/class_chat_models.dart';
import '../services/class_chat_service.dart';
import '../widgets/chat_bubble.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ChannelPage extends StatefulWidget {
  final ClassChannel channel;
  final int userId;
  const ChannelPage({super.key, required this.channel, required this.userId});
  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  final ClassChatService _service = ClassChatService();
  final _msgC = TextEditingController();
  final _scrollC = ScrollController();
  List<ClassChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final result = await _service.getMessages(channelId: widget.channel.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _messages = result.items.reversed.toList();
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgC.text.trim();
    if (text.isEmpty) return;
    _msgC.clear();
    setState(() => _isSending = true);
    final result = await _service.sendMessage(channelId: widget.channel.id, body: text);
    if (mounted) {
      setState(() => _isSending = false);
      if (result.success && result.data != null) {
        setState(() => _messages.add(result.data!));
        _scrollC.animateTo(_scrollC.position.maxScrollExtent + 60, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.channel.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text(widget.channel.type.subtitle, style: const TextStyle(fontSize: 11, color: _kSecondary)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
              : _messages.isEmpty
                  ? const Center(child: Text('Hakuna ujumbe bado / No messages yet', style: TextStyle(color: _kSecondary)))
                  : ListView.builder(
                      controller: _scrollC,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => ChatBubble(message: _messages[i], isMe: _messages[i].senderId == widget.userId),
                    ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _msgC,
                  decoration: const InputDecoration(hintText: 'Andika ujumbe...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                    : const Icon(Icons.send_rounded, color: _kPrimary),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
