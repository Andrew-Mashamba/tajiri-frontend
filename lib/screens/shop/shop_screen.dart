import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';
import '../../widgets/shop/product_card.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

/// Main marketplace screen - Shop tab in bottom navigation.
/// Displays featured products, categories, trending items, and product grid.
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
  int? _selectedCategoryId;
  bool _categoriesLoading = true;

  // Featured products
  List<Product> _featuredProducts = [];
  bool _featuredLoading = true;

  // Trending products
  List<Product> _trendingProducts = [];
  bool _trendingLoading = true;

  // Recommended products
  List<Product> _recommendedProducts = [];
  bool _recommendedLoading = true;

  // All products (grid)
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  // Cart
  int _cartItemCount = 0;

  // Search
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCategories(),
      _loadFeaturedProducts(),
      _loadTrendingProducts(),
      _loadRecommendedProducts(),
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
      }
    });
  }

  Future<void> _loadTrendingProducts() async {
    setState(() => _trendingLoading = true);
    final result = await _shopService.getTrendingProducts(
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _trendingLoading = false;
      if (result.success) {
        _trendingProducts = result.products;
      }
    });
  }

  Future<void> _loadRecommendedProducts() async {
    setState(() => _recommendedLoading = true);
    final result = await _shopService.getRecommendedProducts(
      widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _recommendedLoading = false;
      if (result.success) {
        _recommendedProducts = result.products;
      }
    });
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    }

    setState(() => _isLoading = true);

    final result = await _shopService.getProducts(
      page: 1,
      perPage: 20,
      categoryId: _selectedCategoryId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      currentUserId: widget.currentUserId,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _products = result.products;
        _hasMore = result.meta?.hasMore ?? false;
        _currentPage = 1;
      }
    });
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _shopService.getProducts(
      page: _currentPage + 1,
      perPage: 20,
      categoryId: _selectedCategoryId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
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

  Future<void> _onToggleFavorite(Product product) async {
    final result = await _shopService.toggleFavorite(
      widget.currentUserId,
      product.id,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        // Update in all lists
        _updateProductFavorite(product.id, result.isFavorited);
      });
    }
  }

  void _updateProductFavorite(int productId, bool isFavorited) {
    // Helper to update a product in a list
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
    updateList(_trendingProducts);
    updateList(_recommendedProducts);
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
            onPressed: () => _openCart(),
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

  void _openCart() {
    Navigator.pushNamed(context, '/shop/cart');
  }

  void _openProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      '/shop/product',
      arguments: {'productId': product.id},
    );
  }

  void _openCategory(ProductCategory category) {
    Navigator.pushNamed(
      context,
      '/shop/category',
      arguments: {'category': category},
    );
  }

  void _openSearch() {
    Navigator.pushNamed(context, '/shop/search');
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadCategories(),
      _loadFeaturedProducts(),
      _loadTrendingProducts(),
      _loadRecommendedProducts(),
      _loadProducts(refresh: true),
      _loadCartCount(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App bar with search and cart
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: _kBackground,
                elevation: 0,
                titleSpacing: 0,
                title: _buildSearchBar(),
                actions: [
                  _buildCartButton(),
                  const SizedBox(width: 8),
                ],
              ),
            ];
          },
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: GestureDetector(
        onTap: _openSearch,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStringsScope.of(context)?.searchProducts ?? 'Search products...',
                  style: const TextStyle(
                    color: _kTertiaryText,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return Stack(
      children: [
        IconButton(
          onPressed: _openCart,
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

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        // Categories
        SliverToBoxAdapter(child: _buildCategoriesSection()),

        // Featured products
        if (_featuredProducts.isNotEmpty || _featuredLoading)
          SliverToBoxAdapter(child: _buildFeaturedSection()),

        // Trending products
        if (_trendingProducts.isNotEmpty || _trendingLoading)
          SliverToBoxAdapter(child: _buildTrendingSection()),

        // Recommended for you
        if (_recommendedProducts.isNotEmpty || _recommendedLoading)
          SliverToBoxAdapter(child: _buildRecommendedSection()),

        // All products header
        SliverToBoxAdapter(child: _buildSectionHeader(AppStringsScope.of(context)?.allProducts ?? 'All Products', null)),

        // Products grid
        _buildProductsGrid(),

        // Loading more indicator
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: _kPrimaryText),
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    if (_categoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
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
      );
    }

    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            s?.categories ?? 'Categories',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryItem(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(ProductCategory category) {
    return GestureDetector(
      onTap: () => _openCategory(category),
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: category.icon != null
                    ? Text(
                        category.icon!,
                        style: const TextStyle(fontSize: 28),
                      )
                    : const HeroIcon(
                        HeroIcons.squares2x2,
                        size: 28,
                        color: _kSecondaryText,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(s?.featured ?? 'Featured', null),
        _buildHorizontalProductList(
          _featuredProducts,
          _featuredLoading,
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(s?.trending ?? 'Trending', null),
        _buildHorizontalProductList(
          _trendingProducts,
          _trendingLoading,
        ),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    final s = AppStringsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(s?.forYou ?? 'For You', null),
        _buildHorizontalProductList(
          _recommendedProducts,
          _recommendedLoading,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    AppStringsScope.of(context)?.viewAll ?? 'View all',
                    style: const TextStyle(
                      color: _kSecondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const HeroIcon(
                    HeroIcons.chevronRight,
                    size: 16,
                    color: _kSecondaryText,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductList(List<Product> products, bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
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
      );
    }

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: 160,
            child: ProductCard(
              product: product,
              compact: true,
              showSeller: false,
              onTap: () => _openProductDetail(product),
              onFavorite: () => _onToggleFavorite(product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: _kPrimaryText),
        ),
      );
    }

    if (_products.isEmpty) {
      final s = AppStringsScope.of(context);
      return SliverFillRemaining(
        child: Center(
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
                _selectedCategoryId != null
                    ? s?.noCategoryProducts ?? 'No products in this category'
                    : s?.productsWillAppear ?? 'Products will appear here',
                style: const TextStyle(
                  color: _kTertiaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

}
