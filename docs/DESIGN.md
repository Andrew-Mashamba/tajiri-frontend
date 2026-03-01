# TAJIRI Design Guidelines

> **Note:** This document is the **single source of truth** for all TAJIRI UI components. All screens, widgets, and features MUST follow these guidelines. See [NAVIGATION.md](NAVIGATION.md) for navigation patterns.

## Quick Reference

| Token | Value | Usage |
|-------|-------|-------|
| `background` | `#FAFAFA` | Scaffold, page backgrounds |
| **Profile UI** | §13.4 | Hero/cover layout, stats row, pill buttons, custom tabs, info card — apply on profile-like screens |
| `surface` | `#FFFFFF` | Cards, buttons, sheets |
| `primaryText` | `#1A1A1A` | Headings, titles, icons |
| `secondaryText` | `#666666` | Subtitles, descriptions |
| `tertiaryText` | `#999999` | Hints, tips, borders |
| `borderRadius.lg` | `16px` | Cards, containers |
| `borderRadius.md` | `12px` | Buttons, chips, small cards |
| `borderRadius.sm` | `8px` | List tiles, inputs |
| `spacing.xs` | `4px` | Tight spacing |
| `spacing.sm` | `8px` | Icon-to-text gaps |
| `spacing.md` | `12px` | Between cards/items |
| `spacing.lg` | `16px` | Container padding |
| `spacing.xl` | `24px` | Section margins |
| `touchTarget` | `48x48dp` | Minimum for all tappable elements |

---

## 1. Color System

### 1.1 Monochrome Palette

```dart
class TajiriColors {
  // Backgrounds
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text & Icons
  static const Color primaryText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF666666);
  static const Color tertiaryText = Color(0xFF999999);

  // Icon Containers
  static const Color iconBackground = Color(0xFF1A1A1A);
  static const Color iconForeground = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFF999999); // Use with 0.3 opacity
  static const Color divider = Color(0xFFE0E0E0);

  // Overlays
  static const Color shadowColor = Color(0xFF000000); // Use with 0.06-0.1 opacity
  static const Color overlay = Color(0xFF1A1A1A); // Use with 0.08 opacity for chips
}
```

### 1.2 Design Rationale
- **No Colorful Elements**: No orange, green, blue buttons - monochrome only
- **Professional Appearance**: Conveys trust for financial/social applications
- **Reduced Cognitive Load**: Users focus on content, not decoration

---

## 2. Typography

### 2.1 Font Sizes

| Style | Size | Weight | Color | Usage |
|-------|------|--------|-------|-------|
| `titleLarge` | 20px | 700 | `#1A1A1A` | Page titles |
| `titleMedium` | 16px | 600 | `#1A1A1A` | Section headers |
| `titleSmall` | 15px | 600 | `#1A1A1A` | Card titles, button text |
| `bodyLarge` | 14px | 400 | `#1A1A1A` | Body text |
| `bodyMedium` | 13px | 500 | `#1A1A1A` | List items |
| `bodySmall` | 12px | 400 | `#666666` | Descriptions, tips |
| `labelLarge` | 12px | 500 | `#666666` | Labels, badges |
| `labelSmall` | 11px | 400 | `#666666` | Subtitles, timestamps |
| `caption` | 10px | 400 | `#999999` | Tertiary info |

### 2.2 Text Overflow Rules

**MANDATORY for all dynamic text:**
```dart
Text(
  dynamicContent,
  maxLines: 1, // or 2 for descriptions
  overflow: TextOverflow.ellipsis,
)
```

---

## 3. Spacing & Layout

### 3.1 Spacing Scale

```dart
class TajiriSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}
```

### 3.2 Common Padding Patterns

| Context | Padding |
|---------|---------|
| Screen horizontal | `24px` |
| Container internal | `16px` |
| Card internal | `16px` |
| Section header | `fromLTRB(20, 24, 20, 16)` |
| List item | `horizontal: 16, vertical: 12` |
| Chip/Badge | `horizontal: 8, vertical: 4` |

### 3.3 Gap Between Elements

