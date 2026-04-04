import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';
import '../../models/ad_models.dart';
import '../../services/shop_service.dart';
import '../../services/ad_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/shop_database.dart';
import '../../widgets/shop/filter_bottom_sheet.dart';
import '../../widgets/shop/product_card.dart';
import '../../widgets/shop/search_suggestions.dart';
import '../../widgets/cached_media_image.dart';
import '../../widgets/native_ad_card.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

/// Main marketplace screen - Shop tab in bottom navigation.
/// Modern mobile shop layout: search, category chips, featured banner,
/// sort bar, and infinite-scroll product grid.
class ShopScreen extends StatefulWidget {
  final int currentUserId;

  const ShopScreen({super.key, required this.currentUserId});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ShopService _shopService = ShopService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Categories
  List<ProductCategory> _categories = [];
  bool _categoriesLoading = true;
  int? _selectedCategoryId;

  // Featured products (banner)
  List<Product> _featuredProducts = [];
  bool _featuredLoading = true;
  late final PageController _bannerController;
  Timer? _bannerTimer;
  int _bannerCurrentPage = 0;

  // Product grid
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalProducts = 0;

  // Sort
  String _sortBy = 'newest';

  // Filters
  ShopFilterResult? _activeFilters;

  // Search
  String _searchQuery = '';
  Timer? _searchDebounce;
  bool _showSuggestions = false;

  // Cart
  int _cartItemCount = 0;

  // Staggered animation tracking
  final Set<int> _animatedIndices = {};

