import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

class _MockProduct {
  final String name;
  final String price;
  final String category;
  final int likes;
  const _MockProduct(this.name, this.price, this.category, this.likes);
}

class _MockPost {
  final String caption;
  final String productName;
  final String productPrice;
  final int likes;
  final int views;
  const _MockPost(this.caption, this.productName, this.productPrice,
      this.likes, this.views);
}

class _MockSession {
  final String title;
  final String dateLabel;
  final int productCount;
  final int viewerCount;
  final bool isPast;
  const _MockSession(this.title, this.dateLabel, this.productCount,
      this.viewerCount, this.isPast);
}

/// Creator's social storefront — products, posts and live sessions.
class CreatorShopScreen extends StatefulWidget {
  const CreatorShopScreen({super.key, this.creatorId});

  final int? creatorId;

  @override
  State<CreatorShopScreen> createState() => _CreatorShopScreenState();
}

class _CreatorShopScreenState extends State<CreatorShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _following = false;

  final List<_MockProduct> _products = const [
    _MockProduct('Blue Leso Fabric', 'TZS 18,500', 'Textiles', 124),
    _MockProduct('Handmade Leather Bag', 'TZS 72,000', 'Accessories', 89),
    _MockProduct('Kitenge Dress', 'TZS 45,000', 'Fashion', 211),
    _MockProduct('Wooden Bowl Set', 'TZS 32,000', 'Homewares', 56),
    _MockProduct('Beaded Bracelet', 'TZS 9,500', 'Jewellery', 304),
    _MockProduct('Sisal Basket', 'TZS 14,000', 'Homewares', 77),
  ];

  final List<_MockPost> _posts = const [
    _MockPost('New arrivals just dropped — limited stock!', 'Blue Leso Fabric',
        'TZS 18,500', 412, 3200),
    _MockPost('Handcrafted with love. Every piece is unique.',
        'Wooden Bowl Set', 'TZS 32,000', 189, 1540),
    _MockPost('Style that travels with you anywhere.',
        'Handmade Leather Bag', 'TZS 72,000', 530, 4800),
    _MockPost('Bold colours, bold you. #Kitenge', 'Kitenge Dress',
        'TZS 45,000', 872, 7100),
  ];

  final List<_MockSession> _sessions = const [
    _MockSession('Leso Fabric Showcase', 'Sat 10 May · 6 PM', 8, 300, false),
    _MockSession('Flash Sale Live!', 'Sun 11 May · 8 PM', 12, 500, false),
    _MockSession('New Spring Collection', '28 Apr 2026', 10, 1240, true),
    _MockSession('Accessories Unboxing', '14 Apr 2026', 6, 890, true),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            scrolledUnderElevation: 1,
            foregroundColor: _kText,
            pinned: true,
            title: const Text(
              'Creator Shop',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: _kText),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: _kText),
                onPressed: () {},
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(180),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  TabBar(
                    controller: _tabs,
                    labelColor: _kText,
                    unselectedLabelColor: _kMuted,
                    indicatorColor: _kText,
                    indicatorWeight: 2,
                    tabs: const [
                      Tab(text: 'Products'),
                      Tab(text: 'Posts'),
                      Tab(text: 'Live'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: SafeArea(
          top: false,
          child: TabBarView(
            controller: _tabs,
            children: [
              _ProductsTab(products: _products),
              _PostsTab(posts: _posts),
              _LiveTab(sessions: _sessions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE0E0E0),
              border: Border.all(color: _kDivider, width: 1.5),
            ),
            child: const Icon(Icons.person_rounded, size: 32, color: _kMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Amina Designs',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kText),
                ),
                const SizedBox(height: 2),
                const Text(
                  '@aminadesigns · Dar es Salaam',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statChip('4.2K', 'Followers'),
                    const SizedBox(width: 16),
                    _statChip('6', 'Products'),
                    const SizedBox(width: 16),
                    _statChip('98%', 'Rating'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _following = !_following),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: _following ? _kBg : _kText,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _kText),
              ),
              child: Center(
                child: Text(
                  _following ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _following ? _kText : _kSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kText)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: _kMuted)),
      ],
    );
  }
}

// ── Products tab ──────────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.products});
  final List<_MockProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _EmptyState(
        icon: Icons.shopping_bag_rounded,
        title: 'No products yet',
        subtitle: 'This creator has not listed any products.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) => _ProductGridCard(product: products[i]),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({required this.product});
  final _MockProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEE),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(Icons.image_rounded, size: 48, color: _kMuted),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                      height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  product.price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kText),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 12, color: _kFaint),
                    const SizedBox(width: 3),
                    Text(
                      '${product.likes}',
                      style:
                          const TextStyle(fontSize: 11, color: _kFaint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Posts tab ─────────────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.posts});
  final List<_MockPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _EmptyState(
        icon: Icons.post_add_rounded,
        title: 'No posts yet',
        subtitle: 'This creator has not shared any posts.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      separatorBuilder: (_, i) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _PostCard(post: posts[i]),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final _MockPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFFEEEEEE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Icon(Icons.image_rounded, size: 56, color: _kMuted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: _kText, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kDivider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_rounded,
                          size: 14, color: _kMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kText),
                        ),
                      ),
                      Text(
                        post.productPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 14, color: _kFaint),
                    const SizedBox(width: 4),
                    Text('${post.likes}',
                        style: const TextStyle(
                            fontSize: 12, color: _kFaint)),
                    const SizedBox(width: 14),
                    const Icon(Icons.visibility_rounded,
                        size: 14, color: _kFaint),
                    const SizedBox(width: 4),
                    Text('${post.views}',
                        style: const TextStyle(
                            fontSize: 12, color: _kFaint)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live tab ──────────────────────────────────────────────────────────────────

class _LiveTab extends StatelessWidget {
  const _LiveTab({required this.sessions});
  final List<_MockSession> sessions;

  @override
  Widget build(BuildContext context) {
    final upcoming = sessions.where((s) => !s.isPast).toList();
    final past = sessions.where((s) => s.isPast).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (upcoming.isNotEmpty) ...[
          _SectionHeader(title: 'Upcoming Sessions'),
          const SizedBox(height: 8),
          ...upcoming.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionCard(session: s),
              )),
          const SizedBox(height: 8),
        ],
        if (past.isNotEmpty) ...[
          _SectionHeader(title: 'Past Sessions'),
          const SizedBox(height: 8),
          ...past.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionCard(session: s),
              )),
        ],
        if (upcoming.isEmpty && past.isEmpty)
          _EmptyState(
            icon: Icons.live_tv_rounded,
            title: 'No live sessions',
            subtitle: 'This creator has not hosted any live shopping sessions.',
          ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final _MockSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.live_tv_rounded,
                size: 24, color: _kMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kText),
                ),
                const SizedBox(height: 2),
                Text(
                  session.dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_rounded,
                        size: 12, color: _kFaint),
                    const SizedBox(width: 3),
                    Text('${session.productCount} products',
                        style: const TextStyle(
                            fontSize: 11, color: _kFaint)),
                    const SizedBox(width: 10),
                    const Icon(Icons.visibility_rounded,
                        size: 12, color: _kFaint),
                    const SizedBox(width: 3),
                    Text('${session.viewerCount}',
                        style: const TextStyle(
                            fontSize: 11, color: _kFaint)),
                  ],
                ),
              ],
            ),
          ),
          if (!session.isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kText,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Remind',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kSurface),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: _kText),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

