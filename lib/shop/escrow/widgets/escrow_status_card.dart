import 'package:flutter/material.dart';
import '../models/escrow_models.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kDivider = Color(0xFFE0E0E0);

const BoxShadow _kCardShadow = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 4,
  offset: Offset(0, 2),
);

class EscrowStatusCard extends StatelessWidget {
  final EscrowInfo escrow;

  const EscrowStatusCard({super.key, required this.escrow});

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconColor, title, subtitle) = _statusContent();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
        boxShadow: const [_kCardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, size: 20, color: iconColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (escrow.isHeld && escrow.autoReleaseDaysLeft != null)
            _CountdownPill(days: escrow.autoReleaseDaysLeft!),
        ],
      ),
    );
  }

  (IconData, Color, Color, String, String) _statusContent() {
    switch (escrow.status) {
      case EscrowStatus.held:
        final days = escrow.autoReleaseDaysLeft;
        final subtitle = days != null
            ? 'Payment secured · Auto-releases in $days day${days == 1 ? '' : 's'}'
            : 'Payment secured · Awaiting your confirmation';
        return (
          Icons.lock_outline_rounded,
          const Color(0xFFF0F0F0),
          _kPrimaryText,
          'Payment Held in Escrow',
          subtitle,
        );
      case EscrowStatus.released:
        return (
          Icons.check_circle_outline_rounded,
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          'Payment Released',
          'Funds have been released to the seller',
        );
      case EscrowStatus.autoReleased:
        return (
          Icons.check_circle_outline_rounded,
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          'Auto-Released',
          'Funds were automatically released after 7 days',
        );
      case EscrowStatus.refunded:
        return (
          Icons.replay_rounded,
          const Color(0xFFF3F4F6),
          _kSecondaryText,
          'Refunded',
          'Payment has been refunded to your account',
        );
      case EscrowStatus.disputed:
        return (
          Icons.warning_amber_rounded,
          const Color(0xFFFFF8E1),
          const Color(0xFFF57F17),
          'Dispute in Progress',
          escrow.dispute?.statusLabel ?? 'Under review by our team',
        );
      case EscrowStatus.pending:
        return (
          Icons.hourglass_empty_rounded,
          _kBackground,
          _kSecondaryText,
          'Payment Pending',
          'Escrow will be activated upon order confirmation',
        );
    }
  }
}

class _CountdownPill extends StatelessWidget {
  final int days;
  const _CountdownPill({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$days d',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _kPrimaryText,
        ),
      ),
    );
  }
}
