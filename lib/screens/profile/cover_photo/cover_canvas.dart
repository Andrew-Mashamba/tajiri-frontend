// CoverCanvas — single source of truth for how the profile cover renders.
// Used both by:
//   • CoverPreviewScreen (live preview before upload — local File source)
//   • ProfileScreen SliverAppBar (the actual rendered cover — network URL)
//
// Keeps the layout, sizing, gradient, camera-button, and avatar/name
// chrome identical in both places so the user never sees an aspect-ratio
// or framing mismatch between preview and the live cover.
//
// Spec: docs/superpowers/specs/2026-05-02-cover-photo-upload-design.md §3
//
// IMPORTANT: this widget intentionally bypasses our generic
// `CachedMediaImage` for the URL path. That helper hardcodes
// `memCacheWidth: 800, memCacheHeight: 800` when no explicit size is
// supplied — and Flutter's `ResizeImage` (which `cached_network_image`
// uses under the hood) defaults to `ResizeImagePolicy.exact`, which
// decodes the bitmap to exactly 800×800 *regardless of the source aspect
// ratio*. For a 16:9 cover that produces a vertically-stretched bitmap,
// then BoxFit.cover paints that already-distorted image onto the canvas.
// We pass `memCacheWidth` only (no height) so the decoder preserves
// the 16:9 source aspect.

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../services/media_cache_service.dart';
import '../../../widgets/cached_media_image.dart';

/// Source for the cover image — either a local File (preview) or a URL
/// (profile). Exactly one should be non-null.
class CoverImageSource {
  final File? file;
  final String? url;

  const CoverImageSource.file(File this.file) : url = null;
  const CoverImageSource.url(String this.url) : file = null;
  const CoverImageSource.empty()
      : file = null,
        url = null;

  bool get isEmpty => file == null && (url == null || url!.isEmpty);
}

/// Fixed-aspect rendering of the cover photo with profile chrome on top.
///
/// `height` defaults to 280dp (matches the SliverAppBar.expandedHeight).
/// Children stack order, top to bottom:
///   1. The cover image (or fallback gradient)
///   2. Black-bottom gradient overlay
///   3. Camera-edit button (bottom-right, optional)
///   4. Avatar + name + @username (bottom-left)
///   5. Optional overlay slot (e.g. CoverUploadOverlay)
class CoverCanvas extends StatelessWidget {
  final CoverImageSource cover;

  /// Avatar source (nullable URL → falls back to initials).
  final String? avatarUrl;

  /// When non-null, takes precedence over [avatarUrl] and renders the
  /// avatar from this local File. Used by the profile-photo preview
  /// screen to show the user's *new* avatar in real chrome before upload.
  final File? avatarFile;

  final String? avatarInitials;

  /// Name + handle shown bottom-left over the gradient.
  final String? fullName;
  final String? username;

  /// When non-null shows an interactive camera button bottom-right; tap
  /// invokes the callback. When null, no camera button is rendered.
  ///
  /// CoverPreviewScreen uses [showStaticCameraIcon] instead so the icon
  /// appears for layout parity but isn't tappable.
  final VoidCallback? onCameraTap;

  /// Renders a non-interactive camera-icon chip at bottom-right (for
  /// preview-mode parity). Ignored when [onCameraTap] is provided.
  final bool showStaticCameraIcon;

  /// When non-null, makes the avatar tappable (profile own-photo edit).
  final VoidCallback? onAvatarTap;

  /// Show a small camera badge over the avatar bottom-right (own-profile).
  final bool showAvatarEditBadge;

  /// Show a circular spinner overlay on top of the avatar (uploading).
  final bool isUploadingAvatar;

  /// Optional overlay layered on top of everything (e.g. cover upload
  /// progress / error).
  final Widget? overlay;

  /// Default fallback shown when [cover] is empty.
  final Widget? fallback;

  /// Canvas height. When null, the canvas defers to its parent's
  /// constraints — used inside `FlexibleSpaceBar.background` where the
  /// SliverAppBar already controls the height. The preview screen passes
  /// 280 explicitly to match the SliverAppBar's expanded height.
  final double? height;

