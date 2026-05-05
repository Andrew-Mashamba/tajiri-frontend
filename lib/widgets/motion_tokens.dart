// lib/widgets/motion_tokens.dart
//
// Canonical motion tokens per docs/ENGINEERING_PLAYBOOK.md → Part VI.
// Use these instead of inventing per-widget durations or curves.
//
// Selection rules:
//   • Default to MotionTokens.standard (~280ms).
//   • Don't go faster than 100ms (janky) or slower than ~500ms (laggy).
//   • Bounce/elastic is one-per-screen — usually a success ack.
//   • easeOut for incoming, easeIn for outgoing.
//   • Always respect MediaQuery.disableAnimations via [MotionTokens.duration].

import 'package:flutter/material.dart';

class MotionTokens {
  MotionTokens._();

  // ── Durations (pick by intent, not vibe) ─────────────────────────────

  /// 100ms — tiny acks: ripple, checkbox tick.
  static const Duration micro = Duration(milliseconds: 100);

  /// 180ms — hover, focus, swap a value.
  static const Duration short = Duration(milliseconds: 180);

  /// 280ms — default for sheets, chips, in-card transitions.
  static const Duration medium = Duration(milliseconds: 280);

  /// 420ms — route push, hero, card expand.
  static const Duration long = Duration(milliseconds: 420);

  /// 520ms — celebrations, splash. Use sparingly.
  static const Duration emph = Duration(milliseconds: 520);

  /// 320ms — standard page transition.
  static const Duration page = Duration(milliseconds: 320);

  // ── Curves (semantically named) ──────────────────────────────────────

  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeOutQuint;
  static const Curve smooth = Curves.fastOutSlowIn;
  static const Curve bounce = Curves.elasticOut;
  static const Curve overshoot = Curves.easeOutBack;
  static const Curve linear = Curves.linear;
  static const Curve decelerate = Curves.decelerate;
  static const Curve sharp = Cubic(0.4, 0.0, 0.6, 1.0);

  // ── Reduce-motion guard ──────────────────────────────────────────────

  /// Returns the requested [d] unless the OS is in reduce-motion mode,
  /// in which case returns Duration.zero so animations resolve instantly.
  /// Pass [context] from build() — never call from initState before
  /// dependencies are ready.
  static Duration duration(BuildContext context, Duration d) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return reduce ? Duration.zero : d;
  }

  /// Convenience: are animations suppressed by the OS?
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}
