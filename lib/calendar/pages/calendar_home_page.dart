// lib/calendar/pages/calendar_home_page.dart
import 'package:flutter/material.dart';
import '../models/calendar_models.dart';
import '../services/calendar_service.dart';
import '../widgets/event_card.dart';
import 'add_event_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CalendarHomePage extends StatefulWidget {
  final int userId;
  const CalendarHomePage({super.key, required this.userId});
  @override
  State<CalendarHomePage> createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  final CalendarService _service = CalendarService();
  List<CalendarEvent> _monthEvents = [];
  List<CalendarEvent> _dayEvents = [];
  bool _isLoading = true;
  bool _isDayLoading = false;

  late DateTime _currentMonth;
  late DateTime _selectedDay;

  static const List<String> _dayNames = [
    'Jmt', 'Jtt', 'Jnn', 'Alh', 'Ijm', 'Jms', 'Jpi'
  ];

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
    'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _loadMonthEvents();
  }

  Future<void> _loadMonthEvents() async {
    setState(() => _isLoading = true);
    final result = await _service.getEvents(
      widget.userId,
      year: _currentMonth.year,
      month: _currentMonth.month,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _monthEvents = result.items;
      });
      _loadDayEvents();
    }
  }

  Future<void> _loadDayEvents() async {
    setState(() => _isDayLoading = true);
    final result = await _service.getEventsForDay(
      widget.userId,
      date: _selectedDay,
    );
    if (mounted) {
      setState(() {
        _isDayLoading = false;
        if (result.success) _dayEvents = result.items;
      });
    }
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
    _loadMonthEvents();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    });
    _loadMonthEvents();
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
    _loadDayEvents();
  }

  List<CalendarEvent> _eventsForDay(int day) {
    return _monthEvents.where((e) => e.date.day == day).toList();
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  bool _isSelected(DateTime day) {
    return day.year == _selectedDay.year &&
        day.month == _selectedDay.month &&
        day.day == _selectedDay.day;
  }

  Future<void> _addEvent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEventPage(
          userId: widget.userId,
          initialDate: _selectedDay,
        ),
      ),
    );
    if (result == true && mounted) {
      _loadMonthEvents();
    }
  }

  Future<void> _editEvent(CalendarEvent event) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEventPage(
          userId: widget.userId,
          initialDate: event.date,
          existingEvent: event,
        ),
      ),
    );
    if (result == true && mounted) {
      _loadMonthEvents();
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Tukio?'),
        content: Text('Unahitaji kufuta "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana',
                style: TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Futa',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await _service.deleteEvent(event.id);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tukio limefutwa')),
          );
          _loadMonthEvents();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result.message ?? 'Imeshindwa kufuta')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadMonthEvents,
          color: _kPrimary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Month nav
              _buildMonthHeader(),
              const SizedBox(height: 12),

              // Day names
              _buildDayNamesRow(),
              const SizedBox(height: 4),

              // Calendar grid
              _buildCalendarGrid(),
              const SizedBox(height: 16),

              // Selected day header
              _buildDayHeader(),
              const SizedBox(height: 8),

              // Day events
              if (_isDayLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary),
                  ),
                )
              else if (_dayEvents.isEmpty)
                _buildEmptyDay()
              else
                ..._dayEvents.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EventCard(
                        event: e,
                        onTap: e.source == EventSource.personal
                            ? () => _editEvent(e)
                            : null,
                        onDelete: e.source == EventSource.personal
                            ? () => _deleteEvent(e)
                            : null,
                      ),
                    )),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // FAB — pill button
        Positioned(
          bottom: 16,
          right: 16,
          child: Material(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(28),
            elevation: 4,
            child: InkWell(
              onTap: _addEvent,
              borderRadius: BorderRadius.circular(28),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('Tukio Jipya',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _prevMonth,
          icon: const Icon(Icons.chevron_left_rounded, color: _kPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        Column(
          children: [
            Text(
              _monthNames[_currentMonth.month - 1],
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
            Text(
              '${_currentMonth.year}',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
          ],
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right_rounded, color: _kPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }

  Widget _buildDayNamesRow() {
    return Row(
      children: _dayNames
          .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kSecondary)),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // Monday = 1, Sunday = 7
    final startWeekday = firstDay.weekday; // 1=Mon ... 7=Sun

    final cells = <Widget>[];

    // Empty cells before first day
    for (var i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final date =
          DateTime(_currentMonth.year, _currentMonth.month, day);
      final events = _eventsForDay(day);
      final isToday = _isToday(date);
      final isSelected = _isSelected(date);

      cells.add(
        GestureDetector(
          onTap: () => _selectDay(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _kPrimary
                  : isToday
                      ? _kPrimary.withValues(alpha: 0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : _kPrimary,
                  ),
                ),
                if (events.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events
                        .take(3)
                        .map((e) => Container(
                              width: 5,
                              height: 5,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : e.source.dotColor,
                                shape: BoxShape.circle,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: cells,
    );
  }

  Widget _buildDayHeader() {
    final dayOfWeek = _selectedDay.weekday; // 1=Mon
    final dayName = _dayNames[dayOfWeek - 1];
    return Row(
      children: [
        Text(
          '$dayName, ${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]}',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        if (_isToday(_selectedDay)) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Leo',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.event_available_rounded,
                size: 48, color: _kSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('Hakuna matukio',
                style: TextStyle(fontSize: 15, color: _kSecondary)),
            const SizedBox(height: 4),
            const Text('Bonyeza "Tukio Jipya" kuongeza tukio',
                style: TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
