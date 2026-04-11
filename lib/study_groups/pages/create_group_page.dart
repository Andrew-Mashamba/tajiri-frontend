// lib/study_groups/pages/create_group_page.dart
import 'package:flutter/material.dart';
import '../services/study_groups_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBg = Color(0xFFFAFAFA);

class CreateGroupPage extends StatefulWidget {
  final int userId;
  const CreateGroupPage({super.key, required this.userId});
  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameC = TextEditingController();
  final _subjectC = TextEditingController();
  final _descC = TextEditingController();
  int _maxMembers = 8;
  bool _isPublic = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameC.dispose();
    _subjectC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameC.text.trim().isEmpty || _subjectC.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final result = await StudyGroupsService().createGroup(
      name: _nameC.text.trim(),
      subject: _subjectC.text.trim(),
      description: _descC.text.trim().isEmpty ? null : _descC.text.trim(),
      maxMembers: _maxMembers,
      isPublic: _isPublic,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kikundi kimeundwa! / Group created!')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa kuunda / Failed to create group')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Unda Kikundi / Create Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextFormField(controller: _nameC, decoration: const InputDecoration(labelText: 'Jina la Kikundi / Group Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextFormField(controller: _subjectC, decoration: const InputDecoration(labelText: 'Somo / Subject', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextFormField(controller: _descC, decoration: const InputDecoration(labelText: 'Maelezo / Description (hiari)', border: OutlineInputBorder()), maxLines: 3),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _maxMembers,
          decoration: const InputDecoration(labelText: 'Wanachama wa Juu / Max Members', border: OutlineInputBorder()),
          items: [4, 6, 8, 10, 12].map((m) => DropdownMenuItem(value: m, child: Text('$m'))).toList(),
          onChanged: (v) => setState(() => _maxMembers = v!),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Wazi kwa wote / Public', style: TextStyle(fontSize: 14)),
          subtitle: const Text('Yeyote anaweza kujiunga', style: TextStyle(fontSize: 12)),
          value: _isPublic,
          activeColor: _kPrimary,
          onChanged: (v) => setState(() => _isPublic = v),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Unda Kikundi'),
        ),
      ]),
    );
  }
}
