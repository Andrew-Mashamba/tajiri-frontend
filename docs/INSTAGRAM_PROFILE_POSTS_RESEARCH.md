# Instagram Profile Posts — Research & Implementation Guide

## UX/UI Patterns

| Pattern | Instagram | TAJIRI Status |
|---|---|---|
| **Layout** | 3-column grid, 1px gaps, square 1:1 thumbnails, edge-to-edge | DONE — `SliverGrid` with `PostGridCell` |
| **Post indicators** | Carousel icon (top-right), Reels badge, view count (bottom-left), pin icon (top-left) | DONE — all overlay icons implemented |
| **Scroll architecture** | Single `CustomScrollView` — header scrolls away, tab bar pins sticky | DONE — `CustomScrollView` with `SliverGrid` |
| **Tabs** | Icon-only (Posts/Reels/Tagged), swipeable, independent scroll state | Existing `TabController` (unchanged) |
| **Tap behavior** | Grid tap opens scrollable feed view from that post onward | DONE — opens `PostDetailScreen` |
| **Long-press** | Popup preview (80% width, dimmed backdrop, video auto-plays) | DONE — peek preview with scale animation, dismiss on finger lift |
| **Pinned posts** | Up to 3, pin icon, always first in grid | DONE — sorted first, pin icon overlay |

## Grid Layout Specs

- **3-column grid**, edge-to-edge (no horizontal padding on outer edges)
- **1px gap** between cells (horizontal and vertical)
- **1:1 square aspect ratio** for every thumbnail, center-cropped
- **Cell size** = `(screenWidth - 2px gaps) / 3`
- Grid is part of a single scroll context with the profile header (not a separate scrollable widget)

## Post Type Indicators (Overlay Icons)

All indicators have subtle drop shadows for legibility:

- **Carousel / Multi-image**: Stacked-squares icon, top-right corner
- **Reels / Video**: Reels clapperboard icon, top-right corner
- **View count**: Play-triangle + count text, bottom-left (Reels/videos only, e.g., "▶ 12.3K")
- **Pinned posts**: White pin icon, top-left corner

## Performance Tricks

### 1. Three-Tier Image Loading
- **Tiny thumbnail** (~150x150px, ~5-10KB) — loaded first for the grid
- **Medium resolution** (~640x640px) — used when viewing the post
- **Full resolution** (~1080x1080px) — loaded for zoom/detail
- Grid **only ever loads tiny thumbnails** — single biggest performance win

### 2. Dominant Color Placeholders
- Server sends dominant color value in API response (computed server-side)
- Grid shows colored box instantly as placeholder before thumbnail loads
- Zero layout shift — placeholders are exact same size as final thumbnails
- Fades in thumbnail over the color placeholder

### 3. Virtualized Grid (Recycled Cells)
- Only cells visible on screen + 1-2 row buffer are rendered
- Off-screen cells are recycled — image views reused for new cells
- Even a profile with 5,000 posts only has ~21-30 image widgets alive at any time

### 4. Scroll-Direction-Aware Prefetching
- Prefetches thumbnail images 2-3 rows ahead of current scroll position
- Direction-aware: scrolling down prefetches below, scrolling up prefetches above
- Prefetch priority lower than on-screen image loads (visible content always loads first)

### 5. Decode at Display Size
- Thumbnails decoded at exact pixel size needed (e.g., 130pt × 3x = 390px)
- Never decode at full resolution — saves massive amounts of memory
- Flutter: use `memCacheWidth` and `memCacheHeight` on `cached_network_image`

### 6. RepaintBoundary Per Cell
- Each grid cell wrapped in `RepaintBoundary` to isolate repaints
- Prevents entire grid from repainting when one cell changes

### 7. Fixed Pre-computed Sizes
- No dynamic measurement during scroll layout
- All cell sizes computed once and reused
- Prevents jank from layout recalculation

### 8. API Prefetch at ~70% Scroll
- Next page of posts fetched when user is ~70% through current batch
- Cursor-based pagination for consistent results
- Loading spinner or shimmer row at bottom during fetch

### 9. Flat View Hierarchy
- Each grid cell is minimal: one image + optional overlay icons
- No nested layouts within cells
- All image decoding on background threads; UI thread only composites pre-decoded bitmaps

## Features

