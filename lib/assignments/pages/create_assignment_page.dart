// lib/assignments/pages/create_assignment_page.dart
import 'package:flutter/material.dart';
import '../models/assignments_models.dart';
import '../services/assignments_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class CreateAssignmentPage extends StatefulWidget {
  final int userId;
  const CreateAssignmentPage({super.key, required this.userId});
  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _subjectC = TextEditingController();
  AssignmentPriority _priority = AssignmentPriority.medium;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _subjectC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final result = await AssignmentsService().createAssignment(
      title: _titleC.text.trim(),
      description: _descC.text.trim(),
      subject: _subjectC.text.trim(),
      priority: _priority.name,
      dueDate: _dueDate,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kazi imeundwa!')));
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
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Unda Kazi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(controller: _titleC, decoration: const InputDecoration(labelText: 'Kichwa / Title', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Jaza' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _subjectC, decoration: const InputDecoration(labelText: 'Somo / Subject', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Jaza' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _descC, decoration: const InputDecoration(labelText: 'Maelezo / Description', border: OutlineInputBorder()), maxLines: 4),
          const SizedBox(height: 12),
          DropdownButtonFormField<AssignmentPriority>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Kipaumbele / Priority', border: OutlineInputBorder()),
            items: AssignmentPriority.values.map((p) => DropdownMenuItem(value: p, child: Text('${p.displayName} (${p.subtitle})'))).toList(),
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text('Tarehe: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Unda Kazi'),
          ),
        ]),
      ),
    );
  }
}
