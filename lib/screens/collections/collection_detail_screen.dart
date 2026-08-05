// lib/screens/collections/collection_detail_screen.dart
//
// UN-011 / posts.md row 60 (collection_view·curator) — opens a single
// curator's board, lists its items in a grid, and fires the view event
// once on first build. Tapping an item opens FullScreenPostViewer with
// referrer=collection so reference_revisit·author also fires (UN-016).
//
// Engineering playbook: monochrome (#1A1A1A primary), 48dp targets,
// _rounded icons, AppStringsScope bilingual, RefreshIndicator,
// empty/loading/error triumvirate, no FAB.

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../models/post_models.dart';
import '../../services/collection_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/post_service.dart';
import '../feed/full_screen_post_viewer_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  final int collectionId;
  final int currentUserId;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.currentUserId,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kSurface = Colors.white;
  static const _kBackground = Color(0xFFFAFAFA);
  static const _kIconBg = Color(0xFFF5F5F5);

  final CollectionService _service = CollectionService();
  final PostService _postService = PostService();
  Collection? _collection;
  List<Post> _items = const [];
  bool _loading = true;
  bool _viewRecorded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = (await LocalStorageService.getInstance()).getAuthToken();
    final col = await _service.get(widget.collectionId, token: token);
    if (!mounted) return;
    if (col == null) {
      setState(() {
        _loading = false;
        _error = 'Collection not found';
      });
      return;
    }
    final postIds = await _service.listItems(widget.collectionId, token: token);
    final posts = await _fetchPosts(postIds);

    if (!mounted) return;
    setState(() {
      _collection = col;
      _items = posts;
      _loading = false;
    });

    // UN-011 / row 60 — collection_view·curator. Fire once per session.
    if (!_viewRecorded) {
      _viewRecorded = true;
      _service.recordView(
        collectionId: widget.collectionId,
        userId: widget.currentUserId,
        token: token,
      );
    }
  }

  Future<List<Post>> _fetchPosts(List<int> postIds) async {
    if (postIds.isEmpty) return const [];
    final result = <Post>[];
    for (final id in postIds.take(50)) {
      final r = await _postService.getPost(id, currentUserId: widget.currentUserId);
      if (r.success && r.post != null) result.add(r.post!);
    }
    return result;
  }

  void _openPost(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenPostViewerScreen(
          posts: _items,
          initialIndex: index,
          currentUserId: widget.currentUserId,
          referrer: PostReferrer.collection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        foregroundColor: _kPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          _collection?.name ?? (isSw ? 'Mkusanyiko' : 'Collection'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: _hydrate,
          child: _loading
              ? const _LoadingView()
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _hydrate)
                  : _items.isEmpty
                      ? _EmptyView(isSw: isSw)
                      : _buildGrid(isSw),
        ),
      ),
    );
  }

  Widget _buildGrid(bool isSw) {
    return CustomScrollView(
      slivers: [
        if (_collection?.description != null && _collection!.description!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                _collection!.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _Stat(label: isSw ? 'Vipande' : 'Items', value: '${_items.length}'),
                const SizedBox(width: 24),
                _Stat(label: isSw ? 'Wafuasi' : 'Followers', value: '${_collection?.followsCount ?? 0}'),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PostThumb(
                post: _items[index],
                onTap: () => _openPost(index),
              ),
              childCount: _items.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _CollectionDetailScreenState._kPrimary)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: _CollectionDetailScreenState._kSecondary)),
      ],
    );
  }
}

class _PostThumb extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  const _PostThumb({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final firstImage = post.media.isNotEmpty ? post.media.first.fileUrl : null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: _CollectionDetailScreenState._kIconBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _CollectionDetailScreenState._kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: firstImage != null
            ? Image.network(
                firstImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_rounded,
                      color: _CollectionDetailScreenState._kTertiary, size: 24),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    post.content ?? '',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _CollectionDetailScreenState._kSecondary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: _CollectionDetailScreenState._kPrimary),
      );
}

class _EmptyView extends StatelessWidget {
  final bool isSw;
  const _EmptyView({required this.isSw});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.collections_bookmark_rounded,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          isSw ? 'Hakuna vipande bado' : 'No items yet',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          isSw
              ? 'Curator hawajaongeza machapisho hapa'
              : 'The curator hasn\'t added posts here yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              minimumSize: const Size(120, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}
