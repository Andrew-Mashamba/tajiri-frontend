# How TikTok-Style Feed & Story Snap Work (Research)

## 1. TikTok-style vertical feed (one post per screen)

### Behavior
- **Full-screen per item**: One video/post fills the viewport. No partial items; scroll is “page by page.”
- **Vertical scroll**: Swipe up = next, swipe down = previous (like TikTok/Reels/Shorts).
- **Snap**: After a drag, the list snaps so exactly one item is centered in the viewport (no half-scrolled items).
- **Lifecycle**: When a new item becomes the “current” page: play its video; pause the previous one; often preload next/previous.

### Flutter implementation (our app: `ShortsVideoFeed`)

| Concept | Implementation |
|--------|-----------------|
| One item per viewport | `PageView.builder` — Flutter forces each child to the **same size as the viewport** (see [PageView](https://api.flutter.dev/flutter/widgets/PageView-class.html)). |
| Vertical scroll | `scrollDirection: Axis.vertical`. |
| Snap to one page | **Default**: `pageSnapping: true` (not set in code). So the scroll snaps to a single page. |
| Which page is “current” | `PageController` + `onPageChanged(int index)`. |
| Play/pause on change | In `onPageChanged`: pause `_videoControllers[oldIndex]`, play `_videoControllers[newIndex]`, preload nearby. |

**Relevant code** (`lib/widgets/shorts_video_feed.dart`):

```dart
PageView.builder(
  controller: _pageController,
  scrollDirection: Axis.vertical,
  itemCount: widget.posts.length,
  onPageChanged: _onPageChanged,
  itemBuilder: (context, index) => _buildVideoPage(widget.posts[index], index),
)
```

- **No custom `physics`** → default `PageScrollPhysics` with snapping.
- **No `viewportFraction`** → default `1.0` → one full viewport per page.
- **Result**: One post per screen, vertical swipe, snap to next/previous.

---

## 2. Story viewer (one story per “page”, snap by tap)

### Behavior (Instagram/Facebook-style)
- **One user’s story “strip” per screen**: Each **page** = one user (one story group). One story (one photo/video) is shown at a time within that group.
- **No swipe between users**: The horizontal PageView is **not** scrollable by finger; it only moves when you go to next/previous **user**.
- **Tap zones**: Tap **right** (or right third) = next story (or next user if no more stories). Tap **left** (or left third) = previous story (or previous user).
- **Snap**: When moving to next/previous user, the view **animates** to the next page and stops exactly on that page (one story group per page).
- **Auto-advance**: A timer (e.g. 5s) advances to the next story; at end of a user’s stories, advance to next user (next page).
- **Progress bars**: One segment per story in the current group; fill as the current story plays.

### Flutter implementation (our app: `StoryViewerScreen`)

| Concept | Implementation |
|--------|-----------------|
| One story **group** per page | `PageView.builder` with `itemCount: widget.storyGroups.length`. Each page = one `StoryGroup`. |
| No swipe between pages | `physics: const NeverScrollableScrollPhysics()`. User cannot drag the PageView; it only moves when we call `_pageController.nextPage()` / `previousPage()`. |
| Snap to one page | Because we only ever animate to a full page index, we’re always “snapped” to one group. |
| Next/previous by tap | `GestureDetector(onTapDown: _onTapDown)`: if `dx < width/3` → `_previousStory()`, if `dx > width*2/3` → `_nextStory()`. |
| Next/previous story inside group | `_nextStory()` / `_previousStory()`: change `_currentStoryIndex` or call `_nextGroup()` / `_previousGroup()`. |
| Moving to next/previous **group** (next page) | `_nextGroup()`: `_pageController.nextPage(duration: 300ms, curve: Curves.easeInOut)`. `_previousGroup()`: `_pageController.previousPage(...)`. |
| Auto-advance | `AnimationController` (e.g. 5s). On `AnimationStatus.completed` → `_nextStory()` (which may call `_nextGroup()` and thus animate to next page). |

**Relevant code** (`lib/screens/clips/storyviewer_screen.dart`):

```dart
PageView.builder(
  controller: _pageController,
  physics: const NeverScrollableScrollPhysics(),  // no drag; only programmatic
  itemCount: widget.storyGroups.length,
  onPageChanged: _onPageChanged,
  itemBuilder: (context, groupIndex) {
    final group = widget.storyGroups[groupIndex];
    return Stack(
      children: [
        _StoryContent(story: ...),  // one story at a time per group
        _buildProgressBars(group, groupIndex),
        _buildHeader(...),
      ],
    );
  },
)
```

- **One story per “page”** in the sense: one **page** = one story **group** (one user). Within that page, one **story** (one segment) is shown; tap or timer moves to next segment or next group.
- **Snap**: We never scroll by drag; we only `nextPage()`/`previousPage()`, so we always land on a full page index.

---

## 3. Flutter primitives (reference)

### PageView
- **Docs**: [PageView class](https://api.flutter.dev/flutter/widgets/PageView-class.html)
- **Behavior**: “A scrollable list that works **page by page**. Each child is forced to be the **same size as the viewport**.”
- **Snap**: `pageSnapping` (default `true`) — scroll snaps to the nearest page.
- **Direction**: `scrollDirection`: `Axis.vertical` (TikTok feed) or `Axis.horizontal` (stories).

### PageController
- **initialPage**: Which page index is shown first.
- **viewportFraction**: Size of each page as a fraction of viewport (default `1.0` = one full screen per page). Use `< 1.0` only for “peek” of adjacent pages (e.g. carousel).
- **Programmatic move**: `nextPage()`, `previousPage()`, `animateToPage()`.

### Physics
- **Default (null)**: `PageScrollPhysics` — normal drag + snap to page.
- **NeverScrollableScrollPhysics**: Disables drag; only programmatic scrolling (used in our story viewer for “tap only” between users).
- **ClampingScrollPhysics**: No overscroll glow/bounce (e.g. feed list).

---

## 4. Summary table

| Aspect | TikTok-style feed (Shorts) | Story viewer |
|--------|----------------------------|--------------|
| Widget | `PageView.builder` | `PageView.builder` |
| Direction | Vertical | Horizontal (one group per page) |
| One item per “page” | One post per viewport | One story **group** per page; one **story** shown at a time inside |
| User scroll/drag | Yes — swipe up/down | No — `NeverScrollableScrollPhysics` |
| Snap | Default `pageSnapping: true` | Always (we only animate to full page index) |
| Advance | Swipe or (e.g.) tap | Tap left/right + auto-advance timer |
| Lifecycle | `onPageChanged` → play/pause/preload | `onPageChanged` + timer → next/previous story or group |

---

## 5. Files in this project

- **TikTok-style feed**: `lib/widgets/shorts_video_feed.dart` — vertical `PageView`, one post per page, default snap.
- **Story viewer**: `lib/screens/clips/storyviewer_screen.dart` — horizontal `PageView` with `NeverScrollableScrollPhysics`, tap + timer, one story group per page.
