// lib/past_papers/pages/upload_paper_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/past_papers_models.dart';
import '../services/past_papers_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class UploadPaperPage extends StatefulWidget {
  final int userId;
  const UploadPaperPage({super.key, required this.userId});
  @override
  State<UploadPaperPage> createState() => _UploadPaperPageState();
}

class _UploadPaperPageState extends State<UploadPaperPage> {
  final _subjectC = TextEditingController();
  final _instC = TextEditingController();
  EducationLevel _level = EducationLevel.degree;
  ExamType _examType = ExamType.endSemester;
  int _year = DateTime.now().year;
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _subjectC.dispose();
    _instC.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imeshindwa kuchagua faili / Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chagua PDF kwanza / Select a PDF first')),
      );
      return;
    }
    if (_subjectC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza somo / Fill in subject')),
      );
      return;
    }
    setState(() => _isUploading = true);
    final result = await PastPapersService().uploadPaper(
      filePath: _selectedFilePath!,
      subject: _subjectC.text.trim(),
      year: _year,
      level: _level.name,
      examType: _examType.name,
      institution: _instC.text.trim().isEmpty ? null : _instC.text.trim(),
    );
    if (mounted) {
      setState(() => _isUploading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mtihani umepakiwa! / Paper uploaded!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kupakia / Upload failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Pakia Mtihani / Upload Paper', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            height: 100,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(_selectedFilePath != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, size: 32, color: _kPrimary),
              const SizedBox(height: 6),
              Text(
                _selectedFileName ?? 'Chagua PDF / Select PDF',
                style: const TextStyle(color: _kPrimary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ])),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(controller: _subjectC, decoration: const InputDecoration(labelText: 'Somo / Subject', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<EducationLevel>(
          value: _level,
          decoration: const InputDecoration(labelText: 'Kiwango / Level', border: OutlineInputBorder()),
          items: EducationLevel.values.map((l) => DropdownMenuItem(value: l, child: Text(l.displayName))).toList(),
          onChanged: (v) => setState(() => _level = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ExamType>(
          value: _examType,
          decoration: const InputDecoration(labelText: 'Aina / Exam Type', border: OutlineInputBorder()),
          items: ExamType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
          onChanged: (v) => setState(() => _examType = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _year,
          decoration: const InputDecoration(labelText: 'Mwaka / Year', border: OutlineInputBorder()),
          items: List.generate(12, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
          onChanged: (v) => setState(() => _year = v!),
        ),
        const SizedBox(height: 12),
        TextFormField(controller: _instC, decoration: const InputDecoration(labelText: 'Chuo / Institution (hiari / optional)', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isUploading ? null : _upload,
          style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          child: _isUploading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Pakia / Upload'),
        ),
      ]),
    );
  }
}
