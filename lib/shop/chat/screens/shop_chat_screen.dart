import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class _ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;

  _ChatMessage({required this.text, required this.isMe, required this.time});
}

class ShopChatScreen extends StatefulWidget {
  const ShopChatScreen({super.key, this.sellerId, this.productId});

  final int? sellerId;
  final int? productId;

  @override
  State<ShopChatScreen> createState() => _ShopChatScreenState();
}

class _ShopChatScreenState extends State<ShopChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isOtherTyping = false;

  late final List<_ChatMessage> _messages;

  static const String _sellerName = 'Shop Seller';
  static const String _productTitle = 'Product details';
  static const String _productPrice = 'TZS 2,500';

  @override
  void initState() {
    super.initState();
    final base = DateTime.now().subtract(const Duration(minutes: 10));
    _messages = [
      _ChatMessage(
        text: 'Hello! I\'m interested in this product. Is it still available?',
        isMe: true,
        time: base,
      ),
      _ChatMessage(
        text: 'Hi! Yes, it\'s available and ready to ship. Would you like more details?',
        isMe: false,
        time: base.add(const Duration(minutes: 1)),
      ),
      _ChatMessage(
        text: 'Can I get a discount if I buy 2?',
        isMe: true,
        time: base.add(const Duration(minutes: 3)),
      ),
      _ChatMessage(
        text: 'Sure! For 2 or more pieces, I can offer you 10% off. Let me know if that works.',
        isMe: false,
        time: base.add(const Duration(minutes: 4)),
      ),
    ];
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isMe: true, time: DateTime.now()));
      _isOtherTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _isOtherTyping = false;
      _messages.add(_ChatMessage(
        text: 'Thanks for your message! I\'ll get back to you shortly.',
        isMe: false,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE0E0E0),
              child: Text(
                _sellerName.isNotEmpty ? _sellerName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: _kText,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sellerId != null ? 'Seller #${widget.sellerId}' : _sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
            tooltip: 'More options',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.productId != null) _buildProductCard(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length + (_isOtherTyping ? 1 : 0) + 1,
                itemBuilder: (ctx, i) {
                  if (i == 0) {
                    return _buildDateDivider(_formatDate(_messages.first.time));
                  }
                  final msgIndex = i - 1;
                  if (_isOtherTyping && msgIndex == _messages.length) {
                    return _buildTypingBubble();
                  }
                  return _buildMessageBubble(_messages[msgIndex]);
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: _kSecondary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productId != null
                      ? 'Product #${widget.productId}'
                      : _productTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  _productPrice,
                  style: TextStyle(fontSize: 13, color: _kSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: _kText,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('View', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE0E0E0),
              child: Text(
                _sellerName[0].toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kText),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? _kText : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : _kText,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(msg.time),
                      style: const TextStyle(fontSize: 10, color: _kSecondary),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.done_all_rounded, size: 12, color: _kSecondary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFE0E0E0),
            child: Text(
              _sellerName[0].toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kText),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'typing…',
              style: TextStyle(fontSize: 13, color: _kSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(color: _kSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: _kText,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _sendMessage(_inputController.text),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
