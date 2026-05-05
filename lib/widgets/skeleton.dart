// lib/widgets/skeleton.dart
//
// Lightweight shimmer skeleton primitives. Per playbook §2389, loads in
// the 1-10s window should show skeletons matching the final layout
// (not generic spinners). Compose [SkeletonBox] in the same shape as
// the loaded content.
//
// Usage:
//   SkeletonRow(),                      // single 16dp-tall line
//   SkeletonBox(height: 64, radius: 12), // a tile placeholder
//   SkeletonGrid(columns: 3, items: 9), // a 3-col grid of squares
//
// Reduce-motion: when MediaQuery.disableAnimations is true, the
// shimmer animation is suppressed (a static muted-grey block remains).

import 'package:flutter/material.dart';

import 'motion_tokens.dart';

const Color _kBase = Color(0xFFE5E5E5);
const Color _kHighlight = Color(0xFFF5F5F5);

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MotionTokens.reduced(context);
    if (reduce) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _kBase,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              stops: [(t - 0.3).clamp(0.0, 1.0), t, (t + 0.3).clamp(0.0, 1.0)],
              colors: const [_kBase, _kHighlight, _kBase],
            ),
          ),
        );
      },
    );
  }
}

/// Single skeleton line — drop-in replacement for a Text node while
/// loading. Defaults to 60% width to evoke a typical body line.
class SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;
  const SkeletonLine({super.key, this.widthFactor = 0.6, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: SkeletonBox(height: height, radius: 6),
    );
  }
}

/// Square cell for grid placeholders.
class SkeletonGrid extends StatelessWidget {
  final int columns;
  final int items;
  final double spacing;
  const SkeletonGrid({
    super.key,
    this.columns = 3,
    this.items = 9,
    this.spacing = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: items,
      itemBuilder: (_, _) =>
          const SkeletonBox(height: double.infinity, radius: 0),
    );
  }
}
