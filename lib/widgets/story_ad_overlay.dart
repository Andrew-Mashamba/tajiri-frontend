import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ad_models.dart';
import '../config/api_config.dart';

/// Full-screen overlay for story-like ad experience.
///
/// Used between story groups and clips. Shows a 5-second countdown before
/// the skip button appears. Supports self-serve [ServedAd] creative rendering.
class StoryAdOverlay extends StatefulWidget {
  final ServedAd? servedAd;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onImpression;
  final VoidCallback? onClick;

  const StoryAdOverlay({
    super.key,
    this.servedAd,
    this.onComplete,
    this.onSkip,
    this.onImpression,
    this.onClick,
  });

  @override
  State<StoryAdOverlay> createState() => _StoryAdOverlayState();
}

class _StoryAdOverlayState extends State<StoryAdOverlay> {
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
        // Auto-complete after countdown
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            widget.onComplete?.call();
          }
        });
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

  void _handleSkip() {
    _timer?.cancel();
    widget.onSkip?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.servedAd;
    final mediaUrl = _resolveMediaUrl(ad?.mediaUrl);
    final size = MediaQuery.of(context).size;

    return Material(
      color: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background creative image
              if (mediaUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height,
                  placeholder: (_, p) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (_, e, s) => const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: Colors.white38,
                      size: 64,
                    ),
                  ),
                ),

              // Dark gradient overlay for readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // "Tangazo" badge — top-left
              Positioned(
                top: 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Tangazo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Skip / Countdown — top-right
              Positioned(
                top: 12,
                right: 16,
                child: _countdown > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_countdown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _handleSkip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white38),
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

              // Bottom content — headline + CTA
              if (ad != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ad.headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ad.bodyText != null && ad.bodyText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          ad.bodyText!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
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
            ],
          ),
        ),
      ),
    );
  }
}
