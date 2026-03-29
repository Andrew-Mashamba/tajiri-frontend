import 'package:flutter/material.dart';
import '../models/ad_models.dart';

/// Small semi-transparent overlay badge for live streams showing the sponsor.
///
/// 120x40dp, positioned bottom-left by the consumer. Displays
/// "Imetolewa na [Brand]" on a semi-transparent dark background.
/// Non-intrusive — doesn't block stream content.
class StreamSponsorBadge extends StatelessWidget {
  final ServedAd servedAd;
  final VoidCallback? onTap;

  const StreamSponsorBadge({
    super.key,
    required this.servedAd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brandName = servedAd.headline.isNotEmpty
        ? servedAd.headline
        : servedAd.title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 120,
          maxWidth: 200,
          minHeight: 40,
          maxHeight: 40,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 14,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Imetolewa na $brandName',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
