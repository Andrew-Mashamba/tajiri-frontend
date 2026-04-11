// lib/events/pages/edit_event_page.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../services/event_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EditEventPage extends StatefulWidget {
  final int userId;
  final Event event;

  const EditEventPage({
    super.key,
    required this.userId,
    required this.event,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final EventService _service = EventService();
  final _formKey = GlobalKey<FormState>();
  late EventStrings _strings;

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationNameController;
  late final TextEditingController _addressController;

  // State
  late EventCategory _category;
  late EventPrivacy _privacy;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');

    final e = widget.event;
    _nameController = TextEditingController(text: e.name);
    _descriptionController = TextEditingController(text: e.description ?? '');
    _locationNameController =
        TextEditingController(text: e.locationName ?? '');
    _addressController =
        TextEditingController(text: e.locationAddress ?? '');

    _category = e.category;
    _privacy = e.privacy;
    _startDate = e.startDate;
    _endDate = e.endDate;

    if (e.startTime != null) {
      final parts = e.startTime!.split(':');
      _startTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
    }

    if (e.endTime != null) {
      final parts = e.endTime!.split(':');
      _endTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 11,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : (_endTime ?? _startTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final fields = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _category.apiValue,
      'privacy': _privacy.apiValue,
      'start_date':
          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
      'start_time': _formatTimeOfDay(_startTime),
      if (_endDate != null)
        'end_date':
            '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
      if (_endTime != null) 'end_time': _formatTimeOfDay(_endTime!),
      if (_locationNameController.text.trim().isNotEmpty)
        'location_name': _locationNameController.text.trim(),
      if (_addressController.text.trim().isNotEmpty)
        'location_address': _addressController.text.trim(),
    };

    final result = await _service.updateEvent(
        eventId: widget.event.id, fields: fields);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_strings.isSwahili
            ? 'Tukio limehifadhiwa!'
            : 'Event updated!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context, result.data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ?? _strings.loadError),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(_strings.editEvent,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                _strings.isSwahili ? 'Hifadhi' : 'Save',
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Name ──
            _sectionLabel(_strings.eventName),
            const SizedBox(height: 6),
            _inputField(
              controller: _nameController,
              hint: _strings.eventName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_strings.isSwahili ? 'Jina linahitajika' : 'Name is required')
                  : null,
            ),
            const SizedBox(height: 16),

            // ── Description ──
            _sectionLabel(_strings.description),
            const SizedBox(height: 6),
            _inputField(
              controller: _descriptionController,
              hint: _strings.description,
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // ── Category ──
            _sectionLabel(_strings.category),
            const SizedBox(height: 6),
            _dropdownCard<EventCategory>(
              value: _category,
              items: EventCategory.values,
              label: (c) => '${c.displayName} · ${c.subtitle}',
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

            // ── Privacy ──
            _sectionLabel(_strings.privacy),
            const SizedBox(height: 6),
            _dropdownCard<EventPrivacy>(
              value: _privacy,
              items: EventPrivacy.values,
              label: (p) => '${p.displayName} · ${p.subtitle}',
              onChanged: (v) => setState(() => _privacy = v!),
            ),
            const SizedBox(height: 16),

            // ── Date & Time ──
            _sectionLabel(_strings.dateAndTime),
            const SizedBox(height: 6),
            _card(
              child: Column(
                children: [
                  _dateTimeRow(
                    label: _strings.startDate,
                    value:
                        _strings.formatDateShort(_startDate),
                    onTap: () => _pickDate(isStart: true),
                  ),
                  const Divider(height: 1),
                  _dateTimeRow(
                    label: _strings.startTime,
                    value: _startTime.format(context),
                    onTap: () => _pickTime(isStart: true),
                  ),
                  const Divider(height: 1),
                  _dateTimeRow(
                    label: _strings.endDate,
                    value: _endDate != null
                        ? _strings.formatDateShort(_endDate!)
                        : (_strings.isSwahili ? 'Chagua tarehe' : 'Select date'),
                    onTap: () => _pickDate(isStart: false),
                    optional: true,
                  ),
                  const Divider(height: 1),
                  _dateTimeRow(
                    label: _strings.endTime,
                    value: _endTime != null
                        ? _endTime!.format(context)
                        : (_strings.isSwahili ? 'Chagua muda' : 'Select time'),
                    onTap: () => _pickTime(isStart: false),
                    optional: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Location ──
            _sectionLabel(_strings.location),
            const SizedBox(height: 6),
            _inputField(
              controller: _locationNameController,
              hint: _strings.isSwahili ? 'Jina la mahali' : 'Venue name',
            ),
            const SizedBox(height: 8),
            _inputField(
              controller: _addressController,
              hint: _strings.address,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary));
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _kPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _dropdownCard<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: _kPrimary),
          dropdownColor: Colors.white,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(label(item),
                        style: const TextStyle(
                            fontSize: 14, color: _kPrimary),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _dateTimeRow({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool optional = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: optional ? _kSecondary : _kPrimary)),
            Row(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _kPrimary)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: _kSecondary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
