import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_models.dart';
import '../config/api_config.dart';

/// A conversation-tile-shaped ad card for insertion in message lists.
///
/// Mimics the height and padding of a standard conversation tile: avatar on
/// the left (ad icon or creative thumbnail), advertiser name (headline) as
/// title, preview text (body_text) as subtitle, and a "Tangazo" badge.
/// Records impression when 50%+ visible; records click and opens CTA URL on tap.
class ConversationAdCard extends StatefulWidget {
  final ServedAd servedAd;
  final VoidCallback? onImpression;
  final VoidCallback? onClick;

  const ConversationAdCard({
    super.key,
    required this.servedAd,
    this.onImpression,
    this.onClick,
  });

  @override
  State<ConversationAdCard> createState() => _ConversationAdCardState();
}

class _ConversationAdCardState extends State<ConversationAdCard> {
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

  Future<void> _handleTap() async {
    widget.onClick?.call();
    final url = widget.servedAd.ctaUrl;
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.servedAd;
    final mediaUrl = _resolveMediaUrl(ad.mediaUrl);
    final theme = Theme.of(context);

    return VisibilityDetector(
      key: Key('conv_ad_${ad.campaignId}_${ad.creativeId}'),
      onVisibilityChanged: _handleImpression,
      child: InkWell(
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar — ad icon or creative thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: mediaUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: mediaUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (_, p) => _placeholderAvatar(theme),
                        errorWidget: (_, e, s) => _placeholderAvatar(theme),
                      )
                    : _placeholderAvatar(theme),
              ),

              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ad.headline,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // "Tangazo" badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Tangazo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ad.bodyText != null && ad.bodyText!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        ad.bodyText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderAvatar(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.campaign_rounded,
        color: theme.colorScheme.primary.withValues(alpha: 0.5),
        size: 22,
      ),
    );
  }
}
