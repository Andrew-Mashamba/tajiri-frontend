// lib/my_class/pages/create_class_page.dart
import 'package:flutter/material.dart';
import '../services/my_class_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class CreateClassPage extends StatefulWidget {
  final int userId;
  const CreateClassPage({super.key, required this.userId});
  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _codeC = TextEditingController();
  final _deptC = TextEditingController();
  final _instC = TextEditingController();
  String _semester = 'Semester 1';
  int _year = DateTime.now().year;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameC.dispose();
    _codeC.dispose();
    _deptC.dispose();
    _instC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final service = MyClassService();
    final result = await service.createClass(
      name: _nameC.text.trim(),
      courseCode: _codeC.text.trim(),
      semester: _semester,
      year: _year,
      department: _deptC.text.trim().isEmpty ? null : _deptC.text.trim(),
      institution: _instC.text.trim().isEmpty ? null : _instC.text.trim(),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Darasa limeundwa!')),
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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: const Text('Unda Darasa / Create Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameC,
                decoration: const InputDecoration(labelText: 'Jina la Darasa / Class Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Jaza jina' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _codeC,
                decoration: const InputDecoration(labelText: 'Nambari ya Somo / Course Code', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Jaza nambari' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _semester,
                decoration: const InputDecoration(labelText: 'Muhula / Semester', border: OutlineInputBorder()),
                items: ['Semester 1', 'Semester 2', 'Summer'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _semester = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _year,
                decoration: const InputDecoration(labelText: 'Mwaka / Year', border: OutlineInputBorder()),
                items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) => setState(() => _year = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _deptC,
                decoration: const InputDecoration(labelText: 'Idara / Department (hiari)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _instC,
                decoration: const InputDecoration(labelText: 'Chuo / Institution (hiari)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Unda Darasa / Create Class'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
