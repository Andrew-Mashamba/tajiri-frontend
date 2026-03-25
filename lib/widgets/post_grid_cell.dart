import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post_models.dart';
import 'cached_media_image.dart';

/// Grid thumbnail cache size — small for performance (Instagram uses ~150px).
/// We use 300px to account for 3x device pixel ratio on modern phones.
const int kGridThumbnailCacheSize = 300;

/// Instagram-style square grid cell for profile posts.
///
/// Shows a 1:1 center-cropped thumbnail with overlay indicators for:
/// - Carousel/multi-image (top-right stacked-squares icon)
/// - Video/Reel (top-right play icon + bottom-left view count)
/// - Pinned post (top-left pin icon)
/// - Text-only post (colored background with text preview)
///
/// Wrapped in [RepaintBoundary] for scroll performance isolation.
class PostGridCell extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PostGridCell({
    super.key,
    required this.post,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress?.call();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base thumbnail
            _buildThumbnail(),
            // Overlay indicators
            ..._buildOverlays(),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // Prefer server-generated grid thumbnail (300x300 square) from first media
    final firstMedia = post.media.isNotEmpty ? post.media.first : null;
    final gridThumbUrl = firstMedia?.gridThumbnailUrl;
    final thumbnailUrl = gridThumbUrl ?? post.thumbnailUrl;

    // Text-only posts with colored background
    if (post.hasBackgroundColor && thumbnailUrl == null) {
      return _buildColoredTextThumbnail();
    }

    // Audio posts with cover image
    if (post.isAudioPost && post.coverImagePath != null) {
      return CachedMediaImage(
        imageUrl: post.coverImageUrl,
        fit: BoxFit.cover,
        cacheWidth: kGridThumbnailCacheSize,
        cacheHeight: kGridThumbnailCacheSize,
        placeholder: _buildPlaceholder(),
      );
    }

    // Posts with media — use grid thumbnail if available, else fallback
    if (thumbnailUrl != null) {
      return CachedMediaImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        cacheWidth: kGridThumbnailCacheSize,
        cacheHeight: kGridThumbnailCacheSize,
        placeholder: _buildPlaceholder(),
      );
    }

    // Fallback: text-only post without color
    return _buildTextOnlyThumbnail();
  }

  Widget _buildColoredTextThumbnail() {
    Color bgColor;
    try {
      final hex = post.backgroundColor!.replaceFirst('#', '');
      bgColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      bgColor = const Color(0xFF1A1A1A);
    }

    return Container(
      color: bgColor,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        post.content ?? '',
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildTextOnlyThumbnail() {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        post.content ?? '',
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade300,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }

  /// Dominant-color placeholder: uses the media's server-extracted dominant color,
  /// falls back to post's background color, then neutral grey.
  /// This creates the Instagram-style zero-layout-shift colored placeholder.
  Widget _buildPlaceholder() {
    // Try server-extracted dominant color from first media
    final firstMedia = post.media.isNotEmpty ? post.media.first : null;
    final dominantColor = firstMedia?.dominantColor;
    if (dominantColor != null) {
      try {
        final hex = dominantColor.replaceFirst('#', '');
        return Container(color: Color(int.parse('FF$hex', radix: 16)));
      } catch (_) {
        // Fall through
      }
    }
    // Fallback to post's background color (for colored text posts)
    if (post.hasBackgroundColor) {
      try {
        final hex = post.backgroundColor!.replaceFirst('#', '');
        return Container(color: Color(int.parse('FF$hex', radix: 16)));
      } catch (_) {
        // Fall through
      }
    }
    return Container(color: Colors.grey.shade200);
  }

  List<Widget> _buildOverlays() {
    final overlays = <Widget>[];

    // Pinned icon — top-left
    if (post.isPinned) {
      overlays.add(
        const Positioned(
          top: 6,
          left: 6,
          child: _OverlayIcon(icon: Icons.push_pin_rounded, size: 16),
        ),
      );
    }

    // Carousel indicator — top-right
    if (post.media.length > 1) {
      overlays.add(
        const Positioned(
          top: 6,
          right: 6,
          child: _OverlayIcon(icon: Icons.collections_rounded, size: 16),
        ),
      );
    }
    // Video/Reel indicator — top-right (only if not carousel)
    else if (post.hasVideo) {
      overlays.add(
        const Positioned(
          top: 6,
          right: 6,
          child: _OverlayIcon(icon: Icons.videocam_rounded, size: 16),
        ),
      );
    }
    // Audio indicator — top-right
    else if (post.isAudioPost) {
      overlays.add(
        const Positioned(
          top: 6,
          right: 6,
          child: _OverlayIcon(icon: Icons.headphones_rounded, size: 16),
        ),
      );
    }

    // View count — bottom-left (videos only)
    if (post.hasVideo && post.viewsCount > 0) {
      overlays.add(
        Positioned(
          bottom: 6,
          left: 6,
          child: _ViewCountBadge(count: post.viewsCount),
        ),
      );
    }

    return overlays;
  }
}

/// Small white icon with drop shadow for grid overlays.
class _OverlayIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _OverlayIcon({required this.icon, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: Colors.white,
      shadows: const [
        Shadow(color: Colors.black54, blurRadius: 4),
      ],
    );
  }
}

