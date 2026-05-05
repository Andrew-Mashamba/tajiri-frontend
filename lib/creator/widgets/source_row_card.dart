// Source row card — single row in the unified income sources list.
// Spec §3 (IA): one row per source, mixed active and locked, separated by
// state badges. Tappable opens IncomeSourceDetailScreen.

import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/income_source.dart';
import 'state_badge.dart';
import 'kpi_tile.dart';

class SourceRowCard extends StatelessWidget {
  final IncomeSource source;
  final VoidCallback? onTap;

  const SourceRowCard({super.key, required this.source, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLocked = source.state.isLocked;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Icon(icon: source.icon, dimmed: isLocked),
                const SizedBox(width: 12),
                Expanded(child: _Body(source: source)),
                const SizedBox(width: 8),
                _Trailing(source: source),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isLocked ? const Color(0xFF999999) : const Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  final String? icon;
  final bool dimmed;
  const _Icon({required this.icon, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          icon ?? '·',
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final IncomeSource source;
  const _Body({required this.source});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    final name = source.displayName.forContext(context);

    String stateLine;
    if (source.state.isLocked) {
      final rule = source.eligibility?.blockingRule;
      if (rule != null && rule.currentValue != null && rule.targetValue != null) {
        stateLine = '${rule.currentValue} / ${rule.targetValue} ${rule.label.forContext(context).toLowerCase()}';
      } else if (rule != null) {
        stateLine = rule.label.forContext(context);
      } else {
        stateLine = isSw ? 'Vigezo bado' : 'Eligibility pending';
      }
    } else if (source.currentPeriod != null) {
      final cp = source.currentPeriod!;
      final countLbl = cp.countLabel.forContext(context);
      stateLine = countLbl.isNotEmpty ? '${cp.count} $countLbl' : (isSw ? 'Hai' : 'Active');
    } else {
      stateLine = '';
    }

    final showProgress = source.state.isLocked &&
        source.eligibility != null &&
        source.eligibility!.completionPct > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (stateLine.isNotEmpty)
              Flexible(
                child: Text(
                  stateLine,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (stateLine.isNotEmpty) const SizedBox(width: 6),
            StateBadge(
              state: source.state,
              pulse: source.state == SourceState.live,
            ),
          ],
        ),
        if (showProgress) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: ProgressBar(pct: source.eligibility!.completionPct),
          ),
        ],
      ],
    );
  }
}

class _Trailing extends StatelessWidget {
  final IncomeSource source;
  const _Trailing({required this.source});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;

    if (source.state.isLocked) {
      final cta = source.primaryCta;
      final label = cta?.label.forContext(context) ??
          (source.state == SourceState.ready
              ? (isSw ? 'Anza →' : 'Start →')
              : (isSw ? 'Fungua →' : 'Unlock →'));
      return Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final cp = source.currentPeriod;
    if (cp == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatTzsMinorBare(cp.netMinor),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          isSw ? 'net' : 'net',
          style: const TextStyle(fontSize: 9, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}
