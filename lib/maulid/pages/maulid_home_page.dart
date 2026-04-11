// lib/maulid/pages/maulid_home_page.dart
import 'package:flutter/material.dart';
import '../models/maulid_models.dart';
import '../services/maulid_service.dart';
import 'event_detail_page.dart';
import 'qaswida_library_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class MaulidHomePage extends StatefulWidget {
  final int userId;
  const MaulidHomePage({super.key, required this.userId});

  @override
  State<MaulidHomePage> createState() => _MaulidHomePageState();
}

class _MaulidHomePageState extends State<MaulidHomePage> {
  final _service = MaulidService();
  List<MaulidEvent> _events = [];
  List<QaswidaRecording> _latestQaswida = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.getEvents(),
      _service.getRecordings(),
    ]);
    if (mounted) {
      final eventsResult = results[0] as PaginatedResult<MaulidEvent>;
      final qaswidaResult = results[1] as PaginatedResult<QaswidaRecording>;
      setState(() {
        _events = eventsResult.items;
        _latestQaswida = qaswidaResult.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(
            strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            color: _kPrimary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                    // ─── Countdown Card ───────────────────
                    _buildCountdownCard(),
                    const SizedBox(height: 16),

                    // ─── Qaswida Quick Access ─────────────
                    InkWell(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) =>
                              const QaswidaLibraryPage())),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                        child: const Row(
                          children: [
                            Icon(Icons.music_note_rounded,
                                color: _kPrimary, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Maktaba ya Qaswida',
                                      style: TextStyle(color: _kPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  Text('Sikiliza qaswida za Maulid',
                                      style: TextStyle(
                                          color: _kSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: _kSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Events ───────────────────────────
                    const Text('Matukio ya Maulid',
                        style: TextStyle(color: _kPrimary, fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Hakuna matukio bado',
                            style: TextStyle(
                                color: _kSecondary, fontSize: 14),
                            textAlign: TextAlign.center),
                      )
                    else
                      ..._events.take(10).map(_buildEventCard),

                    const SizedBox(height: 24),

                    // ─── Latest Qaswida ───────────────────
                    if (_latestQaswida.isNotEmpty) ...[
                      const Text('Qaswida Mpya',
                          style: TextStyle(color: _kPrimary, fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ..._latestQaswida.take(5).map(_buildQaswidaTile),
                    ],
                  ],
                ),
              );
  }

  Widget _buildCountdownCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: const Column(
        children: [
          Icon(Icons.celebration_rounded, color: Colors.white70, size: 40),
          SizedBox(height: 8),
          Text('Maulid un-Nabi',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('12 Rabi ul-Awwal',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          SizedBox(height: 12),
          Text('Sherehe ya kuzaliwa Mtume Muhammad (SAW)',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildEventCard(MaulidEvent event) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => MaulidEventDetailPage(event: event))),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${event.startTime.day}',
                      style: const TextStyle(color: _kPrimary, fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text('${event.startTime.month}',
                      style: const TextStyle(
                          color: _kSecondary, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.titleSwahili.isNotEmpty
                        ? event.titleSwahili : event.title,
                    style: const TextStyle(color: _kPrimary, fontSize: 15,
                        fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(event.venue,
                      style: const TextStyle(
                          color: _kSecondary, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (event.qaswidaGroups.isNotEmpty)
                    Text(event.qaswidaGroups.join(', '),
                        style: const TextStyle(
                            color: _kSecondary, fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (event.isLiveStreamable)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv_rounded,
                        color: Colors.red, size: 12),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(
                        color: Colors.red, fontSize: 10,
                        fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQaswidaTile(QaswidaRecording q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          const Icon(Icons.play_circle_rounded, color: _kPrimary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.title,
                    style: const TextStyle(color: _kPrimary, fontSize: 14,
                        fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(q.groupName,
                    style: const TextStyle(
                        color: _kSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(q.durationFormatted,
              style: const TextStyle(color: _kSecondary, fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
