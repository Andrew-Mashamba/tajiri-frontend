import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../state/cart_provider.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../shared/widgets/product_card.dart';
import '../../../widgets/cached_media_image.dart';
import 'category_screen.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

/// Marketplace discovery screen — alternative to the shop tab.
/// Emphasises browsing: featured horizontal scroll, inline sort/filter row,
/// and infinite-scroll product grid (loads more at 70% scroll depth).
class MarketplaceScreen extends StatefulWidget {
  final int currentUserId;
  final String? initialSearchQuery;

  const MarketplaceScreen({
    super.key,
    required this.currentUserId,
    this.initialSearchQuery,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Categories
  List<ProductCategory> _categories = [];
  bool _categoriesLoading = true;
  int? _selectedCategoryId;

  // Featured products
  List<Product> _featuredProducts = [];
  bool _featuredLoading = true;

  // Product grid
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalProducts = 0;

  // Filters
  String _sortBy = 'relevance';
  ProductCondition? _selectedCondition;
  ProductType? _selectedType;
  ShopFilterResult? _activeFilters;

  // Search
  String _searchQuery = '';
  Timer? _searchDebounce;

  // Cart
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery?.isNotEmpty == true) {
      _searchController.text = widget.initialSearchQuery!;
      _searchQuery = widget.initialSearchQuery!;
    }
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.7 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreProducts();
    }
  }

  // ── Data loading ──────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      _loadFeaturedProducts(),
      _loadProducts(),
      _loadCartCount(),
    ]);
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    final result = await _repo.getCategories();
    if (!mounted) return;
    setState(() {
      _categoriesLoading = false;
      if (result.success) _categories = result.categories;
    });
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() => _featuredLoading = true);
    final result = await _repo.getFeaturedProducts(
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _featuredLoading = false;
      if (result.success) _featuredProducts = result.products;
    });
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _products = [];
      });
    }
    setState(() => _isLoading = true);

    final result = await _repo.getProducts(
      page: 1,
      perPage: 20,
      categoryId: _selectedCategoryId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      sortBy: _sortBy == 'relevance' ? null : _sortBy,
      condition: _selectedCondition ?? _activeFilters?.condition,
      type: _selectedType ?? _activeFilters?.type,
      minPrice: _activeFilters?.minPrice,
      maxPrice: _activeFilters?.maxPrice,
      currentUserId: widget.currentUserId,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _products = result.products;
        _hasMore = result.meta?.hasMore ?? false;
        _totalProducts = result.meta?.total ?? result.products.length;
        _currentPage = 1;
      }
    });
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await _repo.getProducts(
      page: _currentPage + 1,
      perPage: 20,
      categoryId: _selectedCategoryId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      sortBy: _sortBy == 'relevance' ? null : _sortBy,
      condition: _selectedCondition ?? _activeFilters?.condition,
      type: _selectedType ?? _activeFilters?.type,
      minPrice: _activeFilters?.minPrice,
      maxPrice: _activeFilters?.maxPrice,
      currentUserId: widget.currentUserId,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (result.success) {
        _products.addAll(result.products);
        _hasMore = result.meta?.hasMore ?? false;
        _currentPage++;
      }
    });
  }

  Future<void> _loadCartCount() async {
    final result = await _repo.getCart(widget.currentUserId);
    if (!mounted) return;
    CartProvider.instance.ingestCartSnapshot(result, userId: widget.currentUserId);
    setState(() => _cartItemCount = result.cart?.itemCount ?? 0);
  }

  // ── Actions ───────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
      _loadProducts(refresh: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    setState(() => _searchQuery = '');
    _loadProducts(refresh: true);
  }

  void _onCategoryTap(ProductCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryScreen(
          category: category,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _onCategoryFilterSelected(int? categoryId) {
    if (categoryId == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _loadProducts(refresh: true);
  }

  void _onSortSelected(String sortBy) {
    if (sortBy == _sortBy) {
      if (sortBy == 'price_asc') {
        sortBy = 'price_desc';
      } else if (sortBy == 'price_desc') {
        sortBy = 'price_asc';
      } else {
        return;
      }
    }
    setState(() => _sortBy = sortBy);
    _loadProducts(refresh: true);
  }

  void _onConditionSelected(ProductCondition? condition) {
    setState(() => _selectedCondition = condition);
    _loadProducts(refresh: true);
  }

  void _onTypeSelected(ProductType? type) {
    setState(() => _selectedType = type);
    _loadProducts(refresh: true);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        currentFilters: _activeFilters,
        onApply: (filters) {
          setState(() {
            _activeFilters = filters;
            // Sync inline chips with filter sheet selections
            if (filters.condition != null) _selectedCondition = filters.condition;
            if (filters.type != null) _selectedType = filters.type;
          });
          _loadProducts(refresh: true);
        },
      ),
    );
  }

  Future<void> _onToggleFavorite(Product product) async {
    final result = await _repo.toggleFavorite(widget.currentUserId, product.id);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _updateFavoriteInLists(product.id, result.isFavorited);
      });
    }
  }

  void _updateFavoriteInLists(int productId, bool isFavorited) {
    void updateList(List<Product> list) {
      final idx = list.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(isFavorited: isFavorited);
      }
    }
    updateList(_featuredProducts);
    updateList(_products);
  }

  Future<void> _onAddToCart(Product product) async {
    final result = await _repo.addToCart(widget.currentUserId, product.id);
    if (!mounted) return;
    if (result.success) {
      CartProvider.instance.ingestCartSnapshot(result, userId: widget.currentUserId);
      setState(() => _cartItemCount = result.cart?.itemCount ?? _cartItemCount + 1);
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} ${s?.addedToCart ?? 'added to cart'}'),
          action: SnackBarAction(
            label: s?.viewCart ?? 'View',
            onPressed: () => Navigator.pushNamed(context, '/shop/cart'),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to add to cart')),
      );
    }
  }

  void _openProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      product.isService ? '/shop/service' : '/shop/product',
      arguments: {'productId': product.id},
    );
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadCategories(),
      _loadFeaturedProducts(),
      _loadProducts(refresh: true),
      _loadCartCount(),
    ]);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: _kPrimaryText,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. AppBar with search
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: _kBackground,
                elevation: 0,
                scrolledUnderElevation: 1,
                titleSpacing: 0,
                title: _buildSearchField(),
                actions: [
                  IconButton(
                    icon: const HeroIcon(HeroIcons.heart),
                    onPressed: () => Navigator.pushNamed(context, '/shop/wishlist'),
                    tooltip: 'Wishlist',
                  ),
                  _buildCartButton(),
                  const SizedBox(width: 4),
                ],
              ),

              // 2. Category chips
              SliverToBoxAdapter(child: _buildCategoryChips()),

              // 3. Featured horizontal scroll
              if (_featuredProducts.isNotEmpty || _featuredLoading)
                SliverToBoxAdapter(child: _buildFeaturedSection()),

              // 4. Filter row
              SliverToBoxAdapter(child: _buildFilterRow()),

              // 5. Product grid / shimmer / empty
              if (_isLoading)
                SliverToBoxAdapter(child: _buildGridShimmer())
              else if (_products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => _openProductDetail(product),
                          onFavorite: () => _onToggleFavorite(product),
                          onAddToCart: product.isInStock
                              ? () => _onAddToCart(product)
                              : null,
                        );
                      },
                      childCount: _products.length,
                    ),
                  ),
                ),

              // 6. Load-more spinner
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kPrimaryText,
                        ),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────

  Widget _buildSearchField() {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kDivider, width: 1),
        ),
        child: Row(
          children: [
            const HeroIcon(HeroIcons.magnifyingGlass, size: 20, color: _kTertiaryText),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14, color: _kPrimaryText),
                decoration: InputDecoration(
                  hintText: s?.searchProducts ?? 'Search marketplace...',
                  hintStyle:
                      const TextStyle(color: _kTertiaryText, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: const HeroIcon(HeroIcons.xMark, size: 18, color: _kTertiaryText),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return Stack(
      children: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/shop/cart'),
          icon: const HeroIcon(HeroIcons.shoppingCart, size: 24, color: _kPrimaryText),
        ),
        if (_cartItemCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _cartItemCount > 99 ? '99+' : '$_cartItemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final s = AppStringsScope.of(context);
    if (_categoriesLoading) {
      return _buildChipShimmer();
    }
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        itemCount: _categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? _selectedCategoryId == null
              : _categories[index - 1].id == _selectedCategoryId;
          final label =
              isAll ? (s?.all ?? 'All') : _categories[index - 1].name;

          return GestureDetector(
            onTap: () {
              if (isAll) {
                _onCategoryFilterSelected(null);
              } else {
                _onCategoryTap(_categories[index - 1]);
              }
            },
            onLongPress: () {
              if (!isAll) {
                _onCategoryFilterSelected(_categories[index - 1].id);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _kPrimaryText : _kSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? _kPrimaryText : _kDivider,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? _kSurface : _kPrimaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (_featuredLoading) {
      return _buildFeaturedShimmer();
    }
    if (_featuredProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text(
                'Featured',
                style: TextStyle(
                  color: _kPrimaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/shop/recommended',
                  arguments: {'currentUserId': widget.currentUserId},
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: _kSecondaryText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _featuredProducts.length,
            itemBuilder: (context, index) {
              final product = _featuredProducts[index];
              return GestureDetector(
                onTap: () => _openProductDetail(product),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
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
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (product.thumbnailPath != null ||
                                product.images.isNotEmpty)
                              CachedMediaImage(
                                imageUrl: product.thumbnailUrl,
                                fit: BoxFit.cover,
                              )
                            else
                              Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Center(
                                  child: HeroIcon(
                                    HeroIcons.photo,
                                    size: 36,
                                    color: _kTertiaryText,
                                  ),
                                ),
                              ),
                            if (product.hasDiscount)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    product.discountPercentFormatted,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Info
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(
                                color: _kPrimaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.priceFormatted,
                              style: const TextStyle(
                                color: _kPrimaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort + filter button row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'Results ($_totalProducts)'
                      : 'All Products ($_totalProducts)',
                  style: const TextStyle(
                    color: _kPrimaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildSortChip(label: 'Newest', value: 'newest'),
              const SizedBox(width: 6),
              _buildSortChip(
                label: 'Price',
                value: _sortBy == 'price_desc' ? 'price_desc' : 'price_asc',
                suffix: _sortBy == 'price_asc'
                    ? ' \u2191'
                    : _sortBy == 'price_desc'
                        ? ' \u2193'
                        : null,
              ),
              const SizedBox(width: 6),
              _buildFilterIconButton(),
            ],
          ),
        ),
        // Condition + Type chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            children: [
              _buildConditionChip(null, 'Any'),
              const SizedBox(width: 6),
              _buildConditionChip(ProductCondition.brandNew, 'New'),
              const SizedBox(width: 6),
              _buildConditionChip(ProductCondition.used, 'Used'),
              const SizedBox(width: 6),
              _buildConditionChip(ProductCondition.refurbished, 'Refurbished'),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: _kDivider, margin: const EdgeInsets.symmetric(vertical: 4)),
              const SizedBox(width: 12),
              _buildTypeChip(null, 'All Types'),
              const SizedBox(width: 6),
              _buildTypeChip(ProductType.physical, 'Physical'),
              const SizedBox(width: 6),
              _buildTypeChip(ProductType.digital, 'Digital'),
              const SizedBox(width: 6),
              _buildTypeChip(ProductType.service, 'Services'),
            ],
          ),
        ),
        const Divider(height: 1, color: _kDivider),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSortChip({required String label, required String value, String? suffix}) {
    final isActive = _sortBy == value ||
        (value == 'price_asc' && _sortBy == 'price_desc') ||
        (value == 'price_desc' && _sortBy == 'price_asc');
    return GestureDetector(
      onTap: () => _onSortSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? _kPrimaryText : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? _kPrimaryText : _kDivider, width: 1),
        ),
        child: Text(
          '$label${suffix ?? ''}',
          style: TextStyle(
            color: isActive ? _kSurface : _kSecondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildConditionChip(ProductCondition? condition, String label) {
    final isActive = _selectedCondition == condition;
    return GestureDetector(
      onTap: () => _onConditionSelected(condition == _selectedCondition ? null : condition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? _kPrimaryText : _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? _kPrimaryText : _kDivider, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _kSurface : _kSecondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ProductType? type, String label) {
    final isActive = _selectedType == type;
    return GestureDetector(
      onTap: () => _onTypeSelected(type == _selectedType ? null : type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? _kPrimaryText : _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? _kPrimaryText : _kDivider, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? _kSurface : _kSecondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterIconButton() {
    final hasFilters = _activeFilters != null &&
        (_activeFilters!.minPrice != null ||
            _activeFilters!.maxPrice != null ||
            _activeFilters!.minRating != null);
    return GestureDetector(
      onTap: _showFilterSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: hasFilters ? _kPrimaryText : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasFilters ? _kPrimaryText : _kDivider, width: 1),
        ),
        child: Icon(
          Icons.tune_rounded,
          size: 16,
          color: hasFilters ? Colors.white : _kSecondaryText,
        ),
      ),
    );
  }

  Widget _buildGridShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(3, (row) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: _kDivider,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: _kDivider,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildFeaturedShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: _kDivider,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipShimmer() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          width: 72,
          height: 36,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _kDivider,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedCategoryId != null ||
        _selectedCondition != null ||
        _selectedType != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No products found' : 'No products',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters or search'
                  : 'Products will appear here',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategoryId = null;
                    _selectedCondition = null;
                    _selectedType = null;
                    _activeFilters = null;
                  });
                  _loadProducts(refresh: true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kPrimaryText,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
