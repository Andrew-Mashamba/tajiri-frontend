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

// ─── Bilingual helpers ──────────────────────────────────────────────────

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

String _deliveryMethodLabel(BuildContext context, DeliveryMethod method) {
  final s = AppStringsScope.of(context);
  switch (method) {
    case DeliveryMethod.pickup:
      return s?.pickup ?? 'Pickup';
    case DeliveryMethod.delivery:
      return s?.delivery ?? 'Delivery';
    case DeliveryMethod.shipping:
      return s?.shipping ?? 'Shipping';
    case DeliveryMethod.digital:
      return s?.digitalDownload ?? 'Digital Download';
  }
}

/// Order detail screen for both buyers and sellers.
class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final int currentUserId;
  final bool isSeller;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.currentUserId,
    this.isSeller = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ShopService _shopService = ShopService();

  Order? _order;
  bool _isLoading = true;
  String? _error;
  bool _isActioning = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _shopService.getOrder(
      widget.orderId,
      userId: widget.currentUserId,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.order != null) {
          _order = result.order;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _updateStatus(OrderStatus newStatus, {String? trackingNumber, String? note}) async {
    if (_isActioning) return;
    setState(() => _isActioning = true);

    final result = await _shopService.updateOrderStatus(
      widget.orderId,
      sellerId: widget.currentUserId,
      status: newStatus,
      trackingNumber: trackingNumber,
      note: note,
    );

    if (mounted) {
      setState(() => _isActioning = false);
      final s = AppStringsScope.of(context);
      if (result.success) {
        _loadOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_statusUpdateMessage(context, newStatus))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (s?.failedToUpdateOrder ?? 'Failed to update order'))),
        );
      }
    }
  }

  String _statusUpdateMessage(BuildContext context, OrderStatus status) {
    final s = AppStringsScope.of(context);
    switch (status) {
      case OrderStatus.confirmed:
        return s?.orderConfirmed ?? 'Order confirmed';
      case OrderStatus.shipped:
        return s?.orderShipped ?? 'Order shipped';
      case OrderStatus.cancelled:
        return s?.orderCancelled ?? 'Order cancelled';
      default:
        return _orderStatusLabel(context, status);
    }
  }

  Future<void> _cancelOrder() async {
    if (_isActioning) return;
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

    setState(() => _isActioning = true);
    final result = await _shopService.cancelOrder(
      widget.orderId,
      userId: widget.currentUserId,
      reason: reasonController.text.isNotEmpty ? reasonController.text : null,
    );
    reasonController.dispose();

    if (mounted) {
      setState(() => _isActioning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success
            ? (s?.orderCancelled ?? 'Order cancelled')
            : (result.message ?? (s?.failedToUpdateOrder ?? 'Failed to update order')))),
      );
      if (result.success) _loadOrder();
    }
  }

  Future<void> _confirmReceived() async {
    if (_isActioning) return;
    final s = AppStringsScope.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.confirmReceived ?? 'Confirm Received'),
        content: Text(s?.confirmReceivedMessage ?? 'Confirm you have received this order?'),
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

    setState(() => _isActioning = true);
    final result = await _shopService.confirmReceived(
      widget.orderId,
      buyerId: widget.currentUserId,
    );

    if (mounted) {
      setState(() => _isActioning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.success
            ? (s?.orderReceived ?? 'Order received')
            : (result.message ?? (s?.failedToUpdateOrder ?? 'Failed to update order')))),
      );
      if (result.success) _loadOrder();
    }
  }

  Future<void> _shipWithTracking() async {
    final s = AppStringsScope.of(context);
    final trackingController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.markAsShipped ?? 'Mark as Shipped'),
        content: TextField(
          controller: trackingController,
          decoration: InputDecoration(
            labelText: s?.trackingNumber ?? 'Tracking Number',
            hintText: s?.trackingNumberHint ?? 'Enter tracking number (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
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

    if (confirm != true) {
      trackingController.dispose();
      return;
    }

    await _updateStatus(
      OrderStatus.shipped,
      trackingNumber: trackingController.text.isNotEmpty ? trackingController.text : null,
    );
    trackingController.dispose();
  }

  Future<void> _showReturnDialog() async {
    if (_isActioning) return;
    final reasonController = TextEditingController();
    var submitted = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Return/Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please describe why you want to return this item:',
              style: TextStyle(fontSize: 14, color: _kSecondaryText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for return...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryText,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              submitted = true;
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);
              setState(() => _isActioning = true);
              final result = await _shopService.requestReturn(
                widget.orderId,
                userId: widget.currentUserId,
                reason: reason,
              );
              if (!mounted) return;
              setState(() => _isActioning = false);
              if (result.success && result.order != null) {
                setState(() => _order = result.order);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message ?? 'Return request submitted')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message ?? 'Failed to submit return request')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (!submitted) reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          s?.orderDetails ?? 'Order Details',
          style: const TextStyle(
            color: _kPrimaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimaryText),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(context)
                : _order == null
                    ? const SizedBox.shrink()
                    : _buildContent(context),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final s = AppStringsScope.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HeroIcon(HeroIcons.exclamationTriangle, size: 48, color: _kTertiaryText),
          const SizedBox(height: 16),
          Text(_error ?? (s?.errorOccurred ?? 'An error occurred'),
              style: const TextStyle(color: _kSecondaryText)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrder,
            child: Text(s?.tryAgain ?? 'Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final order = _order!;
    final s = AppStringsScope.of(context);

    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status header card
          _buildStatusCard(context, order),
          const SizedBox(height: 16),

          // Product card
          _buildProductCard(context, order),
          const SizedBox(height: 16),

          // Price breakdown
          _buildPriceCard(context, order),
          const SizedBox(height: 16),

          // Delivery info
          _buildDeliveryCard(context, order),

          // Buyer/Seller info
          if (widget.isSeller && order.buyer != null) ...[
            const SizedBox(height: 16),
            _buildPersonCard(
              context,
              title: s?.buyer ?? 'Buyer',
              user: order.buyer!,
              actionLabel: s?.contactBuyer ?? 'Contact Buyer',
              onAction: () => _navigateToChat(order.buyer!.id),
            ),
          ],
          if (!widget.isSeller && order.seller != null) ...[
            const SizedBox(height: 16),
            _buildPersonCard(
              context,
              title: s?.seller ?? 'Seller',
              user: order.seller!,
              actionLabel: s?.contactSeller ?? 'Contact Seller',
              onAction: () => _navigateToChat(order.seller!.id),
            ),
          ],

          // Status history
          if (order.statusHistory != null && order.statusHistory!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildHistoryCard(context, order),
          ],

          // Action buttons
          const SizedBox(height: 24),
          _buildActions(context, order),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Order order) {
    final (bgColor, textColor) = _statusColors(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: HeroIcon(
              _statusIcon(order.status),
              size: 24,
              color: textColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _orderStatusLabel(context, order.status),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(order.updatedAt),
                  style: const TextStyle(fontSize: 12, color: _kTertiaryText),
                ),
              ],
            ),
          ),
          Text(
            order.orderNumber,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Order order) {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: order.product?.thumbnailUrl.isNotEmpty == true
                  ? CachedMediaImage(
                      imageUrl: order.product!.thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _kBackground,
                      child: const Center(
                        child: HeroIcon(HeroIcons.photo, size: 28, color: _kTertiaryText),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.product?.title ?? (s?.product ?? 'Product'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${s?.quantity ?? 'Qty'}: ${order.quantity}',
                  style: const TextStyle(fontSize: 13, color: _kSecondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, Order order) {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(
        children: [
          _buildPriceRow(
            s?.subtotal ?? 'Subtotal',
            '${order.currency} ${order.subtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _buildPriceRow(
            s?.deliveryFee ?? 'Delivery Fee',
            order.deliveryFee > 0
                ? '${order.currency} ${order.deliveryFee.toStringAsFixed(0)}'
                : (s?.free ?? 'Free'),
          ),
          const SizedBox(height: 8),
          const Divider(color: _kDivider),
          const SizedBox(height: 8),
          _buildPriceRow(
            s?.total ?? 'Total',
            order.totalFormatted,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: 14,
          color: isBold ? _kPrimaryText : _kSecondaryText,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        )),
        Text(value, style: TextStyle(
          fontSize: 14,
          color: _kPrimaryText,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
        )),
      ],
    );
  }

  Widget _buildDeliveryCard(BuildContext context, Order order) {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HeroIcon(HeroIcons.truck, size: 18, color: _kSecondaryText),
              const SizedBox(width: 8),
              Text(
                _deliveryMethodLabel(context, order.deliveryMethod),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryText,
                ),
              ),
            ],
          ),
          if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              order.deliveryAddress!,
              style: const TextStyle(fontSize: 13, color: _kSecondaryText),
            ),
          ],
          if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${s?.trackingNumber ?? 'Tracking'}: ',
                  style: const TextStyle(fontSize: 13, color: _kSecondaryText),
                ),
                Text(
                  order.trackingNumber!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText),
                ),
              ],
            ),
          ],
          if (order.estimatedDelivery != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${s?.estimatedDelivery ?? 'Estimated Delivery'}: ',
                  style: const TextStyle(fontSize: 13, color: _kSecondaryText),
                ),
                Text(
                  _formatDate(order.estimatedDelivery!),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context, {
    required String title,
    required OrderUser user,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
            backgroundColor: _kBackground,
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: _kTertiaryText),
                ),
                const SizedBox(height: 2),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: _kPrimaryText,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: HeroIcon(HeroIcons.chatBubbleLeftRight, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Order order) {
    final s = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.statusHistory ?? 'Status History',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 12),
          ...order.statusHistory!.map((entry) {
            final (bgColor, textColor) = _statusColors(entry.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _orderStatusLabel(context, entry.status),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if (entry.note != null && entry.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              entry.note!,
                              style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(entry.createdAt),
                          style: const TextStyle(fontSize: 11, color: _kTertiaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Order order) {
    final s = AppStringsScope.of(context);

    if (_isActioning) {
      return const Center(child: CircularProgressIndicator());
    }

    final actions = <Widget>[];

    if (widget.isSeller) {
      if (order.canConfirm) {
        actions.add(_buildFullButton(
          label: s?.confirmOrder ?? 'Confirm Order',
          icon: HeroIcons.checkCircle,
          onTap: () => _updateStatus(OrderStatus.confirmed),
          isPrimary: true,
        ));
      }
      if (order.canShip) {
        actions.add(_buildFullButton(
          label: s?.markAsShipped ?? 'Mark as Shipped',
          icon: HeroIcons.truck,
          onTap: _shipWithTracking,
          isPrimary: true,
        ));
      }
      if (order.canCancel) {
        actions.add(_buildFullButton(
          label: s?.cancelOrder ?? 'Cancel Order',
          icon: HeroIcons.xCircle,
          onTap: _cancelOrder,
          isDestructive: true,
        ));
      }
    } else {
      // Buyer actions
      if (order.canComplete) {
        actions.add(_buildFullButton(
          label: s?.confirmReceived ?? 'Confirm Received',
          icon: HeroIcons.checkCircle,
          onTap: _confirmReceived,
          isPrimary: true,
        ));
      }
      if (order.canCancel) {
        actions.add(_buildFullButton(
          label: s?.cancelOrder ?? 'Cancel Order',
          icon: HeroIcons.xCircle,
          onTap: _cancelOrder,
          isDestructive: true,
        ));
      }
      if (order.status == OrderStatus.delivered || order.status == OrderStatus.completed) {
        actions.add(_buildFullButton(
          label: 'Request Return',
          icon: HeroIcons.arrowUturnLeft,
          onTap: _showReturnDialog,
          isDestructive: true,
        ));
      }
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: actions.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: a,
      )).toList(),
    );
  }

  Widget _buildFullButton({
    required String label,
    required HeroIcons icon,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final Color bg = isDestructive
        ? Colors.transparent
        : isPrimary
            ? _kPrimaryText
            : _kSurface;
    final Color fg = isDestructive
        ? const Color(0xFFDC2626)
        : isPrimary
            ? Colors.white
            : _kPrimaryText;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: (isPrimary && !isDestructive) ? null : Border.all(
                color: isDestructive ? const Color(0xFFDC2626) : _kDivider,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeroIcon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToChat(int userId) {
    Navigator.pushNamed(context, '/chat/$userId');
  }

  HeroIcons _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return HeroIcons.clock;
      case OrderStatus.confirmed:
        return HeroIcons.checkCircle;
      case OrderStatus.processing:
        return HeroIcons.cog6Tooth;
      case OrderStatus.shipped:
        return HeroIcons.truck;
      case OrderStatus.delivered:
        return HeroIcons.archiveBoxArrowDown;
      case OrderStatus.completed:
        return HeroIcons.checkBadge;
      case OrderStatus.cancelled:
        return HeroIcons.xCircle;
      case OrderStatus.refunded:
        return HeroIcons.arrowUturnLeft;
    }
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
