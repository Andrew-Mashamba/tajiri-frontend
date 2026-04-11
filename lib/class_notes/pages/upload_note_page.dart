// lib/class_notes/pages/upload_note_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/class_notes_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class UploadNotePage extends StatefulWidget {
  final int userId;
  const UploadNotePage({super.key, required this.userId});
  @override
  State<UploadNotePage> createState() => _UploadNotePageState();
}

class _UploadNotePageState extends State<UploadNotePage> {
  final _titleC = TextEditingController();
  final _subjectC = TextEditingController();
  final _topicC = TextEditingController();
  final _descC = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleC.dispose();
    _subjectC.dispose();
    _topicC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png'],
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
        const SnackBar(content: Text('Chagua faili kwanza / Select a file first')),
      );
      return;
    }
    if (_titleC.text.trim().isEmpty || _subjectC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza kichwa na somo / Fill title and subject')),
      );
      return;
    }
    setState(() => _isUploading = true);
    final result = await ClassNotesService().uploadNote(
      filePath: _selectedFilePath!,
      title: _titleC.text.trim(),
      subject: _subjectC.text.trim(),
      topic: _topicC.text.trim().isEmpty ? null : _topicC.text.trim(),
      description: _descC.text.trim().isEmpty ? null : _descC.text.trim(),
      semester: 'Semester 1',
      year: DateTime.now().year,
    );
    if (mounted) {
      setState(() => _isUploading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maelezo yamepakiwa! / Notes uploaded!')),
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
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Pakia Maelezo / Upload Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // File selector
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(_selectedFilePath != null ? Icons.check_circle_rounded : Icons.cloud_upload_rounded, size: 36, color: _kPrimary),
                const SizedBox(height: 8),
                Text(
                  _selectedFileName ?? 'Bonyeza kuchagua faili / Tap to select file',
                  style: TextStyle(color: _kPrimary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('PDF, picha, au hati / PDF, images, or docs', style: TextStyle(color: Color(0xFF999999), fontSize: 11)),
              ])),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _titleC, decoration: const InputDecoration(labelText: 'Kichwa / Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _subjectC, decoration: const InputDecoration(labelText: 'Somo / Subject', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _topicC, decoration: const InputDecoration(labelText: 'Mada / Topic (hiari / optional)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _descC, decoration: const InputDecoration(labelText: 'Maelezo / Description (hiari / optional)', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isUploading ? null : _upload,
            style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
            child: _isUploading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Pakia / Upload'),
          ),
        ]),
      ),
    );
  }
}
