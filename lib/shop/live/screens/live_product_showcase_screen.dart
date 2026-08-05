import 'dart:async';

import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSubtext = Color(0xFF666666);

class LiveProductShowcaseScreen extends StatefulWidget {
  const LiveProductShowcaseScreen({super.key});

  @override
  State<LiveProductShowcaseScreen> createState() =>
      _LiveProductShowcaseScreenState();
}

class _LiveProductShowcaseScreenState
    extends State<LiveProductShowcaseScreen> {
  bool _loading = true;
  late Timer _shimmerTimer;
  int _featuredIndex = 0;
  final ScrollController _queueScroll = ScrollController();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  final _products = const [
    _ShowcaseProduct('Maasai Beaded Necklace', 45000, 'Jewelry'),
    _ShowcaseProduct('Kanga Print Dress', 35000, 'Clothing'),
    _ShowcaseProduct('Sisal Basket', 25000, 'Home Decor'),
    _ShowcaseProduct('Wood Carved Mask', 75000, 'Art'),
    _ShowcaseProduct('Tie-Dye Shirt', 20000, 'Clothing'),
  ];

  final List<_ChatMessage> _chatMessages = [
    _ChatMessage('Amina', 'This necklace is beautiful!'),
    _ChatMessage('John', 'What sizes are available?'),
    _ChatMessage('Fatuma', 'Can you ship to Mombasa?'),
    _ChatMessage('David', 'Price is fair!'),
  ];

  final int _viewerCount = 342;
  final int _likeCount = 1289;

  @override
  void initState() {
    super.initState();
    _shimmerTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _shimmerTimer.cancel();
    _queueScroll.dispose();
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _featureNext() {
    setState(() {
      _featuredIndex = (_featuredIndex + 1) % _products.length;
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(_ChatMessage('You', text));
      _chatController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
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
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Product Showcase',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: _refresh,
          child: _loading ? _buildShimmer() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (_) => Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildStatsBar(),
              const SizedBox(height: 12),
              _buildFeaturedProduct(),
              const SizedBox(height: 16),
              _buildProductQueue(),
              const SizedBox(height: 16),
              _buildFeatureNextButton(),
              const SizedBox(height: 16),
              _buildChat(),
              const SizedBox(height: 8),
            ],
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Row(
      children: [
        _buildStatChip(
          Icons.remove_red_eye_rounded,
          '$_viewerCount viewers',
        ),
        const SizedBox(width: 8),
        _buildStatChip(Icons.favorite_rounded, '$_likeCount likes'),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _kText),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _kText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProduct() {
    final product = _products[_featuredIndex];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.image_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _kText,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Now Featuring',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: _kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.category,
                        style: const TextStyle(
                          color: _kSubtext,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTzs(product.price),
                        style: const TextStyle(
                          color: _kText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kText,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductQueue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Up Next',
          style: TextStyle(
            color: _kText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            controller: _queueScroll,
            scrollDirection: Axis.horizontal,
            itemCount: _products.length,
            itemBuilder: (ctx, i) {
              final p = _products[i];
              final isCurrent = i == _featuredIndex;
              return GestureDetector(
                onTap: () => setState(() => _featuredIndex = i),
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(color: _kText, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_rounded,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          _formatTzs(p.price),
                          style: TextStyle(
                            color: isCurrent ? _kText : _kSubtext,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _featureNext,
        icon: const Icon(Icons.skip_next_rounded, size: 20),
        label: const Text(
          'Feature Next Product',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kText),
          foregroundColor: _kText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Chat',
          style: TextStyle(
            color: _kText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.all(12),
            itemCount: _chatMessages.length,
            itemBuilder: (ctx, i) {
              final m = _chatMessages[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${m.sender}: ',
                        style: const TextStyle(
                          color: _kText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: m.message,
                        style: const TextStyle(
                          color: _kSubtext,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Say something…',
                hintStyle: const TextStyle(color: _kSubtext, fontSize: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kText,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseProduct {
  final String name;
  final int price;
  final String category;
  const _ShowcaseProduct(this.name, this.price, this.category);
}

class _ChatMessage {
  final String sender;
  final String message;
  _ChatMessage(this.sender, this.message);
}