  // Ad state
  List<ServedAd> _shopAds = [];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.92);
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
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
    final result = await _shopService.getCategories();
    if (!mounted) return;
    setState(() {
      _categoriesLoading = false;
      if (result.success) {
        _categories = result.categories;
      }
    });
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() => _featuredLoading = true);
    final result = await _shopService.getFeaturedProducts(
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _featuredLoading = false;
      if (result.success) {
        _featuredProducts = result.products;
        _startBannerAutoScroll();
      }
    });
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _products = [];
        _animatedIndices.clear();
      });
    }

    setState(() => _isLoading = true);

    final result = await _shopService.getProducts(
      page: 1,
      perPage: 20,
      categoryId: _selectedCategoryId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      sortBy: _sortBy,
      minPrice: _activeFilters?.minPrice,
      maxPrice: _activeFilters?.maxPrice,
      condition: _activeFilters?.condition,
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

    // Fetch promoted marketplace ads
    if (result.success && _products.isNotEmpty) {
      _fetchShopAds();
    } else {
      setState(() => _shopAds = []);
    }
  }

  Future<void> _fetchShopAds() async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    final ads = await AdService.getServedAds(token, 'marketplace', 2);
    if (mounted) {
      setState(() => _shopAds = ads);
    }
  }

  void _recordShopAdImpression(ServedAd ad) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    AdService.recordAdEvent(
      token, ad.campaignId, ad.creativeId,
      widget.currentUserId, 'marketplace', 'impression',
    );
  }

  void _recordShopAdClick(ServedAd ad) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    AdService.recordAdEvent(
      token, ad.campaignId, ad.creativeId,
      widget.currentUserId, 'marketplace', 'click',
    );
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _shopService.getProducts(
      page: _currentPage + 1,
      perPage: 20,
      categoryId: _selectedCategoryId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      sortBy: _sortBy,
      minPrice: _activeFilters?.minPrice,
      maxPrice: _activeFilters?.maxPrice,
      condition: _activeFilters?.condition,
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
    final result = await _shopService.getCart(widget.currentUserId);
    if (!mounted) return;
    setState(() {
      _cartItemCount = result.cart?.itemCount ?? 0;
    });
  }

  // ── Banner auto-scroll ────────────────────────────────────────────────

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (_featuredProducts.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      _bannerCurrentPage = (_bannerCurrentPage + 1) % _featuredProducts.length;
      _bannerController.animateToPage(
        _bannerCurrentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────

  void _onCategorySelected(int? categoryId) {
    if (categoryId == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    _loadProducts(refresh: true);
  }

  void _onSortSelected(String sortBy) {
    if (sortBy == _sortBy) {
      // Toggle price direction
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

  void _onSearchChanged(String value) {
    setState(() => _showSuggestions = true);
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
    setState(() {
      _searchQuery = '';
      _showSuggestions = false;
    });
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
          setState(() => _activeFilters = filters);
          _loadProducts(refresh: true);
        },
      ),
    );
  }

  Future<void> _onToggleFavorite(Product product) async {
    final result = await _shopService.toggleFavorite(
      widget.currentUserId,
      product.id,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _updateProductFavorite(product.id, result.isFavorited);
      });
    }
  }

  void _updateProductFavorite(int productId, bool isFavorited) {
    void updateList(List<Product> list) {
      final index = list.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final old = list[index];
        list[index] = Product(
          id: old.id,
          sellerId: old.sellerId,
          title: old.title,
          description: old.description,
          slug: old.slug,
          type: old.type,
          status: old.status,
          price: old.price,
          compareAtPrice: old.compareAtPrice,
          currency: old.currency,
          stockQuantity: old.stockQuantity,
          images: old.images,
          thumbnailPath: old.thumbnailPath,
          categoryId: old.categoryId,
          tags: old.tags,
          condition: old.condition,
          locationName: old.locationName,
          latitude: old.latitude,
          longitude: old.longitude,
          allowPickup: old.allowPickup,
          allowDelivery: old.allowDelivery,
          allowShipping: old.allowShipping,
          deliveryFee: old.deliveryFee,
          deliveryNotes: old.deliveryNotes,
          pickupAddress: old.pickupAddress,
          downloadUrl: old.downloadUrl,
          downloadLimit: old.downloadLimit,
          durationMinutes: old.durationMinutes,
          serviceLocation: old.serviceLocation,
          viewsCount: old.viewsCount,
          favoritesCount: old.favoritesCount + (isFavorited ? 1 : -1),
          ordersCount: old.ordersCount,
          rating: old.rating,
          reviewsCount: old.reviewsCount,
          seller: old.seller,
          category: old.category,
          isFavorited: isFavorited,
          createdAt: old.createdAt,
          updatedAt: old.updatedAt,
        );
      }
    }

    updateList(_featuredProducts);
    updateList(_products);
  }

  Future<void> _onAddToCart(Product product) async {
    final result = await _shopService.addToCart(
      widget.currentUserId,
      product.id,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _cartItemCount = result.cart?.itemCount ?? _cartItemCount + 1;
      });
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
      final s = AppStringsScope.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? s?.failedToAdd ?? 'Failed to add')),
      );
    }
  }

  void _openProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      '/shop/product',
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
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. Search bar + cart
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: _kBackground,
                elevation: 0,
                titleSpacing: 0,
                title: _buildSearchField(),
                actions: [
                  IconButton(
                    icon: const HeroIcon(HeroIcons.heart),
                    onPressed: () => Navigator.pushNamed(context, '/shop/wishlist'),
                  ),
                  _buildCartButton(),
                  const SizedBox(width: 8),
                ],
              ),

              // 2. Search suggestions overlay
              if (_showSuggestions)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SearchSuggestions(
                      query: _searchController.text,
                      onSelect: (query) {
                        _searchController.text = query;
                        setState(() {
                          _showSuggestions = false;
                          _searchQuery = query;
                        });
                        _loadProducts(refresh: true);
                      },
                      onClearHistory: () async {
                        await ShopDatabase.instance.clearSearchHistory();
                        setState(() {});
                      },
                    ),
                  ),
                ),

              // 3. Category filter chips
              SliverToBoxAdapter(child: _buildCategoryChips()),

              // 3. Featured banner
              if (_featuredProducts.isNotEmpty || _featuredLoading)
                SliverToBoxAdapter(child: _buildFeaturedBanner()),

              // 4. Sort bar
              SliverToBoxAdapter(child: _buildSortBar()),

              // 5. Product grid (shimmer / empty / data)
              if (_isLoading)
                SliverToBoxAdapter(child: _buildGridShimmer())
              else if (_products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else ...[
                // Promoted ad at top of product grid
                if (_shopAds.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NativeAdCard(
                        servedAd: _shopAds[0],
                        onImpression: () => _recordShopAdImpression(_shopAds[0]),
                        onClick: () => _recordShopAdClick(_shopAds[0]),
                      ),
                    ),
                  ),

                // First section of products (first 4)
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
                        return _StaggeredGridItem(
                          index: index,
                          alreadyAnimated: _animatedIndices.contains(index),
                          onAnimated: () => _animatedIndices.add(index),
                          child: ProductCard(
                            product: product,
                            onTap: () => _openProductDetail(product),
                            onFavorite: () => _onToggleFavorite(product),
                            onAddToCart: product.isInStock
                                ? () => _onAddToCart(product)
                                : null,
                          ),
                        );
                      },
                      childCount: _products.length > 4 && _shopAds.length >= 2
                          ? 4
                          : _products.length,
                    ),
                  ),
                ),

                // Second promoted ad after first 4 products
                if (_shopAds.length >= 2 && _products.length > 4)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: NativeAdCard(
                        servedAd: _shopAds[1],
                        onImpression: () => _recordShopAdImpression(_shopAds[1]),
                        onClick: () => _recordShopAdClick(_shopAds[1]),
                      ),
                    ),
                  ),

                // Remaining products (after 4)
                if (_shopAds.length >= 2 && _products.length > 4)
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
                          final realIndex = index + 4;
                          final product = _products[realIndex];
                          return _StaggeredGridItem(
                            index: realIndex,
                            alreadyAnimated: _animatedIndices.contains(realIndex),
                            onAnimated: () => _animatedIndices.add(realIndex),
                            child: ProductCard(
                              product: product,
                              onTap: () => _openProductDetail(product),
                              onFavorite: () => _onToggleFavorite(product),
                              onAddToCart: product.isInStock
                                  ? () => _onAddToCart(product)
                                  : null,
                            ),
                          );
                        },
                        childCount: _products.length - 4,
                      ),
                    ),
                  ),
              ],

              // 6. Loading more spinner
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

              // Bottom padding
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
            const HeroIcon(
              HeroIcons.magnifyingGlass,
              size: 20,
              color: _kTertiaryText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(fontSize: 14, color: _kPrimaryText),
                decoration: InputDecoration(
                  hintText: s?.searchProducts ?? 'Search products...',
                  hintStyle: const TextStyle(color: _kTertiaryText, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: const HeroIcon(
                  HeroIcons.xMark,
                  size: 18,
                  color: _kTertiaryText,
                ),
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
          icon: const HeroIcon(
            HeroIcons.shoppingCart,
            size: 24,
            color: _kPrimaryText,
          ),
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
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
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
      return _ShimmerContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 72,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kDivider,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        itemCount: _categories.length + 1, // +1 for "All"
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final isSelected = isAll
              ? _selectedCategoryId == null
              : _categories[index - 1].id == _selectedCategoryId;
          final label =
              isAll ? (s?.all ?? 'All') : _categories[index - 1].name;

          return GestureDetector(
            onTap: () => _onCategorySelected(
              isAll ? null : _categories[index - 1].id,
            ),
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

  Widget _buildFeaturedBanner() {
    if (_featuredLoading) {
      return _ShimmerContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: _kDivider,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (_featuredProducts.isEmpty) return const SizedBox.shrink();

    final displayCount =
        _featuredProducts.length > 5 ? 5 : _featuredProducts.length;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _featuredProducts.length,
            onPageChanged: (page) {
              setState(() => _bannerCurrentPage = page);
            },
            itemBuilder: (context, index) {
              final product = _featuredProducts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: GestureDetector(
                  onTap: () => _openProductDetail(product),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _kSurface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Product image
                        if (product.thumbnailPath != null)
                          CachedMediaImage(
                            imageUrl: product.thumbnailPath!,
                            fit: BoxFit.cover,
                          )
                        else if (product.images.isNotEmpty)
                          CachedMediaImage(
                            imageUrl: product.images.first,
                            fit: BoxFit.cover,
                          )
                        else
                          const Center(
                            child: HeroIcon(
                              HeroIcons.photo,
                              size: 48,
                              color: _kTertiaryText,
                            ),
                          ),
                        // Gradient overlay + text
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  product.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.priceFormatted,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Dot indicators
        if (_featuredProducts.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(displayCount, (index) {
                final isActive = index == _bannerCurrentPage % displayCount;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? _kPrimaryText : _kDivider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildSortBar() {
    final s = AppStringsScope.of(context);
    final countLabel = _isLoading
        ? ''
        : ' ($_totalProducts)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${s?.allProducts ?? 'All Products'}$countLabel',
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _buildSortChip(
            label: s?.newest ?? 'Newest',
            value: 'newest',
          ),
          const SizedBox(width: 6),
          _buildSortChip(
            label: s?.popular ?? 'Popular',
            value: 'popular',
          ),
          const SizedBox(width: 6),
          _buildSortChip(
            label: s?.price ?? 'Price',
            value: _sortBy == 'price_desc' ? 'price_desc' : 'price_asc',
            suffix: _sortBy == 'price_asc'
                ? ' \u2191'
                : _sortBy == 'price_desc'
                    ? ' \u2193'
                    : null,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _activeFilters != null &&
                        (_activeFilters!.minPrice != null ||
                            _activeFilters!.maxPrice != null ||
                            _activeFilters!.condition != null ||
                            _activeFilters!.minRating != null)
                    ? _kPrimaryText
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _activeFilters != null &&
                          (_activeFilters!.minPrice != null ||
                              _activeFilters!.maxPrice != null ||
                              _activeFilters!.condition != null ||
                              _activeFilters!.minRating != null)
                      ? _kPrimaryText
                      : _kDivider,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: _activeFilters != null &&
                        (_activeFilters!.minPrice != null ||
                            _activeFilters!.maxPrice != null ||
                            _activeFilters!.condition != null ||
                            _activeFilters!.minRating != null)
                    ? Colors.white
                    : _kSecondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip({
    required String label,
    required String value,
    String? suffix,
  }) {
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
          border: Border.all(
            color: isActive ? _kPrimaryText : _kDivider,
            width: 1,
          ),
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

  Widget _buildGridShimmer() {
    return _ShimmerContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (int row = 0; row < 3; row++)
              Padding(
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final s = AppStringsScope.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HeroIcon(
            HeroIcons.shoppingBag,
            size: 64,
            color: _kTertiaryText,
          ),
          const SizedBox(height: 16),
          Text(
            s?.noProducts ?? 'No products',
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? (s?.noProductsFound ?? 'No products found')
                : _selectedCategoryId != null
                    ? (s?.noCategoryProducts ?? 'No products in this category')
                    : (s?.productsWillAppear ?? 'Products will appear here'),
            style: const TextStyle(
              color: _kTertiaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Private helper widgets ─────────────────────────────────────────────────

/// Pulsing shimmer container — animates opacity of children.
class _ShimmerContainer extends StatefulWidget {
  final Widget child;
  const _ShimmerContainer({required this.child});

  @override
  State<_ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<_ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (_controller.value * 0.6),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Grid item with staggered fade + slide entry animation.
class _StaggeredGridItem extends StatefulWidget {
  final int index;
  final bool alreadyAnimated;
  final VoidCallback onAnimated;
  final Widget child;

  const _StaggeredGridItem({
    required this.index,
    required this.alreadyAnimated,
    required this.onAnimated,
    required this.child,
  });

  @override
  State<_StaggeredGridItem> createState() => _StaggeredGridItemState();
}

class _StaggeredGridItemState extends State<_StaggeredGridItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.alreadyAnimated) {
      _controller.value = 1.0;
    } else {
      Future.delayed(Duration(milliseconds: 40 * (widget.index % 6)), () {
        if (mounted) {
          _controller.forward();
          widget.onAnimated();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
