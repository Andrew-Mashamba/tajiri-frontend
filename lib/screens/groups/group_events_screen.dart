// In-group events and RSVPs: list events linked to a group and open event detail for RSVP (Going/Interested/Not going).
// Extension of the main events feature; opened from group chat.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_models.dart';
import '../../services/event_service.dart';
import '../../widgets/cached_media_image.dart';
import '../events/event_detail_screen.dart';
import 'createevent_screen.dart';

const Color _bg = Color(0xFFFAFAFA);
const Color _primaryText = Color(0xFF1A1A1A);
const Color _secondaryText = Color(0xFF666666);
const Color _accent = Color(0xFF999999);
const Color _cardBg = Color(0xFFFFFFFF);

class GroupEventsScreen extends StatefulWidget {
  final int groupId;
  final int currentUserId;
  final String groupName;

  const GroupEventsScreen({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.groupName,
  });

  @override
  State<GroupEventsScreen> createState() => _GroupEventsScreenState();
}

class _GroupEventsScreenState extends State<GroupEventsScreen> {
  final EventService _eventService = EventService();
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _eventService.getEventsByGroup(
      groupId: widget.groupId,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _events = result.events;
      } else {
        _error = result.message;
      }
    });
  }

  void _openEventDetail(EventModel event) {
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
  }

  void _openCreateEvent() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => CreateEventScreen(
          creatorId: widget.currentUserId,
          groupId: widget.groupId,
        ),
      ),
    ).then((created) {
      if (created == true && mounted) _loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        foregroundColor: _primaryText,
        elevation: 0,
        title: Text(
          widget.groupName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _secondaryText),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _loadEvents,
                            child: const Text('Jaribu tena'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 64, color: _accent),
                            const SizedBox(height: 16),
                            const Text(
                              'Hakuna matukio ya kikundi bado',
                              style: TextStyle(
                                fontSize: 14,
                                color: _secondaryText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _openCreateEvent,
                              icon: const Icon(Icons.add),
                              label: const Text('Tengeneza tukio'),
                              style: FilledButton.styleFrom(
                                backgroundColor: _primaryText,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) =>
                              _buildEventCard(_events[index]),
                        ),
                      ),
      ),
      floatingActionButton: _events.isNotEmpty || _error != null
          ? FloatingActionButton(
              heroTag: 'group_events_fab',
              backgroundColor: _primaryText,
              foregroundColor: _cardBg,
              onPressed: _openCreateEvent,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _cardBg,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openEventDetail(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 72,
                  color: _accent.withValues(alpha: 0.2),
                  child: event.coverPhotoUrl != null &&
                          event.coverPhotoUrl!.isNotEmpty
                      ? CachedMediaImage(
                          imageUrl: event.coverPhotoUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.event, size: 32, color: _secondaryText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEE, MMM d • HH:mm', 'sw').format(event.startDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _secondaryText,
                      ),
                    ),
                    if (event.userResponse != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryText.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.isGoing
                              ? 'Unaenda'
                              : event.isInterested
                                  ? 'Unavutiwa'
                                  : 'Sitaenda',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _primaryText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _secondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
