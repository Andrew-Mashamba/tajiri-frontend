import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/shop_models.dart';
import '../../../services/shop_service.dart' show SellerStats;
import '../../data/repositories/shop_repository.dart';
import '../../routes/shop_routes.dart';
import '../../../services/local_storage_service.dart';
import './seller_analytics_screen.dart';
import './create_product_post_screen.dart';
import './seller_notifications_screen.dart';
import './seller_verification_screen.dart';
import '../../shared/widgets/product_card.dart';
import '../../social_commerce/screens/live_shopping_screen.dart';
import '../../payments/screens/shop_wallet_screen.dart';
import '../../common/screens/shop_feature_hub_screen.dart';
import '../../inventory/screens/restock_alerts_screen.dart';
import '../../reviews/screens/seller_reviews_screen.dart';
import '../models/trust_models.dart';
import '../services/seller_verification_service.dart';

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

// DESIGN.md shadow token §7.1
const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000), // black 0.1
  blurRadius: 4,
  offset: Offset(0, 2),
);

/// Shopify-style seller dashboard for profile shop tab.
/// Features:
/// - Stats overview (products, orders, revenue)
/// - Product management with status filters
/// - Quick actions (add, edit, delete products)
/// - Pending orders summary
class MyShopScreen extends StatefulWidget {
  final int userId;
  final bool isOwnProfile;
  final VoidCallback? onProductAdded;

  const MyShopScreen({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
    this.onProductAdded,
  });

  @override
  State<MyShopScreen> createState() => _MyShopScreenState();
}

