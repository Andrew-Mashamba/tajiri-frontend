// Story 90: Events Screen — browse events.
// Navigation: Discover/Home → Events → EventsScreen.
// Design: DOCS/DESIGN.md (layout, touch targets 48dp min, colors).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_models.dart';
import '../../services/event_service.dart';
import '../../widgets/cached_media_image.dart';
import '../events/event_detail_screen.dart';
import 'createevent_screen.dart';

/// Events browse screen with Yanayokuja / Matukio Yangu tabs.
class EventsScreen extends StatefulWidget {
  final int currentUserId;

  const EventsScreen({super.key, required this.currentUserId});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventService _eventService = EventService();

  List<EventModel> _upcomingEvents = [];
  List<EventModel> _myEvents = [];
  bool _isLoadingUpcoming = true;
  bool _isLoadingMy = true;

  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _accent = Color(0xFF999999);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const double _minTouchTarget = 48.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    _loadUpcomingEvents();
    _loadMyEvents();
  }

  Future<void> _loadUpcomingEvents() async {
    setState(() => _isLoadingUpcoming = true);
    final result =
        await _eventService.getEvents(currentUserId: widget.currentUserId);
    if (mounted) {
      setState(() {
        _isLoadingUpcoming = false;
        if (result.success) _upcomingEvents = result.events;
      });
    }
  }

  Future<void> _loadMyEvents() async {
    setState(() => _isLoadingMy = true);
    final result =
        await _eventService.getUserEvents(widget.currentUserId, filter: 'going');
    if (mounted) {
      setState(() {
        _isLoadingMy = false;
        if (result.success) _myEvents = result.events;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        foregroundColor: _primaryText,
        elevation: 0,
        title: const Text(
          'Matukio',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryText,
          unselectedLabelColor: _secondaryText,
          indicatorColor: _primaryText,
          tabs: const [
            Tab(text: 'Yanayokuja'),
            Tab(text: 'Matukio Yangu'),
          ],
        ),
        actions: [
          Semantics(
            label: 'Tafuta matukio',
            child: SizedBox(
              width: _minTouchTarget,
              height: _minTouchTarget,
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Story for event search
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUpcomingTab(),
            _buildMyEventsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'events_fab',
        backgroundColor: _primaryText,
        foregroundColor: _cardBg,
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute<bool>(
              builder: (context) =>
                  CreateEventScreen(creatorId: widget.currentUserId),
            ),
          );
          if (result == true && mounted) _loadEvents();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isLoadingUpcoming) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_upcomingEvents.isEmpty) {
      return _buildEmptyState('Hakuna matukio yanayokuja');
    }
    return RefreshIndicator(
      onRefresh: _loadUpcomingEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingEvents.length,
        itemBuilder: (context, index) =>
            _buildEventCard(_upcomingEvents[index]),
      ),
    );
  }

  Widget _buildMyEventsTab() {
    if (_isLoadingMy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myEvents.isEmpty) {
      return _buildEmptyState('Hujajiunga na tukio lolote');
    }
    return RefreshIndicator(
      onRefresh: _loadMyEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myEvents.length,
        itemBuilder: (context, index) => _buildEventCard(_myEvents[index]),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 64, color: _accent),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final dateFormat = DateFormat('EEE, MMM d', 'sw');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _cardBg,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => EventDetailScreen(
                  eventId: event.id,
                  currentUserId: widget.currentUserId,
                ),
              ),
            ).then((_) {
              if (mounted) _loadEvents();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: _accent.withValues(alpha: 0.2),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (event.coverPhotoUrl != null &&
                          event.coverPhotoUrl!.isNotEmpty)
                        CachedMediaImage(
                          imageUrl: event.coverPhotoUrl,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          backgroundColor: _accent.withValues(alpha: 0.2),
                        )
                      else
                        const SizedBox.shrink(),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('MMM')
                                    .format(event.startDate)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: _secondaryText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                DateFormat('d').format(event.startDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (event.userResponse != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _primaryText,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              event.isGoing ? 'Unaenda' : 'Unavutiwa',
                              style: const TextStyle(
                                color: _cardBg,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: _secondaryText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.isAllDay
                                ? 'Siku nzima'
                                : event.startTime != null
                                    ? '${dateFormat.format(event.startDate)} ${event.startTime}'
                                    : dateFormat.format(event.startDate),
                            style: const TextStyle(
                                color: _secondaryText, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (event.locationName != null || event.isOnline) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            event.isOnline
                                ? Icons.videocam
                                : Icons.location_on,
                            size: 14,
                            color: _secondaryText,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.isOnline
                                  ? 'Mtandaoni'
                                  : event.locationName ?? '',
                              style: const TextStyle(
                                  color: _secondaryText, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: _secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${event.goingCount} wanaenda',
                          style: const TextStyle(
                              fontSize: 12, color: _secondaryText),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star,
                            size: 14, color: _secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${event.interestedCount} wanavutiwa',
                          style: const TextStyle(
                              fontSize: 12, color: _secondaryText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
