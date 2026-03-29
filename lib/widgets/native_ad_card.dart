import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_models.dart';
import '../config/api_config.dart';

/// A card widget for displaying ads in feed-like surfaces.
///
/// Supports two modes:
/// 1. **Self-serve**: renders a [ServedAd] with creative image, headline, body,
///    CTA button. Records impression via [VisibilityDetector] when 50%+ visible.
/// 2. **AdMob**: wraps a [NativeAd] in an [AdWidget].
class NativeAdCard extends StatefulWidget {
  final ServedAd? servedAd;
  final NativeAd? nativeAd;
  final VoidCallback? onImpression;
  final VoidCallback? onClick;

  const NativeAdCard({
    super.key,
    this.servedAd,
    this.nativeAd,
    this.onImpression,
    this.onClick,
  });

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  bool _impressionRecorded = false;

  String _resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.storageUrl}/$url';
  }

  void _handleImpression(VisibilityInfo info) {
    if (_impressionRecorded) return;
    if (info.visibleFraction >= 0.5) {
      _impressionRecorded = true;
      widget.onImpression?.call();
    }
  }

  Future<void> _handleCtaTap() async {
    widget.onClick?.call();
    final url = widget.servedAd?.ctaUrl ?? '';
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _ctaLabel(String ctaType) {
    switch (ctaType.toLowerCase()) {
      case 'shop_now':
        return 'Nunua Sasa';
      case 'learn_more':
        return 'Jifunze Zaidi';
      case 'download':
        return 'Pakua';
      case 'sign_up':
        return 'Jiunge';
      case 'visit':
        return 'Tembelea';
      default:
        return 'Jifunze Zaidi';
    }
  }

  @override
  Widget build(BuildContext context) {
    // AdMob mode
    if (widget.nativeAd != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 320,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              AdWidget(ad: widget.nativeAd!),
              Positioned(
                top: 8,
                right: 8,
                child: _adBadge(context),
              ),
            ],
          ),
        ),
      );
    }

    // Self-serve mode
    final ad = widget.servedAd;
    if (ad == null) return const SizedBox.shrink();

    final mediaUrl = _resolveMediaUrl(ad.mediaUrl);
    final theme = Theme.of(context);

    return VisibilityDetector(
      key: Key('native_ad_${ad.campaignId}_${ad.creativeId}'),
      onVisibilityChanged: _handleImpression,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Creative image
              if (mediaUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, p) => Container(
                          color: const Color(0xFFE0E0E0),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, e, s) => Container(
                          color: const Color(0xFFE0E0E0),
                          child: const Icon(Icons.image_not_supported_rounded, size: 40),
                        ),
                      ),
                      // "Tangazo" badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _adBadge(context),
                      ),
                    ],
                  ),
                ),

              // No image — show badge in header area
              if (mediaUrl.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _adBadge(context),
                  ),
                ),

              // Headline
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  ad.headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Body text
              if (ad.bodyText != null && ad.bodyText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Text(
                    ad.bodyText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // CTA button
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: _handleCtaTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _ctaLabel(ad.ctaType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Tangazo',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
