import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_models.dart';
import '../config/api_config.dart';

/// Overlay shown before video playback begins (pre-roll ad).
///
/// Displays a semi-transparent dark background with "Video inaanza..." text,
/// creative image/headline/CTA, and a 3-5 second countdown. Skip button
/// appears after 3 seconds.
class VideoPrerollOverlay extends StatefulWidget {
  final ServedAd servedAd;
  final VoidCallback? onComplete;
  final VoidCallback? onImpression;
  final VoidCallback? onClick;
  /// Total ad duration in seconds (default 5).
  final int duration;

  const VideoPrerollOverlay({
    super.key,
    required this.servedAd,
    this.onComplete,
    this.onImpression,
    this.onClick,
    this.duration = 5,
  });

  @override
  State<VideoPrerollOverlay> createState() => _VideoPrerollOverlayState();
}

class _VideoPrerollOverlayState extends State<VideoPrerollOverlay> {
  late int _countdown;
  Timer? _timer;
  bool _canSkip = false;
  bool _impressionRecorded = false;

  @override
  void initState() {
    super.initState();
    _countdown = widget.duration;
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
        // Allow skip after 3 seconds
        if ((widget.duration - _countdown) >= 3) {
          _canSkip = true;
        }
      });
      if (_countdown <= 0) {
        timer.cancel();
        widget.onComplete?.call();
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

    return Material(
      color: const Color(0xFF1A1A1A).withValues(alpha: 0.92),
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // "Video inaanza..." indicator
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Video inaanza baada ya $_countdown...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // "Tangazo" badge — top-left
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tangazo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Skip button — top-right
            if (_canSkip)
              Positioned(
                top: 12,
                right: 16,
                child: GestureDetector(
                  onTap: _handleSkip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'Ruka',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // Center content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Creative image
                    if (mediaUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: mediaUrl,
                          width: 280,
                          height: 180,
                          fit: BoxFit.cover,
                          placeholder: (_, p) => Container(
                            width: 280,
                            height: 180,
                            color: Colors.white10,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white38,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, e, s) => Container(
                            width: 280,
                            height: 180,
                            color: Colors.white10,
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              color: Colors.white24,
                              size: 40,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Headline
                    Text(
                      ad.headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Body text
                    if (ad.bodyText != null && ad.bodyText!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        ad.bodyText!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // CTA button
                    SizedBox(
                      height: 48,
                      width: 220,
                      child: ElevatedButton(
                        onPressed: _handleCtaTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _ctaLabel(ad.ctaType),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
