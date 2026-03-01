import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';
import '../models/subscription_models.dart';
import 'user_avatar.dart';

/// Reusable card widget to display a subscription in lists
class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onTap;
  final Function(bool)? onAutoRenewToggle;
  final bool showAutoRenewToggle;
  final bool isCompact;

  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF22C55E);
  static const Color _kWarning = Color(0xFFF59E0B);
  static const Color _kDanger = Color(0xFFEF4444);

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onTap,
    this.onAutoRenewToggle,
    this.showAutoRenewToggle = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final creator = subscription.creator;
    final tier = subscription.tier;
    final isActive = subscription.isActive;
    final daysRemaining = subscription.daysRemaining;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
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
              // Creator avatar
              UserAvatar(
                photoUrl: creator?.avatarUrl,
                name: creator?.fullName ?? 'Creator',
                radius: isCompact ? 24 : 28,
              ),
              SizedBox(width: isCompact ? 12 : 16),
              // Info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Creator name
                    Text(
                      creator?.fullName ?? 'Creator',
                      style: TextStyle(
                        color: _kPrimary,
                        fontSize: isCompact ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Tier name and price
                    Row(
                      children: [
                        if (tier != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tier.name,
                              style: const TextStyle(
                                color: _kPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          tier != null
                              ? '${tier.priceFormatted}/${tier.billingPeriod == 'yearly' ? (s?.yearly ?? 'yr') : (s?.monthly ?? 'mo')}'
                              : 'TZS ${subscription.amountPaid.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: _kSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Status and renewal info
                    Row(
                      children: [
                        // Status badge
                        _buildStatusBadge(isActive, daysRemaining, s),
                        if (showAutoRenewToggle && onAutoRenewToggle != null) ...[
                          const Spacer(),
                          // Auto-renew toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                s?.autoRenewal ?? 'Auto',
                                style: const TextStyle(
                                  color: _kSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                height: 24,
                                child: Switch(
                                  value: subscription.autoRenew,
                                  onChanged: onAutoRenewToggle,
                                  activeTrackColor: _kSuccess.withValues(alpha: 0.5),
                                  thumbColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return _kSuccess;
                                    }
                                    return null;
                                  }),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow indicator
              if (onTap != null && !showAutoRenewToggle)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right,
                    color: _kSecondary.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
            ],
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
    } else if (daysRemaining <= 3) {
      bgColor = _kWarning.withValues(alpha: 0.1);
      textColor = _kWarning;
      text = s?.daysRemainingCount(daysRemaining) ?? '$daysRemaining days left';
    } else if (daysRemaining <= 7) {
      bgColor = _kWarning.withValues(alpha: 0.1);
      textColor = _kWarning;
      text = s?.daysRemainingCount(daysRemaining) ?? '$daysRemaining days left';
    } else {
      bgColor = _kSuccess.withValues(alpha: 0.1);
      textColor = _kSuccess;
      text = s?.activeSubscriptions ?? 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Compact subscriber card for creator's subscriber list
class SubscriberCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onTap;

  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);
  static const Color _kSuccess = Color(0xFF22C55E);

  const SubscriberCard({
    super.key,
    required this.subscription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subscriber = subscription.subscriber;
    final tier = subscription.tier;
    final isActive = subscription.isActive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Subscriber avatar with online indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    photoUrl: subscriber?.avatarUrl,
                    name: subscriber?.fullName ?? 'Subscriber',
                    radius: 22,
                  ),
                  if (isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _kSuccess,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Subscriber info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subscriber?.fullName ?? 'Subscriber',
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (subscriber?.username != null) ...[
                          Text(
                            '@${subscriber!.username}',
                            style: const TextStyle(
                              color: _kSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const Text(' · ', style: TextStyle(color: _kSecondary, fontSize: 12)),
                        ],
                        Text(
                          _formatDate(subscription.startedAt),
                          style: const TextStyle(
                            color: _kSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tier badge
              if (tier != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tier.name,
                    style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
