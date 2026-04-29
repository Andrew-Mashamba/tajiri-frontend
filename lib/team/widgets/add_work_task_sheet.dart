// lib/team/widgets/add_work_task_sheet.dart
import 'package:flutter/material.dart';
import '../models/team_models.dart';
import '../services/work_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class AddWorkTaskSheet extends StatefulWidget {
  final String token;
  final int businessId;
  final int? preselectedEmployeeId;
  final String? preselectedEmployeeName;
  final List<Employee> employees;
  final VoidCallback onSaved;
  final bool sw;

  const AddWorkTaskSheet({
    super.key,
    required this.token,
    required this.businessId,
    this.preselectedEmployeeId,
    this.preselectedEmployeeName,
    required this.employees,
    required this.onSaved,
    required this.sw,
  });

  @override
  State<AddWorkTaskSheet> createState() => _AddWorkTaskSheetState();
}

class _AddWorkTaskSheetState extends State<AddWorkTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _taskType = 'adhoc';
  String? _recurrence;
  final List<int> _customDays = [];
  DateTime? _dueDate;
  int? _selectedEmployeeId;
  bool _saving = false;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.preselectedEmployeeId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_taskType == 'standing' && _recurrence == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.sw ? 'Chagua mpangilio wa kurudia' : 'Select recurrence pattern')));
      return;
    }
    if (_taskType == 'adhoc' && _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.sw ? 'Chagua tarehe ya mwisho' : 'Select a due date')));
      return;
    }
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.sw ? 'Chagua mfanyakazi' : 'Select an employee')));
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final body = {
      'employee_id': _selectedEmployeeId,
      'business_id': widget.businessId,
      'title': _titleCtrl.text.trim(),
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      'task_type': _taskType,
      if (_taskType == 'standing') 'recurrence': _recurrence,
      if (_taskType == 'standing' && _recurrence == 'custom' && _customDays.isNotEmpty)
        'recurrence_days': _customDays,
      if (_taskType == 'adhoc' && _dueDate != null)
        'due_date': '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}',
      'assigned_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    };

    final res = await WorkService.createTask(widget.token, body);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.sw ? 'Kazi imegawiwa' : 'Task assigned')));
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ??
              (widget.sw ? 'Imeshindwa kugawanya kazi. Jaribu tena.' : 'Failed to assign task. Try again.')),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final hasPreselected = widget.preselectedEmployeeId != null;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Gawanya Kazi' : 'Assign Task',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimary)),
            const SizedBox(height: 16),

            if (!hasPreselected) ...[
              DropdownButtonFormField<int>(
                initialValue: _selectedEmployeeId,
                decoration: InputDecoration(
                  labelText: sw ? 'Mfanyakazi' : 'Employee',
                  border: const OutlineInputBorder(),
                ),
                items: widget.employees
                    .where((e) => e.isActive)
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedEmployeeId = v),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Kichwa cha Kazi' : 'Task Title',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (sw ? 'Weka kichwa cha kazi' : 'Enter task title') : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo (hiari)' : 'Description (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Text(sw ? 'Aina ya Kazi' : 'Task Type',
                style: const TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'standing', label: Text(sw ? 'Kawaida' : 'Standing')),
                ButtonSegment(value: 'adhoc', label: Text(sw ? 'Maalum' : 'Ad-hoc')),
              ],
              selected: {_taskType},
              onSelectionChanged: (s) =>
                  setState(() { _taskType = s.first; _recurrence = null; }),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                    states.contains(WidgetState.selected) ? _kPrimary : null),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) =>
                    states.contains(WidgetState.selected) ? Colors.white : _kPrimary),
              ),
            ),
            const SizedBox(height: 12),

            if (_taskType == 'standing') ...[
              Text(sw ? 'Mpangilio wa Kurudia' : 'Recurrence',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final r in ['daily', 'weekly', 'weekdays', 'custom'])
                  ChoiceChip(
                    label: Text(sw
                        ? (r == 'daily' ? 'Kila Siku' : r == 'weekly' ? 'Kila Wiki'
                            : r == 'weekdays' ? 'Siku za Kazi' : 'Maalum')
                        : (r == 'daily' ? 'Daily' : r == 'weekly' ? 'Weekly'
                            : r == 'weekdays' ? 'Weekdays' : 'Custom'),
                        style: const TextStyle(fontSize: 12)),
                    selected: _recurrence == r,
                    onSelected: (_) => setState(() => _recurrence = r),
                    selectedColor: _kPrimary,
                    labelStyle: TextStyle(color: _recurrence == r ? Colors.white : _kPrimary),
                  ),
              ]),
              if (_recurrence == 'custom') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final selected = _customDays.contains(day);
                    return GestureDetector(
                      onTap: () => setState(() {
                        selected ? _customDays.remove(day) : _customDays.add(day);
                      }),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: selected ? _kPrimary : Colors.grey.shade200,
                        child: Text(_dayLabels[i],
                            style: TextStyle(
                                fontSize: 11,
                                color: selected ? Colors.white : _kPrimary,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 12),
            ],

            if (_taskType == 'adhoc') ...[
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(_dueDate != null
                    ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                    : (sw ? 'Chagua Tarehe ya Mwisho' : 'Select Due Date')),
                style: OutlinedButton.styleFrom(foregroundColor: _kPrimary),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48)),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(sw ? 'Gawanya' : 'Assign'),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
