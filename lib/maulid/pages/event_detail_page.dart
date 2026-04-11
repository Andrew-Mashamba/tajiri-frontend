// lib/maulid/pages/event_detail_page.dart
import 'package:flutter/material.dart';
import '../models/maulid_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MaulidEventDetailPage extends StatelessWidget {
  final MaulidEvent event;
  const MaulidEventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Tukio la Maulid',
            style: TextStyle(color: _kPrimary, fontSize: 18,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share coming soon / Kushiriki kunakuja'),
                  backgroundColor: _kPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Hero Image ───────────────────────────────
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: _kPrimary, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.celebration_rounded,
                        color: Colors.white70, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      event.titleSwahili.isNotEmpty
                          ? event.titleSwahili : event.title,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Details ──────────────────────────────────
            _detailRow(Icons.location_on_rounded, 'Mahali',
                '${event.venue}, ${event.address}'),
            _detailRow(Icons.calendar_today_rounded, 'Tarehe',
                '${event.startTime.day}/${event.startTime.month}/${event.startTime.year}'),
            _detailRow(Icons.access_time_rounded, 'Wakati',
                '${event.startTime.hour.toString().padLeft(2, '0')}:'
                '${event.startTime.minute.toString().padLeft(2, '0')}'),
            _detailRow(Icons.person_rounded, 'Mratibu',
                event.organizerName),
            if (event.attendeeCount != null)
              _detailRow(Icons.people_rounded, 'Washiriki',
                  '${event.attendeeCount}'),

            const SizedBox(height: 16),

            // ─── Description ──────────────────────────────
            if (event.description.isNotEmpty) ...[
              const Text('Maelezo',
                  style: TextStyle(color: _kPrimary, fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
                child: Text(event.description,
                    style: const TextStyle(
                        color: _kPrimary, fontSize: 14, height: 1.6)),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Qaswida Groups ───────────────────────────
            if (event.qaswidaGroups.isNotEmpty) ...[
              const Text('Vikundi vya Qaswida',
                  style: TextStyle(color: _kPrimary, fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: event.qaswidaGroups.map((g) =>
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_note_rounded,
                            color: _kSecondary, size: 16),
                        const SizedBox(width: 6),
                        Text(g, style: const TextStyle(
                            color: _kPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Actions ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('RSVP sent / Umesajiliwa'),
                            backgroundColor: _kPrimary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('I will attend / Nitahudhuria'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ),
                if (event.isLiveStreamable) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Live stream coming soon / Matangazo ya moja kwa moja yanakuja'),
                              backgroundColor: _kPrimary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.live_tv_rounded, size: 20),
                        label: const Text('Watch Live / Tazama Live'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(icon, color: _kSecondary, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(
              color: _kSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value, style: const TextStyle(
                color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
