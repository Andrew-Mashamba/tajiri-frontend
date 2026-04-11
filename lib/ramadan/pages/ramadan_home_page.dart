// lib/ramadan/pages/ramadan_home_page.dart
import 'package:flutter/material.dart';
import '../models/ramadan_models.dart';
import 'fasting_calendar_page.dart';
import 'ramadan_goals_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class RamadanHomePage extends StatelessWidget {
  final int userId;
  final RamadanOverview? overview;

  const RamadanHomePage({
    super.key,
    required this.userId,
    this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final o = overview;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
            // ─── Day Counter ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Siku ya Ramadan',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${o?.currentDay ?? 0}',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'ya ${o?.totalDays ?? 30}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (o?.totalDays ?? 30) > 0
                        ? (o?.currentDay ?? 0) / (o?.totalDays ?? 30)
                        : 0,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Siku ${o?.daysRemaining ?? 0} zimebaki',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Suhoor / Iftar ──────────────────────────
            Row(
              children: [
                Expanded(child: _timeCard(
                  'Suhoor', o?.suhoorToday ?? '--:--',
                  Icons.dark_mode_rounded,
                )),
                const SizedBox(width: 12),
                Expanded(child: _timeCard(
                  'Iftar', o?.iftarToday ?? '--:--',
                  Icons.wb_sunny_rounded,
                )),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Quran Progress ──────────────────────────
            _buildQuranProgress(o?.quranProgress ?? 0),
            const SizedBox(height: 16),

            // ─── Daily Dua ────────────────────────────────
            if (o?.todayDuaSwahili != null || o?.todayDua != null)
              _buildDuaCard(o!),
            const SizedBox(height: 16),

            // ─── Actions ──────────────────────────────────
            Row(
              children: [
                Expanded(child: _actionButton(
                  'Kalenda ya Kufunga',
                  Icons.calendar_month_rounded,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FastingCalendarPage(userId: userId),
                  )),
                )),
                const SizedBox(width: 12),
                Expanded(child: _actionButton(
                  'Malengo',
                  Icons.flag_rounded,
                  () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RamadanGoalsPage(userId: userId),
                  )),
                )),
              ],
            ),
          ],
    );
  }

  Widget _timeCard(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: _kPrimary, size: 24),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: _kSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: _kPrimary, fontSize: 22, fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranProgress(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Khatm ya Quran',
              style: TextStyle(
                color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text(
            'Juz ${(progress * 30).toInt()} / 30',
            style: const TextStyle(color: _kSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDuaCard(RamadanOverview o) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dua ya Leo',
              style: TextStyle(
                color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          if (o.todayDua != null)
            Text(o.todayDua!,
                style: const TextStyle(
                  color: _kPrimary, fontSize: 18, height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                maxLines: 3, overflow: TextOverflow.ellipsis),
          if (o.todayDuaSwahili != null) ...[
            const SizedBox(height: 8),
            Text(o.todayDuaSwahili!,
                style: const TextStyle(
                  color: _kSecondary, fontSize: 14, height: 1.5,
                ),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                  color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
