import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heroicons/heroicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/shop_models.dart';
import '../../../services/local_storage_service.dart';
import '../../data/repositories/shop_repository.dart';
import '../../../widgets/cached_media_image.dart';
import '../../escrow/screens/dispute_detail_screen.dart';
import '../../shipping/models/delivery_models.dart';
import '../../shipping/screens/dispatch_delivery_screen.dart';
import '../../offers/screens/seller_offers_screen.dart';
import '../../offers/services/offer_service.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

// ─── Bilingual label helper ─────────────────────────────────────────────

String _orderStatusLabel(BuildContext context, OrderStatus status) {
  final s = AppStringsScope.of(context);
  switch (status) {
    case OrderStatus.pending:
      return s?.orderStatusPending ?? 'Pending';
    case OrderStatus.confirmed:
      return s?.orderStatusConfirmed ?? 'Confirmed';
    case OrderStatus.processing:
      return s?.orderStatusProcessing ?? 'Processing';
    case OrderStatus.shipped:
      return s?.orderStatusShipped ?? 'Shipped';
    case OrderStatus.delivered:
      return s?.orderStatusDelivered ?? 'Delivered';
    case OrderStatus.completed:
      return s?.orderStatusCompleted ?? 'Completed';
    case OrderStatus.cancelled:
      return s?.orderStatusCancelled ?? 'Cancelled';
    case OrderStatus.refunded:
      return s?.orderStatusRefunded ?? 'Refunded';
  }
}

/// Seller orders management screen with status filter tabs.
class SellerOrdersScreen extends StatefulWidget {
  final int currentUserId;

  const SellerOrdersScreen({super.key, required this.currentUserId});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  final ShopRepository _repo = ShopRepository.instance;
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  List<Order> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  bool _multiSelectMode = false;
  final Set<int> _selectedOrderIds = {};

  // Pending offers badge count
  int _pendingOffersCount = 0;

  // Tab filters: null = all active, then specific statuses
  final List<(OrderStatus?, String)> _tabs = [
    (null, 'all'),
    (OrderStatus.pending, 'pending'),
    (OrderStatus.confirmed, 'confirmed'),
    (OrderStatus.processing, 'processing'),
    (OrderStatus.shipped, 'shipped'),
    (OrderStatus.completed, 'completed'),
    (OrderStatus.cancelled, 'cancelled'),
  ];

