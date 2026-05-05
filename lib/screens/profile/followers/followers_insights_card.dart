import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_strings_scope.dart';
import '../../../models/friend_models.dart';

enum FollowerFilter { total, newThisWeek, inactive, mutualGap }

/// Dark stat card with 4 tappable filter pills doubling as the data
/// story (counts) and the filter control. Tapping the active pill
/// resets to `total` (no filter).
class FollowersInsightsCard extends StatelessWidget {
  final FollowerInsights? insights;
  final FollowerFilter active;
  final ValueChanged<FollowerFilter> onTap;

  const FollowersInsightsCard({
    super.key,
    required this.insights,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final loading = insights == null;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _pill(
            FollowerFilter.total,
            value: loading ? '–' : '${insights!.total}',
            label: isSw ? 'Jumla' : 'Total',
            loading: loading,
          ),
          _pill(
            FollowerFilter.newThisWeek,
            value: loading ? '+–' : '+${insights!.newThisWeek}',
            label: isSw ? 'wiki hii' : 'this week',
            loading: loading,
          ),
          _pill(
            FollowerFilter.inactive,
            value: loading ? '–' : '${insights!.inactive60d}',
            label: isSw ? 'hawatumi' : 'inactive',
            loading: loading,
          ),
          _pill(
            FollowerFilter.mutualGap,
            value: loading ? '–' : '${insights!.mutualGap}',
            label: isSw ? 'hawajafuatwa' : 'not mutual',
            loading: loading,
          ),
        ],
      ),
    );
  }

  Widget _pill(
    FollowerFilter f, {
    required String value,
    required String label,
    required bool loading,
  }) {
    final isActive = active == f;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap(f);
              },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