| Elements | Gap |
|----------|-----|
| Cards in grid | `12px` |
| List items | `8px` |
| Icon to text | `8px` |
| Title to subtitle | `4px` |
| Sections | `24px` |

---

## 4. Component Patterns

### 4.1 Action Card (Post Type, Feature Selection)

Use for grid-based selection cards (e.g., Create Post type selection).

```dart
Container(
  constraints: const BoxConstraints(minHeight: 72),
  width: double.infinity,
  child: Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container (48x48 circle)
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  ),
)
```

**Grid Layout for Action Cards:**
```dart
// 2-column grid with 12px gap
Row(
  children: [
    Expanded(child: ActionCard(...)),
    const SizedBox(width: 12),
    Expanded(child: ActionCard(...)),
  ],
)
```

### 4.2 Info Card (Tips, Notices)

Use for informational sections with icon + content.

```dart
Container(
  margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFF999999).withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          // Icon container (48x48 rounded square)
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(Icons.tips_and_updates, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Section Title',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Content items...
    ],
  ),
)
```

### 4.3 Tip Item (List item with icon)

```dart
Padding(
  padding: const EdgeInsets.only(top: 8),
  child: Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF999999)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
)
```

### 4.4 Horizontal Scroll Card (Drafts, Stories)

```dart
Container(
  width: 160,
  margin: const EdgeInsets.only(right: 12),
  child: Material(
    color: const Color(0xFFFAFAFA),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: // Content
      ),
    ),
  ),
)

// Container
SizedBox(
  height: 100,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemBuilder: (context, index) => HorizontalCard(...),
  ),
)
```

### 4.5 Navigation Card (Clickable with chevron)

```dart
Container(
  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFF999999).withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Row(
      children: [
        // Leading icon container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1A1A1A), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Color(0xFF666666))),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Color(0xFF999999)),
      ],
    ),
  ),
)
```

