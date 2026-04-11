// lib/results/pages/add_grade_page.dart
import 'package:flutter/material.dart';
import '../services/results_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class AddGradePage extends StatefulWidget {
  final int userId;
  const AddGradePage({super.key, required this.userId});
  @override
  State<AddGradePage> createState() => _AddGradePageState();
}

class _AddGradePageState extends State<AddGradePage> {
  final _nameC = TextEditingController();
  final _codeC = TextEditingController();
  final _creditsC = TextEditingController();
  String _grade = 'A';
  bool _isSaving = false;

  static const _grades = ['A', 'B+', 'B', 'C', 'D', 'E', 'F'];
  static const _points = {'A': 5.0, 'B+': 4.0, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'E': 0.5, 'F': 0.0};

  @override
  void dispose() {
    _nameC.dispose();
    _codeC.dispose();
    _creditsC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameC.text.trim().isEmpty || _codeC.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final result = await ResultsService().addGrade(
      courseName: _nameC.text.trim(),
      courseCode: _codeC.text.trim(),
      grade: _grade,
      gradePoint: _points[_grade] ?? 0,
      creditHours: int.tryParse(_creditsC.text) ?? 3,
      semesterId: 1,
      semester: 'Semester 1',
      year: DateTime.now().year,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alama imeongezwa! / Grade added!')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa kuongeza / Failed to add grade')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Ongeza Alama / Add Grade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _nameC, decoration: const InputDecoration(labelText: 'Jina la Somo / Course Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextFormField(controller: _codeC, decoration: const InputDecoration(labelText: 'Nambari / Course Code', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _grade,
          decoration: const InputDecoration(labelText: 'Alama / Grade', border: OutlineInputBorder()),
          items: _grades.map((g) => DropdownMenuItem(value: g, child: Text('$g (${_points[g]})'))).toList(),
          onChanged: (v) => setState(() => _grade = v!),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _creditsC, decoration: const InputDecoration(labelText: 'Credit Hours', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Hifadhi'),
        ),
      ]),
    );
  }
}
