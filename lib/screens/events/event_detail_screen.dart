import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_models.dart';
import '../../services/event_service.dart';
import 'event_attendees_screen.dart';

/// Event detail with RSVP: Going / Interested / Not Going.
/// Design: DOCS/DESIGN.md — monochrome, 48dp touch targets, SafeArea.
/// Navigation: Event detail → Going/Interested/Not Going; View attendees.
class EventDetailScreen extends StatefulWidget {
  final int eventId;
  final int currentUserId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.currentUserId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();

  EventModel? _event;
  bool _isLoading = true;
  bool _isResponding = false;
  String? _errorMessage;

  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _iconBg = Color(0xFF1A1A1A);
  static const double _minTouchTarget = 48.0;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await _eventService.getEvent(
      widget.eventId.toString(),
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _event = result.event;
      } else {
        _errorMessage = result.message ?? 'Tukio halipatikani';
      }
    });
  }

  Future<void> _respond(String response) async {
    if (_event == null) return;
    if (!mounted) return;
    setState(() => _isResponding = true);
    final result = await _eventService.respondToEvent(
      widget.eventId,
      widget.currentUserId,
      response,
    );
    if (!mounted) return;
    setState(() => _isResponding = false);
    if (result.success) {
      final goingCount = result.goingCount ?? _event!.goingCount;
      final interestedCount = result.interestedCount ?? _event!.interestedCount;
      final notGoingCount = result.notGoingCount ?? _event!.notGoingCount;
      setState(() {
        _event = _event!.copyWith(
          userResponse: response,
          goingCount: goingCount,
          interestedCount: interestedCount,
          notGoingCount: notGoingCount,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response == 'going'
                ? 'Umeweka: Nitaenda'
                : response == 'interested'
                    ? 'Umeweka: Ninavutiwa'
                    : 'Umeweka: Sitaenda',
          ),
          backgroundColor: _primaryText,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Imeshindwa kusasisha jibu. Jaribu tena.'),
          backgroundColor: _primaryText,
        ),
      );
    }
  }

  void _openAttendees({String type = 'going'}) {
    if (_event == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EventAttendeesScreen(
          eventId: widget.eventId,
          eventName: _event!.name,
          initialType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _primaryText,
          elevation: 0,
        ),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator(color: _iconBg)),
        ),
      );
    }

    if (_event == null || _errorMessage != null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _primaryText,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage ?? 'Tukio halipatikani',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _secondaryText, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: _loadEvent,
                      child: const Text('Jaribu tena'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy', 'sw');
    final event = _event!;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.height * 0.28,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _primaryText,
              flexibleSpace: FlexibleSpaceBar(
                background: event.coverPhotoUrl != null && event.coverPhotoUrl!.isNotEmpty
                    ? Image.network(event.coverPhotoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFF999999),
                        child: Icon(Icons.event, size: 80, color: Colors.white.withOpacity(0.8)),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryText,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      Icons.calendar_today,
                      dateFormat.format(event.startDate),
                      event.isAllDay ? 'Siku nzima' : (event.startTime ?? ''),
                    ),
                    const SizedBox(height: 12),

                    if (event.locationName != null || event.isOnline)
                      _buildInfoRow(
                        event.isOnline ? Icons.videocam : Icons.location_on,
                        event.isOnline ? 'Tukio la Mtandaoni' : event.locationName!,
                        event.isOnline
                            ? (event.onlineLink ?? '')
                            : (event.locationAddress ?? ''),
                      ),
                    if (event.locationName != null || event.isOnline) const SizedBox(height: 12),

                    if (event.hasTickets)
                      _buildInfoRow(
                        Icons.confirmation_number,
                        '${event.ticketCurrency} ${event.ticketPrice!.toStringAsFixed(0)}',
                        event.ticketLink != null ? 'Bonyeza kupata tiketi' : '',
                        onTap: event.ticketLink != null
                            ? () => launchUrl(Uri.parse(event.ticketLink!))
                            : null,
                      ),
                    if (event.hasTickets) const SizedBox(height: 24),

                    // Stats (tappable → View attendees)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatTap(
                          Icons.check_circle,
                          event.goingCount.toString(),
                          'Wanaenda',
                          () => _openAttendees(type: 'going'),
                        ),
                        _buildStatTap(
                          Icons.star,
                          event.interestedCount.toString(),
                          'Wanavutiwa',
                          () => _openAttendees(type: 'interested'),
                        ),
                        _buildStatTap(
                          Icons.cancel,
                          event.notGoingCount.toString(),
                          'Hawaendi',
                          () => _openAttendees(type: 'not_going'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // RSVP: Going / Interested / Not Going (min 48dp)
                    Row(
                      children: [
                        Expanded(
                          child: _buildRsvpButton(
                            label: event.isGoing ? 'Unaenda' : 'Nitaenda',
                            icon: event.isGoing ? Icons.check_circle : Icons.add_circle_outline,
                            isSelected: event.isGoing,
                            onPressed: _isResponding ? null : () => _respond('going'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRsvpButton(
                            label: event.isInterested ? 'Unavutiwa' : 'Ninavutiwa',
                            icon: event.isInterested ? Icons.star : Icons.star_border,
                            isSelected: event.isInterested,
                            onPressed: _isResponding ? null : () => _respond('interested'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildRsvpButton(
                            label: event.userResponse == 'not_going' ? 'Sitaenda' : 'Sitaenda',
                            icon: Icons.cancel_outlined,
                            isSelected: event.userResponse == 'not_going',
                            onPressed: _isResponding ? null : () => _respond('not_going'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (event.description != null && event.description!.isNotEmpty) ...[
                      const Text(
                        'Kuhusu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: const TextStyle(fontSize: 12, color: _secondaryText),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (event.creator != null) ...[
                      const Text(
                        'Mwandaaji',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: _iconBg,
                          backgroundImage: event.creator!.avatarUrl != null
                              ? NetworkImage(event.creator!.avatarUrl!)
                              : null,
                          child: event.creator!.avatarUrl == null
                              ? Text(
                                  event.creator!.firstName.isNotEmpty
                                      ? event.creator!.firstName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                          event.creator!.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _primaryText,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: event.creator!.username != null
                            ? Text(
                                '@${event.creator!.username}',
                                style: const TextStyle(color: _secondaryText, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _minTouchTarget,
                height: _minTouchTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _primaryText,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: onTap != null ? _secondaryText : _secondaryText,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildStatTap(IconData icon, String count, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: _minTouchTarget * 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _iconBg, size: 28),
              const SizedBox(height: 4),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryText,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: _secondaryText, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRsvpButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onPressed,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? _iconBg : _secondaryText,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? _primaryText : _secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
