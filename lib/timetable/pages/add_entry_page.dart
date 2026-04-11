// lib/timetable/pages/add_entry_page.dart
import 'package:flutter/material.dart';
import '../models/timetable_models.dart';
import '../services/timetable_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class AddEntryPage extends StatefulWidget {
  final int userId;
  const AddEntryPage({super.key, required this.userId});
  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectC = TextEditingController();
  final _codeC = TextEditingController();
  final _lecturerC = TextEditingController();
  final _roomC = TextEditingController();
  final _buildingC = TextEditingController();
  SchoolDay _day = SchoolDay.monday;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSaving = false;

  @override
  void dispose() {
    _subjectC.dispose();
    _codeC.dispose();
    _lecturerC.dispose();
    _roomC.dispose();
    _buildingC.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime);
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final result = await TimetableService().addEntry(
      subject: _subjectC.text.trim(),
      courseCode: _codeC.text.trim(),
      lecturer: _lecturerC.text.trim(),
      room: _roomC.text.trim(),
      building: _buildingC.text.trim().isEmpty ? null : _buildingC.text.trim(),
      day: _day.name,
      startTime: _fmtTime(_startTime),
      endTime: _fmtTime(_endTime),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kipindi kimeongezwa!')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Ongeza Kipindi / Add Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(controller: _subjectC, decoration: const InputDecoration(labelText: 'Somo / Subject', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Jaza' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _codeC, decoration: const InputDecoration(labelText: 'Nambari / Code', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Jaza' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _lecturerC, decoration: const InputDecoration(labelText: 'Mhadhiri / Lecturer', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextFormField(controller: _roomC, decoration: const InputDecoration(labelText: 'Chumba / Room', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Jaza' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _buildingC, decoration: const InputDecoration(labelText: 'Jengo / Building (hiari)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<SchoolDay>(
              value: _day,
              decoration: const InputDecoration(labelText: 'Siku / Day', border: OutlineInputBorder()),
              items: SchoolDay.values.map((d) => DropdownMenuItem(value: d, child: Text(d.displayName))).toList(),
              onChanged: (v) => setState(() => _day = v!),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => _pickTime(true), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), child: Text('Kuanza: ${_fmtTime(_startTime)}'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(onPressed: () => _pickTime(false), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), child: Text('Kuisha: ${_fmtTime(_endTime)}'))),
            ]),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
              child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Hifadhi'),
            ),
          ]),
        ),
      ),
    );
  }
}
