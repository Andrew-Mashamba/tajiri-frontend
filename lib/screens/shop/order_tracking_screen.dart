import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/shop_models.dart';

// DESIGN.md tokens
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kTertiaryText = Color(0xFF999999);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

class OrderTrackingScreen extends StatelessWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(context);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          'Track Order #${order.orderNumber}',
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _statusColor(order.status).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _statusLabel(context, order.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(order.status),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _formatDate(order.updatedAt),
                style: const TextStyle(fontSize: 12, color: _kTertiaryText),
              ),
            ),
            const SizedBox(height: 24),

            // Timeline card
            Container(
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
                    'Order Timeline',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final isLast = index == steps.length - 1;
                    return _buildTimelineStep(step, isLast: isLast);
                  }),
                ],
              ),
            ),

            // Tracking number card
            if (order.trackingNumber != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [_kCardShadow],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: _kPrimaryText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracking Number',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTertiaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.trackingNumber!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Estimated delivery card
            if (order.estimatedDelivery != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [_kCardShadow],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: _kPrimaryText,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Delivery',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTertiaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(order.estimatedDelivery!),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Cancellation reason card
            if (order.status == OrderStatus.cancelled &&
                order.cancellationReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancellation Reason',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.cancellationReason!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB91C1C),
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<_TimelineStep> _buildSteps(BuildContext context) {
    final steps = <_TimelineStep>[];
    final isCancelled = order.status == OrderStatus.cancelled;
    final isRefunded = order.status == OrderStatus.refunded;

    // Standard order flow (in enum .index order)
    final standardFlow = [
      (OrderStatus.pending, _statusLabel(context, OrderStatus.pending)),
      (OrderStatus.confirmed, _statusLabel(context, OrderStatus.confirmed)),
      (OrderStatus.processing, _statusLabel(context, OrderStatus.processing)),
      (OrderStatus.shipped, _statusLabel(context, OrderStatus.shipped)),
      (OrderStatus.delivered, _statusLabel(context, OrderStatus.delivered)),
      (OrderStatus.completed, _statusLabel(context, OrderStatus.completed)),
    ];

    for (final (status, label) in standardFlow) {
      final isReached = order.status.index >= status.index && !isCancelled && !isRefunded;
      final isCurrent = order.status == status;
      // Find matching history entry for timestamp
      DateTime? timestamp;
      if (order.statusHistory != null) {
        try {
          final entry = order.statusHistory!.lastWhere(
            (h) => h.status == status,
          );
          timestamp = entry.createdAt;
        } catch (_) {
          // No history entry for this status
        }
      }
      if (isCurrent && timestamp == null) {
        timestamp = order.updatedAt;
      }
      steps.add(_TimelineStep(
        label: label,
        isCompleted: isReached,
        isCurrent: isCurrent,
        timestamp: timestamp,
      ));
    }

    if (isCancelled) {
      steps.add(_TimelineStep(
        label: _statusLabel(context, OrderStatus.cancelled),
        isCompleted: true,
        isCurrent: true,
        isError: true,
        timestamp: order.cancelledAt ?? order.updatedAt,
      ));
    }

    if (isRefunded) {
      steps.add(_TimelineStep(
        label: _statusLabel(context, OrderStatus.refunded),
        isCompleted: true,
        isCurrent: true,
        isError: true,
        timestamp: order.updatedAt,
      ));
    }

    return steps;
  }

  Widget _buildTimelineStep(_TimelineStep step, {bool isLast = false}) {
    final Color dotColor = step.isError
        ? const Color(0xFFDC2626)
        : step.isCompleted
            ? const Color(0xFF059669)
            : const Color(0xFFE0E0E0);

    final Color lineColor = step.isCompleted
        ? const Color(0xFF059669).withValues(alpha: 0.4)
        : const Color(0xFFE0E0E0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: step.isCurrent ? 18 : 12,
                  height: step.isCurrent ? 18 : 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: step.isCurrent
                        ? [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: (step.isCompleted && !step.isError)
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: step.isError
                          ? const Color(0xFFDC2626)
                          : step.isCompleted
                              ? _kPrimaryText
                              : _kTertiaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (step.timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(step.timestamp!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTertiaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFD97706);
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        return const Color(0xFF2563EB);
      case OrderStatus.shipped:
        return const Color(0xFF4F46E5);
      case OrderStatus.delivered:
        return const Color(0xFF059669);
      case OrderStatus.completed:
        return const Color(0xFF047857);
      case OrderStatus.cancelled:
        return const Color(0xFFDC2626);
      case OrderStatus.refunded:
        return const Color(0xFF6B7280);
    }
  }

  String _statusLabel(BuildContext context, OrderStatus status) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineStep {
  final String label;
  final bool isCompleted;
  final bool isCurrent;
  final bool isError;
  final DateTime? timestamp;

  const _TimelineStep({
    required this.label,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isError = false,
    this.timestamp,
  });
}