### 4.6 Badge/Chip

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A1A).withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: const Color(0xFF666666)),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF666666),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  ),
)
```

### 4.7 List Tile Card

```dart
Card(
  margin: const EdgeInsets.only(bottom: 8),
  child: ListTile(
    onTap: onTap,
    leading: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF666666).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF666666)),
    ),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Row(
      children: [
        Text(label),
        const Text(' • '),
        Text(timestamp),
      ],
    ),
    trailing: IconButton(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline),
    ),
  ),
)
```

---

## 5. AppBar & Navigation

### 5.1 Standard AppBar

```dart
AppBar(
  title: const Text('Page Title'),
  centerTitle: true,
  elevation: 0,
  backgroundColor: Colors.white,
  foregroundColor: Colors.black87,
  actions: [
    // Optional actions
  ],
)
```

### 5.2 AppBar with Badge

```dart
actions: [
  TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.drafts_outlined, size: 20),
    label: Text('$count'),
  ),
]
```

### 5.3 Bottom Navigation (Heroicons)

| Index | Label (EN / SW) | Icon |
|-------|------------------|------|
| 0 | Feed / Nyumbani | `HeroIcons.home` |
| 1 | Messages / Ujumbe | `HeroIcons.chatBubbleOvalLeft` (badge for unread) |
| 2 | Friends / Marafiki | `HeroIcons.users` |
| 3 | Shop / Duka | `HeroIcons.shoppingBag` |
| 4 | Profile / Mimi | `HeroIcons.user` |

---

## 6. Touch Targets & Interaction

### 6.1 Minimum Touch Target: 48x48dp

**MANDATORY for all tappable elements:**

```dart
// IconButton with proper constraints
IconButton(
  onPressed: onTap,
  icon: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
  padding: const EdgeInsets.all(12),
  constraints: const BoxConstraints(
    minWidth: 48,
    minHeight: 48,
  ),
)
```

### 6.2 Button Specifications

| Type | Min Height | Width | Border Radius |
|------|------------|-------|---------------|
| Primary Action | 72-80px | Full width | 16px |
| Secondary Button | 48px | Fit content | 12px |
| Icon Button | 48x48px | 48px | Circle |
| Chip/Badge | 28px | Fit content | 12px |

### 6.3 Primary Button Template

```dart
Container(
  width: double.infinity,
  constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
  child: Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF666666),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
)
```

---

## 7. Shadows & Elevation

### 7.1 Shadow Presets

```dart
class TajiriShadows {
  // Cards, buttons (elevation: 2)
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  // Info cards, modals (elevation: 4)
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Bottom sheets, dialogs (elevation: 8)
  static List<BoxShadow> modal = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
```

### 7.2 Material Elevation Mapping

| Component | Elevation | Shadow |
|-----------|-----------|--------|
| Action Cards | 2 | `card` |
| Info Cards | 0 (border only) | `elevated` |
| Floating Buttons | 4 | `elevated` |
| Bottom Sheets | 8 | `modal` |
| Dialogs | 8 | `modal` |

---

## 8. Icon System

### 8.1 Icon Sizes

| Context | Size |
|---------|------|
| In 48x48 container | 24px |
| Inline with text | 16px |
| Small badges | 14px |
| List trailing | 20px |
| AppBar actions | 20px |

### 8.2 Icon Container Styles

**Dark Circle (Primary actions):**
```dart
Container(
  width: 48,
  height: 48,
  decoration: const BoxDecoration(
    color: Color(0xFF1A1A1A),
    shape: BoxShape.circle,
  ),
  child: Icon(icon, size: 24, color: Colors.white),
)
```

**Dark Rounded Square (Section headers):**
```dart
Container(
  width: 48,
  height: 48,
  decoration: const BoxDecoration(
    color: Color(0xFF1A1A1A),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  child: Icon(icon, size: 24, color: Colors.white),
)
```

**Light Rounded Square (List items, navigation):**
```dart
Container(
  width: 48,
  height: 48,
  decoration: BoxDecoration(
    color: const Color(0xFF1A1A1A).withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Icon(icon, size: 24, color: const Color(0xFF1A1A1A)),
)
```

### 8.3 Preferred Icon Variants

Always use `_rounded` icon variants for modern appearance:
- `Icons.videocam_rounded` (not `Icons.videocam`)
- `Icons.photo_library_rounded`
- `Icons.edit_note_rounded`
- `Icons.mic_rounded`
- `Icons.poll_rounded`

---

## 9. Dialogs & Sheets

### 9.1 Alert Dialog

```dart
AlertDialog(
  title: const Text('Title'),
  content: const Text('Description text'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: const Text('Cancel'),
    ),
    TextButton(
      onPressed: () => Navigator.pop(context, true),
      style: TextButton.styleFrom(foregroundColor: Colors.red), // for destructive
      child: const Text('Confirm'),
    ),
  ],
)
```

### 9.2 Popup Menu

```dart
PopupMenuButton<String?>(
  onSelected: onSelected,
  itemBuilder: (context) => [
    const PopupMenuItem(value: null, child: Text('All Types')),
    const PopupMenuItem(value: 'text', child: Text('Text')),
    // ...
  ],
  icon: const Icon(Icons.filter_list),
)
```

---

## 10. Empty States

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.drafts_outlined,
        size: 64,
        color: Colors.grey.shade400,
      ),
      const SizedBox(height: 16),
      Text(
        'No items yet',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Helpful description here',
        style: TextStyle(
          color: Colors.grey.shade500,
        ),
      ),
    ],
  ),
)
```

---

## 11. Performance & Accessibility

### 11.1 Performance Rules

- **Animations**: See §12 Animations & Motion; prefer 200–400 ms for UI feedback, use curves (e.g. `CurvedAnimation`); dispose controllers
- **Memory**: Dispose controllers, use `const` constructors
- **Rebuilds**: Minimize with `const` and proper state management
- **Images**: Always use `CachedNetworkImage`

### 11.2 Accessibility Checklist

- [ ] Minimum 48x48dp touch targets
- [ ] Contrast ratio 4.5:1 minimum
- [ ] `maxLines` + `TextOverflow.ellipsis` on all dynamic text
- [ ] Meaningful semantic labels
- [ ] Large, readable text (11px minimum)

---

## 12. Animations & Motion

Use smooth bounces, curves, and transitions for a modern, polished feel. All motion MUST stay within the performance and duration guidelines in §11.1.

### 12.1 Built-in Curves (bounces & smooth motion)

Use with `CurvedAnimation`, `AnimatedContainer.curve`, or `curve:` on implicit animations.

| Curve | Use case |
|-------|----------|
| **`Curves.bounceIn`** | Element appears with a bounce |
| **`Curves.bounceOut`** | Element settles with a bounce |
| **`Curves.bounceInOut`** | Bounce at start and end |
| **`Curves.elasticIn`** | Strong overshoot when entering |
| **`Curves.elasticOut`** | Spring-like overshoot when leaving |
| **`Curves.elasticInOut`** | Elastic both ways |
| **`Curves.easeOutBack`** | Slight overshoot, then settle (common for “pop”) |
| **`Curves.easeInOutBack`** | Overshoot in and out |
| **`Curves.easeInOutCubic`** | Smooth, no overshoot |
| **`Curves.easeInOutCubicEmphasized`** | Material 3–style emphasized motion |
| **`Curves.fastOutSlowIn`** | Quick start, slow end (Material default) |

**Example — bouncy container (e.g. selected card):**
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeOutBack,  // or Curves.bounceOut
  transform: Matrix4.identity()..scale(selected ? 1.05 : 1.0),
  child: child,
)
```

### 12.2 Implicit Animations (no controller)

Change a value → widget animates. Prefer these for simple UI feedback.

| Widget | What it animates |
|--------|-------------------|
| **`AnimatedContainer`** | size, padding, decoration, color, alignment, transform |
| **`AnimatedOpacity`** | opacity |
| **`AnimatedPositioned`** | position inside Stack |
| **`AnimatedPadding`** | padding |
| **`AnimatedAlign`** | alignment |
| **`AnimatedDefaultTextStyle`** | text style |
| **`AnimatedSwitcher`** | swap child with fade/size transition |
| **`AnimatedCrossFade`** | cross-fade between two children |

**Example — smooth list item tap:**
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeOut,
  padding: EdgeInsets.all(isPressed ? 12 : 8),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [...],
  ),
  child: content,
)
```

### 12.3 Page / Route Transitions

Use the official **`animations`** package for Material motion:

```yaml
# pubspec.yaml
dependencies:
  animations: ^2.1.1
```

- **Shared axis** — slide on x/y/z (e.g. list → detail on x).
- **Fade through** — fade out then fade in (e.g. bottom nav switch).
- **Fade** — simple fade (dialogs, menus).
- **Container transform** — card/FAB morphs into full screen.

**Example — shared axis (horizontal):**
```dart
import 'package:animations/animations.dart';

Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      );
    },
  ),
);
```

**Fade through (e.g. tab / nav bar):**
```dart
FadeThroughTransition(
  animation: animation,
  secondaryAnimation: secondaryAnimation,
  child: child,
)
```

### 12.4 Physics-based (springs, real bounces)

For drag-to-release or “throw” then snap back, use **`SpringSimulation`** and **`AnimationController.animateWith()`**.

```dart
import 'package:flutter/physics.dart';

const spring = SpringDescription(
  mass: 1,
  stiffness: 100,
  damping: 0.8,
);
final simulation = SpringSimulation(spring, start, end, velocity);
controller.animateWith(simulation);
```

- **Softer bounce:** lower `stiffness`, lower `damping` (e.g. `0.5`).
- **Snappier, less bounce:** higher `stiffness`, higher `damping` (e.g. `1.2`).

### 12.5 Staggered Animations (list / grid)

Animate list/grid items with a delay per index for a wave effect.

**Option A — `flutter_staggered_animations` package:**
```dart
AnimationConfiguration.staggeredList(
  position: index,
  duration: const Duration(milliseconds: 375),
  child: SlideAnimation(
    verticalOffset: 50,
    child: FadeInAnimation(child: YourListItem()),
  ),
)
```

**Option B — manual with `Interval`:**
```dart
Tween(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: controller,
    curve: Interval(
      (index * 0.05).clamp(0.0, 0.9),
      ((index + 1) * 0.05).clamp(0.0, 1.0),
      curve: Curves.easeOut,
    ),
  ),
)
```

### 12.6 Hero (shared element) Transitions

Smooth “fly” of an image/card from list to detail. Use the same `tag` on both screens.

**List screen:** `Hero(tag: 'post-${post.id}', child: Image.network(post.imageUrl))`  
**Detail screen:** `Hero(tag: 'post-${post.id}', child: Image.network(post.imageUrl))`

### 12.7 TweenAnimationBuilder (custom implicit)

One-off custom interpolation without a full `AnimationController`:

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: 1),
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeOutBack,
  builder: (context, value, child) {
    return Transform.scale(scale: value, child: child);
  },
  child: YourWidget(),
)
```

### 12.8 Recommended Animation Packages

| Package | Purpose |
|---------|---------|
| **animations** | Material motion: SharedAxis, FadeThrough, ContainerTransform, Fade |
| **flutter_staggered_animations** | Staggered list/grid with slide, fade, scale |
| **simple_animations** | Declarative custom animations and timelines |
| **shimmer_animation** | Skeleton / shimmer loading |
| **auto_animated** | Animate list items when they enter viewport |

### 12.9 Animation Checklist (modern feel)

- **Curves:** Use `easeOutBack` / `bounceOut` / `elasticOut` for playful bounces; `easeInOutCubic` or `fastOutSlowIn` for calm transitions.
- **Duration:** 200–400 ms for UI feedback; 300–500 ms for page transitions.
- **Lists:** Stagger entry (e.g. 30–50 ms delay per item) with fade + slight slide or scale.
- **Navigation:** Prefer Shared axis or Fade through from `animations` over default platform slide.
- **Tap feedback:** Slight scale (e.g. 0.97) + `easeOut` for 100–150 ms.
- **Hero:** Use for one main image/card from list to detail.

### 12.10 References

- [Flutter animations overview](https://docs.flutter.dev/ui/animations)
- [Curves (API)](https://api.flutter.dev/flutter/animation/Curves-class.html)
- [Physics simulation (spring) cookbook](https://docs.flutter.dev/cookbook/animation/physics-simulation)
- [Staggered animations](https://docs.flutter.dev/ui/animations/staggered-animations)
- [animations package](https://pub.dev/packages/animations)
- [Implicit animations (Flutter blog)](https://blog.flutter.dev/flutter-animation-basics-with-implicit-animations-95db481c5916)

---

## 13. Page Templates

### 13.1 Standard Page Structure

**MANDATORY: All pages MUST use SafeArea**

```dart
Scaffold(
  backgroundColor: const Color(0xFFFAFAFA),
  appBar: AppBar(
    title: const Text('Page Title'),
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
  ),
  body: SafeArea(
    child: RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1
            _buildSection1(),
            // Section 2
            _buildSection2(),
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    ),
  ),
)
```

### 13.2 Section Header

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
  child: Text(
    'Section Title',
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

### 13.3 Section with Header Row (Title + Action)

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
  child: Row(
    children: [
      const Icon(Icons.history, size: 20, color: Colors.grey),
      const SizedBox(width: 8),
      Text(
        'Section Title',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const Spacer(),
      TextButton(
        onPressed: onSeeAll,
        child: const Text('See All'),
      ),
    ],
  ),
)
```

