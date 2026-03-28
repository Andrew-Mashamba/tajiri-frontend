import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/media_cache_service.dart';

/// Max decode size for list/feed images when dimensions are unbounded (reduces jank).
const int kDefaultFeedImageCacheWidth = 800;
const int kDefaultFeedImageCacheHeight = 800;

/// Cached network image widget with placeholder and error handling.
/// Uses [MediaCacheManager] so images are stored in the app media cache for
/// offline viewing (same 30-day cache as other media).
/// Use [cacheWidth]/[cacheHeight] (or pass from list context) to decode at display size for smooth scrolling.
class CachedMediaImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  /// Decode at this width for memory/scroll perf. When null, uses [width] or [kDefaultFeedImageCacheWidth].
  final int? cacheWidth;
  /// Decode at this height for memory/scroll perf. When null, uses [height] or [kDefaultFeedImageCacheHeight].
  final int? cacheHeight;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  /// Override fade-in duration (default 200ms). Set to Duration.zero for blur layers.
  final Duration? fadeInDuration;
  /// Override fade-out duration (default 200ms). Set to Duration.zero for blur layers.
  final Duration? fadeOutDuration;

  const CachedMediaImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
    this.fadeInDuration,
    this.fadeOutDuration,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    final int memW = cacheWidth ?? width?.toInt() ?? kDefaultFeedImageCacheWidth;
    final int memH = cacheHeight ?? height?.toInt() ?? kDefaultFeedImageCacheHeight;

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      cacheManager: MediaCacheManager.instance,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 200),
      fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 200),
      memCacheWidth: memW,
      memCacheHeight: memH,
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: backgroundColor ?? Colors.grey.shade200,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: backgroundColor ?? Colors.grey.shade200,
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey.shade400,
            size: 32,
          ),
        );
  }
}

/// Cached avatar image with circular shape
class CachedAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String? fallbackName;
  final Color? backgroundColor;

  const CachedAvatarImage({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.fallbackName,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: backgroundColor ?? Colors.grey.shade200,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade200,
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    final initials = _getInitials(fallbackName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? _getColorForName(fallbackName),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getColorForName(String? name) {
    if (name == null || name.isEmpty) return Colors.grey;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}

/// Precache images for smoother scrolling and offline availability.
class ImagePreloader {
  static final Set<String> _precachedUrls = {};

  /// Precache a single image by URL (uses Flutter's precacheImage with NetworkImage).
  static Future<void> precacheImageUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty || _precachedUrls.contains(url)) return;

    try {
      _precachedUrls.add(url);
      await precacheImage(NetworkImage(url), context);
    } catch (e) {
      _precachedUrls.remove(url);
    }
  }

  /// Precache multiple images
  static Future<void> precacheImages(
      BuildContext context, List<String?> urls) async {
    for (final url in urls) {
      if (url != null && url.isNotEmpty && !_precachedUrls.contains(url)) {
        precacheImageUrl(context, url);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// Clear precache tracking
  static void clearPrecacheTracking() {
    _precachedUrls.clear();
  }
}