class _MyShopScreenState extends State<MyShopScreen>
    with SingleTickerProviderStateMixin {
  final ShopRepository _repo = ShopRepository.instance;
  final ScrollController _scrollController = ScrollController();

  // State
  List<Product> _allProducts = []; // Unfiltered master list
  List<Product> _products = [];    // Filtered for current tab
  SellerStats? _stats;
  SellerVerificationStatus? _verificationStatus;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  int? _currentUserId;
  String? _token;

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
    final token = storage.getAuthToken();
    if (mounted) {
      setState(() {
        if (user?.userId != null) _currentUserId = user!.userId;
        _token = token;
      });
    }
    if (token != null && widget.isOwnProfile) {
      final status = await SellerVerificationService.getVerificationStatus(token);
      if (mounted) setState(() => _verificationStatus = status);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final newStatus = _statusFilters[_tabController.index].$1;
    if (newStatus != _statusFilter) {
      setState(() {
        _statusFilter = newStatus;
        _products = _filterProducts(_allProducts, newStatus);
      });
    }
  }

  List<Product> _filterProducts(List<Product> products, ProductStatus? status) {
    if (status == null) return List.of(products);
    return products.where((p) => p.status == status).toList();
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
      ],
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    final result = await _repo.getSellerProducts(
      widget.userId,
      page: 1,
      perPage: 20,
      currentUserId: _currentUserId,
    );

    if (mounted) {
      setState(() {
        if (result.success) {
          _allProducts = result.products;
          _products = _filterProducts(_allProducts, _statusFilter);
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

    final result = await _repo.getSellerProducts(
      widget.userId,
      page: _currentPage,
      perPage: 20,
      currentUserId: _currentUserId,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _allProducts.addAll(result.products);
          _products = _filterProducts(_allProducts, _statusFilter);
          _hasMore = result.meta?.hasMore ?? false;
        }
      });
    }
  }

  Future<void> _loadStats() async {
    final result = await _repo.getSellerStats(widget.userId);
    if (mounted && result.success) {
      setState(() => _stats = result.stats);
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

  void _navigateToAdCampaigns() {
    Navigator.pushNamed(context, ShopRoutes.adCampaigns);
  }

  void _navigateToFeatures() {
    Navigator.pushNamed(context, ShopRoutes.features);
  }

  Future<void> _toggleProductStatus(Product product) async {
    final s = AppStringsScope.of(context);
    final newStatus = product.status == ProductStatus.active
        ? ProductStatus.soldOut
        : ProductStatus.active;

    final result = await _repo.updateProduct(
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

    final success = await _repo.deleteProduct(product.id, widget.userId);
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
      return SafeArea(child: _buildShimmerLoading(context));
    }

    if (_error != null && _products.isEmpty) {
      return SafeArea(child: _buildErrorState(context));
    }

    // For non-owner viewing, show simple product grid
    if (!widget.isOwnProfile) {
      return SafeArea(child: _buildViewerMode(context));
    }

    // Owner's seller dashboard
    return SafeArea(child: _buildSellerDashboard(context));
  }

  // ─── Shimmer Loading ──────────────────────────────────────────────────

  Widget _buildShimmerLoading(BuildContext context) {
    return _ShimmerContainer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title placeholder
            _buildShimmerBox(width: 120, height: 20),
            const SizedBox(height: 16),
            // Stats cards skeleton (2x2 grid)
            if (widget.isOwnProfile) ...[
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 100)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerBox(height: 100)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 100)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerBox(height: 100)),
                ],
              ),
              const SizedBox(height: 16),
              // Quick action buttons skeleton
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 56)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerBox(height: 56)),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Products section title placeholder
            _buildShimmerBox(width: 100, height: 18),
            const SizedBox(height: 16),
            // Product grid skeleton (2x2)
            Row(
              children: [
                Expanded(child: _buildShimmerBox(height: 220)),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerBox(height: 220)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildShimmerBox(height: 220)),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerBox(height: 220)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kDivider,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ─── Error State ──────────────────────────────────────────────────────

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

  // ─── Viewer Mode ──────────────────────────────────────────────────────

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

  // ─── Seller Dashboard ─────────────────────────────────────────────────

  Widget _buildSellerDashboard(BuildContext context) {
    final stats = _stats ?? SellerStats();
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimaryText,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. Search + nav bar — always visible
          SliverToBoxAdapter(child: _buildGlobalCommandBar(context)),
          // 2. TODAY CENTER — revenue, orders, visitors at a glance
          SliverToBoxAdapter(child: _buildTodayCenter(context, stats)),
          // 3. ACTION REQUIRED — urgent items (pending orders, low stock, messages)
          SliverToBoxAdapter(child: _buildActionRequired(context, stats)),
          // 3b. Verification CTA (unverified sellers only)
          if (_verificationStatus != null &&
              _verificationStatus!.verificationStatus != 'verified')
            SliverToBoxAdapter(child: _buildVerificationCta(context)),
          // 4. Quick fire actions
          SliverToBoxAdapter(child: _buildQuickActions(context)),
          // 5. Module OS grid (navigation)
          SliverToBoxAdapter(child: _buildOperatingSystemGrid(context, stats)),
          // 6. Products
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
                    return _StaggeredEntry(
                      index: index,
                      child: _buildSellerProductCard(ctx, _products[index]),
                    );
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

  // ─── TODAY CENTER ─────────────────────────────────────────────────────────

  Widget _buildTodayCenter(BuildContext context, SellerStats stats) {
    final revenue = stats.revenueFormatted.isNotEmpty ? stats.revenueFormatted : 'TZS 0';
    final pendingCount = stats.pendingOrders;
    final completedCount = stats.completedOrders;
    final totalProducts = stats.totalProducts;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimaryText,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.wb_sunny_rounded, color: Colors.white54, size: 14),
            const SizedBox(width: 6),
            Text(
              _todayLabel(),
              style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SellerAnalyticsScreen(sellerId: widget.userId),
              )),
              child: const Row(children: [
                Text('Full analytics', style: TextStyle(color: Colors.white54, fontSize: 11)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 10),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            revenue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Text('Total Revenue', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 16),
          Row(children: [
            _buildTodayStat('$pendingCount', 'Pending', Icons.hourglass_top_rounded,
                pendingCount > 0 ? const Color(0xFFFBBF24) : Colors.white70),
            _buildTodayDivider(),
            _buildTodayStat('$completedCount', 'Completed', Icons.check_circle_outline_rounded, Colors.white70),
            _buildTodayDivider(),
            _buildTodayStat('$totalProducts', 'Products', Icons.inventory_2_rounded, Colors.white70),
            _buildTodayDivider(),
            _buildTodayStat(
              stats.averageRating > 0 ? stats.averageRating.toStringAsFixed(1) : '—',
              'Rating',
              Icons.star_rounded,
              stats.averageRating >= 4 ? const Color(0xFFFBBF24) : Colors.white70,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildTodayStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildTodayDivider() {
    return Container(width: 1, height: 36, color: Colors.white12, margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  String _todayLabel() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ─── ACTION REQUIRED ──────────────────────────────────────────────────────

  Widget _buildActionRequired(BuildContext context, SellerStats stats) {
    final items = <_ActionItem>[];

    if (stats.pendingOrders > 0) {
      items.add(_ActionItem(
        icon: Icons.shopping_bag_rounded,
        label: '${stats.pendingOrders} order${stats.pendingOrders > 1 ? 's' : ''} awaiting confirmation',
        urgency: _Urgency.high,
        onTap: _navigateToOrders,
      ));
    }

    final lowStockCount = _allProducts.where((p) => p.stockQuantity <= 4 && p.stockQuantity >= 0).length;
    final outOfStockCount = _allProducts.where((p) => p.stockQuantity == 0).length;
    if (outOfStockCount > 0) {
      items.add(_ActionItem(
        icon: Icons.inventory_2_rounded,
        label: '$outOfStockCount product${outOfStockCount > 1 ? 's' : ''} out of stock',
        urgency: _Urgency.high,
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const RestockAlertsScreen(),
        )),
      ));
    } else if (lowStockCount > 0) {
      items.add(_ActionItem(
        icon: Icons.warning_amber_rounded,
        label: '$lowStockCount product${lowStockCount > 1 ? 's' : ''} running low on stock',
        urgency: _Urgency.medium,
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const RestockAlertsScreen(),
        )),
      ));
    }

    if (stats.totalReviews > 0) {
      items.add(_ActionItem(
        icon: Icons.star_rounded,
        label: '${stats.totalReviews} review${stats.totalReviews > 1 ? 's' : ''} — check your ratings',
        urgency: _Urgency.low,
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const SellerReviewsScreen(),
        )),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              const Icon(Icons.notifications_active_rounded, size: 16, color: _kPrimaryText),
              const SizedBox(width: 8),
              const Text('Action Required', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kPrimaryText)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: _kPrimaryText, borderRadius: BorderRadius.circular(10)),
                child: Text('${items.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          ...items.map((item) => _buildActionRequiredRow(item)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildActionRequiredRow(_ActionItem item) {
    final Color dotColor;
    switch (item.urgency) {
      case _Urgency.high:
        dotColor = _kError;
        break;
      case _Urgency.medium:
        dotColor = _kWarning;
        break;
      case _Urgency.low:
        dotColor = const Color(0xFF22C55E);
        break;
    }

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Icon(item.icon, size: 18, color: _kSecondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 13, color: _kPrimaryText, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 16, color: _kTertiaryText),
        ]),
      ),
    );
  }

  // ─── VERIFICATION CTA ─────────────────────────────────────────────────────

  Widget _buildVerificationCta(BuildContext context) {
    final isPending = _verificationStatus?.verificationStatus == 'pending';
    final isRejected = _verificationStatus?.verificationStatus == 'rejected';

    final String title;
    final String subtitle;
    final IconData icon;
    final Color accentColor;

    if (isPending) {
      title = 'Verification Under Review';
      subtitle = 'We\'ll notify you within 48 hours once reviewed.';
      icon = Icons.hourglass_top_rounded;
      accentColor = const Color(0xFFF59E0B);
    } else if (isRejected) {
      title = 'Verification Rejected';
      subtitle = 'Resubmit with valid documents to get verified.';
      icon = Icons.cancel_rounded;
      accentColor = const Color(0xFFDC2626);
    } else {
      title = 'Get Verified — Sell More';
      subtitle = 'Verified sellers earn more buyer trust and higher conversion.';
      icon = Icons.shield_rounded;
      accentColor = _kPrimaryText;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kPrimaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSecondaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isPending) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SellerVerificationScreen(),
                ),
              ).then((_) {
                if (_token != null) {
                  SellerVerificationService.getVerificationStatus(_token!).then((s) {
                    if (mounted) setState(() => _verificationStatus = s);
                  });
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kPrimaryText,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isRejected ? 'Resubmit' : 'Get Verified',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── QUICK ACTIONS ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        Expanded(child: _buildActionButton(
          icon: HeroIcons.plus,
          label: s?.addProduct ?? 'Add Product',
          onTap: _navigateToAddProduct,
          isPrimary: true,
        )),
        const SizedBox(width: 10),
        Expanded(child: _buildActionButton(
          icon: HeroIcons.clipboardDocumentList,
          label: s?.myOrders ?? 'Orders',
          onTap: _navigateToOrders,
        )),
        const SizedBox(width: 10),
        Expanded(child: _buildActionButton(
          icon: HeroIcons.megaphone,
          label: 'Ads',
          onTap: _navigateToAdCampaigns,
        )),
        const SizedBox(width: 10),
        Expanded(child: _buildActionButton(
          icon: HeroIcons.queueList,
          label: 'More',
          onTap: _navigateToFeatures,
        )),
      ]),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: isPrimary ? null : const [_kCardShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroIcon(icon, size: 20, color: isPrimary ? Colors.white : _kPrimaryText),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : _kPrimaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (badge != null) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: _kError, borderRadius: BorderRadius.circular(8)),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── GLOBAL COMMAND BAR ───────────────────────────────────────────────────

  Widget _buildGlobalCommandBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const HeroIcon(HeroIcons.bars3, color: _kPrimaryText, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kDivider),
                  ),
                  child: InkWell(
                    onTap: _navigateToFeatures,
                    borderRadius: BorderRadius.circular(12),
                    child: const Row(
                      children: [
                        SizedBox(width: 10),
                        HeroIcon(HeroIcons.magnifyingGlass, size: 18, color: _kSecondaryText),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search products, orders, customers, ads...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: _kSecondaryText, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SellerNotificationsScreen(),
                  ),
                ),
                icon: const HeroIcon(HeroIcons.bell, color: _kPrimaryText, size: 20),
              ),
              IconButton(
                tooltip: 'Messages',
                onPressed: () => Navigator.pushNamed(context, ShopRoutes.sellerInbox),
                icon: const HeroIcon(HeroIcons.chatBubbleLeftRight, color: _kPrimaryText, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTopNavPill('Orders', _navigateToOrders),
                _buildTopNavPill('Products', _navigateToAddProduct),
                _buildTopNavPill('Content', () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateProductPostScreen(),
                      ),
                    )),
                _buildTopNavPill('Ads', _navigateToAdCampaigns),
                _buildTopNavPill('Live', () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveShoppingScreen(),
                      ),
                    )),
                _buildTopNavPill('Customers', () => Navigator.pushNamed(context, ShopRoutes.sellerInbox)),
                _buildTopNavPill('Wallet', () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopWalletScreen(userId: widget.userId),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavPill(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kDivider),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatingSystemGrid(BuildContext context, SellerStats stats) {
    final modules = _buildOperatingSystemModules(context, stats);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seller Operating System',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kPrimaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Core modules grouped in a 3-column control grid',
            style: TextStyle(
              fontSize: 12,
              color: _kSecondaryText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) => _buildOperatingSystemCard(
              module: modules[index],
            ),
          ),
        ],
      ),
    );
  }

  List<({
    HeroIcons icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  })> _buildOperatingSystemModules(BuildContext context, SellerStats stats) {
    return [
      (
        icon: HeroIcons.fire,
        title: 'Today Center',
        subtitle: '${stats.pendingOrders} actions due today',
        onTap: () => _openModuleFeatures(
          title: 'Today Center',
          groups: const ['seller', 'inventory', 'shipping', 'moderation'],
        ),
      ),
      (
        icon: HeroIcons.plusCircle,
        title: 'Create & Grow',
        subtitle: 'Add products and launch offers',
        onTap: () => _openModuleFeatures(
          title: 'Create & Grow',
          groups: const ['seller'],
        ),
      ),
      (
        icon: HeroIcons.clipboardDocumentList,
        title: 'Selling Operations',
        subtitle: '${stats.totalOrders} orders in pipeline',
        onTap: () => _openModuleFeatures(
          title: 'Selling Operations',
          groups: const ['seller', 'inventory', 'shipping'],
        ),
      ),
      (
        icon: HeroIcons.sparkles,
        title: 'Content & Social Commerce',
        subtitle: 'Live + shoppable publishing',
        onTap: () => _openModuleFeatures(
          title: 'Content & Social Commerce',
          groups: const ['social_commerce', 'live'],
        ),
      ),
      (
        icon: HeroIcons.megaphone,
        title: 'Ads & Discovery',
        subtitle: 'Scale reach and visibility',
        onTap: () => _openModuleFeatures(
          title: 'Ads & Discovery',
          groups: const ['seller', 'search', 'buyer'],
        ),
      ),
      (
        icon: HeroIcons.users,
        title: 'Creator & Community',
        subtitle: 'Affiliate partnerships',
        onTap: () => _openModuleFeatures(
          title: 'Creator & Community',
          groups: const ['affiliate', 'subscriptions', 'social_commerce'],
        ),
      ),
      (
        icon: HeroIcons.chatBubbleLeftRight,
        title: 'Customer Relationships',
        subtitle: 'Inbox and reviews',
        onTap: () => _openModuleFeatures(
          title: 'Customer Relationships',
          groups: const ['chat', 'reviews'],
        ),
      ),
      (
        icon: HeroIcons.banknotes,
        title: 'Money & Payouts',
        subtitle: stats.revenueFormatted,
        onTap: () => _openModuleFeatures(
          title: 'Money & Payouts',
          groups: const ['payments', 'seller'],
        ),
      ),
      (
        icon: HeroIcons.cpuChip,
        title: 'Automation & AI',
        subtitle: 'Rules and optimization',
        onTap: () => _openModuleFeatures(
          title: 'Automation & AI',
          groups: const ['seller', 'search', 'analytics'],
        ),
      ),
      (
        icon: HeroIcons.paintBrush,
        title: 'Store Identity',
        subtitle: 'Brand and storefront',
        onTap: () => _openModuleFeatures(
          title: 'Store Identity',
          groups: const ['seller', 'social_commerce'],
        ),
      ),
      (
        icon: HeroIcons.shieldCheck,
        title: 'Trust, Health & Platform Status',
        subtitle: 'Moderation and standing',
        onTap: () => _openModuleFeatures(
          title: 'Trust, Health & Platform Status',
          groups: const ['moderation', 'reviews', 'seller'],
        ),
      ),
    ];
  }

  void _openModuleFeatures({
    required String title,
    required List<String> groups,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopFeatureHubScreen(
          currentUserId: _currentUserId ?? widget.userId,
          allowedGroups: groups,
          titleOverride: title,
        ),
      ),
    );
  }

  Widget _buildOperatingSystemCard({
    required ({
      HeroIcons icon,
      String title,
      String subtitle,
      VoidCallback onTap,
    }) module,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kDivider),
        color: _kBackground,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: module.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroIcon(module.icon, size: 18, color: _kPrimaryText),
                const SizedBox(height: 8),
                Text(
                  module.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPrimaryText,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  module.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kSecondaryText,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
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
        return _stats!.draftProducts;
      case ProductStatus.soldOut:
        return _stats!.soldOutProducts;
      case ProductStatus.archived:
        return _stats!.archivedProducts;
    }
  }

  // ─── Products Section ─────────────────────────────────────────────────

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

  /// Seller product card — reuses ProductCard with status/menu overlays.
  Widget _buildSellerProductCard(BuildContext context, Product product) {
    final s = AppStringsScope.of(context);
    return GestureDetector(
      onLongPress: () => _showProductActions(product),
      child: Stack(
        children: [
          // Reuse the standard ProductCard for consistent styling
          ProductCard(
            product: product,
            compact: true,
            showSeller: false,
            onTap: () => _navigateToProductDetail(product),
          ),

          // Status badge overlay (top-left)
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
                _productStatusLabel(context, product.status),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Menu button overlay (top-right)
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
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
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
              ),
            ),
        ],
      ),
    );
  }

  String _productStatusLabel(BuildContext context, ProductStatus status) {
    final s = AppStringsScope.of(context);
    switch (status) {
      case ProductStatus.draft:
        return s?.statusDraft ?? 'Draft';
      case ProductStatus.active:
        return s?.statusActive ?? 'Active';
      case ProductStatus.soldOut:
        return s?.statusSoldOut ?? 'Sold Out';
      case ProductStatus.archived:
        return s?.statusArchived ?? 'Archived';
    }
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

  /// Viewer product grid — reuses ProductCard for consistent marketplace styling.
  Widget _buildProductsGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: _products.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _StaggeredEntry(
          index: index,
          child: ProductCard(
            product: _products[index],
            showSeller: false,
            onTap: () => _navigateToProductDetail(_products[index]),
          ),
        );
      },
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────

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

// ═══════════════════════════════════════════════════════════════════════════
// Helper widgets
// ═══════════════════════════════════════════════════════════════════════════

/// Sliver delegate for pinned tab bar with bottom border.
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
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(
          bottom: BorderSide(color: _kDivider, width: 1),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

/// Staggered fade+slide animation for grid items (§12).
class _StaggeredEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredEntry({required this.index, required this.child});

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Stagger delay: 30ms per item, capped at 300ms — plays once only
    final delay = Duration(milliseconds: (widget.index * 30).clamp(0, 300));
    Future.delayed(delay, () {
      if (mounted && !_hasAnimated) {
        _hasAnimated = true;
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

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

// ─── Action Required helpers ───────────────────────────────────────────────

enum _Urgency { high, medium, low }

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.urgency,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final _Urgency urgency;
  final VoidCallback onTap;
}