### 13.4 Profile Page UI Tactics (apply everywhere)

The Profile screen establishes patterns that **SHOULD be reused** on other screens for consistency.

#### 13.4.1 Hero / Cover Screen Structure (NestedScrollView)

Use `NestedScrollView` when the screen has a large header (cover + avatar) that collapses on scroll, followed by a sticky tab bar and tab content.

```dart
Scaffold(
  backgroundColor: Color(0xFFFAFAFA),
  body: SafeArea(
    child: NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _buildSliverAppBar(),                    // Cover + avatar + title
        SliverToBoxAdapter(child: _buildInfoCard()),  // White card below
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            child: _buildCustomTabBar(context),
            height: kTabBarHeight,
            selectedIndex: _tabController?.index ?? 0,  // Required for shouldRebuild
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [...],
      ),
    ),
  ),
)
```

- **SliverAppBar:** `expandedHeight: 280`, `pinned: true`, `elevation: 0`, `surfaceTintColor: Colors.transparent`. Use `flexibleSpace` for cover + overlay + avatar row.
- **Title:** Context-aware: e.g. own profile = "Me" / "Mimi", other = user's full name. White text when over cover (`fontWeight: w600`, `color: Colors.white`).
- **Cover fallback:** Gradient using `Theme.of(context).colorScheme.primary` and `secondary` when no image.
- **Gradient overlay:** `LinearGradient` top→bottom, `Colors.transparent` → `Colors.black.withOpacity(0.7)` so text stays readable.

