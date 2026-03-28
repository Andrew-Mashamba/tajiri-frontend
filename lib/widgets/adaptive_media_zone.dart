import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/post_models.dart';
import 'cached_media_image.dart';
import 'video_player_widget.dart';
import 'package:heroicons/heroicons.dart';

// ─── Constants ──────────────────────────────────────────────
const double _kMinRatio = 4 / 5;     // 0.8  — tallest portrait
const double _kMaxRatio = 1.91;      // 1.91 — widest landscape
const double _kDefaultImageRatio = 1.0;  // square fallback
const double _kDefaultVideoRatio = 16 / 9;
const double _kGridGap = 2.0;
const double _kThumbnailSize = 56.0;
const double _kThumbnailGap = 4.0;
const double _kDotSize = 6.0;
const double _kDotSpacing = 4.0;
const Color _kFallbackBg = Color(0xFF666666);

/// Parse a hex dominant color string like '#778393' into a Color.
Color parseDominantColor(String? hex, {Color fallback = _kFallbackBg}) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return fallback;
  }
}

enum _RatioClass { inRange, ultraTall, ultraWide }

_RatioClass _classifyRatio(double ratio) {
  if (ratio < _kMinRatio) return _RatioClass.ultraTall;
  if (ratio > _kMaxRatio) return _RatioClass.ultraWide;
  return _RatioClass.inRange;
}

double _computeRatio(PostMedia media) {
  if (media.width != null && media.height != null && media.height! > 0) {
    return media.width! / media.height!;
  }
  return media.mediaType == MediaType.video ? _kDefaultVideoRatio : _kDefaultImageRatio;
}

double _clampRatio(double ratio) => ratio.clamp(_kMinRatio, _kMaxRatio);

Color _mediaBgColor(PostMedia media, Color? fallback) {
  return parseDominantColor(media.dominantColor, fallback: fallback ?? _kFallbackBg);
}

// ─── AdaptiveMediaZone ──────────────────────────────────────

/// Displays a collection of image/video media with adaptive aspect ratio
/// strategies inspired by Instagram, TikTok, and Twitter.
///
/// Pass only visual media (image + video). Documents and audio-only are
/// handled by the parent PostCard.
class AdaptiveMediaZone extends StatefulWidget {
  final List<PostMedia> media;
  final Color? dominantColor;
  final VoidCallback? onTap;
  /// Opens image viewer. Uses its own BuildContext for navigation.
  final Function(List<PostMedia>, PostMedia)? onImageTap;

  const AdaptiveMediaZone({
    super.key,
    required this.media,
    this.dominantColor,
    this.onTap,
    this.onImageTap,
  });

  @override
  State<AdaptiveMediaZone> createState() => _AdaptiveMediaZoneState();
}

class _AdaptiveMediaZoneState extends State<AdaptiveMediaZone> {
  // For mixed-media hero swapping
  int _heroIndex = 0;
  // For video dimension resolution
  double? _resolvedVideoRatio;

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();

    final media = widget.media;
    final hasVideo = media.any((m) => m.mediaType == MediaType.video);
    final hasImage = media.any((m) => m.mediaType == MediaType.image);
    final isMixed = hasVideo && hasImage;

    Widget content;

    if (media.length == 1) {
      content = _buildSingle(media.first);
    } else if (isMixed) {
      content = _buildMixed(media);
    } else if (media.length >= 5) {
      content = _buildCarousel(media);
    } else {
      content = _buildGrid(media);
    }

