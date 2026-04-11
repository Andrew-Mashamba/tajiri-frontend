// lib/career/pages/cv_builder_page.dart
import 'package:flutter/material.dart';
import '../models/career_models.dart';
import '../services/career_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CvBuilderPage extends StatefulWidget {
  final int userId;
  const CvBuilderPage({super.key, required this.userId});
  @override
  State<CvBuilderPage> createState() => _CvBuilderPageState();
}

class _CvBuilderPageState extends State<CvBuilderPage> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _summaryC = TextEditingController();
  final _educationC = TextEditingController();
  final _experienceC = TextEditingController();
  final _skillsC = TextEditingController();

  bool _isGenerating = false;

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _summaryC.dispose();
    _educationC.dispose();
    _experienceC.dispose();
    _skillsC.dispose();
    super.dispose();
  }

  Future<void> _generateCV() async {
    if (_nameC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza jina kamili / Fill in full name')),
      );
      return;
    }
    setState(() => _isGenerating = true);
    final sections = [
      CVSection(type: 'personal', fields: {
        'name': _nameC.text.trim(),
        'email': _emailC.text.trim(),
        'phone': _phoneC.text.trim(),
      }),
      CVSection(type: 'summary', fields: {'summary': _summaryC.text.trim()}),
      CVSection(type: 'education', fields: {'education': _educationC.text.trim()}),
      CVSection(type: 'experience', fields: {'experience': _experienceC.text.trim()}),
      CVSection(type: 'skills', fields: {'skills': _skillsC.text.trim()}),
    ];
    final result = await CareerService().generateCV(sections: sections);
    if (mounted) {
      setState(() => _isGenerating = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV imehifadhiwa! / CV saved!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kutengeneza CV / Failed to generate CV')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        title: const Text('CV Builder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _isGenerating ? null : _generateCV,
            child: _isGenerating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : const Text('Tengeneza / Generate', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _sectionHeader('Taarifa Binafsi', 'Personal Information'),
          TextFormField(controller: _nameC, decoration: const InputDecoration(labelText: 'Jina Kamili / Full Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextFormField(controller: _emailC, decoration: const InputDecoration(labelText: 'Barua Pepe / Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          TextFormField(controller: _phoneC, decoration: const InputDecoration(labelText: 'Simu / Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 20),

          _sectionHeader('Muhtasari', 'Professional Summary'),
          TextFormField(controller: _summaryC, decoration: const InputDecoration(labelText: 'Andika muhtasari wako...', border: OutlineInputBorder()), maxLines: 4),
          const SizedBox(height: 20),

          _sectionHeader('Elimu', 'Education'),
          TextFormField(controller: _educationC, decoration: const InputDecoration(labelText: 'Chuo, Shahada, Mwaka...', border: OutlineInputBorder(), hintText: 'UDSM, BSc Computer Science, 2020-2024'), maxLines: 3),
          const SizedBox(height: 20),

          _sectionHeader('Uzoefu wa Kazi', 'Work Experience'),
          TextFormField(controller: _experienceC, decoration: const InputDecoration(labelText: 'Kampuni, Nafasi, Muda...', border: OutlineInputBorder()), maxLines: 4),
          const SizedBox(height: 20),

          _sectionHeader('Ujuzi', 'Skills'),
          TextFormField(controller: _skillsC, decoration: const InputDecoration(labelText: 'Python, Excel, Kiswahili...', border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _isGenerating ? null : _generateCV,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Tengeneza PDF / Generate PDF'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              if (_nameC.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jaza taarifa kwanza / Fill in details first')),
                );
                return;
              }
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Muhtasari wa CV / CV Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(_nameC.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  if (_emailC.text.isNotEmpty) Text(_emailC.text, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  if (_phoneC.text.isNotEmpty) Text(_phoneC.text, style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  if (_summaryC.text.isNotEmpty) ...[const SizedBox(height: 12), const Text('Summary', style: TextStyle(fontWeight: FontWeight.w600)), Text(_summaryC.text)],
                  if (_educationC.text.isNotEmpty) ...[const SizedBox(height: 12), const Text('Education', style: TextStyle(fontWeight: FontWeight.w600)), Text(_educationC.text)],
                  if (_experienceC.text.isNotEmpty) ...[const SizedBox(height: 12), const Text('Experience', style: TextStyle(fontWeight: FontWeight.w600)), Text(_experienceC.text)],
                  if (_skillsC.text.isNotEmpty) ...[const SizedBox(height: 12), const Text('Skills', style: TextStyle(fontWeight: FontWeight.w600)), Text(_skillsC.text)],
                ])),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Funga / Close'))],
              ));
            },
            icon: const Icon(Icons.preview_rounded),
            label: const Text('Angalia / Preview'),
            style: OutlinedButton.styleFrom(foregroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          ),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String swahili, String english) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(swahili, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
        Text(english, style: const TextStyle(fontSize: 12, color: _kSecondary)),
      ]),
    );
  }
}
