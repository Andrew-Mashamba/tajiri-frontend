import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/content_engine_models.dart';
import '../../models/message_models.dart';
import '../../services/content_engine_service.dart';
import '../../services/message_service.dart';
import '../../services/message_database.dart';
import '../../services/search_history_service.dart';
import '../../widgets/content_result_card.dart';
import '../../widgets/trending_digest_card.dart';
import '../../config/api_config.dart';

class UniversalSearchScreen extends StatefulWidget {
  final int currentUserId;

  const UniversalSearchScreen({super.key, required this.currentUserId});

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  int get _currentUserId => widget.currentUserId;
  bool _isLoading = false;
  String? _activeQuery;

  // Pre-search state
  TrendingDigest? _digest;
  bool _digestLoading = true;

  // Search results
  ContentEngineResult? _searchResult;
  List<Message> _messageResults = [];
  String _selectedType = 'all';
  int _currentPage = 1;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  List<String> _searchHistory = [];
  Timer? _debounce;

  // Sub-filter for message type: all, text, media, links
  String _messageSubFilter = 'all';
  static const _messageSubFilters = ['all', 'text', 'media', 'links'];

  static const _typeFilters = [
    'all',
    'post',
    'clip',
    'music',
    'user_profile',
    'message',
    'event',
    'group',
    'campaign',
    'product',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadDigest();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryService.instance.getHistory();
    if (mounted) {
      setState(() => _searchHistory = history);
    }
  }

  Future<void> _loadDigest() async {
    final digest = await ContentEngineService.getTrendingDigest();
    if (mounted) {
      setState(() {
        _digest = digest;
        _digestLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _activeQuery = null;
        _searchResult = null;
        _currentPage = 1;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query, reset: true);
    });
  }