    return RepaintBoundary(child: content);
  }

  // ─── Single Media ───────────────────────────────────────

  Widget _buildSingle(PostMedia media) {
    if (media.mediaType == MediaType.video) {
      return _buildSingleVideo(media);
    }
    return _buildSingleImage(media);
  }

  Widget _buildSingleImage(PostMedia media) {
    final ratio = _computeRatio(media);
    final bg = _mediaBgColor(media, widget.dominantColor);

    return GestureDetector(
      onTap: () => widget.onImageTap?.call(
        widget.media.where((m) => m.mediaType == MediaType.image).toList(),
        media,
      ),
      child: _buildAdaptiveContainer(
        ratio: ratio,
        bgColor: bg,
        imageUrl: media.fileUrl,
      ),
    );
  }

  Widget _buildSingleVideo(PostMedia media) {
    final ratio = _resolvedVideoRatio ?? _computeRatio(media);
    final clampedRatio = _clampRatio(ratio);

    return AspectRatio(
      aspectRatio: clampedRatio,
      child: VideoPlayerWidget(
        videoUrl: media.fileUrl,
        thumbnailUrl: media.thumbnailUrl,
        aspectRatio: clampedRatio,
        onTap: () => widget.onTap?.call(),
        onAspectRatioResolved: (resolved) {
          if (mounted && _resolvedVideoRatio == null) {
            setState(() => _resolvedVideoRatio = resolved);
          }
        },
      ),
    );
  }

  /// Optimal memCacheWidth: screenWidth * devicePixelRatio capped at 1200.
  int _optimalCacheWidth(BuildContext context) {
    final mq = MediaQuery.of(context);
    return (mq.size.width * mq.devicePixelRatio).clamp(0, 1200).toInt();
  }

  /// Builds the correct container based on ratio classification.
  Widget _buildAdaptiveContainer({
    required double ratio,
    required Color bgColor,
    required String imageUrl,
  }) {
    final cls = _classifyRatio(ratio);
    final cacheW = _optimalCacheWidth(context);

    switch (cls) {
      case _RatioClass.inRange:
        return AspectRatio(
          aspectRatio: ratio,
          child: CachedMediaImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            backgroundColor: bgColor,
            placeholder: Container(color: bgColor),
            errorWidget: _buildErrorPlaceholder(bgColor),
            cacheWidth: cacheW,
          ),
        );

      case _RatioClass.ultraTall:
        final cw = _optimalCacheWidth(context);
        return AspectRatio(
          aspectRatio: _kMinRatio, // 4:5 container
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Blurred background layer — zero fade to avoid animation artifacts
              ExcludeSemantics(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: CachedMediaImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    backgroundColor: bgColor,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    cacheWidth: cw,
                  ),
                ),
              ),
              // Dark tint
              Container(color: Colors.black.withValues(alpha: 0.15)),
              // Sharp foreground
              Center(
                child: CachedMediaImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  backgroundColor: Colors.transparent,
                  cacheWidth: cw,
                ),
              ),
            ],
          ),
        );

      case _RatioClass.ultraWide:
        return AspectRatio(
          aspectRatio: _kMaxRatio, // 1.91:1 container
          child: Container(
            color: bgColor,
            child: Center(
              child: CachedMediaImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                backgroundColor: Colors.transparent,
                cacheWidth: cacheW,
              ),
            ),
          ),
        );
    }
  }

  // ─── Grid (2–4 items) ─────────────────────────────────────

  Widget _buildGrid(List<PostMedia> media) {
    final items = media.take(4).toList();
    final count = items.length;

    return Semantics(
      label: 'Photo grid, $count items',
      child: _buildGridLayout(items, media.length > 4),
    );
  }

  Widget _buildGridLayout(List<PostMedia> items, bool hasMore) {
    switch (items.length) {
      case 2:
        return _buildGrid2(items);
      case 3:
        return _buildGrid3(items);
      case 4:
        return _buildGrid4(items, hasMore);
      default:
        return _buildGrid2(items);
    }
  }

  Widget _buildGrid2(List<PostMedia> items) {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(child: _buildGridCell(items[0], items)),
          const SizedBox(width: _kGridGap),
          Expanded(child: _buildGridCell(items[1], items)),
        ],
      ),
    );
  }

  Widget _buildGrid3(List<PostMedia> items) {
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Expanded(child: _buildGridCell(items[0], items)),
          const SizedBox(width: _kGridGap),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildGridCell(items[1], items)),
                const SizedBox(height: _kGridGap),
                Expanded(child: _buildGridCell(items[2], items)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid4(List<PostMedia> items, bool hasMore) {
    return SizedBox(
      height: 280,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridCell(items[0], items)),
                const SizedBox(width: _kGridGap),
                Expanded(child: _buildGridCell(items[1], items)),
              ],
            ),
          ),
          const SizedBox(height: _kGridGap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridCell(items[2], items)),
                const SizedBox(width: _kGridGap),
                Expanded(
                  child: hasMore
                      ? _buildMoreOverlay(items[3], items, widget.media.length - 4)
                      : _buildGridCell(items[3], items),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(PostMedia media, List<PostMedia> allItems) {
    final bg = _mediaBgColor(media, widget.dominantColor);
    final isVideo = media.mediaType == MediaType.video;

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          widget.onTap?.call();
        } else {
          widget.onImageTap?.call(
            allItems.where((m) => m.mediaType == MediaType.image).toList(),
            media,
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedMediaImage(
            imageUrl: isVideo ? (media.thumbnailUrl ?? media.fileUrl) : media.fileUrl,
            fit: BoxFit.cover,
            backgroundColor: bg,
          ),
          if (isVideo)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const HeroIcon(HeroIcons.play, style: HeroIconStyle.solid, size: 28, color: Colors.white),
              ),
            ),
          if (isVideo && media.duration != null)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(media.duration!),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoreOverlay(PostMedia media, List<PostMedia> allItems, int extraCount) {
    return GestureDetector(
      onTap: () => widget.onTap?.call(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedMediaImage(
            imageUrl: media.fileUrl,
            fit: BoxFit.cover,
            backgroundColor: _mediaBgColor(media, widget.dominantColor),
          ),
          Container(color: Colors.black54),
          Center(
            child: Text(
              '+$extraCount',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Carousel (5+ items) ──────────────────────────────────

  Widget _buildCarousel(List<PostMedia> media) {
    final leadRatio = _clampRatio(_computeRatio(media.first));
    final pageController = PageController();

    return StatefulBuilder(
      builder: (context, setLocalState) {
        int currentPage = 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: leadRatio,
              child: Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        final page = pageController.page?.round() ?? 0;
                        if (page != currentPage) {
                          setLocalState(() => currentPage = page);
                        }
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: media.length,
                      itemBuilder: (context, index) {
                        final item = media[index];
                        return Semantics(
                          label: 'Image ${index + 1} of ${media.length}',
                          child: GestureDetector(
                            onTap: () {
                              if (item.mediaType == MediaType.video) {
                                widget.onTap?.call();
                              } else {
                                widget.onImageTap?.call(
                                  media.where((m) => m.mediaType == MediaType.image).toList(),
                                  item,
                                );
                              }
                            },
                            child: _buildCarouselSlide(item),
                          ),
                        );
                      },
                    ),
                  ),
                  // Counter badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentPage + 1}/${media.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Dot indicator (outside media zone)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  media.length.clamp(0, 10), // max 10 dots
                  (i) => Container(
                    width: _kDotSize,
                    height: _kDotSize,
                    margin: EdgeInsets.symmetric(horizontal: _kDotSpacing / 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == currentPage
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCarouselSlide(PostMedia media) {
    if (media.mediaType == MediaType.video) {
      final ratio = _computeRatio(media);
      return VideoPlayerWidget(
        videoUrl: media.fileUrl,
        thumbnailUrl: media.thumbnailUrl,
        aspectRatio: _clampRatio(ratio),
        autoPlayOnVisible: false,
        onTap: () => widget.onTap?.call(),
      );
    }

    final ratio = _computeRatio(media);
    final bg = _mediaBgColor(media, widget.dominantColor);
    final cls = _classifyRatio(ratio);

    if (cls == _RatioClass.inRange) {
      return CachedMediaImage(
        imageUrl: media.fileUrl,
        fit: BoxFit.cover,
        backgroundColor: bg,
      );
    }

    // Ultra-tall or ultra-wide: blur bg + contain
    final cw = _optimalCacheWidth(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: CachedMediaImage(
              imageUrl: media.fileUrl,
              fit: BoxFit.cover,
              backgroundColor: bg,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              cacheWidth: cw,
            ),
          ),
        ),
        Container(color: Colors.black.withValues(alpha: 0.15)),
        Center(
          child: CachedMediaImage(
            imageUrl: media.fileUrl,
            fit: BoxFit.contain,
            backgroundColor: Colors.transparent,
            cacheWidth: cw,
          ),
        ),
      ],
    );
  }

  // ─── Mixed Media (video + images) ─────────────────────────

  Widget _buildMixed(List<PostMedia> media) {
    final hero = media[_heroIndex];
    final thumbnails = <PostMedia>[];
    for (var i = 0; i < media.length; i++) {
      if (i != _heroIndex) thumbnails.add(media[i]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hero
        _buildSingle(hero),
        // Thumbnail strip
        if (thumbnails.isNotEmpty)
          SizedBox(
            height: _kThumbnailSize + 8, // 4px padding top + bottom
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: thumbnails.length,
              separatorBuilder: (_, __) => const SizedBox(width: _kThumbnailGap),
              itemBuilder: (context, index) {
                final item = thumbnails[index];
                final originalIndex = media.indexOf(item);
                final isVideo = item.mediaType == MediaType.video;
                return Semantics(
                  label: 'Thumbnail ${index + 1}',
                  child: GestureDetector(
                    onTap: () => setState(() => _heroIndex = originalIndex),
                    child: SizedBox(
                      width: _kThumbnailSize,
                      height: _kThumbnailSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedMediaImage(
                              imageUrl: isVideo ? (item.thumbnailUrl ?? item.fileUrl) : item.fileUrl,
                              fit: BoxFit.cover,
                              backgroundColor: _mediaBgColor(item, widget.dominantColor),
                            ),
                          ),
                          if (isVideo)
                            const Center(
                              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 24),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────

  Widget _buildErrorPlaceholder(Color bgColor) {
    return Container(
      color: bgColor,
      child: const Center(
        child: HeroIcon(HeroIcons.photo, style: HeroIconStyle.outline, size: 50, color: Color(0xFF999999)),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
