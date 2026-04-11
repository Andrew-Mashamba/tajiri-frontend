// lib/owners_club/pages/community_events_page.dart
import 'package:flutter/material.dart';
import '../models/owners_club_models.dart';
import '../services/owners_club_service.dart';
import '../widgets/event_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CommunityEventsPage extends StatefulWidget {
  final Community community;
  const CommunityEventsPage({super.key, required this.community});
  @override
  State<CommunityEventsPage> createState() => _CommunityEventsPageState();
}

class _CommunityEventsPageState extends State<CommunityEventsPage> {
  final OwnersClubService _service = OwnersClubService();
  List<CommunityEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getCommunityEvents(widget.community.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _events = result.items;
      });
    }
  }

  Future<void> _rsvp(CommunityEvent event) async {
    final result = await _service.rsvpEvent(event.id);
    if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RSVP confirmed!'), backgroundColor: _kPrimary),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Events', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _events.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_rounded, size: 48, color: _kSecondary),
                      SizedBox(height: 12),
                      Text('No upcoming events', style: TextStyle(color: _kSecondary, fontSize: 14)),
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
                    itemBuilder: (_, i) => EventCard(
                      event: _events[i],
                      onRsvp: () => _rsvp(_events[i]),
                    ),
                  ),
                ),
    );
  }
}
