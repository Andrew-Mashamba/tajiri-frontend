// lib/events/pages/virtual/virtual_event_page.dart
import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/event_strings.dart';
import '../../services/event_service.dart';
import '../event_wall_page.dart';
import '../event_agenda_page.dart';
import '../../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class VirtualEventPage extends StatefulWidget {
  final int userId;
  final int eventId;
  const VirtualEventPage({super.key, required this.userId, required this.eventId});
  @override
  State<VirtualEventPage> createState() => _VirtualEventPageState();
}

class _VirtualEventPageState extends State<VirtualEventPage> with SingleTickerProviderStateMixin {
  final EventService _service = EventService();
  late TabController _tabController;
  Event? _event;
  bool _isLoading = true;
  late EventStrings _strings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _loadEvent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    final result = await _service.getEvent(eventId: widget.eventId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _event = result.data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: _kPrimary),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
      );
    }

    final event = _event;
    if (event == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: _kPrimary),
        body: Center(child: Text(_strings.loadError, style: const TextStyle(color: _kSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (event.isHappeningNow)
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('LIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade300)),
                ],
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stream area
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: event.onlineLink != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_rounded, size: 48, color: Colors.white54),
                        const SizedBox(height: 12),
                        Text(
                          _strings.isSwahili ? 'Tazama Moja kwa Moja' : 'Watch Live',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Launch external link
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_strings.isSwahili ? 'Fungua Kiungo' : 'Open Link'),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.live_tv_rounded, size: 48, color: Colors.white30),
                        SizedBox(height: 8),
                        Text('Stream area', style: TextStyle(color: Colors.white30)),
                      ],
                    ),
                  ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: _kPrimary,
            unselectedLabelColor: _kSecondary,
            indicatorColor: _kPrimary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: _strings.isSwahili ? 'Mazungumzo' : 'Chat'),
              Tab(text: _strings.isSwahili ? 'Maswali' : 'Q&A'),
              Tab(text: _strings.agenda),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                EventWallPage(eventId: widget.eventId, isHost: event.isHost),
                _buildQATab(),
                EventAgendaPage(eventId: widget.eventId, sessions: event.sessions),
              ],
            ),
          ),
        ],
      ),
      // Attendee count bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_rounded, size: 18, color: _kSecondary),
              const SizedBox(width: 8),
              Text(
                '${event.goingCount} ${_strings.isSwahili ? "wanaotazama" : "watching"}',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const Spacer(),
              Text(
                event.onlinePlatform ?? '',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQATab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_answer_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _strings.isSwahili ? 'Maswali na Majibu' : 'Questions & Answers',
            style: const TextStyle(fontSize: 16, color: _kSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            _strings.isSwahili ? 'Inakuja hivi karibuni' : 'Coming soon',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