#### 13.4.2 Profile / Info Card (white card below header)

Single white card that sits under the hero; use on any “profile-like” or detail header.

- **Decoration:** `color: Colors.white`, `borderRadius.only(topLeft, topRight: 24)`, shadow: `black 0.06`, blur 12, offset `(0, -4)`.
- **Padding:** `fromLTRB(20, 24, 20, 24)`.
- **Content order:** Stats row → action buttons → bio → interests (pills) → info rows (icon + text) → chips (e.g. mutual friends).

#### 13.4.3 Stats Row (counts with dividers)

Use for Followers | Following | Subscribers | Friends (or similar metrics).

- **Layout:** `Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly)` with stat | divider | stat | divider | …
- **Stat item:** `InkWell` (≥48dp tap target), padding `symmetric(horizontal: 12, vertical: 8)`, `Column`: count (20px, w700, letterSpacing -0.3), gap 2, label (13px, grey.shade600, w500).
- **Divider:** `Container(width: 1, height: 32, color: Colors.grey.shade300)`.
- **Count formatting:** 1.2K, 1.5M; no decimal when `.0` (e.g. `1K` not `1.0K`). Use a shared formatter (e.g. `_formatStatCount`) everywhere.

#### 13.4.4 Pill Action Buttons

Use for primary + secondary actions (Follow, Subscribe, Message, etc.).