  OrderStatus? get _currentFilter => _tabs[_tabController.index].$1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadOrders();
    _loadPendingOffersCount();
  }

  Future<void> _loadPendingOffersCount() async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return;
    final offers = await OfferService.listMyOffers(token, type: 'received');
    if (!mounted) return;
    final count = offers.where((o) =>
        o.status.name == 'pending').length;
    setState(() => _pendingOffersCount = count);
  }

  void _openOffersScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerOffersScreen(currentUserId: widget.currentUserId),
      ),
    ).then((_) => _loadPendingOffersCount());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadOrders();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _orders = [];
      _currentPage = 1;
      _hasMore = true;
      _multiSelectMode = false;
      _selectedOrderIds.clear();
    });

    final result = await _repo.getSellerOrders(
      widget.currentUserId,
      status: _currentFilter,
      page: 1,
      perPage: 20,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _orders = result.orders;
          _hasMore = result.meta?.hasMore ?? false;
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

    final result = await _repo.getSellerOrders(
      widget.currentUserId,
      status: _currentFilter,
      page: _currentPage,
      perPage: 20,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _orders.addAll(result.orders);
          _hasMore = result.meta?.hasMore ?? false;
        }
      });
    }
  }

  Future<void> _confirmOrder(Order order) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);

    final result = await _repo.updateOrderStatus(
      order.id,
      sellerId: widget.currentUserId,
      status: OrderStatus.confirmed,
    );

    if (!mounted) return;
    if (result.success) {
      _loadOrders();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Order confirmed'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _navigateToOrderDetail(order),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to confirm order')),
      );
    }
  }

  Future<void> _shipOrder(Order order) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ShipOrderSheet(
        order: order,
        onShip: (tracking, carrier, eta) async {
          Navigator.pop(ctx);
          HapticFeedback.lightImpact();
          final messenger = ScaffoldMessenger.of(context);
          final result = await _repo.updateOrderStatus(
            order.id,
            sellerId: widget.currentUserId,
            status: OrderStatus.shipped,
            trackingNumber: tracking.isNotEmpty ? tracking : null,
          );
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text(result.success ? 'Order marked as shipped' : (result.message ?? 'Failed'))),
          );
          if (result.success) _loadOrders();
        },
      ),
    );
  }

  Future<void> _cancelOrder(Order order) async {
    final s = AppStringsScope.of(context);
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.cancelOrder ?? 'Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s?.cancelOrderMessage ?? 'Are you sure you want to cancel this order?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: s?.cancelReason ?? 'Reason for cancellation',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.no ?? 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(s?.cancelOrder ?? 'Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _repo.cancelOrder(
      order.id,
      userId: widget.currentUserId,
      reason: reasonController.text.isNotEmpty ? reasonController.text : null,
    );
    reasonController.dispose();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success
            ? (s?.orderCancelled ?? 'Order cancelled')
            : (result.message ?? (s?.failedToUpdateOrder ?? 'Failed to update order')))),
      );
      if (result.success) _loadOrders();
    }
  }

  void _navigateToOrderDetail(Order order) {
    Navigator.pushNamed(
      context,
      '/shop/order',
      arguments: {'orderId': order.id, 'isSeller': true},
    ).then((_) => _loadOrders());
  }

  Future<void> _markDelivered(Order order) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final result = await _repo.updateOrderStatus(
      order.id,
      sellerId: widget.currentUserId,
      status: OrderStatus.delivered,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(result.success ? 'Marked as delivered' : (result.message ?? 'Failed'))),
    );
    if (result.success) _loadOrders();
  }

  void _contactBuyer(BuildContext context, OrderUser buyer) {
    final phone = buyer.phoneNumber;
    if (phone == null || phone.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Contact ${buyer.fullName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimaryText),
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: _kDivider),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_rounded, color: _kPrimaryText, size: 20),
              ),
              title: Text('Call $phone', style: const TextStyle(fontSize: 14, color: _kPrimaryText)),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(Uri.parse('tel:$phone'));
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_rounded, color: _kPrimaryText, size: 20),
              ),
              title: const Text('WhatsApp', style: TextStyle(fontSize: 14, color: _kPrimaryText)),
              onTap: () {
                Navigator.pop(ctx);
                final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
                launchUrl(
                  Uri.parse('https://wa.me/$cleaned'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _bulkUpdateStatus(OrderStatus newStatus) async {
    setState(() => _isLoading = true);
    int successCount = 0;
    for (final orderId in _selectedOrderIds) {
      final result = await _repo.updateOrderStatus(
        orderId,
        sellerId: widget.currentUserId,
        status: newStatus,
      );
      if (result.success) successCount++;
    }
    if (!mounted) return;
    setState(() {
      _multiSelectMode = false;
      _selectedOrderIds.clear();
    });
    _loadOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated $successCount orders to ${newStatus.label}')),
    );
  }

  Widget? _buildBulkActionBar() {
    if (!_multiSelectMode || _selectedOrderIds.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '${_selectedOrderIds.length} selected',
              style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimaryText),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                _multiSelectMode = false;
                _selectedOrderIds.clear();
              }),
              child: const Text('Cancel', style: TextStyle(color: _kSecondaryText)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _bulkUpdateStatus(OrderStatus.confirmed),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm All'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _bulkUpdateStatus(OrderStatus.shipped),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryText,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ship All'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          s?.myOrders ?? 'My Orders',
          style: const TextStyle(
            color: _kPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
        actions: [
          IconButton(
            icon: const Icon(Icons.gavel_rounded, color: _kPrimaryText, size: 22),
            tooltip: 'View Disputes',
            onPressed: () => Navigator.pushNamed(context, '/shop/disputes'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _openOffersScreen,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _pendingOffersCount > 0
                      ? _kPrimaryText
                      : _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kPrimaryText),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      size: 14,
                      color: _pendingOffersCount > 0
                          ? Colors.white
                          : _kPrimaryText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _pendingOffersCount > 0
                          ? 'Offers · $_pendingOffersCount'
                          : 'Offers',
                      style: TextStyle(
                        color: _pendingOffersCount > 0
                            ? Colors.white
                            : _kPrimaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: _kPrimaryText,
          unselectedLabelColor: _kSecondaryText,
          indicatorColor: _kPrimaryText,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _tabs.map((tab) {
            return Tab(text: _tabLabel(context, tab.$1));
          }).toList(),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: _tabs.map((_) => _buildOrderList()).toList(),
        ),
      ),
      bottomNavigationBar: _buildBulkActionBar(),
    );
  }

  String _tabLabel(BuildContext context, OrderStatus? status) {
    final s = AppStringsScope.of(context);
    switch (status) {
      case null:
        return s?.all ?? 'All';
      case OrderStatus.pending:
        return s?.orderStatusPending ?? 'Pending';
      case OrderStatus.confirmed:
        return s?.orderStatusConfirmed ?? 'Confirmed';
      case OrderStatus.processing:
        return 'Preparing';
      case OrderStatus.shipped:
        return s?.orderStatusShipped ?? 'Shipped';
      case OrderStatus.completed:
        return s?.orderStatusCompleted ?? 'Completed';
      case OrderStatus.cancelled:
        return s?.orderStatusCancelled ?? 'Cancelled';
      default:
        return _orderStatusLabel(context, status);
    }
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final s = AppStringsScope.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HeroIcon(HeroIcons.exclamationTriangle, size: 48, color: _kTertiaryText),
            const SizedBox(height: 16),
            Text(_error ?? (s?.failedToLoadOrders ?? 'Failed to load orders'),
                style: const TextStyle(color: _kSecondaryText)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: Text(s?.tryAgain ?? 'Try Again'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _orders.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildOrderCard(context, _orders[index]);
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kDivider.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const HeroIcon(HeroIcons.clipboardDocumentList, size: 48, color: _kTertiaryText),
          ),
          const SizedBox(height: 24),
          Text(
            s?.noOrders ?? 'No orders yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryText),
          ),
          const SizedBox(height: 8),
          Text(
            s?.noOrdersMessage ?? 'New orders will appear here',
            style: const TextStyle(fontSize: 14, color: _kSecondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final s = AppStringsScope.of(context);
    final isSelected = _selectedOrderIds.contains(order.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? _kDivider.withValues(alpha: 0.4) : _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (_multiSelectMode) {
              setState(() {
                if (isSelected) {
                  _selectedOrderIds.remove(order.id);
                  if (_selectedOrderIds.isEmpty) _multiSelectMode = false;
                } else {
                  _selectedOrderIds.add(order.id);
                }
              });
            } else {
              _navigateToOrderDetail(order);
            }
          },
          onLongPress: () {
            if (!_multiSelectMode) {
              setState(() {
                _multiSelectMode = true;
                _selectedOrderIds.add(order.id);
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: checkbox (multi-select) + order number + status badge
                Row(
                  children: [
                    if (_multiSelectMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedOrderIds.add(order.id);
                            } else {
                              _selectedOrderIds.remove(order.id);
                              if (_selectedOrderIds.isEmpty) _multiSelectMode = false;
                            }
                          });
                        },
                        activeColor: _kPrimaryText,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s?.orderNumber(order.orderNumber) ?? 'Order #${order.orderNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(context, order.createdAt),
                            style: const TextStyle(fontSize: 12, color: _kTertiaryText),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(context, order.status),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: _kDivider, height: 1),
                const SizedBox(height: 12),

                // Product info
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: order.product?.thumbnailUrl.isNotEmpty == true
                            ? CachedMediaImage(
                                imageUrl: order.product!.thumbnailUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: _kBackground,
                                child: const Center(
                                  child: HeroIcon(HeroIcons.photo, size: 24, color: _kTertiaryText),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.product?.title ?? (s?.product ?? 'Product'),
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
                            'x${order.quantity} • ${order.totalFormatted}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kPrimaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Dispute chip — shown when order escrow is disputed
                if (order.escrowStatus == 'disputed') ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DisputeDetailScreen(
                          orderId: order.id,
                          isSeller: true,
                        ),
                      ),
                    ).then((_) => _loadOrders()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 6),
                          Text(
                            '⚠ Dispute — Tap to respond',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Buyer info + contact shortcut
                if (order.buyer != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.user, size: 14, color: _kSecondaryText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${s?.buyer ?? 'Buyer'}: ${order.buyer!.fullName}',
                          style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (order.buyer!.phoneNumber != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _contactBuyer(context, order.buyer!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _kBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _kDivider),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_rounded, size: 12, color: _kPrimaryText),
                                SizedBox(width: 4),
                                Text('Contact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimaryText)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Delivery address (for delivery orders)
                if (order.deliveryMethod == DeliveryMethod.delivery &&
                    order.deliveryAddress != null &&
                    order.deliveryAddress!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: _kSecondaryText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.deliveryAddress!,
                          style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Action buttons
                if (order.status.isActive && !order.status.isFinal) ...[
                  const SizedBox(height: 12),
                  _buildActionRow(context, order),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, Order order) {
    final s = AppStringsScope.of(context);
    // "Mark Delivered" shows for shipped self-delivery or pickup orders
    final canMarkDelivered = order.status == OrderStatus.shipped &&
        order.deliveryMethod != DeliveryMethod.shipping;

    return Row(
      children: [
        // Primary actions: Confirm or Ship or Mark Delivered
        if (order.canConfirm)
          Expanded(
            child: _buildActionChip(
              label: s?.confirmOrder ?? 'Confirm',
              icon: HeroIcons.checkCircle,
              onTap: () => _confirmOrder(order),
              isPrimary: true,
            ),
          ),
        if (order.canShip)
          Expanded(
            child: _buildActionChip(
              label: s?.markAsShipped ?? 'Ship',
              icon: HeroIcons.truck,
              onTap: () => _shipOrder(order),
              isPrimary: true,
            ),
          ),
        if (canMarkDelivered)
          Expanded(
            child: _buildActionChip(
              label: 'Delivered',
              icon: HeroIcons.checkBadge,
              onTap: () => _markDelivered(order),
              isPrimary: true,
            ),
          ),

        // Cancel: always secondary, icon-only to avoid accidental tap
        if (order.canCancel) ...[
          if (order.canConfirm || order.canShip || canMarkDelivered)
            const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _cancelOrder(order),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionChip({
    required String label,
    required HeroIcons icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? _kPrimaryText : _kSurface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: isPrimary ? null : Border.all(color: _kDivider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeroIcon(icon, size: 16, color: isPrimary ? Colors.white : _kPrimaryText),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : _kPrimaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, OrderStatus status) {
    final (bgColor, textColor) = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _orderStatusLabel(context, status),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _statusColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (const Color(0xFFFEF3C7), const Color(0xFFD97706));
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        return (const Color(0xFFDBEAFE), const Color(0xFF2563EB));
      case OrderStatus.shipped:
        return (const Color(0xFFE0E7FF), const Color(0xFF4F46E5));
      case OrderStatus.delivered:
        return (const Color(0xFFD1FAE5), const Color(0xFF059669));
      case OrderStatus.completed:
        return (const Color(0xFFD1FAE5), const Color(0xFF047857));
      case OrderStatus.cancelled:
        return (const Color(0xFFFEE2E2), const Color(0xFFDC2626));
      case OrderStatus.refunded:
        return (const Color(0xFFF3F4F6), const Color(0xFF6B7280));
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final s = AppStringsScope.of(context);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return s?.today ?? 'Today';
    } else if (diff.inDays == 1) {
      return s?.yesterday ?? 'Yesterday';
    } else if (diff.inDays < 7) {
      return s?.daysAgo(diff.inDays) ?? '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ─── Ship Order Bottom Sheet ───────────────────────────────────────────────

class _ShipOrderSheet extends StatefulWidget {
  final Order order;
  final void Function(String tracking, String carrier, DateTime? eta) onShip;

  const _ShipOrderSheet({required this.order, required this.onShip});

  @override
  State<_ShipOrderSheet> createState() => _ShipOrderSheetState();
}

class _ShipOrderSheetState extends State<_ShipOrderSheet> {
  final _trackingController = TextEditingController();
  String _selectedCarrier = 'Self-delivery';
  DateTime? _eta;

  static const _carriers = [
    'Self-delivery',
    'DHL',
    'FedEx',
    'Tanzania Post',
    'Courier',
    'Other',
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _pickEta() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _eta = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 16, 20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: _kDivider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mark as Shipped',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimaryText),
          ),
          const SizedBox(height: 4),
          Text(
            'Order ${widget.order.orderNumber}',
            style: const TextStyle(fontSize: 13, color: _kSecondaryText),
          ),
          const SizedBox(height: 20),

          // Carrier selector
          const Text('Carrier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText)),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _carriers.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = _carriers[i];
                final selected = c == _selectedCarrier;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCarrier = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimaryText : _kSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? _kPrimaryText : _kDivider),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : _kPrimaryText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Tracking number
          const Text('Tracking Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText)),
          const SizedBox(height: 8),
          TextField(
            controller: _trackingController,
            decoration: InputDecoration(
              hintText: 'Optional — e.g. TZ1234567890',
              hintStyle: const TextStyle(color: _kTertiaryText, fontSize: 13),
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // ETA
          GestureDetector(
            onTap: _pickEta,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _kBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: _kSecondaryText),
                  const SizedBox(width: 10),
                  Text(
                    _eta != null
                        ? 'Est. delivery: ${_eta!.day}/${_eta!.month}/${_eta!.year}'
                        : 'Set estimated delivery date (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      color: _eta != null ? _kPrimaryText : _kTertiaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Two options: manual mark as shipped OR dispatch via courier
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onShip(_trackingController.text, _selectedCarrier, _eta),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimaryText,
                    side: const BorderSide(color: _kDivider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mark Shipped', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final storage = await LocalStorageService.getInstance();
                    final token = storage.getAuthToken();
                    if (token == null || !context.mounted) return;
                    final result = await Navigator.push<DeliveryResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DispatchDeliveryScreen(
                          order: widget.order,
                          sellerId: widget.order.sellerId,
                          sellerName: widget.order.seller?.fullName ?? 'Seller',
                          sellerPhone: widget.order.seller?.phoneNumber ?? '',
                          sellerAddress: 'Dar es Salaam',
                          authToken: token,
                        ),
                      ),
                    );
                    if (result != null && result.success) {
                      widget.onShip(result.trackingId ?? '', 'Courier', null);
                    }
                  },
                  icon: const Icon(Icons.two_wheeler_rounded, size: 16),
                  label: const Text('Dispatch Courier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
