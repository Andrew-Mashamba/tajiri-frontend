import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';

/// Small "Sponsored" label shown on sponsored posts.
class SponsoredBadge extends StatelessWidget {
  final String? sponsorName;

  const SponsoredBadge({super.key, this.sponsorName});

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_rounded, size: 12, color: Color(0xFF666666)),
          const SizedBox(width: 4),
          Text(
            sponsorName != null
                ? '${strings?.sponsored ?? "Sponsored"} · $sponsorName'
                : strings?.sponsored ?? 'Sponsored',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}