- **Row:** `Expanded` children, gap `SizedBox(width: 10)`.
- **Primary:** `ElevatedButton.icon`, `minHeight: 48`, `shape: RoundedRectangleBorder(borderRadius: 24)`, `padding: symmetric(vertical: 12)`.
- **Secondary:** `OutlinedButton.icon`, same minHeight and pill shape.
- **Loading:** Replace icon with `SizedBox(24, 24)` containing `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)`.

#### 13.4.5 Bio and Interests

- **Bio:** `fontSize: 15`, `height: 1.4`, `color: Colors.grey.shade700`; optional `maxLines` + `overflow: ellipsis` for long text.
- **Interests:** `Wrap(spacing: 8, runSpacing: 8)`. Each pill: `padding: symmetric(horizontal: 14, vertical: 8)`, `borderRadius: 20`, `color: primary.withOpacity(0.08)`, `border: primary.withOpacity(0.2)`, text 13px w500 primary.

#### 13.4.6 Info Item Row (icon + text)

Reuse for location, work, education, “Joined” date, etc.

- **Row:** `Icon(icon, size: 18, color: Colors.grey.shade600)` → `SizedBox(8)` → `Expanded(Text(..., fontSize: 14, color: grey.shade700))`.
- **Spacing:** `padding: only(bottom: 8)` per row.

#### 13.4.7 Chip (e.g. mutual friends)

- **Container:** `Material(color: Colors.grey.shade100, borderRadius: 20)`, padding `symmetric(horizontal: 14, vertical: 10)`.
- **Content:** `Row(mainAxisSize: min)`: icon 18, gap 8, text 13 w500 grey.shade700.

