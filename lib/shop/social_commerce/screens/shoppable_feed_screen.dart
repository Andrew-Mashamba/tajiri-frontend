import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

class _Story {
  final String seller;
  final String tag;
  const _Story(this.seller, this.tag);
}

class _FeedPost {
  final String seller;
  final String caption;
  final String productName;
  final String productPrice;
  final int likes;
  final int comments;
  bool liked;
  bool saved;

  _FeedPost({
    required this.seller,
    required this.caption,
    required this.productName,
    required this.productPrice,
    required this.likes,
    required this.comments,
  })  : liked = false,
        saved = false;
}

/// Social feed with shoppable product posts.
class ShoppableFeedScreen extends StatefulWidget {
  const ShoppableFeedScreen({super.key});

  @override
  State<ShoppableFeedScreen> createState() => _ShoppableFeedScreenState();
}

class _ShoppableFeedScreenState extends State<ShoppableFeedScreen> {
  final List<_Story> _stories = const [
    _Story('Amina D.', 'Leso Fabric'),
    _Story('Juma Crafts', 'Baskets'),
    _Story('Zawadi Co.', 'Jewellery'),
    _Story('Mama Textiles', 'Kitenge'),
    _Story('Baraka Bags', 'Leather'),
    _Story('Nuru Studio', 'Art Prints'),
    _Story('Imani Fashion', 'Dresses'),
  ];

  final List<_FeedPost> _posts = [
    _FeedPost(
      seller: 'Amina Designs',
      caption: 'New arrivals just dropped — limited stock! ✨ #KitengeQueen',
      productName: 'Blue Leso Fabric',
      productPrice: 'TZS 18,500',
      likes: 412,
      comments: 34,
    ),
    _FeedPost(
      seller: 'Juma Crafts',
      caption:
          'Handcrafted with love — every piece tells a story. #MadeInTanzania',
      productName: 'Wooden Bowl Set',
      productPrice: 'TZS 32,000',
      likes: 189,
      comments: 19,
    ),
    _FeedPost(
      seller: 'Baraka Leather',
      caption: 'Style that travels with you anywhere. 🌍',
      productName: 'Handmade Leather Bag',
      productPrice: 'TZS 72,000',
      likes: 530,
      comments: 47,
    ),
    _FeedPost(
      seller: 'Zawadi Jewellery',
      caption: 'Shine in every season. Handbeaded by artisans. #AfricanStyle',
      productName: 'Beaded Bracelet Set',
      productPrice: 'TZS 9,500',
      likes: 304,
      comments: 25,
    ),
    _FeedPost(
      seller: 'Mama Textiles',
      caption: 'Bold colours, bold you. Sizes S–XL available. #Kitenge',
      productName: 'Kitenge Dress',
      productPrice: 'TZS 45,000',
      likes: 872,
      comments: 68,
    ),
  ];

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Shop Feed',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: _kText),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kText,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildStoriesRow(),
              ),
              const SliverToBoxAdapter(
                child: Divider(height: 1, color: _kDivider),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _FeedPostCard(
                    post: _posts[i],
                    onLike: () => setState(() {
                      _posts[i].liked = !_posts[i].liked;
                    }),
                    onSave: () => setState(() {
                      _posts[i].saved = !_posts[i].saved;
                    }),
                  ),
                  childCount: _posts.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesRow() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: _stories.length,
          separatorBuilder: (_, i) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) => _StoryBubble(story: _stories[i]),
        ),
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.story});
  final _Story story;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF424242), Color(0xFF1A1A1A)],
                ),
                border: Border.all(color: _kSurface, width: 2),
              ),
              child: const Icon(Icons.person_rounded,
                  size: 28, color: Colors.white54),
            ),
            const SizedBox(height: 4),
            Text(
              story.seller,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: _kText),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard(
      {required this.post, required this.onLike, required this.onSave});
  final _FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: _kSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEEEEEE),
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 18, color: _kMuted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.seller,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: 20, color: _kMuted),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          // Content image
          Container(
            width: double.infinity,
            height: 300,
            color: const Color(0xFFEEEEEE),
            child: const Center(
              child: Icon(Icons.image_rounded, size: 64, color: _kMuted),
            ),
          ),
          // Caption
          Padding(
            padding:
                const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Text(
              post.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: _kText, height: 1.45),
            ),
          ),
          // Product tag card
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kDivider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded,
                        size: 20, color: _kMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kText),
                        ),
                        Text(
                          post.productPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kText,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kSurface),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Engagement row
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
            child: Row(
              children: [
                _EngageButton(
                  icon: post.liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${post.likes + (post.liked ? 1 : 0)}',
                  active: post.liked,
                  onTap: onLike,
                ),
                _EngageButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.comments}',
                  active: false,
                  onTap: () {},
                ),
                _EngageButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  active: false,
                  onTap: () {},
                ),
                const Spacer(),
                _EngageButton(
                  icon: post.saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: '',
                  active: post.saved,
                  onTap: onSave,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kDivider),
        ],
      ),
    );
  }
}

class _EngageButton extends StatelessWidget {
  const _EngageButton(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: active ? _kText : _kFaint),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? _kText : _kFaint,
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.normal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
