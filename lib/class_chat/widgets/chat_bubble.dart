// lib/class_chat/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import '../models/class_chat_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ChatBubble extends StatelessWidget {
  final ClassChatMessage message;
  final bool isMe;
  const ChatBubble({super.key, required this.message, required this.isMe});

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'sasa';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isMe ? Radius.zero : null,
            bottomLeft: !isMe ? Radius.zero : null,
          ),
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!isMe) ...[
            Text(message.senderName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isMe ? Colors.white70 : _kPrimary)),
            const SizedBox(height: 2),
          ],
          if (message.isPinned) Row(children: [
            Icon(Icons.push_pin_rounded, size: 12, color: isMe ? Colors.white54 : _kSecondary),
            const SizedBox(width: 4),
            Text('Imebandikwa', style: TextStyle(fontSize: 10, color: isMe ? Colors.white54 : _kSecondary)),
          ]),
          Text(message.body, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : _kPrimary, height: 1.4)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (message.isQuestion) Icon(Icons.help_outline_rounded, size: 12, color: isMe ? Colors.white54 : _kSecondary),
            if (message.isQuestion) const SizedBox(width: 4),
            Text(_timeAgo(message.createdAt), style: TextStyle(fontSize: 10, color: isMe ? Colors.white54 : _kSecondary)),
          ]),
        ]),
      ),
    );
  }
}
