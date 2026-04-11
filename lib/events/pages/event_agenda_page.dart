// lib/events/pages/event_agenda_page.dart
import 'package:flutter/material.dart';
import '../models/event_strings.dart';
import '../models/event_session.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventAgendaPage extends StatelessWidget {
  final int eventId;
  final List<EventSession> sessions;

  const EventAgendaPage({
    super.key,
    required this.eventId,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: Localizations.localeOf(context).languageCode == 'sw');

    if (sessions.isEmpty) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.event_note_outlined, size: 56, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              strings.isSwahili ? 'Hakuna ratiba bado' : 'No agenda yet',
              style: const TextStyle(fontSize: 15, color: _kSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              strings.isSwahili
                  ? 'Ratiba ya tukio itaonekana hapa'
                  : 'Event schedule will appear here',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }

    final grouped = _groupByDate(sessions);
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: _kBg,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: sortedDates.length,
        itemBuilder: (context, di) {
          final date = sortedDates[di];
          final daySessions = grouped[date]!..sort((a, b) => a.startTime.compareTo(b.startTime));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayHeader(date: date, strings: strings),
              ...daySessions.asMap().entries.map((entry) => _SessionTile(
                session: entry.value,
                isLast: entry.key == daySessions.length - 1,
              )),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, List<EventSession>> _groupByDate(List<EventSession> sessions) {
    final map = <DateTime, List<EventSession>>{};
    for (final s in sessions) {
      final key = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final EventStrings strings;
  const _DayHeader({required this.date, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            strings.formatDate(date),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

class _SessionTile extends StatefulWidget {
  final EventSession session;
  final bool isLast;
  const _SessionTile({required this.session, required this.isLast});

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final startStr = _formatTime(s.startTime);
    final endStr = _formatTime(s.endTime);

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Timeline column
        SizedBox(
          width: 64,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                startStr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Container(
                  width: 2,
                  color: widget.isLast ? Colors.transparent : const Color(0xFFE0E0E0),
                ),
              ),
            ),
          ]),
        ),
        // Dot
        Column(children: [
          const SizedBox(height: 18),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ]),
        // Content
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: _kSecondary,
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  '$startStr – $endStr',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                if (s.location != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: _kSecondary),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        s.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                      ),
                    ),
                  ]),
                ],
                if (_expanded) ...[
                  if (s.description != null && s.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(s.description!,
                        style: const TextStyle(fontSize: 13, color: _kPrimary, height: 1.4)),
                  ],
                  if (s.speakers.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Wasemaji' : 'Speakers',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary)),
                    const SizedBox(height: 6),
                    ...s.speakers.map((sp) => _SpeakerChip(speaker: sp)),
                  ],
                  if (s.track != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s.track!,
                          style: const TextStyle(fontSize: 11, color: _kSecondary)),
                    ),
                  ],
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SpeakerChip extends StatelessWidget {
  final EventSpeaker speaker;
  const _SpeakerChip({required this.speaker});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFFE0E0E0),
          backgroundImage:
              speaker.avatarUrl != null ? NetworkImage(speaker.avatarUrl!) : null,
          child: speaker.avatarUrl == null
              ? Text(
                  speaker.name.isNotEmpty ? speaker.name[0] : '?',
                  style: const TextStyle(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            speaker.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
          ),
          if (speaker.title != null)
            Text(
              speaker.title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
        ])),
      ]),
    );
  }
}
