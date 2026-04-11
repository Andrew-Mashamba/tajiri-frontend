// lib/events/pages/browse_events_page.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import '../widgets/category_chip.dart';
import 'event_detail_page.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BrowseEventsPage extends StatefulWidget {
  final int userId;
  final EventCategory? initialCategory;

  const BrowseEventsPage({
    super.key,
    required this.userId,
    this.initialCategory,
  });

  @override
  State<BrowseEventsPage> createState() => _BrowseEventsPageState();
}

class _BrowseEventsPageState extends State<BrowseEventsPage> {
  final EventService _service = EventService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Event> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  EventCategory? _filterCategory;
  int _currentPage = 1;
  bool _hasMore = true;
  late EventStrings _strings;

  @override
  void initState() {
    super.initState();
    _filterCategory = widget.initialCategory;
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _loadEvents();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });
    final result = await _service.browseEvents(
      category: _filterCategory,
      search: _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null,
      page: 1,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _events = result.items;
          _hasMore = result.hasMore;
          _currentPage = result.currentPage;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final result = await _service.browseEvents(
      category: _filterCategory,
      search: _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null,
      page: _currentPage + 1,
    );
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _events.addAll(result.items);
          _hasMore = result.hasMore;
          _currentPage = result.currentPage;
        }
      });
    }
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailPage(userId: widget.userId, eventId: event.id),
      ),
    ).then((_) {
      if (mounted) _loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _strings.browseEvents,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Browse Events',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _loadEvents(),
              decoration: InputDecoration(
                hintText: '${_strings.search}...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Category chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  CategoryChip(
                    label: _strings.all,
                    isSelected: _filterCategory == null,
                    onTap: () {
                      setState(() => _filterCategory = null);
                      _loadEvents();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...EventCategory.values.take(12).map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: cat.displayName,
                          isSelected: _filterCategory == cat,
                          onTap: () {
                            setState(() => _filterCategory = cat);
                            _loadEvents();
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Events list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                  )
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _strings.noEvents,
                              style: const TextStyle(color: _kSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        color: _kPrimary,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            if (i >= _events.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _kPrimary,
                                  ),
                                ),
                              );
                            }
                            return EventCard(
                              event: _events[i],
                              onTap: () => _openEvent(_events[i]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
