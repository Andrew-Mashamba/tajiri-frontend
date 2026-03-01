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

/// Category products screen with filtering and sorting.
class CategoryScreen extends StatefulWidget {
  final ProductCategory category;
  final int currentUserId;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.currentUserId,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ShopService _shopService = ShopService();
  final ScrollController _scrollController = ScrollController();

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  // Filters
  String _sortBy = 'newest';
  ProductCondition? _condition;
  ProductType? _type;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      categoryId: widget.category.id,
      sortBy: _sortBy,
      condition: _condition,
      type: _type,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
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
      categoryId: widget.category.id,
      sortBy: _sortBy,
      condition: _condition,
      type: _type,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        sortBy: _sortBy,
        condition: _condition,
        type: _type,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        onApply: (sortBy, condition, type, minPrice, maxPrice) {
          setState(() {
            _sortBy = sortBy;
            _condition = condition;
            _type = type;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
          });
          _loadProducts(refresh: true);
        },
      ),
    );
  }

  void _openProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      '/shop/product',
      arguments: {'productId': product.id},
    );
  }

  Future<void> _toggleFavorite(Product product) async {
    final result = await _shopService.toggleFavorite(
      widget.currentUserId,
      product.id,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          final old = _products[index];
          _products[index] = Product(
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
            favoritesCount: old.favoritesCount,
            ordersCount: old.ordersCount,
            rating: old.rating,
            reviewsCount: old.reviewsCount,
            seller: old.seller,
            category: old.category,
            isFavorited: result.isFavorited,
            createdAt: old.createdAt,
            updatedAt: old.updatedAt,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
        title: Row(
          children: [
            if (widget.category.icon != null) ...[
              Text(
                widget.category.icon!,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.category.name,
              style: const TextStyle(
                color: _kPrimaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: const HeroIcon(
              HeroIcons.adjustmentsHorizontal,
              size: 24,
              color: _kPrimaryText,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Sort and filter chips
            SliverToBoxAdapter(
              child: _buildSortChips(),
            ),

            // Products grid
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: _kPrimaryText),
                    ),
                  )
                : _products.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
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
                                onFavorite: () => _toggleFavorite(product),
                              );
                            },
                            childCount: _products.length,
                          ),
                        ),
                      ),

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
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChips() {
    final s = AppStringsScope.of(context);
    final sortOptions = [
      ('newest', s?.sortNewest ?? 'Newest'),
      ('popular', s?.sortPopular ?? 'Popular'),
      ('price_asc', s?.sortPriceLow ?? 'Price: Low'),
      ('price_desc', s?.sortPriceHigh ?? 'Price: High'),
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = sortOptions[index];
          final isSelected = _sortBy == value;
          return GestureDetector(
            onTap: () {
              setState(() => _sortBy = value);
              _loadProducts(refresh: true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _kPrimaryText : _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _kPrimaryText : _kDivider,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _kPrimaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
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
            s?.noCategoryProducts ?? 'No products in this category',
            style: const TextStyle(
              color: _kTertiaryText,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryText,
              foregroundColor: Colors.white,
            ),
            child: Text(s?.goBack ?? 'Go Back'),
          ),
        ],
      ),
    );
  }
}

/// Filter sheet for category products.
class _FilterSheet extends StatefulWidget {
  final String sortBy;
  final ProductCondition? condition;
  final ProductType? type;
  final double? minPrice;
  final double? maxPrice;
  final Function(
    String sortBy,
    ProductCondition? condition,
    ProductType? type,
    double? minPrice,
    double? maxPrice,
  ) onApply;

  const _FilterSheet({
    required this.sortBy,
    this.condition,
    this.type,
    this.minPrice,
    this.maxPrice,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _sortBy;
  ProductCondition? _condition;
  ProductType? _type;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sortBy = widget.sortBy;
    _condition = widget.condition;
    _type = widget.type;
    if (widget.minPrice != null) {
      _minPriceController.text = widget.minPrice!.toStringAsFixed(0);
    }
    if (widget.maxPrice != null) {
      _maxPriceController.text = widget.maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onApply(
      _sortBy,
      _condition,
      _type,
      _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text)
          : null,
      _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text)
          : null,
    );
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _sortBy = 'newest';
      _condition = null;
      _type = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s?.filterAndSort ?? 'Filter & Sort',
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: Text(
                  s?.clearAll ?? 'Clear All',
                  style: const TextStyle(color: _kSecondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Product type
          Text(
            s?.productType ?? 'Product Type',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: s?.all ?? 'All',
                isSelected: _type == null,
                onTap: () => setState(() => _type = null),
              ),
              ...ProductType.values.map((type) => _buildFilterChip(
                    label: type.label,
                    isSelected: _type == type,
                    onTap: () => setState(() => _type = type),
                  )),
            ],
          ),
          const SizedBox(height: 20),

          // Condition
          Text(
            s?.condition ?? 'Condition',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: s?.all ?? 'All',
                isSelected: _condition == null,
                onTap: () => setState(() => _condition = null),
              ),
              ...ProductCondition.values.map((condition) => _buildFilterChip(
                    label: condition.label,
                    isSelected: _condition == condition,
                    onTap: () => setState(() => _condition = condition),
                  )),
            ],
          ),
          const SizedBox(height: 20),

          // Price range
          Text(
            '${s?.price ?? 'Price'} (TZS)',
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: s?.min ?? 'Min',
                    hintStyle: const TextStyle(color: _kTertiaryText),
                    filled: true,
                    fillColor: _kBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('—', style: TextStyle(color: _kTertiaryText)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: s?.max ?? 'Max',
                    hintStyle: const TextStyle(color: _kTertiaryText),
                    filled: true,
                    fillColor: _kBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                s?.applyFilters ?? 'Apply Filters',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimaryText : _kBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kPrimaryText : _kDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _kPrimaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
