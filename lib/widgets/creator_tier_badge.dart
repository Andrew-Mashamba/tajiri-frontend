import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';

class CreatorTierBadge extends StatelessWidget {
  final String tier;
  final double? multiplier;

  const CreatorTierBadge({super.key, required this.tier, this.multiplier});

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tierColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_tierLabel(strings),
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          if (multiplier != null) ...[
            const SizedBox(width: 4),
            Text('${multiplier!.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Color get _tierColor {
    switch (tier.toLowerCase()) {
      case 'legend': return const Color(0xFF1A1A1A);
      case 'star': return const Color(0xFF333333);
      case 'established': return const Color(0xFF555555);
      default: return const Color(0xFF888888);
    }
  }

  String _tierLabel(AppStrings? strings) {
    switch (tier.toLowerCase()) {
      case 'legend': return strings?.tierLegend ?? 'Legend';
      case 'star': return strings?.tierStar ?? 'Star';
      case 'established': return strings?.tierEstablished ?? 'Established';
      default: return strings?.tierRising ?? 'Rising';
    }
  }
}
