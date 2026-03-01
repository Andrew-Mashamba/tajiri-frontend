import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';
import '../../services/local_storage_service.dart';
import '../cached_media_image.dart';

// DESIGN.md tokens (monochrome palette)
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF22C55E);
const Color _kWarning = Color(0xFFF59E0B);
const Color _kError = Color(0xFFDC2626);

/// Shopify-style seller dashboard for profile shop tab.
/// Features:
/// - Stats overview (products, orders, revenue)
/// - Product management with status filters
/// - Quick actions (add, edit, delete products)
/// - Pending orders summary
class ShopGalleryWidget extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onProductAdded;

  const ShopGalleryWidget({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onProductAdded,
  });

  @override
  State<ShopGalleryWidget> createState() => _ShopGalleryWidgetState();
}

class _ShopGalleryWidgetState extends State<ShopGalleryWidget>
    with SingleTickerProviderStateMixin {
  final ShopService _shopService = ShopService();
  final ScrollController _scrollController = ScrollController();

  // State
  List<Product> _products = [];
  List<Order> _pendingOrders = [];
  SellerStats? _stats;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  int? _currentUserId;

  // Filters
  ProductStatus? _statusFilter;
  late TabController _tabController;

  // Status filter options (status, key)
  final List<(ProductStatus?, String)> _statusFilters = [
    (null, 'all'),
    (ProductStatus.active, 'active'),
    (ProductStatus.draft, 'draft'),
    (ProductStatus.soldOut, 'soldOut'),
  ];

  String _getStatusLabel(BuildContext context, ProductStatus? status) {
    final s = AppStringsScope.of(context);
    switch (status) {
      case null:
        return s?.all ?? 'All';
      case ProductStatus.active:
        return s?.statusActive ?? 'Active';
      case ProductStatus.draft:
        return s?.statusDraft ?? 'Draft';
      case ProductStatus.soldOut:
        return s?.statusSoldOut ?? 'Sold Out';
      case ProductStatus.archived:
        return s?.statusArchived ?? 'Archived';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCurrentUser();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (mounted && user?.userId != null) {
      setState(() => _currentUserId = user!.userId);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final newStatus = _statusFilters[_tabController.index].$1;
    if (newStatus != _statusFilter) {
      setState(() {
        _statusFilter = newStatus;
        _products = [];
        _currentPage = 1;
        _hasMore = true;
      });
      _loadProducts();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.wait([
      _loadProducts(),
      if (widget.isOwnProfile) ...[
        _loadStats(),
        _loadPendingOrders(),
      ],
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    final result = await _shopService.getSellerProducts(
      widget.userId,
      status: _statusFilter,
      page: 1,
      perPage: 20,
      currentUserId: _currentUserId,
    );

    if (mounted) {
      setState(() {
        if (result.success) {
          _products = result.products;
          _hasMore = result.meta?.hasMore ?? false;
          _currentPage = 1;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    final result = await _shopService.getSellerProducts(
      widget.userId,
      status: _statusFilter,
      page: _currentPage,
      perPage: 20,
      currentUserId: _currentUserId,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _products.addAll(result.products);
          _hasMore = result.meta?.hasMore ?? false;
        }
      });
    }
  }

  Future<void> _loadStats() async {
    final result = await _shopService.getSellerStats(widget.userId);
    if (mounted && result.success) {
      setState(() => _stats = result.stats);
    }
  }

  Future<void> _loadPendingOrders() async {
    final result = await _shopService.getSellerOrders(
      widget.userId,
      status: OrderStatus.pending,
      page: 1,
      perPage: 5,
    );
    if (mounted && result.success) {
      setState(() => _pendingOrders = result.orders);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  void _navigateToAddProduct() {
    Navigator.pushNamed(context, '/shop/create-product').then((result) {
      if (result == true) {
        _loadData();
        widget.onProductAdded?.call();
      }
    });
  }

  void _navigateToEditProduct(Product product) {
    Navigator.pushNamed(
      context,
      '/shop/edit-product',
      arguments: {'product': product},
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  void _navigateToProductDetail(Product product) {
    Navigator.pushNamed(
      context,
      '/shop/product',
      arguments: {'productId': product.id},
    );
  }

  void _navigateToOrders() {
    Navigator.pushNamed(context, '/shop/seller-orders');
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.pushNamed(
      context,
      '/shop/order',
      arguments: {'orderId': order.id},
    );
  }

  Future<void> _toggleProductStatus(Product product) async {
    final s = AppStringsScope.of(context);
    final newStatus = product.status == ProductStatus.active
        ? ProductStatus.soldOut
        : ProductStatus.active;

    final result = await _shopService.updateProduct(
      productId: product.id,
      sellerId: widget.userId,
      status: newStatus,
    );

    if (mounted) {
      if (result.success) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == ProductStatus.active
                ? (s?.productActivated ?? 'Product is now active')
                : (s?.productPaused ?? 'Product sales paused')),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (s?.failedToUpdateStatus ?? 'Failed to update status'))),
        );
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final s = AppStringsScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.deleteProduct ?? 'Delete Product'),
        content: Text(s?.deleteProductConfirm(product.title) ?? 'Are you sure you want to delete "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.no ?? 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kError),
            child: Text(s?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _shopService.deleteProduct(product.id, widget.userId);
    if (mounted) {
      if (success) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s?.productDeleted ?? 'Product deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s?.failedToDelete ?? 'Failed to delete product')),
        );
      }
    }
  }

  void _showProductActions(Product product) {
    final s = AppStringsScope.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HeroIcon(HeroIcons.eye),
              title: Text(s?.view ?? 'View'),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToProductDetail(product);
              },
            ),
            ListTile(
              leading: const HeroIcon(HeroIcons.pencilSquare),
              title: Text(s?.edit ?? 'Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToEditProduct(product);
              },
            ),
            ListTile(
              leading: HeroIcon(
                product.status == ProductStatus.active
                    ? HeroIcons.pause
                    : HeroIcons.play,
              ),
              title: Text(product.status == ProductStatus.active
                  ? (s?.pauseSales ?? 'Pause Sales')
                  : (s?.resumeSales ?? 'Resume Sales')),
              onTap: () {
                Navigator.pop(ctx);
                _toggleProductStatus(product);
              },
            ),
            const Divider(),
            ListTile(
              leading: const HeroIcon(HeroIcons.trash, color: _kError),
              title: Text(s?.delete ?? 'Delete', style: const TextStyle(color: _kError)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteProduct(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _products.isEmpty && _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _products.isEmpty) {
      return _buildErrorState(context);
    }

    // For non-owner viewing, show simple product grid
    if (!widget.isOwnProfile) {
      return _buildViewerMode(context);
    }

    // Owner's seller dashboard
    return _buildSellerDashboard(context);
  }

  Widget _buildErrorState(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HeroIcon(HeroIcons.exclamationTriangle, size: 48, color: _kTertiaryText),
          const SizedBox(height: 16),
          Text(_error ?? (s?.errorOccurred ?? 'An error occurred'), style: const TextStyle(color: _kSecondaryText)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: Text(s?.tryAgain ?? 'Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerMode(BuildContext context) {
    if (_products.isEmpty) {
      return _buildEmptyState(context, isOwner: false);
    }

    return Column(
      children: [
        _buildViewerHeader(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: _buildProductsGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildViewerHeader(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const HeroIcon(HeroIcons.shoppingBag, size: 20, color: _kSecondaryText),
          const SizedBox(width: 8),
          Text(
            s?.productsCount(_products.length) ?? '${_products.length} products',
            style: const TextStyle(
              color: _kSecondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerDashboard(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Stats Cards
          SliverToBoxAdapter(child: _buildStatsSection(context)),

          // Quick Actions
          SliverToBoxAdapter(child: _buildQuickActions(context)),

          // Pending Orders (if any)
          if (_pendingOrders.isNotEmpty)
            SliverToBoxAdapter(child: _buildPendingOrdersSection(context)),

          // Products Section Header
          SliverToBoxAdapter(child: _buildProductsSectionHeader(context)),

          // Status Filter Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: _kPrimaryText,
                unselectedLabelColor: _kSecondaryText,
                indicatorColor: _kPrimaryText,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: _statusFilters.map((filter) {
                  final count = _getStatusCount(filter.$1);
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getStatusLabel(context, filter.$1)),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kDivider,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Products Grid or Empty State
          if (_products.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(context, isOwner: true))
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                    if (index >= _products.length) return null;
                    return _buildSellerProductCard(ctx, _products[index]);
                  },
                  childCount: _products.length,
                ),
              ),
            ),

          // Loading More Indicator
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  int _getStatusCount(ProductStatus? status) {
    if (_stats == null) return 0;
    switch (status) {
      case null:
        return _stats!.totalProducts;
      case ProductStatus.active:
        return _stats!.activeProducts;
      case ProductStatus.draft:
        return _stats!.totalProducts - _stats!.activeProducts; // Approximation
      default:
        return 0;
    }
  }

  Widget _buildStatsSection(BuildContext context) {
    final s = AppStringsScope.of(context);
    final stats = _stats ?? SellerStats();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.shopSummary ?? 'Shop Summary',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: HeroIcons.shoppingBag,
                label: s?.products ?? 'Products',
                value: '${stats.totalProducts}',
                subValue: s?.productsActive(stats.activeProducts) ?? '${stats.activeProducts} active',
                color: _kPrimaryText,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                icon: HeroIcons.clipboardDocumentList,
                label: s?.orders ?? 'Orders',
                value: '${stats.totalOrders}',
                subValue: s?.ordersPending(stats.pendingOrders) ?? '${stats.pendingOrders} pending',
                color: stats.pendingOrders > 0 ? _kWarning : _kPrimaryText,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: HeroIcons.banknotes,
                label: s?.revenue ?? 'Revenue',
                value: stats.revenueFormatted,
                subValue: s?.ordersCompleted(stats.completedOrders) ?? '${stats.completedOrders} completed',
                color: _kSuccess,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                icon: HeroIcons.star,
                label: s?.rating ?? 'Rating',
                value: stats.averageRating.toStringAsFixed(1),
                subValue: s?.reviewsCount2(stats.totalReviews) ?? '${stats.totalReviews} reviews',
                color: _kWarning,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required HeroIcons icon,
    required String label,
    required String value,
    required String subValue,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeroIcon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _kSecondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 11,
              color: _kTertiaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: HeroIcons.plus,
              label: s?.addProduct ?? 'Add Product',
              onTap: _navigateToAddProduct,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: HeroIcons.clipboardDocumentList,
              label: s?.myOrders ?? 'My Orders',
              onTap: _navigateToOrders,
              badge: _pendingOrders.isNotEmpty ? '${_pendingOrders.length}' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required HeroIcons icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    String? badge,
  }) {
    return Material(
      color: isPrimary ? _kPrimaryText : _kSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: isPrimary ? null : Border.all(color: _kDivider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeroIcon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : _kPrimaryText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : _kPrimaryText,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kWarning,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingOrdersSection(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _kWarning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s?.pendingOrders ?? 'Pending Orders',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryText,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _navigateToOrders,
                child: Text(s?.viewAll ?? 'View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_pendingOrders.take(3).map((order) => _buildPendingOrderCard(context, order))),
        ],
      ),
    );
  }

  Widget _buildPendingOrderCard(BuildContext context, Order order) {
    final s = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kWarning.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order),
        child: Row(
          children: [
            // Product thumbnail
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: order.product?.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedMediaImage(
                        imageUrl: order.product!.thumbnailUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const HeroIcon(HeroIcons.shoppingBag, size: 24, color: _kTertiaryText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.product?.title ?? (s?.productNumber(order.productId) ?? 'Product #${order.productId}'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.buyer?.firstName ?? (s?.buyer ?? 'Buyer')} • ${order.totalFormatted}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                order.status.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kWarning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSectionHeader(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            s?.myProducts ?? 'My Products',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimaryText,
            ),
          ),
          Text(
            s?.totalCount(_stats?.totalProducts ?? _products.length) ?? '${_stats?.totalProducts ?? _products.length} total',
            style: const TextStyle(
              fontSize: 13,
              color: _kSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerProductCard(BuildContext context, Product product) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      onLongPress: () => _showProductActions(product),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kDivider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status badge and menu
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Product image
                  CachedMediaImage(
                    imageUrl: product.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: _kBackground,
                      child: const Center(
                        child: HeroIcon(HeroIcons.photo, size: 32, color: _kTertiaryText),
                      ),
                    ),
                  ),

                  // Status badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(product.status).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.status.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Menu button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => _showProductActions(product),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: HeroIcon(HeroIcons.ellipsisVertical, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Sold out overlay
                  if (product.status == ProductStatus.soldOut)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Center(
                        child: Text(
                          s?.soldOut2 ?? 'SOLD OUT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      product.priceFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const HeroIcon(HeroIcons.eye, size: 12, color: _kTertiaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${product.viewsCount}',
                          style: const TextStyle(fontSize: 11, color: _kTertiaryText),
                        ),
                        const SizedBox(width: 12),
                        const HeroIcon(HeroIcons.shoppingCart, size: 12, color: _kTertiaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${product.ordersCount}',
                          style: const TextStyle(fontSize: 11, color: _kTertiaryText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return _kSuccess;
      case ProductStatus.draft:
        return _kSecondaryText;
      case ProductStatus.soldOut:
        return _kError;
      case ProductStatus.archived:
        return _kTertiaryText;
    }
  }

  Widget _buildProductsGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildViewerProductCard(_products[index]);
      },
    );
  }

  Widget _buildViewerProductCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: CachedMediaImage(
                imageUrl: product.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: _kBackground,
                  child: const Center(
                    child: HeroIcon(HeroIcons.photo, size: 32, color: _kTertiaryText),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      product.priceFormatted,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kPrimaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isOwner}) {
    final s = AppStringsScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _kDivider.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const HeroIcon(
                        HeroIcons.shoppingBag,
                        size: 48,
                        color: _kTertiaryText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isOwner
                          ? (s?.noProductsYet ?? 'No Products Yet')
                          : (s?.noProductsFound ?? 'No Products'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOwner
                          ? (s?.startSellingMessage ?? 'Start selling by adding your first product')
                          : (s?.sellerNoProducts ?? 'This seller has no products yet'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kSecondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddProduct,
                        icon: const HeroIcon(HeroIcons.plus, size: 20),
                        label: Text(s?.addProduct ?? 'Add Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryText,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Sliver delegate for pinned tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _kBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
