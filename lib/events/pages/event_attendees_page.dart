// lib/events/pages/event_attendees_page.dart
import 'package:flutter/material.dart';
import '../models/event_strings.dart';
import '../models/event_enums.dart';
import '../models/event_rsvp.dart';
import '../services/event_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventAttendeesPage extends StatefulWidget {
  final int eventId;
  final int userId;

  const EventAttendeesPage({super.key, required this.eventId, required this.userId});

  @override
  State<EventAttendeesPage> createState() => _EventAttendeesPageState();
}

class _EventAttendeesPageState extends State<EventAttendeesPage>
    with SingleTickerProviderStateMixin {
  final _eventService = EventService();
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  final Map<int, List<EventAttendee>> _attendees = {0: [], 1: [], 2: []};
  final Map<int, bool> _loading = {0: true, 1: true, 2: true};
  final Map<int, bool> _loadingMore = {0: false, 1: false, 2: false};
  final Map<int, int> _pages = {0: 1, 1: 1, 2: 1};
  final Map<int, int> _lastPages = {0: 1, 1: 1, 2: 1};
  String _searchQuery = '';
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _activeTab = _tabController.index;
      if (_attendees[_activeTab]!.isEmpty && _loading[_activeTab]!) {
        _loadAttendees(_activeTab);
      }
    });
    _loadAttendees(0);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
      _refreshCurrentTab();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  RSVPStatus? _filterForTab(int tab) {
    if (tab == 1) return RSVPStatus.going;
    if (tab == 2) return RSVPStatus.interested;
    return null;
  }

  Future<void> _loadAttendees(int tab, {bool refresh = false}) async {
    if (refresh) setState(() { _pages[tab] = 1; _loading[tab] = true; });
    final result = await _eventService.getAttendees(
      eventId: widget.eventId,
      filter: _filterForTab(tab),
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: _pages[tab]!,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _lastPages[tab] = result.lastPage ?? 1;
        if (refresh || _pages[tab] == 1) {
          _attendees[tab] = result.items ?? [];
        } else {
          _attendees[tab]!.addAll(result.items ?? []);
        }
        _loading[tab] = false;
        _loadingMore[tab] = false;
      });
    } else {
      setState(() { _loading[tab] = false; _loadingMore[tab] = false; });
    }
  }

  void _refreshCurrentTab() {
    for (int i = 0; i < 3; i++) {
      _loadAttendees(i, refresh: true);
    }
  }

  void _loadMoreForTab(int tab) {
    if (!_loadingMore[tab]! && _pages[tab]! < _lastPages[tab]!) {
      setState(() { _pages[tab] = _pages[tab]! + 1; _loadingMore[tab] = true; });
      _loadAttendees(tab);
    }
  }

  void _openProfile(EventAttendee a) {
    Navigator.pushNamed(context, '/profile/${a.userId}');
  }

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: Localizations.localeOf(context).languageCode == 'sw');
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 14, color: _kPrimary),
            decoration: InputDecoration(
              hintText: strings.search,
              hintStyle: const TextStyle(color: _kSecondary),
              prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: _kSecondary),
                      onPressed: () { _searchCtrl.clear(); },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: strings.all),
            Tab(text: strings.going),
            Tab(text: strings.interested),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(3, (i) => _AttendeeTab(
              attendees: _attendees[i]!,
              loading: _loading[i]!,
              loadingMore: _loadingMore[i]!,
              onLoadMore: () => _loadMoreForTab(i),
              onRefresh: () => _loadAttendees(i, refresh: true),
              onTap: _openProfile,
              emptyLabel: strings.noResults,
            )),
          ),
        ),
      ]),
    );
  }
}

class _AttendeeTab extends StatelessWidget {
  final List<EventAttendee> attendees;
  final bool loading;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final ValueChanged<EventAttendee> onTap;
  final String emptyLabel;

  const _AttendeeTab({
    required this.attendees,
    required this.loading,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onRefresh,
    required this.onTap,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _kPrimary));
    if (attendees.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.people_outline_rounded, size: 48, color: _kSecondary),
        const SizedBox(height: 10),
        Text(emptyLabel, style: const TextStyle(color: _kSecondary, fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: attendees.length + (loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == attendees.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: _kPrimary)),
            );
          }
          if (i == attendees.length - 4) onLoadMore();
          return _AttendeeRow(attendee: attendees[i], onTap: () => onTap(attendees[i]));
        },
      ),
    );
  }
}

class _AttendeeRow extends StatelessWidget {
  final EventAttendee attendee;
  final VoidCallback onTap;

  const _AttendeeRow({required this.attendee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE0E0E0),
        backgroundImage: attendee.avatarUrl != null ? NetworkImage(attendee.avatarUrl!) : null,
        child: attendee.avatarUrl == null
            ? Text(
                attendee.firstName.isNotEmpty ? attendee.firstName[0] : '?',
                style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Row(children: [
        Flexible(
          child: Text(
            attendee.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary),
          ),
        ),
        if (attendee.isFriend) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Rafiki' : 'Friend', style: const TextStyle(fontSize: 10, color: _kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
      subtitle: attendee.username != null
          ? Text('@${attendee.username}', style: const TextStyle(fontSize: 12, color: _kSecondary))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: _kSecondary, size: 20),
    );
  }
}
