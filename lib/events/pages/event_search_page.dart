// lib/events/pages/event_search_page.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import '../widgets/event_card.dart';
import 'event_detail_page.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventSearchPage extends StatefulWidget {
  final int userId;
  const EventSearchPage({super.key, required this.userId});

  @override
  State<EventSearchPage> createState() => _EventSearchPageState();
}

class _EventSearchPageState extends State<EventSearchPage> {
  final EventService _service = EventService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late EventStrings _strings;

  List<Event> _results = [];
  final List<String> _recentSearches = [];
  EventCategory? _filterCategory;
  bool _isLoading = false;
  String? _activeQuery;

  static const _quickCategories = [
    EventCategory.music,
    EventCategory.sports,
    EventCategory.business,
    EventCategory.food,
    EventCategory.tech,
    EventCategory.nightlife,
    EventCategory.sherehe,
    EventCategory.harusi,
  ];

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query, {EventCategory? category}) async {
    final q = query.trim();
    if (q.isEmpty && category == null) {
      setState(() {
        _results = [];
        _activeQuery = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _activeQuery = q.isNotEmpty ? q : category?.displayName;
      _filterCategory = category;
    });
    if (q.isNotEmpty && !_recentSearches.contains(q)) {
      setState(() {
        _recentSearches.insert(0, q);
        if (_recentSearches.length > 8) _recentSearches.removeLast();
      });
    }
    final result = await _service.browseEvents(
      search: q.isNotEmpty ? q : null,
      category: category,
      page: 1,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _results = result.success ? result.items : [];
      });
    }
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _results = [];
      _activeQuery = null;
      _filterCategory = null;
    });
    _focusNode.requestFocus();
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EventDetailPage(userId: widget.userId, eventId: event.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '${_strings.search} ${_strings.events}...',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: _kSecondary, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: _kSecondary, size: 18),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
            onSubmitted: (v) => _search(v),
            onChanged: (v) {
              setState(() {});
              if (v.isEmpty) {
                setState(() {
                  _results = [];
                  _activeQuery = null;
                });
              }
            },
            style: const TextStyle(fontSize: 14, color: _kPrimary),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _activeQuery == null
              ? _buildIdle()
              : _buildResults(),
    );
  }

  Widget _buildIdle() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Category quick filters ──
        Text(_strings.category,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickCategories.map((cat) {
            final selected = _filterCategory == cat;
            return GestureDetector(
              onTap: () => _search('', category: selected ? null : cat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _kPrimary : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon,
                        size: 15,
                        color: selected ? Colors.white : _kSecondary),
                    const SizedBox(width: 6),
                    Text(
                      cat.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected ? Colors.white : _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // ── Recent searches ──
        if (_recentSearches.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _strings.isSwahili ? 'Utafutaji wa Hivi Karibuni' : 'Recent Searches',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _recentSearches.clear()),
                style: TextButton.styleFrom(
                    minimumSize: const Size(48, 32),
                    foregroundColor: _kSecondary),
                child: Text(
                  _strings.isSwahili ? 'Futa Zote' : 'Clear All',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._recentSearches.map((term) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded,
                    color: _kSecondary, size: 20),
                title: Text(term,
                    style: const TextStyle(
                        fontSize: 14, color: _kPrimary)),
                trailing: const Icon(Icons.north_west_rounded,
                    color: _kSecondary, size: 16),
                onTap: () {
                  _controller.text = term;
                  _search(term);
                },
              )),
        ],
      ],
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _strings.noResults,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            if (_activeQuery != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('"$_activeQuery"',
                    style:
                        const TextStyle(fontSize: 13, color: _kSecondary)),
              ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (_, i) => EventCard(
        event: _results[i],
        onTap: () => _openEvent(_results[i]),
      ),
    );
  }
}
