// lib/campus_news/pages/campus_events_page.dart
import 'package:flutter/material.dart';
import '../models/campus_news_models.dart';
import '../services/campus_news_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CampusEventsPage extends StatefulWidget {
  final int userId;
  const CampusEventsPage({super.key, required this.userId});
  @override
  State<CampusEventsPage> createState() => _CampusEventsPageState();
}

class _CampusEventsPageState extends State<CampusEventsPage> {
  List<CampusEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await CampusNewsService().getEvents();
    if (mounted) { setState(() { _isLoading = false; if (result.success) _events = result.items; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Matukio / Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _events.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.event_rounded, size: 48, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Hakuna matukio / No events', style: TextStyle(color: _kSecondary)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (_, i) {
                    final e = _events[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: _kSecondary), const SizedBox(width: 6),
                          Text('${e.startDate.day}/${e.startDate.month}/${e.startDate.year}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                          const SizedBox(width: 14),
                          const Icon(Icons.location_on_rounded, size: 14, color: _kSecondary), const SizedBox(width: 4),
                          Expanded(child: Text(e.venue, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Text(e.organizer, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                          const Spacer(),
                          Text('${e.rsvpCount} RSVP', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                          const SizedBox(width: 8),
                          if (!e.hasRsvped) GestureDetector(
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final result = await CampusNewsService().rsvpEvent(e.id);
                              if (mounted) {
                                messenger.showSnackBar(SnackBar(
                                  content: Text(result.success ? 'RSVP imekubaliwa / RSVP confirmed' : 'Imeshindwa / Failed'),
                                ));
                                if (result.success) _load();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)),
                              child: const Text('RSVP', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      ]),
                    );
                  },
                ),
    );
  }
}