#### 13.4.8 Custom Tab Bar (no Material TabBar)

Avoid Material `TabBar` when you want icon + label per tab and no splash overlay. Use a custom row inside `SliverPersistentHeader`.

- **Constants:** Tab bar height (e.g. 112), tab item width (e.g. 80).
- **Container:** `height: kTabBarHeight`, `padding: EdgeInsets.zero`. Child: `ListView.separated( scrollDirection: Axis.horizontal, padding: symmetric(horizontal: 16), separatorBuilder: SizedBox(width: 12) )`.
- **Per tab:** `SizedBox(width: kTabItemWidth)`. Selected indicator: `BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 2)))`.
- **Tab item widget:** Column: (1) Icon in circle (padding 14, circle bg: selected = primary, unselected = grey.shade200; icon 26, color white/grey), (2) gap 8, (3) label 13px (selected w600 primary, unselected w500 grey). Use `GestureDetector(behavior: HitTestBehavior.opaque)` for tap; call `TabController.animateTo(index)`.
- **Delegate:** `SliverPersistentHeaderDelegate` must include `selectedIndex` (and height) in `shouldRebuild` so the tab bar rebuilds when selection changes (e.g. after swipe). Child wrapped in `Material(color: Colors.white)` with bottom border `grey.shade300` 1px and subtle shadow.

#### 13.4.9 Avatar in Header

- **Size:** 100×100; `BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4))`, shadow `black 0.2`, blur 12, offset (0, 4).
- **Tap:** Whole avatar tappable (≥48dp); for “edit photo”, add `Semantics(button: true, label: 'Change profile photo')`.
- **Edit badge:** If editable, overlay a 48×48 circle (primary color, white icon) at bottom-right of avatar.
- **Loading:** Positioned.fill overlay with `black54` and centered `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)`.

#### 13.4.10 Loading and Error States (profile-style)

- **Loading:** `Scaffold(backgroundColor: #FAFAFA)` → `SafeArea` → `Center(child: CircularProgressIndicator())`.
- **Error:** `Scaffold` + `AppBar(backgroundColor: Colors.white)`; body `Center` → `Padding(24)` → Column: icon 64 grey.shade400, gap 16, error text (14px, secondary color, maxLines 3, ellipsis), gap 24, `SizedBox(height: 48)` `ElevatedButton` “Retry”.

#### 13.4.11 Dialogs

- **Shape:** `AlertDialog(shape: RoundedRectangleBorder(borderRadius: 16))`.
- **Destructive:** Red `TextButton` for “Yes” / “Remove”; `FilledButton.styleFrom(backgroundColor: Colors.red.shade400)` for “Yes, log out”.

#### 13.4.12 FAB (contextual)

- Show only when relevant (e.g. own profile). Use unique `heroTag` (e.g. `'profile_create_post_fab'`) to avoid conflicts. Standard: `Icon(Icons.add)`.

Apply these tactics on other “hero” or profile-like screens (e.g. creator profile, channel, event) for consistent layout, typography, touch targets, and tab behavior.

### 13.5 Full Screen with Tabs

```dart
Scaffold(
  body: IndexedStack(
    index: _currentIndex,
    children: [
      FeedScreen(...),
      FriendsScreen(...),
      MessagesScreen(...),
      PhotosScreen(...),
      ProfileScreen(...),
    ],
  ),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (index) => setState(() => _currentIndex = index),
    type: BottomNavigationBarType.fixed,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Nyumbani'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Marafiki'),
      BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Ujumbe'),
      BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Picha'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mimi'),
    ],
  ),
)
```

---

## 14. Widget Best Practices

### 14.1 Zero Overflow Tolerance

- Test on smallest supported devices
- Use `SingleChildScrollView` for scrollable content
- Always set `maxLines` + `overflow` on Text widgets
- Use `Flexible` instead of `Expanded` when needed

### 14.2 Optimized Widget Tree

- Minimize nesting depth
- Use `const` constructors everywhere possible
- Extract reusable widgets into separate classes
- Use `RepaintBoundary` for heavy widgets (videos, animations)