  const CoverCanvas({
    super.key,
    required this.cover,
    required this.avatarUrl,
    this.avatarFile,
    required this.avatarInitials,
    required this.fullName,
    required this.username,
    this.onCameraTap,
    this.showStaticCameraIcon = false,
    this.onAvatarTap,
    this.showAvatarEditBadge = false,
    this.isUploadingAvatar = false,
    this.overlay,
    this.fallback,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
      fit: StackFit.expand,
      children: _children(context),
    );
    return height == null ? stack : SizedBox(height: height, child: stack);
  }

  List<Widget> _children(BuildContext context) {
    return [
          // 1. Cover image
          _CoverImage(cover: cover, fallback: fallback),

          // 2. Bottom-up black gradient overlay
          const _GradientScrim(),

          // 3. Camera button (interactive in profile mode, static in preview)
          if (onCameraTap != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: _CameraChip(onTap: onCameraTap!),
            )
          else if (showStaticCameraIcon)
            const Positioned(
              right: 16,
              bottom: 16,
              child: _CameraChip(onTap: null),
            ),

          // 4. Avatar + name + @username
          //    `right: 80` reserves space for the camera button so long
          //    names can never overlap it.
          Positioned(
            left: 16,
            bottom: 16,
            right: 80,
            child: Row(
              children: [
                _Avatar(
                  file: avatarFile,
                  url: avatarUrl,
                  initials: avatarInitials,
                  onTap: onAvatarTap,
                  showEditBadge: showAvatarEditBadge,
                  isUploading: isUploadingAvatar,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (fullName != null && fullName!.isNotEmpty)
                        Text(
                          fullName!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (username != null && username!.isNotEmpty)
                        Text(
                          '@$username',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xCCFFFFFF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

      // 5. Slot for upload progress / error overlay
      if (overlay != null) overlay!,
    ];
  }
}

class _CoverImage extends StatelessWidget {
  final CoverImageSource cover;
  final Widget? fallback;
  const _CoverImage({required this.cover, required this.fallback});

  @override
  Widget build(BuildContext context) {
    if (cover.file != null) {
      return Image.file(
        cover.file!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback ?? const _DefaultGradient(),
      );
    }
    if (cover.url != null && cover.url!.isNotEmpty) {
      // Decode at screen-width × DPR. Critically: pass `memCacheWidth`
      // ONLY — leave `memCacheHeight` null so ResizeImage preserves the
      // source aspect ratio when generating the in-memory bitmap.
      final mq = MediaQuery.of(context);
      final decodeWidth = (mq.size.width * mq.devicePixelRatio).round();
      return CachedNetworkImage(
        imageUrl: cover.url!,
        fit: BoxFit.cover,
        cacheManager: MediaCacheManager.instance,
        memCacheWidth: decodeWidth,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, _) => const ColoredBox(color: Color(0xFF1A1A1A)),
        errorWidget: (_, _, _) => fallback ?? const _DefaultGradient(),
      );
    }
    return fallback ?? const _DefaultGradient();
  }
}

class _GradientScrim extends StatelessWidget {
  const _GradientScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color(0xB3000000), // black @ 70%
          ],
        ),
      ),
    );
  }
}

class _CameraChip extends StatelessWidget {
  final VoidCallback? onTap;
  const _CameraChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: chip,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final File? file;
  final String? url;
  final String? initials;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final bool isUploading;

  const _Avatar({
    required this.file,
    required this.url,
    required this.initials,
    required this.onTap,
    required this.showEditBadge,
    required this.isUploading,
  });

  @override
  Widget build(BuildContext context) {
    final Widget innerImage;
    if (file != null) {
      innerImage = Image.file(
        file!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _initialsFallback(context),
      );
    } else if (url != null && url!.isNotEmpty) {
      innerImage = CachedMediaImage(
        imageUrl: url,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 120),
        errorWidget: _initialsFallback(context),
      );
    } else {
      innerImage = _initialsFallback(context);
    }
    final core = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: innerImage),
    );

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        core,
        if (showEditBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        if (isUploading)
          Positioned.fill(
            child: ClipOval(
              child: Container(
                color: const Color(0x88000000),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return stack;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: stack,
      ),
    );
  }

  Widget _initialsFallback(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: Theme.of(context).colorScheme.primary,
      alignment: Alignment.center,
      child: Text(
        initials ?? '?',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DefaultGradient extends StatelessWidget {
  const _DefaultGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
    );
  }
}
