// lib/my_family/pages/family_calendar_page.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';
import '../services/my_family_service.dart';
import '../widgets/event_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class FamilyCalendarPage extends StatefulWidget {
  final int userId;
  final List<FamilyMember> members;

  const FamilyCalendarPage({
    super.key,
    required this.userId,
    required this.members,
  });

  @override
  State<FamilyCalendarPage> createState() => _FamilyCalendarPageState();
}

class _FamilyCalendarPageState extends State<FamilyCalendarPage> {
  final MyFamilyService _service = MyFamilyService();

  late DateTime _selectedMonth;
  DateTime? _selectedDay;
  List<FamilyEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedDay = now;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final result = await _service.getEvents(
      widget.userId,
      _selectedMonth.month,
      _selectedMonth.year,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _events = result.items;
      });
    }
  }

  List<FamilyEvent> get _eventsForSelectedDay {
    if (_selectedDay == null) return _events;
    return _events
        .where((e) =>
            e.date.year == _selectedDay!.year &&
            e.date.month == _selectedDay!.month &&
            e.date.day == _selectedDay!.day)
        .toList();
  }

  bool _hasEventsOnDay(DateTime day) {
    return _events.any((e) =>
        e.date.year == day.year &&
        e.date.month == day.month &&
        e.date.day == day.day);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
      _selectedDay = null;
    });
    _loadEvents();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
      _selectedDay = null;
    });
    _loadEvents();
  }

  Future<void> _deleteEvent(FamilyEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa Tukio'),
        content: Text('Una uhakika unataka kufuta "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana', style: TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Ndio, Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _service.deleteEvent(event.id);
      if (result.success && mounted) _loadEvents();
    }
  }

  void _showCreateEventSheet() {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    DateTime eventDate = _selectedDay ?? DateTime.now();
    bool isRecurring = false;
    String? recurrenceRule;
    List<int> selectedMemberIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unda Tukio Jipya',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(fontSize: 14, color: _kPrimary),
                      decoration: InputDecoration(
                        labelText: 'Jina la Tukio',
                        labelStyle:
                            const TextStyle(fontSize: 13, color: _kSecondary),
                        prefixIcon: const Icon(Icons.event_rounded,
                            size: 20, color: _kSecondary),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: eventDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 5)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: _kPrimary,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => eventDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: _kSecondary),
                            const SizedBox(width: 10),
                            Text(
                              '${eventDate.day}/${eventDate.month}/${eventDate.year}',
                              style: const TextStyle(
                                  fontSize: 14, color: _kPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time
                    TextField(
                      controller: timeCtrl,
                      style: const TextStyle(fontSize: 14, color: _kPrimary),
                      decoration: InputDecoration(
                        labelText: 'Saa (mfano: 10:00)',
                        labelStyle:
                            const TextStyle(fontSize: 13, color: _kSecondary),
                        prefixIcon: const Icon(Icons.access_time_rounded,
                            size: 20, color: _kSecondary),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14, color: _kPrimary),
                      decoration: InputDecoration(
                        labelText: 'Maelezo',
                        labelStyle:
                            const TextStyle(fontSize: 13, color: _kSecondary),
                        prefixIcon: const Icon(Icons.notes_rounded,
                            size: 20, color: _kSecondary),
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Assign members
                    if (widget.members.isNotEmpty) ...[
                      const Text(
                        'Wanafamilia Husika',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.members.map((m) {
                          final isSelected =
                              selectedMemberIds.contains(m.id);
                          return FilterChip(
                            label: Text(
                              m.name.split(' ').first,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : _kPrimary,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  selectedMemberIds.add(m.id);
                                } else {
                                  selectedMemberIds.remove(m.id);
                                }
                              });
                            },
                            selectedColor: _kPrimary,
                            checkmarkColor: Colors.white,
                            backgroundColor:
                                _kPrimary.withValues(alpha: 0.06),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Recurring
                    Row(
                      children: [
                        Switch(
                          value: isRecurring,
                          onChanged: (v) =>
                              setSheetState(() => isRecurring = v),
                          activeTrackColor: _kPrimary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tukio la Kurudiwa',
                          style: TextStyle(fontSize: 13, color: _kPrimary),
                        ),
                      ],
                    ),
                    if (isRecurring) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: ['daily', 'weekly', 'monthly', 'yearly']
                            .map((rule) {
                          final labels = {
                            'daily': 'Kila Siku',
                            'weekly': 'Kila Wiki',
                            'monthly': 'Kila Mwezi',
                            'yearly': 'Kila Mwaka',
                          };
                          return ChoiceChip(
                            label: Text(
                              labels[rule]!,
                              style: TextStyle(
                                fontSize: 12,
                                color: recurrenceRule == rule
                                    ? Colors.white
                                    : _kPrimary,
                              ),
                            ),
                            selected: recurrenceRule == rule,
                            onSelected: (s) =>
                                setSheetState(() => recurrenceRule = rule),
                            selectedColor: _kPrimary,
                            backgroundColor:
                                _kPrimary.withValues(alpha: 0.06),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          final result = await _service.createEvent(
                            userId: widget.userId,
                            title: titleCtrl.text.trim(),
                            date: eventDate
                                .toIso8601String()
                                .split('T')
                                .first,
                            time: timeCtrl.text.trim().isNotEmpty
                                ? timeCtrl.text.trim()
                                : null,
                            memberIds: selectedMemberIds.isNotEmpty
                                ? selectedMemberIds
                                : null,
                            isRecurring: isRecurring,
                            recurrenceRule: recurrenceRule,
                            notes: notesCtrl.text.trim().isNotEmpty
                                ? notesCtrl.text.trim()
                                : null,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (result.success && mounted) _loadEvents();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hifadhi Tukio',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];
    const weekDays = ['Jm', 'Jt', 'Jn', 'Ar', 'Al', 'Ij', 'Jp'];

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Kalenda ya Familia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // ─── Month Selector ─────────────────────────────
          Container(
            color: _kCardBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: _kPrimary),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: _kPrimary),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // ─── Calendar Grid ──────────────────────────────
          Container(
            color: _kCardBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // Week day headers
                Row(
                  children: weekDays
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kSecondary,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 6),
                // Calendar days
                _buildCalendarGrid(),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── Events List ────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _eventsForSelectedDay.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded,
                                size: 48,
                                color:
                                    _kPrimary.withValues(alpha: 0.15)),
                            const SizedBox(height: 8),
                            Text(
                              _selectedDay != null
                                  ? 'Hakuna matukio tarehe hii'
                                  : 'Hakuna matukio mwezi huu',
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _eventsForSelectedDay.length,
                        separatorBuilder: (c, i) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final event = _eventsForSelectedDay[index];
                          return EventCard(
                            event: event,
                            onDelete: () => _deleteEvent(event),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startWeekday = (firstDay.weekday - 1) % 7; // Monday = 0
    final totalDays = lastDay.day;
    final today = DateTime.now();

    final rows = <Widget>[];
    int dayCounter = 1;
    int totalCells = startWeekday + totalDays;
    int numRows = (totalCells / 7).ceil();

    for (int row = 0; row < numRows; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;
        if (cellIndex < startWeekday || dayCounter > totalDays) {
          cells.add(const Expanded(child: SizedBox(height: 40)));
        } else {
          final day = DateTime(
              _selectedMonth.year, _selectedMonth.month, dayCounter);
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          final isSelected = _selectedDay != null &&
              day.year == _selectedDay!.year &&
              day.month == _selectedDay!.month &&
              day.day == _selectedDay!.day;
          final hasEvents = _hasEventsOnDay(day);
          final currentDay = dayCounter;

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _kPrimary
                        : isToday
                            ? _kPrimary.withValues(alpha: 0.08)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$currentDay',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : _kPrimary,
                        ),
                      ),
                      if (hasEvents)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : _kPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          dayCounter++;
        }
      }
      rows.add(Row(children: cells));
    }

    return Column(children: rows);
  }
}
