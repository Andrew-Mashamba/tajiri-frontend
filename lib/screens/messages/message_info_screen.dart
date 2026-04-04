import 'package:flutter/material.dart';
import '../../models/message_models.dart';
import '../../services/message_service.dart';
import 'package:intl/intl.dart';

class MessageInfoScreen extends StatefulWidget {
  final int conversationId;
  final int messageId;
  final int currentUserId;
  final Message message;
  const MessageInfoScreen({
    super.key,
    required this.conversationId,
    required this.messageId,
    required this.currentUserId,
    required this.message,
  });

  @override
  State<MessageInfoScreen> createState() => _MessageInfoScreenState();
}

class _MessageInfoScreenState extends State<MessageInfoScreen> {
  List<MessageReceipt> _receipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    try {
      final receipts = await MessageService.getMessageReceipts(
        widget.conversationId,
        widget.messageId,
        widget.currentUserId,
      );
      if (mounted) {
        setState(() {
          _receipts = receipts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load receipts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final readBy = _receipts
        .where((r) => r.readAt != null && r.userId != widget.currentUserId)
        .toList();
    final deliveredTo = _receipts
        .where((r) => r.readAt == null && r.userId != widget.currentUserId)
        .toList();
    final df = DateFormat('MMM d, HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Message Info',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Message preview
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.message.content ?? widget.message.preview,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // Read by section
                if (readBy.isNotEmpty) ...[
                  Row(children: [
                    const Icon(Icons.done_all, size: 16, color: Color(0xFF2196F3)),
                    const SizedBox(width: 8),
                    Text(
                      'Read by (${readBy.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  ...readBy.map((r) => _receiptTile(r, df.format(r.readAt!))),
                  const SizedBox(height: 16),
                ],
                // Delivered to section
                if (deliveredTo.isNotEmpty) ...[
                  Row(children: [
                    const Icon(Icons.done_all, size: 16, color: Color(0xFF999999)),
                    const SizedBox(width: 8),
                    Text(
                      'Delivered to (${deliveredTo.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  ...deliveredTo.map((r) => _receiptTile(
                    r,
                    r.deliveredAt != null ? df.format(r.deliveredAt!) : 'Pending',
                  )),
                ],
                if (readBy.isEmpty && deliveredTo.isEmpty)
                  const Center(
                    child: Text(
                      'No delivery info available',
                      style: TextStyle(color: Color(0xFF999999)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _receiptTile(MessageReceipt r, String subtitle) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: () => Navigator.pushNamed(context, '/profile/${r.userId}'),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFE0E0E0),
        child: Text(
          (r.user?.firstName ?? '?')[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      title: Text(
        r.user?.fullName ?? 'User ${r.userId}',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
      ),
    );
  }
}
