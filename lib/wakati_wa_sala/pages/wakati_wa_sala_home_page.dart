// lib/wakati_wa_sala/pages/wakati_wa_sala_home_page.dart
import 'package:flutter/material.dart';
import '../models/wakati_wa_sala_models.dart';
import '../services/wakati_wa_sala_service.dart';
import '../../services/local_storage_service.dart';
import '../widgets/prayer_time_tile.dart';
import 'prayer_tracker_page.dart';
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class WakatiWaSalaHomePage extends StatefulWidget {
  final int userId;
  final DailyPrayerSchedule? schedule;
  final PrayerStats? stats;

  const WakatiWaSalaHomePage({
    super.key,
    required this.userId,
    this.schedule,
    this.stats,
  });

  @override
  State<WakatiWaSalaHomePage> createState() => _WakatiWaSalaHomePageState();
}

class _WakatiWaSalaHomePageState extends State<WakatiWaSalaHomePage> {
  Future<void> _refresh() async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null || token.isEmpty) return;
      final service = WakatiWaSalaService();
      await Future.wait([
        service.getDailySchedule(latitude: -6.7924, longitude: 39.2083),
        service.getStats(token: token),
      ]);
    } catch (_) {
      // Silently fail on refresh — data remains stale
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    return RefreshIndicator(
          color: _kPrimary,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Date & Location ─────────────────────────
              _buildDateCard(schedule),
              const SizedBox(height: 16),

              // ─── Countdown ──────────────────────────────
              _buildCountdownCard(),
              const SizedBox(height: 16),

              // ─── Streak ─────────────────────────────────
              if (widget.stats != null) ...[
                _buildStreakCard(widget.stats!),
                const SizedBox(height: 16),
              ],

              // ─── Prayer Times List ──────────────────────
              const Text(
                'Nyakati za Sala Leo',
                style: TextStyle(
                  color: _kPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildPrayerList(schedule),

              const SizedBox(height: 16),

              // ─── Prayer Tracker Button ──────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrayerTrackerPage(userId: widget.userId),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text('Fuatilia Sala Zako'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDateCard(DailyPrayerSchedule? schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schedule?.date ?? DateTime.now().toString().split(' ').first,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            schedule?.hijriDate ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  schedule?.location ?? 'Dar es Salaam',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.timer_rounded, color: _kPrimary, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sala Inayofuata',
                  style: TextStyle(color: _kSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Adhuhuri (Dhuhr)',
                  style: TextStyle(
                    color: _kPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '02:15:30',
            style: TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(PrayerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Color(0xFFE65100), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mfuatano wa Sala',
                  style: TextStyle(color: _kSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${stats.currentStreak} siku mfululizo',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${(stats.completionRate * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrayerList(DailyPrayerSchedule? schedule) {
    if (schedule == null || schedule.prayers.isEmpty) {
      // Fallback default prayers
      final defaults = [
        PrayerTime(name: 'Fajr', nameSwahili: 'Alfajiri', time: '05:15'),
        PrayerTime(name: 'Dhuhr', nameSwahili: 'Adhuhuri', time: '12:30'),
        PrayerTime(name: 'Asr', nameSwahili: 'Alasiri', time: '15:45'),
        PrayerTime(name: 'Maghrib', nameSwahili: 'Magharibi', time: '18:25'),
        PrayerTime(name: 'Isha', nameSwahili: 'Ishaa', time: '19:35'),
      ];
      return defaults.map((p) => PrayerTimeTile(prayer: p)).toList();
    }
    return schedule.prayers.map((p) => PrayerTimeTile(prayer: p)).toList();
  }
}
