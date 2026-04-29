import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

/// Spec line 837 — Job Success Score badge. Color tier:
/// 90+ green   "Very high"
/// 75-89 lime  "High"
/// 50-74 amber "Medium"
/// 0-49  red   "Low"
class JssBadge extends StatelessWidget {
  final int? score;
  final bool compact;
  const JssBadge({super.key, required this.score, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final s = score;
    if (s == null) return const SizedBox.shrink();
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final (bg, fg, label) = _classify(s, isSw);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: compact ? 11 : 13, color: fg),
          const SizedBox(width: 3),
          Text(
            'JSS $s',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fg.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color, String) _classify(int s, bool isSw) {
    if (s >= 90) {
      return (
        const Color(0xFFE8F5E9),
        const Color(0xFF1B5E20),
        isSw ? 'Bora sana' : 'Very high',
      );
    }
    if (s >= 75) {
      return (
        const Color(0xFFF1F8E9),
        const Color(0xFF558B2F),
        isSw ? 'Juu' : 'High',
      );
    }
    if (s >= 50) {
      return (
        const Color(0xFFFFF8E1),
        const Color(0xFFE65100),
        isSw ? 'Wastani' : 'Medium',
      );
    }
    return (
      const Color(0xFFFFEBEE),
      const Color(0xFFB71C1C),
      isSw ? 'Chini' : 'Low',
    );
  }

  static Color get fallbackPrimary => _kPrimary;
}