### 14.3 State Management

```dart
// Always check mounted before setState
if (mounted) {
  setState(() {
    _isLoading = false;
    _data = result;
  });
}
```

### 14.4 Resource Disposal

```dart
@override
void dispose() {
  _animationController.dispose();
  _textController.dispose();
  _service.dispose();
  super.dispose();
}
```

---

## 15. Loading States

### 15.1 Loading Indicator

```dart
// Centered loading
const Center(child: CircularProgressIndicator())

// Section loading
const Padding(
  padding: EdgeInsets.all(20),
  child: Center(child: CircularProgressIndicator()),
)
```

### 15.2 Loading Flag Pattern

```dart
bool _isLoading = true;

Future<void> _loadData() async {
  setState(() => _isLoading = true);

  final result = await service.getData();

  if (mounted) {
    setState(() {
      _isLoading = false;
      _data = result;
    });
  }
}
```

---

## 16. Snackbars & Feedback

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Action completed')),
);
```

---

## 17. Design Checklist

Before submitting any new screen or component, verify:

### Colors
- [ ] Background is `#FAFAFA`
- [ ] Cards/surfaces are `#FFFFFF`
- [ ] Primary text is `#1A1A1A`
- [ ] Secondary text is `#666666`
- [ ] No colorful buttons (orange, green, blue)

### Typography
- [ ] Title: 15-16px, weight 600
- [ ] Subtitle: 11-12px, weight 400
- [ ] All dynamic text has `maxLines` + `overflow: ellipsis`

### Spacing
- [ ] Container padding: 16px
- [ ] Section margins: 24px
- [ ] Card gaps: 12px
- [ ] Border radius: 16px (cards), 12px (buttons)

### Touch Targets
- [ ] All tappable elements: minimum 48x48dp
- [ ] Primary buttons: 72-80px height
- [ ] IconButtons have proper constraints

### Animations & Motion
- [ ] UI feedback: 200–400 ms, curve (e.g. `easeOutBack`, `easeOut`)
- [ ] Page transitions: Shared axis or Fade through when using `animations` package
- [ ] Tap feedback: slight scale (e.g. 0.97) + short duration
- [ ] Dispose animation controllers in `dispose()`

### Structure
- [ ] Wrapped in `SafeArea`
- [ ] Uses `SingleChildScrollView` for scrollable content
- [ ] `RefreshIndicator` for pull-to-refresh
- [ ] Proper disposal of controllers/services

### Icons
- [ ] Using `_rounded` variants
- [ ] 24px in containers, 16px inline
- [ ] Dark containers (`#1A1A1A`) with white icons

---

## 18. Version History

| Version | Date | Changes |
|---------|------|---------|
| v2.2.0 | 2025-02-16 | Added §13.4 Profile Page UI Tactics: NestedScrollView hero, info card, stats row, pill buttons, bio/interests, info rows, chips, custom tab bar + delegate, avatar, loading/error, dialogs, FAB; apply everywhere on profile-like screens. |
| v2.1.0 | 2025-02-14 | Added §12 Animations & Motion: curves, implicit animations, page transitions, physics/springs, staggered lists, Hero, TweenAnimationBuilder, packages, checklist; renumbered sections 12–18 to 13–19; updated §11.1 and §17 checklist. |
| v2.0.0 | 2024-02-13 | Major update: Component patterns, icon system, touch targets, page templates extracted from CreatePostScreen |
| v1.0.0 | 2024-12-11 | Initial design guidelines |

---

## 19. Developer Notes

1. **SafeArea is MANDATORY** for all pages/screens
2. **Test on multiple devices** before deployment
3. **Follow monochrome palette** - no colorful elements
4. **48dp minimum touch targets** - no exceptions
5. **Always use `maxLines` + `ellipsis`** on dynamic text
6. **Dispose resources** in `dispose()` method
7. **Check `mounted`** before `setState` in async callbacks
8. **Use `const` constructors** wherever possible

---

*This is the single source of truth for TAJIRI design. All screens and components MUST follow these guidelines.*