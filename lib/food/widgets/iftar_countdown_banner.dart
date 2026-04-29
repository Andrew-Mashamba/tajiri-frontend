import 'dart:async';
import 'package:flutter/material.dart';

import '../../wakati_wa_sala/models/wakati_wa_sala_models.dart';
import '../../wakati_wa_sala/services/wakati_wa_sala_service.dart';

const Color _kCard = Color(0xFFFFFFFF);

// Dar es Salaam — used by wakati_wa_sala home page too. Iftar sunset varies
// only ±20 minutes year-round at this latitude (-6.8°), so a Dar-anchored
// fetch is acceptable when the user has not granted location.
const double _kDarLat = -6.7924;
const double _kDarLng = 39.2083;

class IftarCountdownBanner extends StatefulWidget {
  final VoidCallback? onTap;
  const IftarCountdownBanner({super.key, this.onTap});

  @override
  State<IftarCountdownBanner> createState() => _IftarCountdownBannerState();
}

class _IftarCountdownBannerState extends State<IftarCountdownBanner> {
  Timer? _ticker;
  late DateTime _sunset;
  final _prayerService = WakatiWaSalaService();

  @override
  void initState() {
    super.initState();
    _sunset = _fallbackSunset();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _loadMaghribFromService();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Conservative fallback used while the prayer-times API is in flight or if
  /// the call fails. Sunset is ~18:30 year-round in Dar.
  DateTime _fallbackSunset() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 18, 30);
  }

  /// Load today's Maghrib time from the prayer-times API and adopt it as the
  /// authoritative iftar moment when available.
  Future<void> _loadMaghribFromService() async {
    final res = await _prayerService.getDailySchedule(
      latitude: _kDarLat,
      longitude: _kDarLng,
    );
    if (!mounted || !res.success || res.data == null) return;
    final maghrib = _findMaghrib(res.data!.prayers);
    if (maghrib == null) return;
    final parsed = _parseHm(maghrib);
    if (parsed == null) return;
    final now = DateTime.now();
    setState(() {
      _sunset = DateTime(now.year, now.month, now.day, parsed.$1, parsed.$2);
    });
  }

  String? _findMaghrib(List<PrayerTime> prayers) {
    for (final p in prayers) {
      final n = p.name.toLowerCase();
      if (n == 'maghrib' || n == 'magharibi') return p.time;
    }
    return null;
  }

  (int, int)? _parseHm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = _sunset.difference(now);
    final isAfterIftar = diff.isNegative;
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    final countdownText = isAfterIftar
        ? 'Iftari imefika — kula salama'
        : hours > 0
            ? 'Iftari ndani ya saa $hours na dakika $minutes'
            : 'Iftari ndani ya dakika $minutes';

    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
            ),
          ),
          child: Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Iftari ya Leo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countdownText,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jua linazama saa ${_hhmm(_sunset)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onTap != null)
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
