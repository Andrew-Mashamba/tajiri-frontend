import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F10 #90 — TALA (Tanzania Tourism Licensing Authority) license badge
/// shown on customer-facing travel/safari partner cards. Renders only when
/// the partner's persona has `tala_verified = true`.
class TalaLicenseBadge extends StatelessWidget {
  final bool verified;
  final String? licenseNumber;

  const TalaLicenseBadge({
    super.key,
    required this.verified,
    this.licenseNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (!verified) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1B5E20)),
          const SizedBox(width: 4),
          Text(
            isSw ? 'TALA imethibitishwa' : 'TALA verified',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E20),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (licenseNumber != null && licenseNumber!.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '· $licenseNumber',
              style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20)),
            ),
          ],
        ],
      ),
    );
  }
}
