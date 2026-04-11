// lib/calendar/pages/add_event_page.dart
import 'package:flutter/material.dart';
import '../models/calendar_models.dart';
import '../services/calendar_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AddEventPage extends StatefulWidget {
  final int userId;
  final DateTime initialDate;
  final CalendarEvent? existingEvent;

  const AddEventPage({
    super.key,
    required this.userId,
    required this.initialDate,
    this.existingEvent,
  });

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final CalendarService _service = CalendarService();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  EventRepeat _repeat = EventRepeat.none;
  EventReminder _reminder = EventReminder.none;
  EventSource _source = EventSource.personal;
  bool _isSaving = false;

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_isEditing) {
      final e = widget.existingEvent!;
      _titleController.text = e.title;
      _notesController.text = e.notes ?? '';
      _selectedDate = e.date;
      _isAllDay = e.isAllDay;
      _repeat = e.repeat;
      _reminder = e.reminder;
      _source = e.source;
      if (e.startTime != null) {
        final parts = e.startTime!.split(':');
        if (parts.length >= 2) {
          _startTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      if (e.endTime != null) {
        final parts = e.endTime!.split(':');
        if (parts.length >= 2) {
          _endTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatTimeDisplay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final amPm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $amPm';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
            surface: _kCardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka jina la tukio')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final event = CalendarEvent(
      id: widget.existingEvent?.id ?? 0,
      userId: widget.userId,
      title: title,
      date: _selectedDate,
      startTime: _isAllDay ? null : (_startTime != null ? _formatTimeOfDay(_startTime!) : null),
      endTime: _isAllDay ? null : (_endTime != null ? _formatTimeOfDay(_endTime!) : null),
      isAllDay: _isAllDay,
      repeat: _repeat,
      reminder: _reminder,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      source: _source,
    );

    final CalendarResult<CalendarEvent> result;
    if (_isEditing) {
      result = await _service.updateEvent(widget.existingEvent!.id, event);
    } else {
      result = await _service.createEvent(event);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  _isEditing ? 'Tukio limebadilishwa' : 'Tukio limeundwa')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Badilisha Tukio' : 'Tukio Jipya',
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _isSaving ? null : _save,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEditing ? 'Hifadhi' : 'Unda',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          TextField(
            controller: _titleController,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
            decoration: const InputDecoration(
              hintText: 'Jina la tukio',
              hintStyle: TextStyle(color: _kSecondary),
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Date
          _buildOptionTile(
            icon: Icons.calendar_today_rounded,
            label: 'Tarehe',
            value: _formatDate(_selectedDate),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),

          // All day toggle
          _buildToggleTile(
            icon: Icons.wb_sunny_rounded,
            label: 'Siku Nzima',
            value: _isAllDay,
            onChanged: (v) => setState(() => _isAllDay = v),
          ),
          const SizedBox(height: 8),

          // Start / End time
          if (!_isAllDay) ...[
            _buildOptionTile(
              icon: Icons.access_time_rounded,
              label: 'Muda wa Kuanza',
              value: _startTime != null
                  ? _formatTimeDisplay(_startTime!)
                  : 'Chagua',
              onTap: _pickStartTime,
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              icon: Icons.access_time_filled_rounded,
              label: 'Muda wa Kuisha',
              value: _endTime != null
                  ? _formatTimeDisplay(_endTime!)
                  : 'Chagua',
              onTap: _pickEndTime,
            ),
            const SizedBox(height: 8),
          ],

          // Repeat
          _buildDropdownTile<EventRepeat>(
            icon: Icons.repeat_rounded,
            label: 'Rudia',
            value: _repeat,
            items: EventRepeat.values,
            displayName: (e) => '${e.displayName} (${e.subtitle})',
            onChanged: (v) => setState(() => _repeat = v),
          ),
          const SizedBox(height: 8),

          // Reminder
          _buildDropdownTile<EventReminder>(
            icon: Icons.notifications_outlined,
            label: 'Kikumbusho',
            value: _reminder,
            items: EventReminder.values,
            displayName: (e) => '${e.displayName} (${e.subtitle})',
            onChanged: (v) => setState(() => _reminder = v),
          ),
          const SizedBox(height: 8),

          // Source
          _buildDropdownTile<EventSource>(
            icon: Icons.label_outlined,
            label: 'Chanzo',
            value: _source,
            items: EventSource.values,
            displayName: (e) => '${e.displayName} (${e.subtitle})',
            onChanged: (v) => setState(() => _source = v),
          ),
          const SizedBox(height: 16),

          // Notes
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: _kPrimary),
              decoration: const InputDecoration(
                hintText: 'Maelezo ya ziada...',
                hintStyle: TextStyle(color: _kSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _kSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style:
                        const TextStyle(fontSize: 14, color: _kPrimary)),
              ),
              Text(value,
                  style: const TextStyle(fontSize: 14, color: _kSecondary)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, color: _kPrimary)),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _kPrimary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required IconData icon,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) displayName,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, color: _kPrimary)),
          ),
          DropdownButton<T>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.expand_more_rounded,
                size: 20, color: _kSecondary),
            style: const TextStyle(fontSize: 13, color: _kPrimary),
            items: items
                .map((e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text(displayName(e),
                          style: const TextStyle(
                              fontSize: 13, color: _kPrimary)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}
