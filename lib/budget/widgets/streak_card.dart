// lib/budget/widgets/streak_card.dart
import 'package:flutter/material.dart';
import '../models/budget_models.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kStreakFire = Color(0xFFFF6D00);

/// Displays budget streak counter, longest streak, freeze status, and badges.
///
/// Features 78-80: Streak counter, monthly achievement badges, streak freeze.
class StreakCard extends StatelessWidget {
  final BudgetStreak streak;
  final bool isSwahili;

  const StreakCard({
    super.key,
    required this.streak,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasStreak = streak.currentStreak > 0;
    final fireColor = hasStreak ? _kStreakFire : _kTertiary;

    return Card(
      color: hasStreak
          ? _kStreakFire.withValues(alpha: 0.08)
          : _kPrimary.withValues(alpha: 0.03),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasStreak
              ? _kStreakFire.withValues(alpha: 0.25)
              : _kPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Streak counter row ──────────────────────────────────────
            Row(
              children: [
                // Fire icon
                Text(
                  hasStreak ? '\u{1F525}' : '\u{1F9CA}', // fire or ice
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                // Streak text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSwahili
                            ? 'Siku ${streak.currentStreak} ndani ya bajeti'
                            : '${streak.currentStreak} days within budget',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: hasStreak ? fireColor : _kSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSwahili
                            ? 'Rekodi: Siku ${streak.longestStreak}'
                            : 'Record: ${streak.longestStreak} days',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Freeze status icon
                _buildFreezeIcon(),
              ],
            ),

            // ── Badges row (if any) ─────────────────────────────────────
            if (streak.badges.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: streak.badges.map((b) => _buildBadgeChip(b)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Freeze status ────────────────────────────────────────────────────────

  Widget _buildFreezeIcon() {
    if (streak.freezeUsed) {
      // Freeze already used this month
      return Tooltip(
        message: isSwahili
            ? 'Siku ya kupumzika imetumika'
            : 'Off day used this month',
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kTertiary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 18,
            color: _kTertiary,
          ),
        ),
      );
    }

    // Freeze available
    return Tooltip(
      message: isSwahili
          ? 'Siku 1 ya kupumzika inapatikana'
          : '1 off day available',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.shield_rounded,
          size: 18,
          color: Color(0xFF2196F3),
        ),
      ),
    );
  }

  // ── Badge chips ──────────────────────────────────────────────────────────

  Widget _buildBadgeChip(String badgeId) {
    final badge = _badgeInfo(badgeId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            isSwahili ? badge.nameSw : badge.nameEn,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badge.color,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeInfo _badgeInfo(String id) {
    switch (id) {
      case 'under_budget_master':
        return const _BadgeInfo(
          emoji: '\u{1F3C6}', // trophy
          nameEn: 'Under Budget Master',
          nameSw: 'Bajeti Bora',
          color: Color(0xFF4CAF50),
        );
      case 'savings_champion':
        return const _BadgeInfo(
          emoji: '\u{1F4B0}', // money bag
          nameEn: 'Savings Champion',
          nameSw: 'Bingwa wa Akiba',
          color: Color(0xFF2196F3),
        );
      case 'zero_unallocated':
        return const _BadgeInfo(
          emoji: '\u{2705}', // check mark
          nameEn: 'Zero Unallocated',
          nameSw: 'Sifuri Haijatengwa',
          color: Color(0xFF7C4DFF),
        );
      default:
        return const _BadgeInfo(
          emoji: '\u{2B50}', // star
          nameEn: 'Achievement',
          nameSw: 'Tuzo',
          color: Color(0xFFFF9800),
        );
    }
  }
}

/// Badge display info.
class _BadgeInfo {
  final String emoji;
  final String nameEn;
  final String nameSw;
  final Color color;

  const _BadgeInfo({
    required this.emoji,
    required this.nameEn,
    required this.nameSw,
    required this.color,
  });
}
