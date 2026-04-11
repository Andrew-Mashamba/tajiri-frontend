// lib/kanisa_langu/pages/church_events_page.dart
import 'package:flutter/material.dart';
import '../models/kanisa_langu_models.dart';
import '../services/kanisa_langu_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ChurchEventsPage extends StatefulWidget {
  final int churchId;
  const ChurchEventsPage({super.key, required this.churchId});
  @override
  State<ChurchEventsPage> createState() => _ChurchEventsPageState();
}

class _ChurchEventsPageState extends State<ChurchEventsPage> {
  List<ChurchEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await KanisaLanguService.getEvents(widget.churchId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (r.success) _events = r.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Matukio ya Kanisa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Church Events',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Hakuna matukio yajayo\nNo upcoming events',
                          style: TextStyle(color: _kSecondary, fontSize: 14),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final evt = _events[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(evt.title,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: _kSecondary),
                                const SizedBox(width: 6),
                                Text(evt.date, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                                if (evt.time != null) ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.schedule_rounded, size: 14, color: _kSecondary),
                                  const SizedBox(width: 4),
                                  Text(evt.time!, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                                ],
                              ],
                            ),
                            if (evt.location != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: _kSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(evt.location!,
                                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ],
                            if (evt.description != null) ...[
                              const SizedBox(height: 6),
                              Text(evt.description!,
                                  style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
