// lib/my_pregnancy/widgets/week_progress_card.dart
import 'package:flutter/material.dart';
import '../models/my_pregnancy_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class WeekProgressCard extends StatelessWidget {
  final Pregnancy pregnancy;
  final VoidCallback? onTap;
  final bool isSwahili;

  const WeekProgressCard({
    super.key,
    required this.pregnancy,
    this.onTap,
    this.isSwahili = true,
  });

  @override
  Widget build(BuildContext context) {
    final week = pregnancy.currentWeek.clamp(1, 42);
    final progress = week / 42.0;
    final daysLeft = pregnancy.daysRemaining;
    final sizeComparison = isSwahili
        ? _weekToFruitSwahili(week)
        : _weekToFruitEnglish(week);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Wiki $week' : 'Week $week',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pregnancy.trimesterLabel(isSwahili: isSwahili),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isSwahili
                        ? 'Siku $daysLeft zilizobaki'
                        : '$daysLeft days left',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSwahili ? 'Wiki 1' : 'Week 1',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  isSwahili ? 'Wiki 42' : 'Week 42',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    _weekToFruitEmoji(week),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSwahili ? 'Ukubwa wa Mtoto' : 'Baby Size',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          isSwahili
                              ? 'Kama $sizeComparison'
                              : 'Like a $sizeComparison',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (pregnancy.babyName != null &&
                      pregnancy.babyName!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pregnancy.babyName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekToFruitSwahili(int week) {
    if (week <= 4) return 'Mbegu ya Poppyseed';
    if (week <= 5) return 'Mbegu ya Ufuta';
    if (week <= 6) return 'Dengu';
    if (week <= 7) return 'Bluberi';
    if (week <= 8) return 'Haragwe';
    if (week <= 9) return 'Zabibu';
    if (week <= 10) return 'Tende';
    if (week <= 11) return 'Limau ndogo';
    if (week <= 12) return 'Limau';
    if (week <= 13) return 'Pilipili Hoho';
    if (week <= 14) return 'Ndimu';
    if (week <= 15) return 'Tufaha';
    if (week <= 16) return 'Avokado';
    if (week <= 17) return 'Turnip';
    if (week <= 18) return 'Pilipili Manga';
    if (week <= 19) return 'Embe dogo';
    if (week <= 20) return 'Ndizi';
    if (week <= 21) return 'Karoti';
    if (week <= 22) return 'Papai dogo';
    if (week <= 23) return 'Embe';
    if (week <= 24) return 'Mahindi';
    if (week <= 25) return 'Kaulifulawa';
    if (week <= 26) return 'Lettusi';
    if (week <= 27) return 'Kabichi';
    if (week <= 28) return 'Biringanya';
    if (week <= 29) return 'Boga';
    if (week <= 30) return 'Tikiti maji dogo';
    if (week <= 31) return 'Nazi';
    if (week <= 32) return 'Nanasi';
    if (week <= 33) return 'Nanasi kubwa';
    if (week <= 34) return 'Tikiti maji';
    if (week <= 35) return 'Tikiti maji kubwa';
    if (week <= 36) return 'Papai';
    if (week <= 37) return 'Papai kubwa';
    if (week <= 38) return 'Boga kubwa';
    if (week <= 39) return 'Tikiti maji kubwa';
    if (week <= 40) return 'Tikiti maji kubwa sana';
    return 'Tikiti maji kubwa sana';
  }

  static String _weekToFruitEnglish(int week) {
    if (week <= 4) return 'Poppy Seed';
    if (week <= 5) return 'Sesame Seed';
    if (week <= 6) return 'Lentil';
    if (week <= 7) return 'Blueberry';
    if (week <= 8) return 'Kidney Bean';
    if (week <= 9) return 'Grape';
    if (week <= 10) return 'Date';
    if (week <= 11) return 'Small Lime';
    if (week <= 12) return 'Lime';
    if (week <= 13) return 'Bell Pepper';
    if (week <= 14) return 'Lemon';
    if (week <= 15) return 'Apple';
    if (week <= 16) return 'Avocado';
    if (week <= 17) return 'Turnip';
    if (week <= 18) return 'Chili Pepper';
    if (week <= 19) return 'Small Mango';
    if (week <= 20) return 'Banana';
    if (week <= 21) return 'Carrot';
    if (week <= 22) return 'Small Papaya';
    if (week <= 23) return 'Mango';
    if (week <= 24) return 'Corn';
    if (week <= 25) return 'Cauliflower';
    if (week <= 26) return 'Lettuce';
    if (week <= 27) return 'Cabbage';
    if (week <= 28) return 'Eggplant';
    if (week <= 29) return 'Squash';
    if (week <= 30) return 'Small Watermelon';
    if (week <= 31) return 'Coconut';
    if (week <= 32) return 'Pineapple';
    if (week <= 33) return 'Large Pineapple';
    if (week <= 34) return 'Watermelon';
    if (week <= 35) return 'Large Watermelon';
    if (week <= 36) return 'Papaya';
    if (week <= 37) return 'Large Papaya';
    if (week <= 38) return 'Large Pumpkin';
    if (week <= 39) return 'Large Watermelon';
    if (week <= 40) return 'Very Large Watermelon';
    return 'Very Large Watermelon';
  }

  static String _weekToFruitEmoji(int week) {
    if (week <= 6) return '🫘';
    if (week <= 9) return '🫐';
    if (week <= 11) return '🍋';
    if (week <= 14) return '🍊';
    if (week <= 16) return '🥑';
    if (week <= 19) return '🌶️';
    if (week <= 21) return '🍌';
    if (week <= 24) return '🌽';
    if (week <= 27) return '🥬';
    if (week <= 30) return '🥥';
    if (week <= 33) return '🍍';
    if (week <= 36) return '🍈';
    return '🍉';
  }
}
