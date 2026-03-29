import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_models.dart';
import '../config/api_config.dart';

/// Compact ad overlay for the music player — shown between tracks.
///
/// Positioned at the bottom of the player. Shows creative image, headline,
/// CTA button, and a 5-second countdown before a skip button appears.
class MusicAdOverlay extends StatefulWidget {
  final ServedAd servedAd;
  final VoidCallback? onComplete;
  final VoidCallback? onImpression;
  final VoidCallback? onClick;

  const MusicAdOverlay({
    super.key,
    required this.servedAd,
    this.onComplete,
    this.onImpression,
    this.onClick,
  });

  @override
  State<MusicAdOverlay> createState() => _MusicAdOverlayState();
}

class _MusicAdOverlayState extends State<MusicAdOverlay> {
  int _countdown = 5;
  Timer? _timer;
  bool _impressionRecorded = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _recordImpression();
  }

  void _recordImpression() {
    if (!_impressionRecorded) {
      _impressionRecorded = true;
      widget.onImpression?.call();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiConfig.storageUrl}/$url';
  }

  Future<void> _handleCtaTap() async {
    widget.onClick?.call();
    final url = widget.servedAd.ctaUrl;
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

  void _handleSkip() {
    _timer?.cancel();
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.servedAd;
    final mediaUrl = _resolveMediaUrl(ad.mediaUrl);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header — "Tangazo" badge + countdown/skip
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Container(
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
                ),
                const Spacer(),
                if (_countdown > 0)
                  Text(
                    '$_countdown',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _handleSkip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Ruka',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content row — image + headline + CTA
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Creative image
                if (mediaUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: mediaUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, p) => Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFE0E0E0),
                      ),
                      errorWidget: (_, e, s) => Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(Icons.image_rounded, size: 24),
                      ),
                    ),
                  ),
                if (mediaUrl.isNotEmpty) const SizedBox(width: 12),

                // Headline + body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ad.headline,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ad.bodyText != null && ad.bodyText!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ad.bodyText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // CTA button
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: _handleCtaTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _ctaLabel(ad.ctaType),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