/// Video view count badge (bottom-left) — e.g. "▶ 12.3K"
class _ViewCountBadge extends StatelessWidget {
  final int count;

  const _ViewCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.play_arrow_rounded,
          size: 14,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
        const SizedBox(width: 2),
        Text(
          _formatCount(count),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Long-press peek preview overlay for a post.
///
/// Shows at ~80% screen width with dimmed backdrop, displays:
/// - Image/video thumbnail (first image for carousels)
/// - Like count, comment count
/// - Caption preview (2 lines)
class PostPeekPreview extends StatelessWidget {
  final Post post;

  const PostPeekPreview({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final previewWidth = screenWidth * 0.8;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: previewWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thumbnail
              _buildPreviewImage(previewWidth),
              // Stats + caption
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    Row(
                      children: [
                        Icon(Icons.favorite_rounded, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(post.likesCount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(post.commentsCount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        if (post.hasVideo && post.viewsCount > 0) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.play_arrow_rounded, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(post.viewsCount),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Caption
                    if (post.content != null && post.content!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        post.content!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
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

  Widget _buildPreviewImage(double width) {
    final thumbnailUrl = post.thumbnailUrl;

    if (post.hasBackgroundColor && thumbnailUrl == null) {
      Color bgColor;
      try {
        final hex = post.backgroundColor!.replaceFirst('#', '');
        bgColor = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {
        bgColor = const Color(0xFF1A1A1A);
      }
      return Container(
        width: width,
        height: width * 0.75,
        color: bgColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Text(
          post.content ?? '',
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (thumbnailUrl != null) {
      return CachedMediaImage(
        imageUrl: thumbnailUrl,
        width: width,
        height: width,
        fit: BoxFit.cover,
        cacheWidth: 640,
        cacheHeight: 640,
      );
    }

    // Text-only fallback
    return Container(
      width: width,
      height: width * 0.5,
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        post.content ?? '',
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Shows the [PostPeekPreview] as a full-screen overlay that dismisses
/// when the user lifts their finger (pointer up) — matching Instagram's
/// long-press peek behavior. Includes a scale-in animation.
void showPostPeekPreview(BuildContext context, Post post) {
  late OverlayEntry previewOverlay;
  late OverlayEntry dismissOverlay;
  bool dismissed = false;

  void removeAll() {
    if (dismissed) return;
    dismissed = true;
    previewOverlay.remove();
    dismissOverlay.remove();
  }

  previewOverlay = OverlayEntry(
    builder: (_) => _AnimatedPeekPreview(post: post),
  );

  // Use Listener to catch pointer up (finger lift) — GestureDetector doesn't
  // reliably detect the end of a long-press gesture.
  dismissOverlay = OverlayEntry(
    builder: (_) => Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: (_) => removeAll(),
      onPointerCancel: (_) => removeAll(),
      child: const SizedBox.expand(),
    ),
  );

  Overlay.of(context).insert(previewOverlay);
  Overlay.of(context).insert(dismissOverlay);

  // Safety net: auto-dismiss after 8s in case pointer events are lost
  Future.delayed(const Duration(seconds: 8), () {
    if (!dismissed) removeAll();
  });
}

/// Animated wrapper for the peek preview — scales in from 0.85 to 1.0
/// with a quick ease-out curve for a polished feel.
class _AnimatedPeekPreview extends StatefulWidget {
  final Post post;
  const _AnimatedPeekPreview({required this.post});

  @override
  State<_AnimatedPeekPreview> createState() => _AnimatedPeekPreviewState();
}

class _AnimatedPeekPreviewState extends State<_AnimatedPeekPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: PostPeekPreview(post: widget.post),
    );
  }
}
