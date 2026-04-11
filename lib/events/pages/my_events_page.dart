// lib/events/pages/my_events_page.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'event_detail_page.dart';
import 'create_event_page.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyEventsPage extends StatefulWidget {
  final int userId;
  const MyEventsPage({super.key, required this.userId});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage>
    with SingleTickerProviderStateMixin {
  final EventService _service = EventService();
  late TabController _tabController;
  late EventStrings _strings;

  List<Event> _hosting = [];
  List<Event> _attending = [];
  List<Event> _saved = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Lazy-load saved tab on first visit
    if (_tabController.index == 2 && _saved.isEmpty && !_isLoading) {
      _loadSaved();
    }
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final hosting = _service.getUserEvents(userId: widget.userId);
    final attending = _service.getUserAttendingEvents(userId: widget.userId);
    final saved = _service.getSavedEvents();
    final results = await Future.wait([hosting, attending, saved]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        final hostingResult = results[0];
        final attendingResult = results[1];
        final savedResult = results[2];
        if (hostingResult.success) _hosting = hostingResult.items;
        if (attendingResult.success) _attending = attendingResult.items;
        if (savedResult.success) _saved = savedResult.items;
      });
    }
  }

  Future<void> _loadSaved() async {
    final result = await _service.getSavedEvents();
    if (mounted) {
      setState(() {
        if (result.success) _saved = result.items;
      });
    }
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventDetailPage(userId: widget.userId, eventId: event.id),
      ),
    ).then((_) {
      if (mounted) _loadAll();
    });
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventPage(userId: widget.userId),
      ),
    ).then((_) {
      if (mounted) _loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_strings.myEvents,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            const Text('My Events',
                style: TextStyle(fontSize: 11, color: _kSecondary)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: _strings.hosting),
            Tab(text: _strings.attending),
            Tab(text: _strings.saved),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_hosting, isHosting: true),
                _buildList(_attending),
                _buildList(_saved, isSaved: true),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: _kPrimary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildList(List<Event> events,
      {bool isHosting = false, bool isSaved = false}) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHosting
                  ? Icons.event_available_outlined
                  : isSaved
                      ? Icons.bookmark_border_rounded
                      : Icons.event_busy_outlined,
              size: 52,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              _strings.noEvents,
              style: const TextStyle(
                  color: _kSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              isHosting
                  ? (_strings.isSwahili ? 'Bonyeza + kuunda tukio' : 'Tap + to create an event')
                  : (_strings.isSwahili ? 'Matukio utakayojumuisha yataonekana hapa' : 'Events you join will appear here'),
              style: const TextStyle(color: _kSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (_, i) => EventCard(
          event: events[i],
          onTap: () => _openEvent(events[i]),
        ),
      ),
    );
  }
}
