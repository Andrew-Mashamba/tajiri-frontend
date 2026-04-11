// lib/sala/pages/create_prayer_page.dart
import 'package:flutter/material.dart';
import '../models/sala_models.dart';
import '../services/sala_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class CreatePrayerPage extends StatefulWidget {
  const CreatePrayerPage({super.key});
  @override
  State<CreatePrayerPage> createState() => _CreatePrayerPageState();
}

class _CreatePrayerPageState extends State<CreatePrayerPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _scriptureCtrl = TextEditingController();
  PrayerCategory _category = PrayerCategory.personal;
  PrayerUrgency _urgency = PrayerUrgency.medium;
  bool _isShared = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _scriptureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ombi Jipya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('New Prayer Request', style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kichwa / Title',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    decoration: _inputDecor('Andika kichwa cha ombi...'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Maelezo / Description',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: _inputDecor('Eleza ombi lako...'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Aya / Scripture',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _scriptureCtrl,
                    decoration: _inputDecor('Mf. Zaburi 23:1'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Aina / Category',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PrayerCategory.values.map((c) {
                      final sel = c == _category;
                      return GestureDetector(
                        onTap: () => setState(() => _category = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? _kPrimary : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? _kPrimary : Colors.grey.shade300),
                          ),
                          child: Text(c.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: sel ? Colors.white : _kPrimary,
                                fontWeight: FontWeight.w500,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Uharaka / Urgency',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: PrayerUrgency.values.map((u) {
                      final sel = u == _urgency;
                      final label = u == PrayerUrgency.low
                          ? 'Kawaida / Low'
                          : u == PrayerUrgency.medium
                              ? 'Wastani / Medium'
                              : 'Haraka / Urgent';
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: u != PrayerUrgency.high ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _urgency = u),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: sel ? _kPrimary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: sel ? _kPrimary : Colors.grey.shade300),
                              ),
                              alignment: Alignment.center,
                              child: Text(label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: sel ? Colors.white : _kPrimary,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _isShared,
                        onChanged: (v) => setState(() => _isShared = v ?? false),
                        activeColor: _kPrimary,
                      ),
                      const Expanded(
                        child: Text('Shiriki na jumuiya / Share with community',
                            style: TextStyle(fontSize: 14, color: _kPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hifadhi / Save',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary),
        ),
      );

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final r = await SalaService.createRequest({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'scripture_ref': _scriptureCtrl.text.trim(),
      'category': _category.name,
      'urgency': _urgency.name,
      'is_shared': _isShared,
    });
    if (mounted) {
      setState(() => _saving = false);
      if (r.success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.message ?? 'Imeshindwa kuhifadhi / Failed to save')),
        );
      }
    }
  }
}
