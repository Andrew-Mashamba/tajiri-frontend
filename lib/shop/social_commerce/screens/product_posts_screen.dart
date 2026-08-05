import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kText = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF666666);
const Color _kFaint = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

enum _PostStatus { published, draft, archived }

class _ProductPost {
  final String title;
  final String productName;
  final int likes;
  final int views;
  final _PostStatus status;
  const _ProductPost(
      this.title, this.productName, this.likes, this.views, this.status);
}

/// Manage shoppable product posts — create, filter, edit, boost.
class ProductPostsScreen extends StatefulWidget {
  const ProductPostsScreen({super.key});

  @override
  State<ProductPostsScreen> createState() => _ProductPostsScreenState();
}

class _ProductPostsScreenState extends State<ProductPostsScreen> {
  int _filterIdx = 0;
  final List<String> _filters = ['All', 'Published', 'Draft', 'Archived'];

  final List<_ProductPost> _allPosts = const [
    _ProductPost('New arrivals drop!', 'Blue Leso Fabric', 412, 3200,
        _PostStatus.published),
    _ProductPost('Handcrafted with love', 'Wooden Bowl Set', 189, 1540,
        _PostStatus.published),
    _ProductPost('Style that travels', 'Handmade Leather Bag', 530, 4800,
        _PostStatus.published),
    _ProductPost('Bold colours, bold you', 'Kitenge Dress', 872, 7100,
        _PostStatus.published),
    _ProductPost('Draft: Summer collection', 'Beaded Bracelet', 0, 0,
        _PostStatus.draft),
    _ProductPost('Draft: Homewares promo', 'Sisal Basket', 0, 0,
        _PostStatus.draft),
    _ProductPost('Old spring campaign', 'Kitenge Dress', 210, 1900,
        _PostStatus.archived),
  ];

  List<_ProductPost> get _filtered {
    switch (_filterIdx) {
      case 1:
        return _allPosts
            .where((p) => p.status == _PostStatus.published)
            .toList();
      case 2:
        return _allPosts
            .where((p) => p.status == _PostStatus.draft)
            .toList();
      case 3:
        return _allPosts
            .where((p) => p.status == _PostStatus.archived)
            .toList();
      default:
        return _allPosts;
    }
  }

  void _showPostActions(BuildContext ctx, _ProductPost post) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kText),
              ),
            ),
            const Divider(height: 1),
            _ActionTile(
              icon: Icons.edit_rounded,
              label: 'Edit Post',
              onTap: () => Navigator.pop(ctx),
            ),
            _ActionTile(
              icon: Icons.rocket_launch_rounded,
              label: 'Boost Post',
              onTap: () => Navigator.pop(ctx),
            ),
            if (post.status == _PostStatus.published)
              _ActionTile(
                icon: Icons.archive_rounded,
                label: 'Archive',
                onTap: () => Navigator.pop(ctx),
              ),
            if (post.status == _PostStatus.draft)
              _ActionTile(
                icon: Icons.publish_rounded,
                label: 'Publish',
                onTap: () => Navigator.pop(ctx),
              ),
            _ActionTile(
              icon: Icons.delete_rounded,
              label: 'Delete',
              color: Colors.red.shade600,
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filtered;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Product Posts',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kText),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _kText,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text(
                    'Create Post',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSurface),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterRow(),
            Expanded(
              child: posts.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: _kText,
                      onRefresh: () async => await Future.delayed(
                          const Duration(milliseconds: 600)),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (ctx, i) => GestureDetector(
                          onLongPress: () =>
                              _showPostActions(ctx, posts[i]),
                          child: _PostGridCard(post: posts[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, i) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final selected = _filterIdx == i;
            return GestureDetector(
              onTap: () => setState(() => _filterIdx = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: selected ? _kText : _kBg,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                      color: selected ? _kText : _kDivider),
                ),
                child: Center(
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? _kSurface : _kMuted,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.post_add_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No posts here',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first product post to\nstart selling socially.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _PostGridCard extends StatelessWidget {
  const _PostGridCard({required this.post});
  final _ProductPost post;

  Color get _statusColor {
    switch (post.status) {
      case _PostStatus.published:
        return const Color(0xFF388E3C);
      case _PostStatus.draft:
        return _kMuted;
      case _PostStatus.archived:
        return const Color(0xFF9E9E9E);
    }
  }

  String get _statusLabel {
    switch (post.status) {
      case _PostStatus.published:
        return 'Published';
      case _PostStatus.draft:
        return 'Draft';
      case _PostStatus.archived:
        return 'Archived';
    }
  }

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
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEEEEE),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_rounded,
                        size: 48, color: _kMuted),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                      height: 1.3),
                ),
                const SizedBox(height: 3),
                Text(
                  post.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: _kMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 11, color: _kFaint),
                    const SizedBox(width: 3),
                    Text('${post.likes}',
                        style: const TextStyle(
                            fontSize: 11, color: _kFaint)),
                    const SizedBox(width: 8),
                    const Icon(Icons.visibility_rounded,
                        size: 11, color: _kFaint),
                    const SizedBox(width: 3),
                    Text('${post.views}',
                        style: const TextStyle(
                            fontSize: 11, color: _kFaint)),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color = _kText});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, color: color),
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      minVerticalPadding: 0,
    );
  }
}
