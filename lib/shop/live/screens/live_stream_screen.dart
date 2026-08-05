import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

const Color _kText = Color(0xFF1A1A1A);

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key, this.streamId});

  final String? streamId;

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  late Timer _heartTimer;
  final List<_FloatingHeart> _hearts = [];
  final Random _rng = Random();

  final List<_ChatEntry> _messages = [
    _ChatEntry('Amina', 'This is amazing! ❤️'),
    _ChatEntry('John_K', 'Where can I buy this?'),
    _ChatEntry('Fatuma_S', 'Great product!'),
    _ChatEntry('David', 'How much does it cost?'),
    _ChatEntry('Grace', 'Shipping to Nairobi?'),
  ];

  final int _viewerCount = 1247;

  final _pinnedProducts = const [
    _PinnedProduct('Kikoy Fabric', 45000),
    _PinnedProduct('Beaded Necklace', 35000),
    _PinnedProduct('Sisal Basket', 25000),
    _PinnedProduct('Carved Bowl', 60000),
  ];

  @override
  void initState() {
    super.initState();
    _heartTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _hearts.add(_FloatingHeart(
          id: DateTime.now().millisecondsSinceEpoch,
          x: _rng.nextDouble(),
        ));
        if (_hearts.length > 6) _hearts.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _chatScroll.dispose();
    _heartTimer.cancel();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatEntry('You', text));
      _commentController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatTzs(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TZS ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildVideoArea(),
            _buildTopOverlay(),
            _buildBottomContent(),
            ..._hearts.map(_buildHeart),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(
          Icons.videocam_rounded,
          size: 80,
          color: Color(0xFF444444),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.remove_red_eye_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatCount(_viewerCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'TajiriSeller',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomContent() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChatMessages(),
          _buildProductsStrip(),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    final visibleMessages =
        _messages.length > 6 ? _messages.sublist(_messages.length - 6) : _messages;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: visibleMessages
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${m.sender}: ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: m.message,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildProductsStrip() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _pinnedProducts.length,
        itemBuilder: (ctx, i) {
          final p = _pinnedProducts[i];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_rounded,
                    size: 24,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTzs(p.price),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      color: Colors.black54,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a comment…',
                hintStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _hearts.add(_FloatingHeart(
                  id: DateTime.now().millisecondsSinceEpoch,
                  x: _rng.nextDouble(),
                ));
              });
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white70,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sendComment,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: _kText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeart(_FloatingHeart heart) {
    return AnimatedPositioned(
      key: ValueKey(heart.id),
      duration: const Duration(milliseconds: 2000),
      left: MediaQuery.of(context).size.width * heart.x * 0.7 + 20,
      bottom: 120,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        builder: (ctx, v, child) => Opacity(
          opacity: (1.0 - v).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -60 * v),
            child: child,
          ),
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white70,
          size: 28,
        ),
      ),
    );
  }
}

class _ChatEntry {
  final String sender;
  final String message;
  _ChatEntry(this.sender, this.message);
}

class _PinnedProduct {
  final String name;
  final int price;
  const _PinnedProduct(this.name, this.price);
}

class _FloatingHeart {
  final int id;
  final double x;
  _FloatingHeart({required this.id, required this.x});
}
