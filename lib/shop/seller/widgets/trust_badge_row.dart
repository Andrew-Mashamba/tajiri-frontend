import 'package:flutter/material.dart';
import '../models/trust_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Horizontal row of compact trust/verification chips for a seller.
///
/// Shows:
/// - "NIDA Verified" (dark filled) when [profile.nidaVerified]
/// - "Business"      (dark filled) when [profile.brelaRegistered]
/// - "500+ Sales"    (outlined)    from [profile.salesBadge]
/// - "< 1hr reply"   (outlined)    from [profile.responseLabel]
class TrustBadgeRow extends StatelessWidget {
  const TrustBadgeRow({
    super.key,
    required this.profile,
  });

  final SellerTrustProfile profile;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (profile.nidaVerified) {
      chips.add(_TrustChip(
        icon: Icons.shield_rounded,
        label: 'NIDA Verified',
        filled: true,
      ));
    }

    if (profile.brelaRegistered) {
      chips.add(_TrustChip(
        icon: Icons.business_rounded,
        label: 'Business',
        filled: true,
      ));
    }

    if (profile.salesBadge != null) {
      chips.add(_TrustChip(
        icon: Icons.star_rounded,
        label: '${profile.salesBadge} Sales',
        filled: false,
      ));
    }

    // Only show response label if it's not 'Slow'
    if (profile.responseLabel != 'Slow' && profile.responseRate > 0) {
      chips.add(_TrustChip(
        icon: Icons.bolt_rounded,
        label: '${profile.responseLabel} reply',
        filled: false,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({
    required this.icon,
    required this.label,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: filled ? _kPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: filled ? _kPrimary : _kSecondary,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: filled ? Colors.white : _kSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : _kSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
