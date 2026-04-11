// lib/events/pages/organizer/attendee_management_page.dart
import 'package:flutter/material.dart';
import '../../models/event_enums.dart';
import '../../models/event_rsvp.dart';
import '../../models/event_strings.dart';
import '../../services/event_organizer_service.dart';
import '../../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AttendeeManagementPage extends StatefulWidget {
  final int eventId;

  const AttendeeManagementPage({super.key, required this.eventId});

  @override
  State<AttendeeManagementPage> createState() => _AttendeeManagementPageState();
}

class _AttendeeManagementPageState extends State<AttendeeManagementPage> {
  final _service = EventOrganizerService();
  final _searchCtrl = TextEditingController();
  late EventStrings _strings;

  List<EventAttendee> _attendees = [];
  bool _loading = false;
  RSVPStatus? _filter;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) { _page = 1; _attendees = []; }
    setState(() => _loading = true);
    final result = await _service.getAttendeeList(
      eventId: widget.eventId,
      filter: _filter,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      page: _page,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _attendees = reset ? result.items : [..._attendees, ...result.items];
        _lastPage = result.lastPage;
        _total = result.total;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _loadMore() {
    if (_page < _lastPage && !_loading) { _page++; _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(_strings.attendees, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text('$_total', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary))),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(reset: true),
              style: const TextStyle(color: _kPrimary),
              decoration: InputDecoration(
                hintText: _strings.searchAttendees,
                hintStyle: const TextStyle(color: _kSecondary),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSecondary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black12)),
              ),
            ),
          ),
          _FilterRow(selected: _filter, onSelect: (f) { setState(() => _filter = f); _load(reset: true); }),
          const Divider(height: 1),
          Expanded(
            child: _loading && _attendees.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : _attendees.isEmpty
                    ? Center(child: Text(_strings.noAttendeesYet, style: const TextStyle(color: _kSecondary)))
                    : NotificationListener<ScrollNotification>(
                        onNotification: (n) { if (n.metrics.extentAfter < 100) _loadMore(); return false; },
                        child: ListView.builder(
                          itemCount: _attendees.length + (_page < _lastPage ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _attendees.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: _kPrimary)));
                            return _AttendeeTile(attendee: _attendees[i]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final RSVPStatus? selected;
  final ValueChanged<RSVPStatus?> onSelect;

  const _FilterRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = <RSVPStatus?>[null, RSVPStatus.going, RSVPStatus.interested, RSVPStatus.notGoing];
    final labels = ['All', 'Going', 'Interested', 'Not Going'];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = selected == filters[i];
          return GestureDetector(
            onTap: () => onSelect(filters[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? _kPrimary : Colors.black26),
              ),
              alignment: Alignment.center,
              child: Text(labels[i], style: TextStyle(fontSize: 12, color: active ? Colors.white : _kSecondary, fontWeight: FontWeight.w500)),
            ),
          );
        },
      ),
    );
  }
}

class _AttendeeTile extends StatelessWidget {
  final EventAttendee attendee;
  const _AttendeeTile({required this.attendee});

  @override
  Widget build(BuildContext context) {
    final status = attendee.rsvpStatus;
    Color statusColor = Colors.orange;
    String statusLabel = 'Interested';
    if (status == RSVPStatus.going) { statusColor = Colors.green; statusLabel = 'Going'; }
    else if (status == RSVPStatus.notGoing) { statusColor = Colors.red; statusLabel = 'Not Going'; }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEEEEEE),
            backgroundImage: attendee.avatarUrl != null ? NetworkImage(attendee.avatarUrl!) : null,
            child: attendee.avatarUrl == null ? const Icon(Icons.person_rounded, color: _kSecondary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attendee.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (attendee.username != null)
                  Text('@${attendee.username}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
