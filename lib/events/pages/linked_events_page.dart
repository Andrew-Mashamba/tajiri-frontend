// lib/events/pages/linked_events_page.dart
// Vertical timeline of linked events for a parent event (wedding series, funeral series, etc.)
// Past events greyed with checkmark, current highlighted, future shows countdown.
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/linked_event.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import 'event_detail_page.dart';
import '../../services/local_storage_service.dart';
import '../../services/authenticated_dio.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class LinkedEventsPage extends StatefulWidget {
  final int userId;
  final int eventId;          // parent event
  final String? eventName;    // optional parent event name for the title
  const LinkedEventsPage({
    super.key,
    required this.userId,
    required this.eventId,
    this.eventName,
  });

  @override
  State<LinkedEventsPage> createState() => _LinkedEventsPageState();
}

class _LinkedEventsPageState extends State<LinkedEventsPage> {
  final EventService _service = EventService();
  final Dio _dio = AuthenticatedDio.instance;
  late EventStrings _strings;

  List<LinkedEvent> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _load();
  }

  // ── Fetch parent event then linked events ──
  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await _service.getEvent(eventId: widget.eventId);
      if (!mounted) return;
      if (!result.success) {
        setState(() { _error = result.message; _isLoading = false; });
        return;
      }
      final linked = await _fetchLinkedEvents(widget.eventId);
      if (mounted) setState(() { _events = linked; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<List<LinkedEvent>> _fetchLinkedEvents(int eventId) async {
    try {
      final response = await _dio.get('/events/$eventId/linked-events');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        // data may be a series object with an 'events' list or a flat list
        if (data is Map && data['events'] is List) {
          return (data['events'] as List).map((e) => LinkedEvent.fromJson(e)).toList();
        }
        if (data is List) {
          return data.map((e) => LinkedEvent.fromJson(e)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Timeline state classification ──
  _TimelineState _stateOf(LinkedEvent e) {
    if (e.isCompleted) return _TimelineState.past;
    final now = DateTime.now();
    // Within ±24 h of event date = "current"
    final diff = e.date.difference(now).abs();
    if (diff.inHours <= 24 && !e.date.isBefore(now.subtract(const Duration(hours: 24)))) {
      return _TimelineState.current;
    }
    if (e.isPast) return _TimelineState.past;
    return _TimelineState.future;
  }

  String _countdown(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inDays > 0) {
      return _strings.isSwahili ? 'Siku ${diff.inDays}' : '${diff.inDays}d left';
    }
    if (diff.inHours > 0) {
      return _strings.isSwahili ? 'Masaa ${diff.inHours}' : '${diff.inHours}h left';
    }
    return _strings.isSwahili ? 'Leo' : 'Today';
  }

  void _openDetail(LinkedEvent e) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailPage(userId: widget.userId, eventId: e.eventId),
      ),
    );
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          widget.eventName ?? (_strings.isSwahili ? 'Matukio Yanayohusiana' : 'Linked Events'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _kPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: _kPrimary),
            tooltip: _strings.tryAgain,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2));
    }
    if (_error != null) return _buildError();
    if (_events.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _events.length,
      itemBuilder: (_, i) => _buildTimelineItem(i),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              Text(
                _error ?? _strings.loadError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: Text(_strings.tryAgain, style: const TextStyle(color: _kPrimary)),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_note_rounded, size: 56, color: _kSecondary),
              const SizedBox(height: 12),
              Text(
                _strings.isSwahili
                    ? 'Hakuna matukio yanayohusiana bado'
                    : 'No linked events yet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  // ── Timeline row ──
  Widget _buildTimelineItem(int index) {
    final e = _events[index];
    final state = _stateOf(e);
    final isLast = index == _events.length - 1;

    final dotColor = switch (state) {
      _TimelineState.past    => _kSecondary.withOpacity(0.4),
      _TimelineState.current => _kPrimary,
      _TimelineState.future  => _kPrimary.withOpacity(0.25),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left column: dot + connector line ──
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildDot(state, dotColor),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(width: 1.5, color: _kPrimary.withOpacity(0.12)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Right column: card ──
          Expanded(
            child: GestureDetector(
              onTap: () => _openDetail(e),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: state == _TimelineState.current ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state == _TimelineState.current
                        ? _kPrimary
                        : _kPrimary.withOpacity(0.1),
                  ),
                  boxShadow: state == _TimelineState.current
                      ? [BoxShadow(color: _kPrimary.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: _buildCardContent(e, state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(_TimelineState state, Color color) {
    switch (state) {
      case _TimelineState.past:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        );
      case _TimelineState.current:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kPrimary,
            border: Border.all(color: _kBg, width: 2.5),
            boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.4), blurRadius: 6)],
          ),
        );
      case _TimelineState.future:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kBg,
            border: Border.all(color: _kPrimary.withOpacity(0.3), width: 1.5),
          ),
        );
    }
  }

  Widget _buildCardContent(LinkedEvent e, _TimelineState state) {
    final isPast = state == _TimelineState.past;
    final isCurrent = state == _TimelineState.current;
    final textColor = isCurrent ? _kBg : (isPast ? _kSecondary : _kPrimary);
    final subColor = isCurrent ? _kBg.withOpacity(0.7) : _kSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + badge row ──
        Row(
          children: [
            Expanded(
              child: Text(
                e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            if (state == _TimelineState.future)
              _badge(_countdown(e.date), bgColor: _kPrimary.withOpacity(0.08), textColor: _kPrimary),
            if (isCurrent)
              _badge(
                _strings.isSwahili ? 'SASA' : 'NOW',
                bgColor: _kBg.withOpacity(0.2),
                textColor: _kBg,
                letterSpacing: 0.8,
              ),
          ],
        ),
        const SizedBox(height: 5),

        // ── Date ──
        Text(
          _strings.formatDateShort(e.date),
          style: TextStyle(color: subColor, fontSize: 13),
        ),

        // ── Location ──
        if (e.location != null && e.location!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 13, color: subColor),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  e.location!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
              ),
            ],
          ),
        ],

        // ── Going count ──
        if (e.goingCount > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.people_rounded, size: 13, color: subColor),
              const SizedBox(width: 3),
              Text(
                _strings.isSwahili
                    ? '${e.goingCount} wanahudhuria'
                    : '${e.goingCount} going',
                style: TextStyle(color: subColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _badge(
    String text, {
    required Color bgColor,
    required Color textColor,
    double letterSpacing = 0.0,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: letterSpacing,
          ),
        ),
      );
}

// ── Timeline state enum ──
enum _TimelineState { past, current, future }
