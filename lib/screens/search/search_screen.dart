import 'dart:async';
import 'package:flutter/material.dart';
import 'user_search_tab.dart';
import 'hashtag_screen.dart';
import '../../models/post_models.dart';
import '../../services/hashtag_service.dart';

// DESIGN.md: background #FAFAFA, primary text #1A1A1A, min touch 48dp
const Color _kBg = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kAccent = Color(0xFF999999);

/// Global search screen. Navigation: Home → Search (global) → Users tab | Hashtags tab.
class SearchScreen extends StatefulWidget {
  final int currentUserId;
  final String? initialQuery;
  final int initialTab; // 0 = Users, 1 = Hashtags

  const SearchScreen({
    super.key,
    required this.currentUserId,
    this.initialQuery,
    this.initialTab = 0,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Tafuta', style: TextStyle(color: _kPrimaryText, fontSize: 15)),
        backgroundColor: _kBg,
        elevation: 0,
        foregroundColor: _kPrimaryText,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimaryText,
          unselectedLabelColor: _kSecondaryText,
          indicatorColor: _kPrimaryText,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'Watu'),
            Tab(text: 'Hashtags'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            UserSearchTab(currentUserId: widget.currentUserId, initialQuery: widget.initialTab == 0 ? widget.initialQuery : null),
            _HashtagSearchTab(currentUserId: widget.currentUserId),
          ],
        ),
      ),
    );
  }
}

/// Hashtags tab: trending hashtags, search (GET /api/hashtags/search), navigate to HashtagScreen. Story 68.
class _HashtagSearchTab extends StatefulWidget {
  final int currentUserId;

  const _HashtagSearchTab({required this.currentUserId});

  @override
  State<_HashtagSearchTab> createState() => _HashtagSearchTabState();
}

class _HashtagSearchTabState extends State<_HashtagSearchTab> {
  final TextEditingController _controller = TextEditingController();
  final HashtagService _hashtagService = HashtagService();

  List<Hashtag> _trending = [];
  List<Hashtag> _searchResults = [];
  bool _trendingLoading = true;
  bool _searchLoading = false;
  String? _trendingError;
  String? _searchError;
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTrending();
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _hasSearched = false;
        _searchResults = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(q);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() {
      _trendingLoading = true;
      _trendingError = null;
    });
    final result = await _hashtagService.getTrendingHashtags(limit: 25);
    if (mounted) {
      setState(() {
        _trendingLoading = false;
        _trending = result.success ? result.hashtags : [];
        _trendingError = result.message;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _hasSearched = false;
        _searchResults = [];
        _searchError = null;
      });
      return;
    }
    setState(() {
      _searchLoading = true;
      _searchError = null;
      _hasSearched = true;
    });
    final result = await _hashtagService.searchHashtags(q, limit: 25);
    if (mounted) {
      setState(() {
        _searchLoading = false;
        _searchResults = result.success ? result.hashtags : [];
        _searchError = result.message;
      });
    }
  }

  void _openHashtag(String tagName) {
    final tag = tagName.startsWith('#') ? tagName.substring(1) : tagName;
    if (tag.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => HashtagScreen(
          hashtag: tag,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Tafuta hashtag (mfano: muziki)',
              hintStyle: const TextStyle(color: _kSecondaryText, fontSize: 14),
              prefixIcon: const Icon(Icons.tag, color: _kSecondaryText, size: 24),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _kAccent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(color: _kPrimaryText, fontSize: 14),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _performSearch(_controller.text),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _hasSearched ? _buildSearchResults() : _buildTrending(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrending() {
    if (_trendingLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimaryText));
    }
    if (_trendingError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _kAccent),
            const SizedBox(height: 12),
            Text(_trendingError!, style: const TextStyle(color: _kSecondaryText, fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: _loadTrending,
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      );
    }
    if (_trending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tag, size: 48, color: _kAccent),
            const SizedBox(height: 12),
            const Text('Hakuna hashtags zinazovuma', style: TextStyle(color: _kSecondaryText, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'Andika hashtag hapa juu au gusa #hashtag kwenye chapisho',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSecondaryText, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTrending,
      color: _kPrimaryText,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _trending.length,
        itemBuilder: (context, index) {
          final tag = _trending[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HashtagTile(
              hashtag: tag,
              onTap: () => _openHashtag(tag.name),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimaryText));
    }
    if (_searchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: _kAccent),
            const SizedBox(height: 12),
            Text(_searchError!, style: const TextStyle(color: _kSecondaryText, fontSize: 14)),
          ],
        ),
      );
    }
    if (_searchResults.isEmpty) {
      final query = _controller.text.trim();
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tag, size: 48, color: _kAccent),
            const SizedBox(height: 12),
            const Text('Hakuna matokeo', style: TextStyle(color: _kSecondaryText, fontSize: 14)),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => _openHashtag(query),
                  child: Text('Gundua #$query'),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final tag = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _HashtagTile(
            hashtag: tag,
            onTap: () => _openHashtag(tag.name),
          ),
        );
      },
    );
  }
}

/// Single hashtag row; min touch target 48dp (DESIGN.md).
class _HashtagTile extends StatelessWidget {
  final Hashtag hashtag;
  final VoidCallback onTap;

  const _HashtagTile({required this.hashtag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tag, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${hashtag.name}',
                      style: const TextStyle(
                        color: _kPrimaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hashtag.formattedPostsCount} machapisho',
                      style: const TextStyle(color: _kSecondaryText, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _kAccent, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