  Future<void> _performSearch(String query, {bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _activeQuery = query;
        _messageResults = [];
      });
      SearchHistoryService.instance.addQuery(query);
      _loadSearchHistory();
    }

    // Messages tab: search SQLite first, then API for completeness
    if (_selectedType == 'message') {
      final msgType = _messageSubFilter == 'all' ? null : _messageSubFilter;
      // Step 1: Search local SQLite for instant results
      try {
        final localResults = await MessageDatabase.instance.searchMessages(query);
        if (mounted && localResults.isNotEmpty) {
          setState(() {
            _messageResults = localResults;
            _isLoading = true; // still loading from API
          });
        }
      } catch (_) {}
      // Step 2: Search API for completeness
      final result = await MessageService.searchMessages(
        userId: _currentUserId,
        query: query,
        messageType: msgType,
      );
      if (mounted) {
        // Cache API results to SQLite
        if (result.messages.isNotEmpty) {
          MessageDatabase.instance.upsertMessages(result.messages);
        }
        setState(() {
          _messageResults = result.messages.isNotEmpty ? result.messages : _messageResults;
          _searchResult = null;
          _isLoading = false;
          _loadingMore = false;
        });
      }
      return;
    }

    final types = _selectedType == 'all' ? null : [_selectedType];
    final result = await ContentEngineService.search(
      query: query,
      userId: _currentUserId,
      types: types,
      page: _currentPage,
    );

    if (mounted) {
      setState(() {
        if (reset || _searchResult == null) {
          _searchResult = result;
        } else {
          // Append for pagination
          _searchResult = ContentEngineResult(
            items: [..._searchResult!.items, ...result.items],
            meta: result.meta,
          );
        }
        _isLoading = false;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      if (!_loadingMore &&
          _activeQuery != null &&
          (_searchResult?.meta.hasMore ?? false)) {
        setState(() {
          _loadingMore = true;
          _currentPage++;
        });
        _performSearch(_activeQuery!);
      }
    }
  }

  void _onTypeFilterChanged(String type) {
    if (type == _selectedType) return;
    setState(() {
      _selectedType = type;
      if (type != 'message') _messageSubFilter = 'all';
    });
    if (_activeQuery != null) {
      _performSearch(_activeQuery!, reset: true);
    }
  }

  void _onMessageSubFilterChanged(String subFilter) {
    if (subFilter == _messageSubFilter) return;
    setState(() => _messageSubFilter = subFilter);
    if (_activeQuery != null) {
      _performSearch(_activeQuery!, reset: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context) ?? AppStrings('en');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: InputDecoration(
              hintText: strings.searchEverything,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Colors.black38),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.black38),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocus.requestFocus();
                      },
                    )
                  : null,
            ),
            onSubmitted: (q) {
              if (q.trim().isNotEmpty) _performSearch(q.trim(), reset: true);
            },
          ),
        ),
      ),
      body: SafeArea(
        child: _activeQuery == null
            ? _buildPreSearchState(strings)
            : _buildSearchResults(strings),
      ),
    );
  }

  /// State 1: Before typing — show trending digest + suggestions
  Widget _buildPreSearchState(AppStrings strings) {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        // Trending digest card
        if (_digestLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF1A1A1A))),
          )
        else if (_digest != null)
          TrendingDigestCard(
            digest: _digest!,
            onStoryTap: (docId) {
              // Navigate to post/document detail
              Navigator.pushNamed(context, '/post/$docId');
            },
          ),

        // Recent searches
        if (_searchHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A)),
                ),
                GestureDetector(
                  onTap: () async {
                    await SearchHistoryService.instance.clear();
                    _loadSearchHistory();
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 13, color: Colors.black38),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((query) => GestureDetector(
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query, reset: true);
                },
                onLongPress: () async {
                  await SearchHistoryService.instance.removeQuery(query);
                  _loadSearchHistory();
                },
                child: Chip(
                  label: Text(query, style: const TextStyle(fontSize: 13)),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              )).toList(),
            ),
          ),
        ],

        // Trending searches section (placeholder — populated by backend)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            strings.trendingSearches,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1A1A1A)),
          ),
        ),
        // Placeholder for trending hashtags
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            strings.noData,
            style: const TextStyle(color: Colors.black38, fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// State 3: After search — type filter tabs + results list
  Widget _buildSearchResults(AppStrings strings) {
    return Column(
      children: [
        // Type filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: _typeFilters.length,
            itemBuilder: (context, index) {
              final type = _typeFilters[index];
              final isSelected = type == _selectedType;
              return ChoiceChip(
                label: Text(_typeLabel(type, strings)),
                selected: isSelected,
                onSelected: (_) => _onTypeFilterChanged(type),
                selectedColor: const Color(0xFF1A1A1A),
                backgroundColor: Colors.grey[100],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: BorderSide.none,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
        ),

        // Message sub-filter chips (only when 'message' type selected)
        if (_selectedType == 'message')
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemCount: _messageSubFilters.length,
              itemBuilder: (context, index) {
                final sf = _messageSubFilters[index];
                final isSelected = sf == _messageSubFilter;
                return ChoiceChip(
                  label: Text(_messageSubFilterLabel(sf)),
                  selected: isSelected,
                  onSelected: (_) => _onMessageSubFilterChanged(sf),
                  selectedColor: const Color(0xFF1A1A1A),
                  backgroundColor: Colors.grey[50],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : Colors.grey.shade300,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),

        // Query expansion info
        if (_searchResult?.meta.queryExpansion != null &&
            (_searchResult!.meta.queryExpansion!.expandedQueries.isNotEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Pia tumetafuta: ${_searchResult!.meta.queryExpansion!.expandedQueries.take(3).join(", ")}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black38),
            ),
          ),

        // Results list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF1A1A1A)))
              : _selectedType == 'message'
                  ? _buildMessageResults()
                  : _searchResult == null || _searchResult!.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 48, color: Colors.black26),
                              const SizedBox(height: 12),
                              Text(strings.noResults,
                                  style:
                                      const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: _searchResult!.items.length +
                              (_loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _searchResult!.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1A1A1A))),
                              );
                            }
                            final item = _searchResult!.items[index];
                            return ContentResultCard(
                              result: item,
                              currentUserId: _currentUserId,
                              onPostTap: (post) => Navigator.pushNamed(
                                  context, '/post/${post.id}'),
                              onHashtagTap: (tag) {
                                _searchController.text = '#$tag';
                                _performSearch('#$tag', reset: true);
                              },
                              onUserTap: (userId) => Navigator.pushNamed(
                                  context, '/profile/$userId'),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildMessageResults() {
    if (_messageResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.black26),
            SizedBox(height: 12),
            Text('No messages found', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }
    final df = DateFormat('MMM d, HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messageResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final msg = _messageResults[index];
        final senderName = msg.sender?.fullName ?? 'User ${msg.senderId}';
        final photo = msg.sender?.profilePhotoPath;
        final query = _activeQuery?.toLowerCase() ?? '';

        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: photo != null
                ? NetworkImage(
                    photo.startsWith('http') ? photo : '${ApiConfig.storageUrl}/$photo',
                  )
                : null,
            child: photo == null
                ? Text(
                    senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  )
                : null,
          ),
          title: Text(
            senderName,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _highlightMatch(msg.content ?? msg.preview, query),
          trailing: Text(
            df.format(msg.createdAt),
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
          onTap: () => Navigator.pushNamed(context, '/chat/${msg.conversationId}'),
        );
      },
    );
  }

  /// Highlight the search query within the message text.
  Widget _highlightMatch(String text, String query) {
    if (query.isEmpty) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)));
    }
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx == -1) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)));
    }
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(
              backgroundColor: Color(0xFFFFF176),
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }

  String _messageSubFilterLabel(String sf) {
    switch (sf) {
      case 'all':
        return 'All';
      case 'text':
        return 'Text';
      case 'media':
        return 'Media';
      case 'links':
        return 'Links';
      default:
        return sf;
    }
  }

  String _typeLabel(String type, AppStrings strings) {
    switch (type) {
      case 'all':
        return strings.ceAllTypes;
      case 'post':
        return strings.posts;
      case 'clip':
        return strings.clips;
      case 'music':
        return strings.musicType;
      case 'user_profile':
        return strings.people;
      case 'message':
        return 'Messages';
      case 'event':
        return strings.eventsType;
      case 'group':
        return strings.groupsType;
      case 'campaign':
        return strings.campaignsType;
      case 'product':
        return strings.productsType;
      default:
        return type;
    }
  }
}
