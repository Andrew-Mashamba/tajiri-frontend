import 'package:flutter/material.dart';
import '../../models/page_models.dart';
import '../../models/post_models.dart';
import '../../services/page_service.dart';
import '../../widgets/post_card.dart';

// Design: DOCS/DESIGN.md – monochrome, touch targets 48dp min
const Color _background = Color(0xFFFAFAFA);
const Color _primaryText = Color(0xFF1A1A1A);
const Color _secondaryText = Color(0xFF666666);

class PageDetailScreen extends StatefulWidget {
  final int pageId;
  final int currentUserId;

  const PageDetailScreen({
    super.key,
    required this.pageId,
    required this.currentUserId,
  });

  @override
  State<PageDetailScreen> createState() => _PageDetailScreenState();
}

class _PageDetailScreenState extends State<PageDetailScreen> with SingleTickerProviderStateMixin {
  final PageService _pageService = PageService();
  late TabController _tabController;

  PageModel? _page;
  List<Post> _posts = [];
  List<PageReview> _reviews = [];
  double? _averageRating;
  bool _isLoading = true;
  bool _isFollowActioning = false;
  bool _isLikeActioning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPage() async {
    setState(() => _isLoading = true);
    final result = await _pageService.getPage(
      widget.pageId.toString(),
      currentUserId: widget.currentUserId,
    );
    if (mounted && result.success) {
      setState(() {
        _page = result.page;
        _isLoading = false;
      });
      _loadPosts();
      _loadReviews();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPosts() async {
    final result = await _pageService.getPagePosts(widget.pageId);
    if (mounted && result.success) {
      setState(() => _posts = result.posts);
    }
  }

  Future<void> _loadReviews() async {
    final result = await _pageService.getReviews(widget.pageId);
    if (mounted && result.success) {
      setState(() {
        _reviews = result.reviews;
        _averageRating = result.averageRating;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_page == null || _isLikeActioning) return;
    setState(() => _isLikeActioning = true);
    final wasLiked = _page!.isLiked == true;
    try {
      final result = wasLiked
          ? await _pageService.unlikePage(widget.pageId, widget.currentUserId)
          : await _pageService.likePage(widget.pageId, widget.currentUserId);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _page = _page!.copyWith(
            isLiked: !wasLiked,
            likesCount: result.likesCount ?? _page!.likesCount + (wasLiked ? -1 : 1),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kusasisha. Jaribu tena.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imeshindwa kusasisha pendo. Jaribu tena.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLikeActioning = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_page == null || _isFollowActioning) return;
    setState(() => _isFollowActioning = true);
    final wasFollowing = _page!.isFollowing == true;
    try {
      final result = wasFollowing
          ? await _pageService.unfollowPage(widget.pageId, widget.currentUserId)
          : await _pageService.followPage(widget.pageId, widget.currentUserId);
      if (!mounted) return;
      if (result.success) {
        setState(() {
          _page = _page!.copyWith(
            isFollowing: !wasFollowing,
            followersCount: result.followersCount ?? _page!.followersCount + (wasFollowing ? -1 : 1),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kusasisha ufuatiliaji. Jaribu tena.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imeshindwa kusasisha ufuatiliaji. Jaribu tena.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFollowActioning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(backgroundColor: _background, foregroundColor: _primaryText),
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_page == null) {
      return Scaffold(
        backgroundColor: _background,
        appBar: AppBar(backgroundColor: _background, foregroundColor: _primaryText),
        body: SafeArea(
          child: Center(
            child: Text('Ukurasa haupatikani', style: const TextStyle(color: _primaryText)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _page!.coverPhotoUrl != null
                        ? Image.network(_page!.coverPhotoUrl!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF999999),
                            child: Icon(Icons.storefront, size: 64, color: _background),
                          ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _page!.profilePhotoUrl != null
                                ? NetworkImage(_page!.profilePhotoUrl!)
                                : null,
                            backgroundColor: Colors.white,
                            child: _page!.profilePhotoUrl == null
                                ? Icon(Icons.storefront, size: 40, color: _secondaryText)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: _primaryText,
                  unselectedLabelColor: _secondaryText,
                  tabs: const [
                    Tab(text: 'Machapisho'),
                    Tab(text: 'Kuhusu'),
                    Tab(text: 'Tathmini'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildAboutTab(),
            _buildReviewsTab(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _page!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_page!.isVerified)
                const Icon(Icons.verified, color: _secondaryText, size: 24),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _page!.category,
            style: const TextStyle(color: _secondaryText, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined, size: 16, color: _secondaryText),
              const SizedBox(width: 4),
              Text(
                '${_page!.likesCount} wanaopenda',
                style: const TextStyle(color: _secondaryText, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.people_outline, size: 16, color: _secondaryText),
              const SizedBox(width: 4),
              Text(
                '${_page!.followersCount} wafuatiliaji',
                style: const TextStyle(color: _secondaryText, fontSize: 12),
              ),
            ],
          ),
          if (_averageRating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < _averageRating!.round() ? Icons.star : Icons.star_border,
                    size: 18,
                    color: _primaryText,
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  _averageRating!.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryText),
                ),
                Text(
                  ' (${_reviews.length} tathmini)',
                  style: const TextStyle(color: _secondaryText, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: InkWell(
                      onTap: _isLikeActioning ? null : _toggleLike,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLikeActioning)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(
                                _page!.isLiked == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                                color: _primaryText,
                                size: 24,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _page!.isLiked == true ? 'Umependia' : 'Penda',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: InkWell(
                      onTap: _isFollowActioning ? null : _toggleFollow,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isFollowActioning)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(
                                _page!.isFollowing == true ? Icons.check : Icons.add,
                                color: _primaryText,
                                size: 24,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _page!.isFollowing == true ? 'Unafuatilia' : 'Fuatilia',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return const Center(child: Text('Hakuna machapisho'));
    }
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostCard(
            post: _posts[index],
            currentUserId: widget.currentUserId,
            onLike: () {},
            onComment: () {},
            onShare: () {},
            onUserTap: () {},
            onMenuTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_page!.description != null) ...[
            const Text('Kuhusu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_page!.description!),
            const SizedBox(height: 24),
          ],
          _buildInfoTile(Icons.category, 'Aina', _page!.category),
          if (_page!.address != null) _buildInfoTile(Icons.location_on, 'Mahali', _page!.address!),
          if (_page!.phone != null) _buildInfoTile(Icons.phone, 'Simu', _page!.phone!),
          if (_page!.email != null) _buildInfoTile(Icons.email, 'Barua pepe', _page!.email!),
          if (_page!.website != null) _buildInfoTile(Icons.language, 'Tovuti', _page!.website!),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddReviewDialog(),
            icon: const Icon(Icons.rate_review),
            label: const Text('Andika Tathmini'),
          ),
        ),
        Expanded(
          child: _reviews.isEmpty
              ? const Center(child: Text('Hakuna tathmini'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(PageReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.user?.profilePhotoPath != null
                      ? NetworkImage(review.user!.profilePhotoPath!)
                      : null,
                  child: review.user?.profilePhotoPath == null
                      ? Text(review.user?.firstName[0] ?? '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.user?.fullName ?? 'Mtumiaji',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.content != null) ...[
              const SizedBox(height: 8),
              Text(review.content!),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    int rating = 5;
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Andika Tathmini'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Andika maoni yako...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ghairi'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pageService.addReview(
                  widget.pageId,
                  widget.currentUserId,
                  rating,
                  content: contentController.text.trim().isNotEmpty
                      ? contentController.text.trim()
                      : null,
                );
                _loadReviews();
              },
              child: const Text('Tuma'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
