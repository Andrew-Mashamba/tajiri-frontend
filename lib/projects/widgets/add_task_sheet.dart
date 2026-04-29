// lib/projects/widgets/add_task_sheet.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../team/models/team_models.dart';
import '../../team/services/team_service.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class AddTaskSheet extends StatefulWidget {
  final String token;
  final int projectId;
  final int businessId;
  final Task? task;
  final VoidCallback onSaved;

  const AddTaskSheet({
    super.key,
    required this.token,
    required this.projectId,
    required this.businessId,
    this.task,
    required this.onSaved,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;
  int? _assigneeId;
  int? _pendingAssigneeId; // holds task assigneeId until employees load
  List<Employee> _employees = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _status = t?.status ?? TaskStatus.todo;
    _dueDate = t?.dueDate;
    _pendingAssigneeId = t?.assigneeId;
    // _assigneeId stays null until employees load (avoids dropdown assertion)
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final res = await TeamService.getEmployees(widget.token, widget.businessId);
    if (mounted && res.success) {
      // Deduplicate by id to avoid dropdown assertion
      final seen = <int>{};
      final unique = res.data
          .where((e) => e.id != null && seen.add(e.id!))
          .toList();
      setState(() {
        _employees = unique;
        // Resolve pending assignee once we know the valid set
        _assigneeId = unique.any((e) => e.id == _pendingAssigneeId)
            ? _pendingAssigneeId
            : null;
      });
    }
  }

  Future<void> _pickDate(bool sw) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  String _priorityLabel(TaskPriority p, bool sw) {
    switch (p) {
      case TaskPriority.low:
        return sw ? 'Chini' : 'Low';
      case TaskPriority.medium:
        return sw ? 'Kati' : 'Medium';
      case TaskPriority.high:
        return sw ? 'Juu' : 'High';
    }
  }

  String _statusLabel(TaskStatus s, bool sw) {
    switch (s) {
      case TaskStatus.todo:
        return sw ? 'Kusubiri' : 'To-Do';
      case TaskStatus.inProgress:
        return sw ? 'Inaendelea' : 'In Progress';
      case TaskStatus.done:
        return sw ? 'Imekamilika' : 'Done';
    }
  }

  Future<void> _save(bool sw) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw
              ? 'Tafadhali weka jina la kazi'
              : 'Please enter a task title')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    // If employees haven't loaded yet, keep the original assignee
    final effectiveAssigneeId =
        _employees.isEmpty ? _pendingAssigneeId : _assigneeId;
    final String? assigneeName = effectiveAssigneeId == null
        ? null
        : _employees
            .where((e) => e.id == effectiveAssigneeId)
            .map((e) => e.name)
            .firstOrNull;

    final body = {
      'project_id': widget.projectId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'assignee_id': effectiveAssigneeId,
      'assignee_name': assigneeName,
      'due_date': _dueDate?.toIso8601String(),
      'priority': switch (_priority) {
        TaskPriority.low => 'low',
        TaskPriority.medium => 'medium',
        TaskPriority.high => 'high',
      },
      'status': switch (_status) {
        TaskStatus.todo => 'todo',
        TaskStatus.inProgress => 'in_progress',
        TaskStatus.done => 'done',
      },
    };
    try {
      final bool success;
      String? msg;
      if (widget.task == null) {
        final res =
            await ProjectService.createTask(widget.token, body);
        success = res.success;
        msg = res.message;
      } else {
        final res = await ProjectService.updateTask(
            widget.token, widget.task!.id!, body);
        success = res.success;
        msg = res.message;
      }
      if (!mounted) return;
      nav.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(success
              ? (sw ? 'Imehifadhiwa' : 'Saved')
              : (msg ?? (sw ? 'Imeshindikana' : 'Failed')))));
      if (success) widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(
            content: Text(
                sw ? 'Imeshindikana' : 'An error occurred')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.task == null
                  ? (sw ? 'Kazi Mpya' : 'New Task')
                  : (sw ? 'Hariri Kazi' : 'Edit Task'),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: sw ? 'Jina la Kazi' : 'Task Title',
                prefixIcon: const Icon(Icons.task_rounded,
                    size: 20, color: _kSecondary),
                filled: true,
                fillColor: _kBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo' : 'Description',
                filled: true,
                fillColor: _kBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              initialValue: _assigneeId,
              decoration: InputDecoration(
                labelText: sw ? 'Mwanatimu' : 'Assignee',
                prefixIcon: const Icon(Icons.person_rounded,
                    size: 20, color: _kSecondary),
                filled: true,
                fillColor: _kBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: [
                DropdownMenuItem<int?>(
                    value: null,
                    child: Text(sw ? 'Hakuna' : 'Unassigned')),
                ..._employees.map((e) => DropdownMenuItem<int?>(
                      value: e.id,
                      child: Text(e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<TaskPriority>(
              initialValue: _priority,
              decoration: InputDecoration(
                labelText: sw ? 'Kipaumbele' : 'Priority',
                prefixIcon: const Icon(Icons.flag_rounded,
                    size: 20, color: _kSecondary),
                filled: true,
                fillColor: _kBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: TaskPriority.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(_priorityLabel(p, sw)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _priority = v ?? TaskPriority.medium),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<TaskStatus>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: sw ? 'Hali' : 'Status',
                prefixIcon: const Icon(Icons.checklist_rounded,
                    size: 20, color: _kSecondary),
                filled: true,
                fillColor: _kBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              items: TaskStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statusLabel(s, sw)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _status = v ?? TaskStatus.todo),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _pickDate(sw),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText:
                      sw ? 'Tarehe ya Mwisho' : 'Due Date',
                  prefixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: _kSecondary),
                  filled: true,
                  fillColor: _kBackground,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                child: Text(
                  _dueDate != null
                      ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                      : '—',
                  style: TextStyle(
                      fontSize: 14,
                      color: _dueDate != null
                          ? _kPrimary
                          : Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _save(sw),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
