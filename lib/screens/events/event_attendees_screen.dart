import 'package:flutter/material.dart';
import '../../models/event_models.dart';
import '../../services/event_service.dart';

/// View attendees for an event: Going / Interested / Not Going.
/// Design: DOCS/DESIGN.md — monochrome, 48dp touch targets, SafeArea.
class EventAttendeesScreen extends StatefulWidget {
  final int eventId;
  final String eventName;
  final String initialType;

  const EventAttendeesScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    this.initialType = 'going',
  });

  @override
  State<EventAttendeesScreen> createState() => _EventAttendeesScreenState();
}

class _EventAttendeesScreenState extends State<EventAttendeesScreen>
    with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late TabController _tabController;

  List<EventCreator> _going = [];
  List<EventCreator> _interested = [];
  List<EventCreator> _notGoing = [];
  bool _loadingGoing = true;
  bool _loadingInterested = true;
  bool _loadingNotGoing = true;

  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);
  static const Color _iconBg = Color(0xFF1A1A1A);
  static const double _minTouchTarget = 48.0;

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialType == 'interested') initialIndex = 1;
    if (widget.initialType == 'not_going') initialIndex = 2;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(_onTabChanged);
    _loadAttendees('going');
    _loadAttendees('interested');
    _loadAttendees('not_going');
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final types = ['going', 'interested', 'not_going'];
      _loadAttendees(types[_tabController.index]);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendees(String type) async {
    final result = await _eventService.getAttendees(widget.eventId, type: type);
    if (!mounted) return;
    setState(() {
      switch (type) {
        case 'going':
          _loadingGoing = false;
          if (result.success) _going = result.attendees;
          break;
        case 'interested':
          _loadingInterested = false;
          if (result.success) _interested = result.attendees;
          break;
        case 'not_going':
          _loadingNotGoing = false;
          if (result.success) _notGoing = result.attendees;
          break;
      }
      // Error handling could be added here if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryText,
        elevation: 0,
        title: Text(
          'Washiriki',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _primaryText,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _primaryText,
          unselectedLabelColor: _secondaryText,
          indicatorColor: _iconBg,
          tabs: const [
            Tab(text: 'Wanaenda'),
            Tab(text: 'Wanavutiwa'),
            Tab(text: 'Hawaendi'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(_going, _loadingGoing),
            _buildList(_interested, _loadingInterested),
            _buildList(_notGoing, _loadingNotGoing),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<EventCreator> attendees, bool loading) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: _iconBg),
      );
    }
    if (attendees.isEmpty) {
      return Center(
        child: Text(
          'Hakuna washiriki',
          style: TextStyle(color: _secondaryText, fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final a = attendees[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minLeadingWidth: _minTouchTarget,
            leading: CircleAvatar(
              radius: _minTouchTarget / 2,
              backgroundColor: _iconBg,
              backgroundImage: a.avatarUrl != null ? NetworkImage(a.avatarUrl!) : null,
              child: a.avatarUrl == null
                  ? Text(
                      a.firstName.isNotEmpty
                          ? a.firstName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            title: Text(
              a.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: _primaryText,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: a.username != null
                ? Text(
                    '@${a.username}',
                    style: const TextStyle(color: _secondaryText, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
          ),
        );
      },
    );
  }
}
