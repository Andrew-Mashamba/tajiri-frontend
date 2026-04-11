import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tajirika_models.dart';

class TierBadge extends StatelessWidget {
  final PartnerTier tier;
  final double fontSize;
  final bool showIcon;

  const TierBadge({
    super.key,
    required this.tier,
    this.fontSize = 11,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tier.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(tier.icon, color: Colors.white, size: fontSize + 3),
            const SizedBox(width: 4),
          ],
          Text(
            isSwahili ? tier.labelSwahili : tier.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
