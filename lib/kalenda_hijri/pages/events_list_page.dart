// lib/kalenda_hijri/pages/events_list_page.dart
import 'package:flutter/material.dart';
import '../models/kalenda_hijri_models.dart';
import 'event_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventsListPage extends StatelessWidget {
  final int userId;
  final List<IslamicEvent> events;

  const EventsListPage({
    super.key,
    required this.userId,
    required this.events,
  });

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
        title: const Text(
          'Matukio ya Kiislamu',
          style: TextStyle(
            color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: events.isEmpty
            ? const Center(
                child: Text('Hakuna matukio',
                    style: TextStyle(color: _kSecondary, fontSize: 14)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, i) {
                  final event = events[i];
                  return InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: event),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.event_rounded,
                                color: _kPrimary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.nameSwahili.isNotEmpty
                                      ? event.nameSwahili
                                      : event.name,
                                  style: const TextStyle(
                                    color: _kPrimary, fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.hijriDate.formatted,
                                  style: const TextStyle(
                                      color: _kSecondary, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (event.gregorianDate != null)
                                  Text(
                                    event.gregorianDate!,
                                    style: const TextStyle(
                                        color: _kSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: _kSecondary, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
