// lib/dawasco/pages/report_issue_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});
  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String _type = 'leak';
  String _severity = 'medium';
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;
  File? _photo;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 80);
      if (xFile != null && mounted) {
        setState(() => _photo = File(xFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw ? 'Imeshindwa kuchukua picha' : 'Failed to take photo')));
    }
  }

  Future<void> _submit() async {
    final sw = _sw;
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sw ? 'Andika maelezo ya tatizo' : 'Enter issue description')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await DawascoService.reportIssue({
        'type': _type,
        'severity': _severity,
        'location': _locationCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      }, photoPath: _photo?.path);
      if (!mounted) return;
      setState(() => _submitting = false);
      final messenger = ScaffoldMessenger.of(context);
      if (result.success) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Taarifa imewasilishwa!' : 'Report submitted!')));
        Navigator.pop(context, true);
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(result.message ?? (sw ? 'Imeshindwa' : 'Failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Ripoti Tatizo' : 'Report Issue',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(sw ? 'Aina ya Tatizo' : 'Issue Type',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip(sw ? 'Uvujaji' : 'Leak', 'leak'),
          _chip(sw ? 'Maji taka' : 'Sewerage', 'sewerage'),
          _chip(sw ? 'Ubora' : 'Quality', 'quality'),
          _chip(sw ? 'Shinikizo' : 'Pressure', 'pressure'),
        ]),
        const SizedBox(height: 16),
        Text(sw ? 'Ukubwa' : 'Severity',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _sevChip(sw ? 'Ndogo' : 'Low', 'low'),
          _sevChip(sw ? 'Wastani' : 'Medium', 'medium'),
          _sevChip(sw ? 'Kubwa' : 'High', 'high'),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _locationCtrl,
          decoration: InputDecoration(
            hintText: sw ? 'Mahali / Eneo' : 'Location / Area',
            hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: sw ? 'Maelezo ya tatizo...' : 'Describe the issue...',
            hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 14, color: _kPrimary),
        ),
        const SizedBox(height: 16),

        // Photo section
        Text(sw ? 'Picha (hiari)' : 'Photo (optional)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            height: _photo != null ? 200 : 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
            ),
            child: _photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(children: [
                      Image.file(_photo!, width: double.infinity, height: 200, fit: BoxFit.cover),
                      Positioned(top: 8, right: 8, child: GestureDetector(
                        onTap: () => setState(() => _photo = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      )),
                    ]),
                  )
                : Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.camera_alt_rounded, size: 28, color: _kPrimary.withValues(alpha: 0.4)),
                      const SizedBox(height: 4),
                      Text(sw ? 'Piga picha' : 'Take photo',
                          style: TextStyle(fontSize: 12, color: _kPrimary.withValues(alpha: 0.5))),
                    ]),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48, width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(sw ? 'Wasilisha Taarifa' : 'Submit Report',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, String value) => ChoiceChip(
    label: Text(label, style: TextStyle(fontSize: 12, color: _type == value ? Colors.white : _kPrimary)),
    selected: _type == value, onSelected: (_) => setState(() => _type = value),
    selectedColor: _kPrimary, backgroundColor: Colors.white,
  );

  Widget _sevChip(String label, String value) => ChoiceChip(
    label: Text(label, style: TextStyle(fontSize: 12, color: _severity == value ? Colors.white : _kPrimary)),
    selected: _severity == value, onSelected: (_) => setState(() => _severity = value),
    selectedColor: _kPrimary, backgroundColor: Colors.white,
  );
}
