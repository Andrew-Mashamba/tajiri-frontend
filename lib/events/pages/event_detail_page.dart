// lib/events/pages/event_detail_page.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import '../widgets/rsvp_button.dart';
import '../widgets/friend_avatar_stack.dart';
import '../widgets/event_status_badge.dart';
import 'event_wall_page.dart';
import 'event_photos_page.dart';
import 'event_attendees_page.dart';
import 'event_agenda_page.dart';
import 'ticket_purchase_page.dart';
import 'event_invite_page.dart';
import '../widgets/event_share_sheet.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventDetailPage extends StatefulWidget {
  final int userId;
  final int eventId;
  const EventDetailPage({super.key, required this.userId, required this.eventId});
  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> with SingleTickerProviderStateMixin {
  final EventService _service = EventService();
  late TabController _tabController;

  Event? _event;
  bool _isLoading = true;
  String? _error;
  bool _rsvpLoading = false;
  late EventStrings _strings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    setState(() { _isLoading = true; _error = null; });
    final result = await _service.getEvent(eventId: widget.eventId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _event = result.data;
        } else {
          _error = result.message ?? _strings.loadError;
        }
      });
    }
  }

  Future<void> _handleRSVP(RSVPStatus status) async {
    if (_rsvpLoading) return;
    setState(() => _rsvpLoading = true);
    final result = await _service.respondToEvent(eventId: widget.eventId, status: status);
    if (mounted) {
      setState(() => _rsvpLoading = false);
      if (result.success) {
        _loadEvent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    if (_event == null) return;
    final isSaved = _event!.isSaved;
    if (isSaved) {
      await _service.unsaveEvent(eventId: widget.eventId);
    } else {
      await _service.saveEvent(eventId: widget.eventId);
    }
    if (mounted) _loadEvent();
  }

  void _openTicketPurchase() {
    if (_event == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TicketPurchasePage(userId: widget.userId, event: _event!),
    )).then((_) { if (mounted) _loadEvent(); });
  }

  void _openInvite() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EventInvitePage(userId: widget.userId, eventId: widget.eventId),
    ));
  }

  void _shareEvent() {
    if (_event == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => EventShareSheet(
        eventName: _event!.name,
        shareLink: 'https://tajiri.app/events/${_event!.id}',
      ),
    );
  }

  void _openAttendees() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EventAttendeesPage(userId: widget.userId, eventId: widget.eventId),
    ));
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

    if (_error != null || _event == null) {
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: _kPrimary),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(_error ?? _strings.loadError, style: const TextStyle(color: _kSecondary)),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadEvent, child: Text(_strings.tryAgain, style: const TextStyle(color: _kPrimary))),
            ],
          ),
        ),
      );
    }

    final event = _event!;
    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        onRefresh: _loadEvent,
        color: _kPrimary,
        child: CustomScrollView(
          slivers: [
            // Hero
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              foregroundColor: event.coverPhotoUrl != null ? Colors.white : _kPrimary,
              backgroundColor: event.coverPhotoUrl != null ? _kPrimary : Colors.grey.shade100,
              actions: [
                IconButton(
                  icon: Icon(event.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                  onPressed: _toggleSave,
                ),
                IconButton(icon: const Icon(Icons.share_rounded), onPressed: _shareEvent),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: event.coverPhotoUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(event.coverPhotoUrl!, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${event.startDate.day}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _kPrimary)),
                            Text(_strings.formatDate(event.startDate), style: const TextStyle(fontSize: 14, color: _kSecondary)),
                          ],
                        ),
                      ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + Category
                    Row(
                      children: [
                        if (event.status != EventStatus.published)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: EventStatusBadge(status: event.status),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text(event.category.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary)),
                        ),
                        const Spacer(),
                        if (event.type != EventType.inPerson)
                          Row(
                            children: [
                              Icon(event.type.icon, size: 16, color: _kSecondary),
                              const SizedBox(width: 4),
                              Text(event.type.displayName, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(event.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _kPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${_strings.isSwahili ? "na" : "by"} ', style: const TextStyle(fontSize: 14, color: _kSecondary)),
                        Text(
                          event.creator?.fullName ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                        if (event.coHosts.isNotEmpty)
                          Text(' + ${event.coHosts.length}', style: const TextStyle(fontSize: 14, color: _kSecondary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Friends Going
                    if (event.friendsGoingCount > 0) ...[
                      GestureDetector(
                        onTap: _openAttendees,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              FriendAvatarStack(attendees: event.friendsGoing, maxShow: 4),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _strings.formatFriendsGoing(
                                    event.friendsGoingCount,
                                    event.friendsGoing.map((a) => a.firstName).toList(),
                                  ),
                                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: _kSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // RSVP Buttons
                    if (event.canRSVP) ...[
                      Row(
                        children: [
                          Expanded(child: RSVPButton(
                            status: RSVPStatus.going,
                            isSelected: event.isGoing,
                            isLoading: _rsvpLoading,
                            onTap: () => _handleRSVP(RSVPStatus.going),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: RSVPButton(
                            status: RSVPStatus.interested,
                            isSelected: event.isInterested,
                            isLoading: _rsvpLoading,
                            onTap: () => _handleRSVP(RSVPStatus.interested),
                          )),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: RSVPButton(
                              status: RSVPStatus.notGoing,
                              isSelected: event.userResponse == 'not_going',
                              isLoading: _rsvpLoading,
                              onTap: () => _handleRSVP(RSVPStatus.notGoing),
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _openInvite,
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: Text(_strings.invite),
                            style: TextButton.styleFrom(foregroundColor: _kPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Details
                    _DetailRow(icon: Icons.calendar_today_rounded, title: _strings.isSwahili ? 'Tarehe' : 'Date', value: _strings.formatDate(event.startDate)),
                    if (event.startTime != null)
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        title: _strings.isSwahili ? 'Muda' : 'Time',
                        value: '${event.startTime}${event.endTime != null ? " - ${event.endTime}" : ""}',
                      ),
                    if (event.locationName != null)
                      _DetailRow(icon: Icons.location_on_rounded, title: _strings.location, value: event.locationName!),
                    if (event.locationAddress != null)
                      _DetailRow(icon: Icons.map_rounded, title: _strings.address, value: event.locationAddress!),
                    if (event.isOnline && event.onlineLink != null)
                      _DetailRow(icon: Icons.videocam_rounded, title: _strings.onlineLink, value: event.onlinePlatform ?? 'Online'),
                    _DetailRow(
                      icon: Icons.confirmation_number_rounded,
                      title: _strings.isSwahili ? 'Bei' : 'Price',
                      value: event.isFree ? '${_strings.free} / Free' : _strings.formatPrice(event.ticketPrice ?? 0, event.ticketCurrency),
                    ),
                    _DetailRow(
                      icon: Icons.people_rounded,
                      title: _strings.attendees,
                      value: '${event.goingCount} ${_strings.going.toLowerCase()} · ${event.interestedCount} ${_strings.interested.toLowerCase()}',
                    ),
                    const SizedBox(height: 16),

                    // Tabs
                    TabBar(
                      controller: _tabController,
                      labelColor: _kPrimary,
                      unselectedLabelColor: _kSecondary,
                      indicatorColor: _kPrimary,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(text: _strings.wall),
                        Tab(text: _strings.details),
                        Tab(text: _strings.agenda),
                        Tab(text: _strings.photos),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  EventWallPage(eventId: widget.eventId, isHost: event.isHost),
                  _buildDetailsTab(event),
                  EventAgendaPage(eventId: widget.eventId, sessions: event.sessions),
                  EventPhotosPage(eventId: widget.eventId),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: event.hasTicketTiers && !event.isFree
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: event.isSoldOut ? null : _openTicketPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      event.isSoldOut ? _strings.soldOut : _strings.getTickets,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailsTab(Event event) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description
        Text(_strings.description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        Text(event.description ?? '', style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.6)),
        const SizedBox(height: 20),

        // Speakers
        if (event.speakers.isNotEmpty) ...[
          Text(_strings.speakers, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          ...event.speakers.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: s.avatarUrl != null ? NetworkImage(s.avatarUrl!) : null,
                  child: s.avatarUrl == null ? const Icon(Icons.person_rounded, size: 20, color: _kSecondary) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                      if (s.title != null) Text(s.title!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
        ],

        // Sponsors
        if (event.sponsors.isNotEmpty) ...[
          Text(_strings.sponsors, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: event.sponsors.map((s) => Chip(
              avatar: s.logoUrl != null ? CircleAvatar(backgroundImage: NetworkImage(s.logoUrl!)) : null,
              label: Text(s.name, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey.shade100,
              side: BorderSide.none,
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Tags
        if (event.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: event.tags.map((t) => Text('#$t', style: const TextStyle(fontSize: 13, color: _kSecondary))).toList(),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _DetailRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _kSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
