# Adaptive Media Zone — Design Spec

## Problem

PostCard displays images and videos at incorrect aspect ratios — ultra-tall screenshots get cropped, panoramas get squished, videos with no dimensions default poorly, and multi-media collections lack a coherent layout strategy. The current approach (hard clamp to Instagram's 4:5–1.91:1 range with BoxFit.cover) loses content for out-of-range media.

## Solution

A single `AdaptiveMediaZone` widget that classifies each post's media collection and picks the optimal display strategy, combining techniques from Instagram (clamp + cover for in-range), TikTok (blur-background fit for out-of-range), and Twitter (smart grids for collections).

## Architecture

```
PostCard
  ├── [documents filtered out — rendered by PostCard directly]
  ├── [audio-only — rendered by PostCard via AudioPlayerWidget directly]
  └── AdaptiveMediaZone(media, dominantColor, onTap, onImageTap)
        ├── _SingleMediaView     (1 image or video)
        │     ├── In-range (0.8–1.91)  → natural AspectRatio + BoxFit.cover
        │     ├── Ultra-tall (< 0.8)   → 4:5 container + blur bg + BoxFit.contain
        │     └── Ultra-wide (> 1.91)  → 1.91:1 container + color bg + BoxFit.contain
        ├── _GridMediaView       (2–4 items)
        │     └── 2=side-by-side, 3=1-big+2-small, 4=2x2
        ├── _CarouselMediaView   (5+ same-type items)
        │     └── PageView + dots + counter badge, lead image ratio
        └── _MixedMediaView      (has video + images)
              └── Lead video full-width + scrollable thumbnail strip
```

**Scope boundary:** AdaptiveMediaZone handles image and video media only. Document attachments and audio-only posts are filtered out before passing to the widget — PostCard retains `_buildDocumentPreview()` and `AudioPlayerWidget` rendering for those types. This keeps AdaptiveMediaZone focused on visual media layout.

## Single Media Strategies

### In-range (ratio 0.8 — 1.91)

- Container: `AspectRatio(naturalRatio)`
- Image fit: `BoxFit.cover`
- Placeholder: solid dominant color background
- No cropping or letterboxing — direct display

### Ultra-tall (ratio < 0.8)

- Container: `AspectRatio(4/5)` — tallest allowed in feed
- Background: blurred, scaled-up copy of the same image via `ImageFiltered(sigmaX: 25, sigmaY: 25)` + dark tint, with dominant color fallback
- Foreground: actual image centered with `BoxFit.contain`
- Result: full image visible, no content loss, blur fills remaining space
- Note: blur layer uses `fadeInDuration: Duration.zero` and `fadeOutDuration: Duration.zero` to avoid animation artifacts under the blur filter

### Ultra-wide (ratio > 1.91)

- Container: `AspectRatio(1.91)` — widest allowed in feed
- Background: dominant color solid fill
- Foreground: actual image centered with `BoxFit.contain`
- Result: full panorama visible, color bands top/bottom

### Unknown dimensions (null width/height)

- Images: default to `AspectRatio(1.0)` (square)
- Videos: default to `AspectRatio(16/9)`, auto-correct when video player reports real dimensions via `onAspectRatioResolved` callback

## Collection Strategies

### Grid (2–4 items)

Twitter-style adaptive grid layouts:

- **2 items:** Side-by-side, equal width, 1:1 cells
- **3 items:** One tall image left (spans full height), two stacked squares right
- **4 items:** 2x2 grid, 1:1 cells
- **Grid gap:** 2px between cells (matching current behavior)

All cells: `BoxFit.cover`, dominant color placeholder, video thumbnails get play icon + duration badge. Image tap opens viewer, video tap opens post detail.

### Carousel (5+ same-type items)

Instagram-style swipeable carousel:

- `PageView.builder` for lazy slide creation
- Lead image ratio sets container ratio (clamped 0.8–1.91)
- Each slide individually applies single-media strategy for its own ratio
- Dot indicator rendered outside the AspectRatio container, adding ~24px below the media
- Counter badge "1/N" positioned inside the media zone (overlaid) at top-right with 8px inset
- Swipe gesture with standard PageView physics

### Mixed media (video + images)

Lead-with-hero approach:

- First video renders full-width using single-media adaptive strategy
- Remaining items as horizontal scrollable thumbnail strip below hero
- Each thumbnail is 56x56px (square) with 4px horizontal gaps, meeting the 48dp minimum touch target
- Tapping a thumbnail swaps it into the hero position
- If collection has no video, first image is hero

## Public API

```dart
class AdaptiveMediaZone extends StatefulWidget {
  final List<PostMedia> media;  // pre-filtered: images + videos only
  final Color? dominantColor;
  final VoidCallback? onTap;
  /// Opens image viewer. AdaptiveMediaZone uses its own BuildContext
  /// for navigation; callback receives only the media list and tapped item.
  final Function(List<PostMedia>, PostMedia)? onImageTap;

  const AdaptiveMediaZone({
    super.key,
    required this.media,
    this.dominantColor,
    this.onTap,
    this.onImageTap,
  });
}
```

## PostCard Integration

PostCard filters media before passing to AdaptiveMediaZone:

```dart
final visualMedia = post.media.where((m) => m.mediaType == MediaType.image || m.mediaType == MediaType.video).toList();
```

Documents and audio-only remain handled by PostCard's existing methods.

Replaces these methods in `post_card.dart`:
- `_buildMedia()`
- `_buildSingleMedia()`
- `_buildMediaGrid()`
- `_buildImageGrid()`
- `_buildImageWithPlaceholder()`
- `_calculateAspectRatio()` and ratio constants

Replaced by single call:
```dart
if (visualMedia.isNotEmpty)
  AdaptiveMediaZone(
    media: visualMedia,
    dominantColor: _parseDominantColor(post),
    onTap: widget.onTap,
    onImageTap: _openImageViewer,
  ),
```

PostCard retains:
- `_buildDocumentPreview()` — rendered separately for document attachments
- `AudioPlayerWidget` — rendered for audio-only posts or audio attachments in the media zone
- `_buildColoredTextContent()` — colored text posts have no media
- `_buildTextOnlyMedia()` — text-only posts

Approximately 200 lines removed from PostCard, replaced by ~5 lines of filtering + widget call.

## VideoPlayerWidget Change

Add optional callback:
```dart
final void Function(double aspectRatio)? onAspectRatioResolved;
```

Implementation: after `controller.initialize()` completes (around line 135 of video_player_widget.dart), read `controller.value.size` and call `onAspectRatioResolved(width / height)` if size is non-zero. Fired once. `AdaptiveMediaZone` uses this to `setState` and re-layout from default 16:9 to actual ratio.

## Blur Background Technique

Two-layer Stack, no backend dependency:

1. **Bottom layer:** `CachedMediaImage(fit: BoxFit.cover, fadeInDuration: Duration.zero, fadeOutDuration: Duration.zero)` wrapped in `ImageFiltered(sigmaX: 25, sigmaY: 25)` + `Container(color: Colors.black.withValues(alpha: 0.3))` tint. Zero fade durations prevent animation artifacts under the blur filter.
2. **Top layer:** `CachedMediaImage(fit: BoxFit.contain)` — sharp actual image with normal fade-in

GPU-accelerated via Flutter's `ImageFiltered` (backed by Skia/Impeller blur shader). Single network request — same image URL used for both layers, cached by `CachedMediaImage`.

## Dominant Color Parsing

Centralized helper in `adaptive_media_zone.dart`:

```dart
Color parseDominantColor(String? hex, {Color fallback = const Color(0xFF666666)}) {
  if (hex == null) return fallback;
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return fallback;
  }
}
```

Priority: media-level `dominantColor` > post-level fallback > grey default.

## Performance

- `ImageFiltered` blur: single GPU pass, no extra network request
- `RepaintBoundary` around the entire zone for scroll isolation
- `CachedMediaImage` with `memCacheWidth` set to `min(screenWidth * devicePixelRatio, 1200).toInt()` balancing quality and memory on high-DPI devices
- `PageView.builder` for lazy carousel page creation
- Dominant color placeholder shown instantly (no network wait)
- Blur layer uses zero fade durations to avoid double-animation artifacts

## Accessibility

- Carousel pages: `Semantics(label: 'Image X of Y')` on each page
- Grid views: `Semantics(label: 'Photo grid, N items')` on the grid container
- Thumbnail strip items: `Semantics(label: 'Thumbnail N')` on each item
- Blur background layer: `excludeSemantics: true` (decorative only)
- All tap targets meet 48dp minimum (grid cells, thumbnails, carousel pages)

## Files

New: `lib/widgets/adaptive_media_zone.dart` (~400–450 lines)
Modified: `lib/widgets/post_card.dart` (net -150 lines)
Modified: `lib/widgets/video_player_widget.dart` (+10 lines for callback)

## Data Available from Backend

Per `PostMedia` model:
- `width: int?`, `height: int?` — pixel dimensions (null for some videos)
- `dominantColor: String?` — hex color like `#778393` (present on most images)
- `mediaType: MediaType` — image, video, audio, document
- `thumbnailUrl: String?` — video thumbnail
- `duration: int?` — video/audio duration in seconds
- `fileUrl: String` — full media URL
