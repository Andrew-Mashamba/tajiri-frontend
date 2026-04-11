// lib/faith/pages/prayer_times_page.dart
import 'package:flutter/material.dart';
import '../models/faith_models.dart';
import '../services/faith_service.dart';
import '../widgets/prayer_time_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PrayerTimesPage extends StatefulWidget {
  final int userId;
  const PrayerTimesPage({super.key, required this.userId});
  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  final FaithService _service = FaithService();
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;

  final double _latitude = -6.7924;
  final double _longitude = 39.2083;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() => _isLoading = true);
    final result = await _service.getPrayerTimes(
      latitude: _latitude,
      longitude: _longitude,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _prayerTimes = result.data;
      });
    }
  }

  int _getCurrentPrayerIndex() {
    if (_prayerTimes == null) return -1;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final prayers = _prayerTimes!.allPrayers;

    for (int i = prayers.length - 1; i >= 0; i--) {
      final parts = prayers[i].value.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        if (nowMinutes >= h * 60 + m) return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nyakati za Sala',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Prayer Times',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _prayerTimes == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Imeshindwa kupakia nyakati za sala',
                          style: TextStyle(color: _kSecondary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadPrayerTimes,
                        child: const Text('Jaribu tena',
                            style: TextStyle(color: _kPrimary)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPrayerTimes,
                  color: _kPrimary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Date
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: _kSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _prayerTimes!.date,
                              style: const TextStyle(
                                  fontSize: 15, color: _kPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Prayer times list
                      ..._prayerTimes!.allPrayers.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PrayerTimeCard(
                                name: entry.value.key,
                                time: entry.value.value,
                                isCurrent:
                                    entry.key == _getCurrentPrayerIndex(),
                              ),
                            ),
                          ),
                      const SizedBox(height: 16),
                      // Info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: _kSecondary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Nyakati zinategemea eneo lako (Dar es Salaam)',
                                style: TextStyle(
                                    fontSize: 13, color: _kSecondary),
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
}
