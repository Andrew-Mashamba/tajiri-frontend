import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/subscription_models.dart';
import '../../services/subscription_service.dart';
import '../../widgets/user_avatar.dart';

/// Screen showing detailed subscription information with management options
class SubscriptionDetailScreen extends StatefulWidget {
  final Subscription subscription;
  final int currentUserId;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscription,
    required this.currentUserId,
  });

  @override
  State<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF22C55E);
  static const Color _kDanger = Color(0xFFEF4444);

  final SubscriptionService _subscriptionService = SubscriptionService();

  late Subscription _subscription;
  bool _isCancelling = false;
  bool _isTogglingAutoRenew = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.subscription;
  }

  Future<void> _toggleAutoRenew(bool value) async {
    if (_isTogglingAutoRenew) return;
    setState(() => _isTogglingAutoRenew = true);

    final result = await _subscriptionService.toggleAutoRenew(
      userId: widget.currentUserId,
      subscriptionId: _subscription.id,
      autoRenew: value,
    );

    if (!mounted) return;
    setState(() => _isTogglingAutoRenew = false);

    if (result.success) {
      // Update local state - create new subscription with updated autoRenew
      setState(() {
        _subscription = Subscription(
          id: _subscription.id,
          subscriberId: _subscription.subscriberId,
          creatorId: _subscription.creatorId,
          tierId: _subscription.tierId,
          status: _subscription.status,
          amountPaid: _subscription.amountPaid,
          startedAt: _subscription.startedAt,
          expiresAt: _subscription.expiresAt,
          cancelledAt: _subscription.cancelledAt,
          autoRenew: value,
          tier: _subscription.tier,
          creator: _subscription.creator,
          subscriber: _subscription.subscriber,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? (AppStringsScope.of(context)?.autoRenewalOn ?? 'Auto-renewal enabled')
                : (AppStringsScope.of(context)?.autoRenewalOff ?? 'Auto-renewal disabled'),
          ),
        ),
      );
    }
  }

  Future<void> _cancelSubscription() async {
    final s = AppStringsScope.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s?.cancelSubscription ?? 'Cancel Subscription'),
        content: Text(
          s?.cancelSubscriptionConfirm ??
              'Are you sure you want to cancel this subscription? You will lose access to exclusive content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _kDanger),
            child: Text(s?.confirm ?? 'Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    final result = await _subscriptionService.cancelSubscription(
      userId: widget.currentUserId,
      subscriptionId: _subscription.id,
    );

    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.subscriptionCancelled ?? 'Subscription cancelled'),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? s?.subscriptionCancelFailed ?? 'Failed to cancel subscription'),
          backgroundColor: _kDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final creator = _subscription.creator;
    final tier = _subscription.tier;
    final isActive = _subscription.isActive;
    final daysRemaining = _subscription.daysRemaining;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(s?.subscriptionDetails ?? 'Subscription Details'),
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Creator info card
              _buildCreatorCard(creator, s),
              const SizedBox(height: 16),

              // Subscription info card
              _buildSubscriptionInfoCard(tier, s, isActive, daysRemaining),
              const SizedBox(height: 16),

              // Tier benefits card
              if (tier?.benefits != null && tier!.benefits!.isNotEmpty) ...[
                _buildBenefitsCard(tier, s),
                const SizedBox(height: 16),
              ],

              // Auto-renewal card
              if (isActive) ...[
                _buildAutoRenewalCard(s),
                const SizedBox(height: 16),
              ],

              // Cancel button
              if (isActive) _buildCancelButton(s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorCard(SubscriptionUser? creator, AppStrings? s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(
            photoUrl: creator?.avatarUrl,
            name: creator?.fullName ?? 'Creator',
            radius: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator?.fullName ?? 'Creator',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (creator?.username != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${creator!.username}',
                    style: const TextStyle(
                      color: _kSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/profile/${_subscription.creatorId}');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: BorderSide(color: _kSecondary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              s?.viewCreatorProfile ?? 'View Profile',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfoCard(SubscriptionTier? tier, AppStrings? s, bool isActive, int daysRemaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier name with status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  tier?.name ?? 'Subscription',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildStatusBadge(isActive, daysRemaining, s),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Price
          _buildInfoRow(
            Icons.payments_outlined,
            s?.amountPaid ?? 'Amount Paid',
            'TZS ${_subscription.amountPaid.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),

          // Started date
          _buildInfoRow(
            Icons.calendar_today_outlined,
            s?.startedOn ?? 'Started on',
            _formatDate(_subscription.startedAt),
          ),
          const SizedBox(height: 12),

          // Expires/Renews date
          _buildInfoRow(
            Icons.event_outlined,
            _subscription.autoRenew
                ? (s?.renewsOn ?? 'Renews on')
                : (s?.expiresOn ?? 'Expires on'),
            _formatDate(_subscription.expiresAt),
          ),

          if (isActive && daysRemaining <= 7) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (daysRemaining <= 3 ? _kDanger : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: daysRemaining <= 3 ? _kDanger : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s?.daysRemainingCount(daysRemaining) ?? '$daysRemaining days remaining',
                    style: TextStyle(
                      color: daysRemaining <= 3 ? _kDanger : const Color(0xFFF59E0B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _kSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _kSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsCard(SubscriptionTier tier, AppStrings? s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s?.tierBenefits ?? 'Tier Benefits',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...tier.benefits!.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 20, color: _kSuccess),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAutoRenewalCard(AppStrings? s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.autorenew, size: 24, color: _kPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s?.autoRenewal ?? 'Auto-Renewal',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subscription.autoRenew
                      ? (s?.autoRenewalOn ?? 'Auto-renewal enabled')
                      : (s?.autoRenewalOff ?? 'Auto-renewal disabled'),
                  style: const TextStyle(
                    color: _kSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _isTogglingAutoRenew
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _subscription.autoRenew,
                  onChanged: _toggleAutoRenew,
                  activeTrackColor: _kSuccess.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _kSuccess;
                    }
                    return null;
                  }),
                ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(AppStrings? s) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isCancelling ? null : _cancelSubscription,
        icon: _isCancelling
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cancel_outlined, size: 20),
        label: Text(s?.cancelSubscription ?? 'Cancel Subscription'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kDanger,
          side: const BorderSide(color: _kDanger),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, int daysRemaining, AppStrings? s) {
    Color bgColor;
    Color textColor;
    String text;

    if (!isActive) {
      bgColor = _kDanger.withValues(alpha: 0.1);
      textColor = _kDanger;
      text = s?.expiredSubscriptions ?? 'Expired';
    } else {
      bgColor = _kSuccess.withValues(alpha: 0.1);
      textColor = _kSuccess;
      text = s?.activeSubscriptions ?? 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
