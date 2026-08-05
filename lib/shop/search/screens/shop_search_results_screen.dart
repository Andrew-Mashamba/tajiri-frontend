import 'package:flutter/material.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../shared/widgets/product_card.dart';

const Color _kBg = Color(0xFFFAFAFA);

class ShopSearchResultsScreen extends StatefulWidget {
  const ShopSearchResultsScreen({
    super.key,
    required this.query,
    required this.currentUserId,
  });

  final String query;
  final int currentUserId;

  @override
  State<ShopSearchResultsScreen> createState() => _ShopSearchResultsScreenState();
}

enum _TypeFilter { all, physical, digital, services }
enum _ConditionFilter { any, brandNew, used }

class _ShopSearchResultsScreenState extends State<ShopSearchResultsScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  final ScrollController _scrollCtrl = ScrollController();

  List<Product> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;

  _TypeFilter _typeFilter = _TypeFilter.all;
  _ConditionFilter _condFilter = _ConditionFilter.any;
  String _sortBy = 'popular'; // popular, price_asc, price_desc, newest

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  ProductType? get _activeType => switch (_typeFilter) {
        _TypeFilter.physical => ProductType.physical,
        _TypeFilter.digital => ProductType.digital,
        _TypeFilter.services => ProductType.service,
        _TypeFilter.all => null,
      };

  ProductCondition? get _activeCondition => switch (_condFilter) {
        _ConditionFilter.brandNew => ProductCondition.brandNew,
        _ConditionFilter.used => ProductCondition.used,
        _ConditionFilter.any => null,
      };

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _items = [];
        _hasMore = true;
      });
    }
    final r = await _repo.getProducts(
      search: widget.query,
      currentUserId: widget.currentUserId,
      page: 1,
      perPage: 40,
      type: _activeType,
      condition: _activeCondition,
      sortBy: _sortBy,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.success) {
        _items = r.products;
        _hasMore = r.products.length >= 40;
        _page = 2;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    final r = await _repo.getProducts(
      search: widget.query,
      currentUserId: widget.currentUserId,
      page: _page,
      perPage: 40,
      type: _activeType,
      condition: _activeCondition,
      sortBy: _sortBy,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (r.success) {
        _items.addAll(r.products);
        _hasMore = r.products.length >= 40;
        _page++;
      }
    });
  }

  void _onFilterChanged() => _load(reset: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          widget.query,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: const Color(0xFF1A1A1A),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (val) {
              setState(() => _sortBy = val);
              _onFilterChanged();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'popular', child: Text('Relevance')),
              PopupMenuItem(value: 'price_asc', child: Text('Price ↑')),
              PopupMenuItem(value: 'price_desc', child: Text('Price ↓')),
              PopupMenuItem(value: 'newest', child: Text('Newest')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)))
            : RefreshIndicator(
                color: const Color(0xFF1A1A1A),
                onRefresh: () => _load(reset: true),
                child: CustomScrollView(
                  controller: _scrollCtrl,
                  slivers: [
                    // Result count
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '${_items.length} result${_items.length == 1 ? '' : 's'} for \'${widget.query}\'',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Type filter chips
                    SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        child: Row(
                          children: [
                            ..._TypeFilter.values.map((f) {
                              final label = switch (f) {
                                _TypeFilter.all => 'All',
                                _TypeFilter.physical => 'Physical',
                                _TypeFilter.digital => 'Digital',
                                _TypeFilter.services => 'Services',
                              };
                              final selected = _typeFilter == f;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(label),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() => _typeFilter = f);
                                    _onFilterChanged();
                                  },
                                  selectedColor: const Color(0xFF1A1A1A),
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : const Color(0xFF1A1A1A),
                                    fontSize: 13,
                                  ),
                                  showCheckmark: false,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              );
                            }),
                            // Condition filters
                            ...[_ConditionFilter.brandNew, _ConditionFilter.used].map((f) {
                              final label = f == _ConditionFilter.brandNew ? 'New' : 'Used';
                              final selected = _condFilter == f;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(label),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() => _condFilter = selected ? _ConditionFilter.any : f);
                                    _onFilterChanged();
                                  },
                                  selectedColor: const Color(0xFF1A1A1A),
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : const Color(0xFF1A1A1A),
                                    fontSize: 13,
                                  ),
                                  showCheckmark: false,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    // Results or empty state
                    if (_items.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => ProductCard(
                              product: _items[i],
                              onTap: () => Navigator.pushNamed(
                                ctx,
                                '/shop/product',
                                arguments: {'productId': _items[i].id},
                              ),
                            ),
                            childCount: _items.length,
                          ),
                        ),
                      ),
                    if (_loadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No results for \'${widget.query}\'',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Try different keywords',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
