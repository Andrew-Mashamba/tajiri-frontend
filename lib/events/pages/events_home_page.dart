// lib/events/pages/events_home_page.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import '../services/event_cache_service.dart';
import '../widgets/event_card.dart';
import '../widgets/happening_now_banner.dart';
import '../widgets/category_chip.dart';
import 'create_event_page.dart';
import 'event_detail_page.dart';
import 'event_search_page.dart';
import 'event_calendar_page.dart';
import 'my_events_page.dart';
import 'my_tickets_page.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventsHomePage extends StatefulWidget {
  final int userId;
  const EventsHomePage({super.key, required this.userId});
  @override
  State<EventsHomePage> createState() => _EventsHomePageState();
}

class _EventsHomePageState extends State<EventsHomePage> with SingleTickerProviderStateMixin {
  final EventService _service = EventService();
  late TabController _tabController;

  List<Event> _feedEvents = [];
  List<Event> _friendsEvents = [];
  List<Event> _happeningNow = [];
  EventCategory? _categoryFilter;
  bool _isLoading = true;
  String? _error;
  late EventStrings _strings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getEventsFeed(page: 1),
        _service.getFriendsEvents(),
        _service.getHappeningNow(),
      ]);
      if (mounted) {
        final feedResult = results[0] as PaginatedResult<Event>;
        setState(() {
          _isLoading = false;
          if (feedResult.success) {
            _feedEvents = feedResult.items;
          } else {
            _error = feedResult.message;
          }
          _friendsEvents = results[1] as List<Event>;
          _happeningNow = results[2] as List<Event>;
        });
        // Cache
        if (feedResult.success) {
          EventCacheService.instance.cacheEvents(key: 'feed', events: feedResult.items);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = '$e'; });
      }
    }
  }

  Future<void> _loadByCategory(EventCategory? cat) async {
    setState(() { _categoryFilter = cat; _isLoading = true; });
    try {
      final result = await _service.browseEvents(category: cat, page: 1);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _feedEvents = result.items;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEvent(Event event) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EventDetailPage(userId: widget.userId, eventId: event.id),
    )).then((_) { if (mounted) _loadData(); });
  }

  void _openCreate() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CreateEventPage(userId: widget.userId),
    )).then((_) { if (mounted) _loadData(); });
  }

  void _openSearch() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EventSearchPage(userId: widget.userId),
    ));
  }

  void _openMyEvents() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MyEventsPage(userId: widget.userId),
    ));
  }

  void _openMyTickets() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MyTicketsPage(userId: widget.userId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // Action row (no AppBar — parent profile tab provides the header)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(_strings.events, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
                ),
                IconButton(icon: const Icon(Icons.search_rounded, color: _kPrimary), onPressed: _openSearch),
                IconButton(icon: const Icon(Icons.confirmation_number_outlined, color: _kPrimary), onPressed: _openMyTickets),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: _kPrimary),
                  onSelected: (v) {
                    if (v == 'my_events') _openMyEvents();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'my_events', child: Text(_strings.myEvents)),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: _kPrimary,
            unselectedLabelColor: _kSecondary,
            indicatorColor: _kPrimary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: _strings.forYou),
              Tab(text: _strings.friends),
              Tab(text: _strings.nearby),
              Tab(text: _strings.calendar),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForYouTab(),
                _buildFriendsTab(),
                _buildNearbyTab(),
                _buildCalendarTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildForYouTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Happening Now
          if (_happeningNow.isNotEmpty)
            ..._happeningNow.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HappeningNowBanner(event: e, onTap: () => _openEvent(e)),
            )),

          // Friends' Events
          if (_friendsEvents.isNotEmpty) ...[
            Text(_strings.friendsGoing, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _friendsEvents.length > 10 ? 10 : _friendsEvents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final event = _friendsEvents[i];
                  return GestureDetector(
                    onTap: () => _openEvent(event),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: event.coverPhotoUrl != null ? NetworkImage(event.coverPhotoUrl!) : null,
                            child: event.coverPhotoUrl == null
                                ? Icon(event.category.icon, size: 20, color: _kSecondary)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.name,
                            style: const TextStyle(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Categories
          Text('${_strings.category}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryChip(
                  label: _strings.all,
                  isSelected: _categoryFilter == null,
                  onTap: () => _loadByCategory(null),
                ),
                const SizedBox(width: 8),
                ...EventCategory.values.take(12).map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CategoryChip(
                    label: cat.displayName,
                    icon: cat.icon,
                    isSelected: _categoryFilter == cat,
                    onTap: () => _loadByCategory(cat),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Error
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 18, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Events
          Text(_strings.upcoming, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 10),
          if (_feedEvents.isNotEmpty)
            ..._feedEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EventCard(event: event, onTap: () => _openEvent(event)),
            ))
          else
            _buildEmpty(_strings.noEvents),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    if (_friendsEvents.isEmpty) {
      return Center(child: _buildEmpty(_strings.noEvents));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _friendsEvents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => EventCard(event: _friendsEvents[i], onTap: () => _openEvent(_friendsEvents[i])),
      ),
    );
  }

  Widget _buildNearbyTab() {
    // Nearby events — loads browse events filtered by proximity
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: _feedEvents.isEmpty
          ? Center(child: _buildEmpty(_strings.noEvents))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _feedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => EventCard(
                event: _feedEvents[i],
                onTap: () => _openEvent(_feedEvents[i]),
              ),
            ),
    );
  }

  Widget _buildCalendarTab() {
    // Inline calendar placeholder — tapping opens full calendar page
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.calendar_month_rounded, size: 40, color: _kSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            _strings.calendar,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _strings.isSwahili
                ? 'Mwonekano wa kalenda unakuja hivi karibuni'
                : 'Calendar view coming soon',
            style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => EventCalendarPage(userId: widget.userId),
              ));
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(_strings.isSwahili ? 'Fungua Kalenda' : 'Open Calendar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: _kSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
