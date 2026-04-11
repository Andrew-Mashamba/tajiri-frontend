// lib/wakati_wa_sala/pages/prayer_stats_page.dart
import 'package:flutter/material.dart';
import '../models/wakati_wa_sala_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PrayerStatsPage extends StatelessWidget {
  final int userId;
  final PrayerStats? stats;

  const PrayerStatsPage({
    super.key,
    required this.userId,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final s = stats ??
        PrayerStats(
          totalPrayers: 0,
          onTimeCount: 0,
          lateCount: 0,
          missedCount: 0,
          currentStreak: 0,
          longestStreak: 0,
          completionRate: 0,
        );

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Prayer Stats / Takwimu za Sala',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Streak Card ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Color(0xFFFF9800), size: 48),
                  const SizedBox(height: 8),
                  Text(
                    '${s.currentStreak}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Consecutive Days / Siku Mfululizo',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rekodi bora: ${s.longestStreak} siku',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Completion Rate ──────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kiwango cha Kukamilisha',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: s.completionRate,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_kPrimary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(s.completionRate * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: _kPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Breakdown ────────────────────────────────
            const Text(
              'Muhtasari',
              style: TextStyle(
                color: _kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _statRow('Jumla ya Sala', '${s.totalPrayers}',
                Icons.mosque_rounded),
            _statRow('Kwa Wakati', '${s.onTimeCount}',
                Icons.check_circle_rounded),
            _statRow('Zilizochelewa', '${s.lateCount}',
                Icons.schedule_rounded),
            _statRow('Zilizokosekana', '${s.missedCount}',
                Icons.cancel_rounded),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _kPrimary, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
