// lib/kalenda_hijri/pages/event_detail_page.dart
import 'package:flutter/material.dart';
import '../models/kalenda_hijri_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventDetailPage extends StatelessWidget {
  final IslamicEvent event;
  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          event.nameSwahili.isNotEmpty ? event.nameSwahili : event.name,
          style: const TextStyle(
            color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600,
          ),
        ),
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
            // ─── Date Card ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    event.hijriDate.formatted,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.gregorianDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.gregorianDate!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (event.isPublicHoliday) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Sikukuu Rasmi',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Description ──────────────────────────────
            const Text('Maelezo',
                style: TextStyle(
                  color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                event.descriptionSwahili.isNotEmpty
                    ? event.descriptionSwahili
                    : event.description,
                style: const TextStyle(
                  color: _kPrimary, fontSize: 14, height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Significance ─────────────────────────────
            if (event.significance.isNotEmpty) ...[
              const Text('Umuhimu',
                  style: TextStyle(
                    color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  event.significance,
                  style: const TextStyle(
                    color: _kSecondary, fontSize: 14, height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── Recommended Practices ────────────────────
            if (event.recommendedPractices.isNotEmpty) ...[
              const Text('Matendo Yanayopendekezwa',
                  style: TextStyle(
                    color: _kPrimary, fontSize: 16, fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 8),
              ...event.recommendedPractices.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: _kSecondary, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p,
                              style: const TextStyle(
                                  color: _kPrimary, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
