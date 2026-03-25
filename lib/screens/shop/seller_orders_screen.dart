import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';
import '../../services/shop_service.dart';
import '../../widgets/cached_media_image.dart';

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
  final ShopService _shopService = ShopService();
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  List<Order> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  // Tab filters: null = all active, then specific statuses
  final List<(OrderStatus?, String)> _tabs = [
    (null, 'all'),
    (OrderStatus.pending, 'pending'),
    (OrderStatus.confirmed, 'confirmed'),
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
    });

    final result = await _shopService.getSellerOrders(
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

    final result = await _shopService.getSellerOrders(
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
    final s = AppStringsScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.confirmOrder ?? 'Confirm Order'),
        content: Text(s?.confirmOrderMessage ?? 'Confirm this order and start processing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.no ?? 'No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryText,
              foregroundColor: Colors.white,
            ),
            child: Text(s?.yes ?? 'Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _shopService.updateOrderStatus(
      order.id,
      sellerId: widget.currentUserId,
      status: OrderStatus.confirmed,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success
            ? (s?.orderConfirmed ?? 'Order confirmed')
            : (result.message ?? (s?.failedToUpdateOrder ?? 'Failed to update order')))),
      );
      if (result.success) _loadOrders();
    }
  }

  Future<void> _shipOrder(Order order) async {
    final s = AppStringsScope.of(context);
    final trackingController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.markAsShipped ?? 'Mark as Shipped'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: trackingController,
              decoration: InputDecoration(
                labelText: s?.trackingNumber ?? 'Tracking Number',
                hintText: s?.trackingNumberHint ?? 'Enter tracking number (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryText,
              foregroundColor: Colors.white,
            ),
            child: Text(s?.markAsShipped ?? 'Mark as Shipped'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _shopService.updateOrderStatus(
      order.id,
      sellerId: widget.currentUserId,
      status: OrderStatus.shipped,
      trackingNumber: trackingController.text.isNotEmpty ? trackingController.text : null,
    );
    trackingController.dispose();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success
            ? (s?.orderShipped ?? 'Order shipped')
            : (result.message ?? (s?.failedToUpdateOrder ?? 'Failed to update order')))),
      );
      if (result.success) _loadOrders();
    }
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

    final result = await _shopService.cancelOrder(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigateToOrderDetail(order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: order number + status badge
                Row(
                  children: [
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

                // Buyer info
                if (order.buyer != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const HeroIcon(HeroIcons.user, size: 14, color: _kSecondaryText),
                      const SizedBox(width: 6),
                      Text(
                        '${s?.buyer ?? 'Buyer'}: ${order.buyer!.fullName}',
                        style: const TextStyle(fontSize: 12, color: _kSecondaryText),
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
    return Row(
      children: [
        if (order.canConfirm)
          Expanded(
            child: _buildActionChip(
              label: s?.confirmOrder ?? 'Confirm',
              icon: HeroIcons.checkCircle,
              onTap: () => _confirmOrder(order),
              isPrimary: true,
            ),
          ),
        if (order.canConfirm && order.canCancel)
          const SizedBox(width: 8),
        if (order.canShip)
          Expanded(
            child: _buildActionChip(
              label: s?.markAsShipped ?? 'Ship',
              icon: HeroIcons.truck,
              onTap: () => _shipOrder(order),
              isPrimary: true,
            ),
          ),
        if (order.canShip) const SizedBox(width: 8),
        if (order.canCancel)
          Expanded(
            child: _buildActionChip(
              label: s?.cancel ?? 'Cancel',
              icon: HeroIcons.xCircle,
              onTap: () => _cancelOrder(order),
            ),
          ),
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