### Pinned Posts
- Up to 3 posts can be pinned to top of grid
- White pin icon at top-left of thumbnail
- Always occupy first positions in grid (left-to-right, top row)
- Pinned via post three-dot menu → "Pin to profile"
- Excluded from chronological position and placed at start

### Long-Press Preview (Peek)
- Long-pressing thumbnail shows popup preview at ~80% screen width
- Centered on screen with dimmed background overlay
- Shows: image/video, like count, comment count, caption preview
- For carousels: shows first image
- For videos: auto-plays muted
- Releasing dismisses the preview

### Grid-Only View
- Instagram removed list-view toggle years ago
- Grid is the only view in Posts tab
- Tapping any post opens it in scrollable feed view (full-size post with comments)
- Can scroll down through subsequent posts in feed format from that point

### Archive (Future — requires backend API)
- Posts can be archived (hidden from grid but saved privately)
- Archive accessible via hamburger menu → "Archive"
- Posts can be unarchived back to original chronological position
- **Status**: Not yet implemented — needs backend `POST /api/posts/{id}/archive` endpoint

### Ordering
- Strictly reverse-chronological (newest first)
- Pinned posts always at top, then chronological
- No user-facing filtering or sorting options

## Flutter Implementation Reference

### Grid Structure
```dart
SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 1,
    mainAxisSpacing: 1,
    childAspectRatio: 1.0,
  ),
  delegate: SliverChildBuilderDelegate(
    (context, index) => PostGridCell(post: posts[index]),
    childCount: posts.length,
  ),
)
```

### Key Packages
- `cached_network_image` — two-layer caching with `memCacheWidth`/`memCacheHeight`
- `shimmer` — shimmer placeholder effects (optional, Instagram uses solid color)

### Thumbnail Strategy
- Backend should serve thumbnails at predictable URL (e.g., `?w=300&h=300` or `/thumbnails/` path)
- Use `cached_network_image` with `memCacheWidth: 300, memCacheHeight: 300`
- Use dominant color from API as `ColoredBox` placeholder for instant display
- Always specify `width`, `height`, and `fit: BoxFit.cover` on images

## Implementation Status

### Completed
- [x] 3-column grid, 1px gaps, 1:1 square thumbnails (`SliverGrid` + `PostGridCell`)
- [x] Post type overlay icons: carousel (top-right), video (top-right), audio (top-right), pin (top-left)
- [x] View count badge (bottom-left) for videos with abbreviated counts (12.3K, 1.2M)
- [x] Drop shadows on all overlay icons
- [x] Dominant-color placeholders (uses `post.backgroundColor` when available)
- [x] Virtualized grid via `SliverGrid` with `addAutomaticKeepAlives: false`
- [x] `RepaintBoundary` per cell for repaint isolation
- [x] Fixed 1:1 aspect ratio — no dynamic measurement during scroll
- [x] Decode at display size (`cacheWidth: 300, cacheHeight: 300`)
- [x] Scroll-direction-aware thumbnail prefetching (2-3 rows ahead in scroll direction)
- [x] API prefetch at ~70% scroll depth
- [x] Loading spinner at bottom during pagination
- [x] Increased `cacheExtent` (~4 rows off-screen pre-built)
- [x] Pinned posts (up to 3) sorted first in grid
- [x] Long-press peek preview (80% width, dimmed backdrop, scale-in animation)
- [x] Dismiss on finger lift (pointer up) via `Listener`
- [x] Haptic feedback on long-press
- [x] Shimmer loading placeholder grid (18 cells)
- [x] Pull-to-refresh
- [x] Grid-only view (no list toggle)
- [x] Empty state with create-post CTA
- [x] Handles all post types: media, colored text, audio with cover, text-only

### Requires Backend Support
- [ ] Archive posts (`POST /api/posts/{id}/archive` + `POST /api/posts/{id}/unarchive`)
- [ ] Server-side dominant color extraction (currently uses `post.backgroundColor` which is for text posts)
- [ ] Dedicated thumbnail URLs at smaller sizes (currently uses full image URL with client-side decode limiting)
- [ ] Pin/unpin API (`POST /api/posts/{id}/pin` + `POST /api/posts/{id}/unpin`)

### Files Changed
- `lib/widgets/post_grid_cell.dart` — New: grid cell, overlay icons, peek preview, animated overlay
- `lib/screens/profile/profile_screen.dart` — Rewrote `_ProfilePostsPage` from `ListView` to `SliverGrid`
