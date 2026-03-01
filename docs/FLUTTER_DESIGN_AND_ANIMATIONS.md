# Modern Flutter Design & Animations — Research Summary

Quick reference for **smooth bounces, transitions, and modern UI** in Flutter.

---

## 1. Built-in curves (bounces & smooth motion)

Use these with `CurvedAnimation`, `AnimatedContainer.curve`, or `curve:` on implicit animations.

| Curve | Use case |
|-------|----------|
| **`Curves.bounceIn`** | Element appears with a bounce |
| **`Curves.bounceOut`** | Element settles with a bounce |
| **`Curves.bounceInOut`** | Bounce at start and end |
| **`Curves.elasticIn`** | Strong overshoot when entering |
| **`Curves.elasticOut`** | Spring-like overshoot when leaving |
| **`Curves.elasticInOut`** | Elastic both ways |
| **`Curves.easeOutBack`** | Slight overshoot, then settle (very common for “pop”) |
| **`Curves.easeInOutBack`** | Overshoot in and out |
| **`Curves.easeInOutCubic`** | Smooth, no overshoot |
| **`Curves.easeInOutCubicEmphasized`** | Material 3–style emphasized motion |
| **`Curves.fastOutSlowIn`** | Quick start, slow end (Material default feel) |

**Example — bouncy container:**
```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeOutBack,  // or Curves.bounceOut
  transform: Matrix4.identity()..scale(selected ? 1.05 : 1.0),
  child: child,
)
```

---

## 2. Implicit animations (easiest)

Change a value → widget animates to it. No `AnimationController` needed.

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

---

## 3. Page / route transitions

Use the official **`animations`** package (Material motion):

```yaml
# pubspec.yaml
dependencies:
  animations: ^2.1.1
```

**Patterns:**

- **Shared axis** — slide on x/y/z (e.g. list → detail on x).
- **Fade through** — fade out then fade in (e.g. bottom nav switch).
- **Fade** — simple fade (dialogs, menus).
- **Container transform** — card/FAB morphs into full screen.

**Example — shared axis (horizontal):**
```dart
import 'package:animations/animations.dart';

// Navigator with shared axis
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

---

## 4. Physics-based (springs, real bounces)

For drag-to-release or “throw” then snap back, use **`SpringSimulation`** and **`AnimationController.animateWith()`**.

```dart
import 'package:flutter/physics.dart';

// Tune for more/less bounce:
// - stiffness: higher = snappier
// - damping: lower = more bounce/overshoot
const spring = SpringDescription(
  mass: 1,
  stiffness: 100,
  damping: 0.8,
);

final simulation = SpringSimulation(spring, start, end, velocity);
controller.animateWith(simulation);
```

**Softer bounce:** lower `stiffness`, lower `damping` (e.g. `0.5`).  
**Snappier, less bounce:** higher `stiffness`, higher `damping` (e.g. `1.2`).

---

## 5. Staggered animations (list / grid)

Animate list/grid items with a **delay per index** for a wave effect.

**Option A — `flutter_staggered_animations`:**

```yaml
dependencies:
  flutter_staggered_animations: ^1.1.1
```

```dart
AnimationConfiguration.staggeredList(
  position: index,
  duration: const Duration(milliseconds: 375),
  child: SlideAnimation(
    verticalOffset: 50,
    child: FadeInAnimation(
      child: YourListItem(),
    ),
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

---

## 6. Hero (shared element) transitions

Smooth “fly” of an image/card from list to detail.

**List screen:**
```dart
Hero(
  tag: 'post-${post.id}',
  child: Image.network(post.imageUrl),
)
```

**Detail screen (same tag):**
```dart
Hero(
  tag: 'post-${post.id}',
  child: Image.network(post.imageUrl),
)
```

Customize with `HeroControllerScope` or a custom `FlightShuttleBuilder` if needed.

---

## 7. TweenAnimationBuilder (custom implicit)

When you need one-off custom interpolation without a full `AnimationController`:

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

---

## 8. Recommended packages (from research)

| Package | Purpose |
|---------|---------|
| **animations** | Material motion: SharedAxis, FadeThrough, ContainerTransform, Fade |
| **flutter_staggered_animations** | Staggered list/grid with slide, fade, scale |
| **simple_animations** | Declarative custom animations and timelines |
| **shimmer_animation** | Skeleton / shimmer loading |
| **auto_animated** | Animate list items when they enter viewport |

---

## 9. Quick “modern” checklist

- **Curves:** Prefer `easeOutBack` / `bounceOut` / `elasticOut` for playful bounces; `easeInOutCubic` or `fastOutSlowIn` for calm, smooth transitions.
- **Duration:** 200–400 ms for UI feedback; 300–500 ms for page transitions.
- **Lists:** Stagger entry (e.g. 30–50 ms delay per item) with fade + slight slide or scale.
- **Navigation:** Use Shared axis or Fade through from `animations` instead of default platform slide.
- **Tap feedback:** Slight scale (e.g. 0.97) + `easeOut` for 100–150 ms.
- **Hero:** Use for one main image/card from list to detail.

---

## 10. Links

- [Flutter animations overview](https://docs.flutter.dev/ui/animations)
- [Curves (API)](https://api.flutter.dev/flutter/animation/Curves-class.html)
- [Physics simulation (spring) cookbook](https://docs.flutter.dev/cookbook/animation/physics-simulation)
- [Staggered animations](https://docs.flutter.dev/ui/animations/staggered-animations)
- [animations package (Material motion)](https://pub.dev/packages/animations)
- [Implicit animations (Flutter blog)](https://blog.flutter.dev/flutter-animation-basics-with-implicit-animations-95db481c5916)
