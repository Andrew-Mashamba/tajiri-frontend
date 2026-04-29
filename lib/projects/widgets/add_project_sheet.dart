// lib/projects/widgets/add_project_sheet.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/project_models.dart';
import '../services/project_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class AddProjectSheet extends StatefulWidget {
  final String token;
  final int businessId;
  final Project? project;
  final VoidCallback onSaved;

  const AddProjectSheet({
    super.key,
    required this.token,
    required this.businessId,
    this.project,
    required this.onSaved,
  });

  @override
  State<AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends State<AddProjectSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late ProjectStatus _status;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  static const _statuses = [
    ProjectStatus.active,
    ProjectStatus.onHold,
    ProjectStatus.completed,
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _status = p?.status ?? ProjectStatus.active;
    _startDate = p?.startDate;
    _endDate = p?.endDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _statusLabel(ProjectStatus s, bool sw) {
    switch (s) {
      case ProjectStatus.active:
        return sw ? 'Inafanya Kazi' : 'Active';
      case ProjectStatus.completed:
        return sw ? 'Imekamilika' : 'Completed';
      case ProjectStatus.onHold:
        return sw ? 'Imesimamishwa' : 'On Hold';
    }
  }

  String _statusValue(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.active:
        return 'active';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.onHold:
        return 'on_hold';
    }
  }

  Future<void> _pickDate(bool isStart, bool sw) async {
    final initial =
        (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save(bool sw) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw
              ? 'Tafadhali weka jina la mradi'
              : 'Please enter a project title')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final body = {
      'business_id': widget.businessId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'status': _statusValue(_status),
      'start_date': _startDate?.toIso8601String(),
      'end_date': _endDate?.toIso8601String(),
    };
    try {
      final bool success;
      String? msg;
      if (widget.project == null) {
        final res =
            await ProjectService.createProject(widget.token, body);
        success = res.success;
        msg = res.message;
      } else {
        final res = await ProjectService.updateProject(
            widget.token, widget.project!.id!, body);
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

  Widget _dateRow(
      String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded,
              size: 18, color: _kSecondary),
          filled: true,
          fillColor: _kBackground,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
        child: Text(
          date != null
              ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
              : '—',
          style: TextStyle(
              fontSize: 14,
              color: date != null
                  ? _kPrimary
                  : Colors.grey.shade400),
        ),
      ),
    );
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
              widget.project == null
                  ? (sw ? 'Mradi Mpya' : 'New Project')
                  : (sw ? 'Hariri Mradi' : 'Edit Project'),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText:
                    sw ? 'Jina la Mradi' : 'Project Title',
                prefixIcon: const Icon(Icons.folder_rounded,
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
              maxLines: 3,
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
            DropdownButtonFormField<ProjectStatus>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: sw ? 'Hali' : 'Status',
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
              items: _statuses
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statusLabel(s, sw)),
                      ))
                  .toList(),
              onChanged: (v) => setState(
                  () => _status = v ?? ProjectStatus.active),
            ),
            const SizedBox(height: 10),
            _dateRow(
              sw ? 'Tarehe ya Kuanza' : 'Start Date',
              _startDate,
              () => _pickDate(true, sw),
            ),
            const SizedBox(height: 10),
            _dateRow(
              sw ? 'Tarehe ya Mwisho' : 'End Date',
              _endDate,
              () => _pickDate(false, sw),
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
