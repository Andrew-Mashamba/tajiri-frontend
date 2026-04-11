// lib/kalenda_hijri/pages/kalenda_hijri_home_page.dart
import 'package:flutter/material.dart';
import '../models/kalenda_hijri_models.dart';
import '../services/kalenda_hijri_service.dart';
import 'events_list_page.dart';
import 'date_converter_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class KalendaHijriHomePage extends StatefulWidget {
  final int userId;
  const KalendaHijriHomePage({super.key, required this.userId});

  @override
  State<KalendaHijriHomePage> createState() => _KalendaHijriHomePageState();
}

class _KalendaHijriHomePageState extends State<KalendaHijriHomePage> {
  final _service = KalendaHijriService();
  HijriDate? _today;
  List<IslamicEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.getTodayHijri(),
      _service.getEvents(),
    ]);
    if (mounted) {
      final dateResult = results[0] as SingleResult<HijriDate>;
      final eventsResult = results[1] as PaginatedResult<IslamicEvent>;
      setState(() {
        _today = dateResult.data;
        _events = eventsResult.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          )
        : RefreshIndicator(
            color: _kPrimary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Date converter action
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded, color: _kPrimary),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DateConverterPage()),
                    ),
                  ),
                ),
                    // ─── Today Card ───────────────────────
                    _buildTodayCard(),
                    const SizedBox(height: 16),

                    // ─── Moon Phase ───────────────────────
                    _buildMoonPhaseCard(),
                    const SizedBox(height: 24),

                    // ─── Upcoming Events ──────────────────
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Matukio Yanayokuja',
                              style: TextStyle(
                                color: _kPrimary, fontSize: 16,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventsListPage(
                                  userId: widget.userId, events: _events),
                            ),
                          ),
                          child: const Text('Ona yote',
                              style: TextStyle(color: _kSecondary, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._events.take(5).map(_buildEventCard),
                  ],
                ),
              );
  }

  Widget _buildTodayCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('Leo',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            _today?.formatted ?? '--',
            style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _today?.gregorianDate ?? '',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoonPhaseCard() {
    final phase = _today?.moonPhase ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            phase > 0.5 ? Icons.nightlight_round : Icons.nightlight_outlined,
            color: _kPrimary, size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Awamu ya Mwezi',
                    style: TextStyle(color: _kSecondary, fontSize: 12)),
                Text(
                  '${(phase * 100).toStringAsFixed(0)}% iliyoangazwa',
                  style: const TextStyle(
                    color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(IslamicEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: event.isPublicHoliday
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.event_rounded,
              color: event.isPublicHoliday ? Colors.green : _kSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.nameSwahili.isNotEmpty ? event.nameSwahili : event.name,
                  style: const TextStyle(
                    color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  event.gregorianDate ?? event.hijriDate.formatted,
                  style: const TextStyle(color: _kSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (event.isPublicHoliday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Sikukuu',
                  style: TextStyle(color: Colors.green, fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}
