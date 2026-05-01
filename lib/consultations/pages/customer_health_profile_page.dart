import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_i_services.dart';

/// Spec F7 #14 — Persistent customer health profile.
class CustomerHealthProfilePage extends StatefulWidget {
  final int userId;
  const CustomerHealthProfilePage({super.key, required this.userId});

  @override
  State<CustomerHealthProfilePage> createState() =>
      _CustomerHealthProfilePageState();
}

class _CustomerHealthProfilePageState extends State<CustomerHealthProfilePage> {
  final _allergiesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  DateTime? _dob;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _bloodCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await HealthProfileService.show(widget.userId);
    if (!mounted) return;
    if (p != null) {
      _allergiesCtrl.text = (p['allergies_json'] is List)
          ? (p['allergies_json'] as List).join(', ')
          : '';
      _conditionsCtrl.text = (p['chronic_conditions_json'] is List)
          ? (p['chronic_conditions_json'] as List).join(', ')
          : '';
      _bloodCtrl.text = p['blood_type']?.toString() ?? '';
      if (p['date_of_birth'] != null) {
        _dob = DateTime.tryParse(p['date_of_birth'].toString())?.toLocal();
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await HealthProfileService.save(
      userId: widget.userId,
      allergies: _allergiesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      chronicConditions: _conditionsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      dateOfBirth: _dob,
      bloodType: _bloodCtrl.text.trim().isEmpty ? null : _bloodCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Imehifadhiwa' : 'Imeshindikana')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(isSw ? 'Wasifu wa afya' : 'Health profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _allergiesCtrl,
                  decoration: InputDecoration(
                    labelText: isSw
                        ? 'Mzio (tenganisha kwa koma)'
                        : 'Allergies (comma-separated)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _conditionsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: isSw
                        ? 'Magonjwa ya muda mrefu (kisukari, n.k.)'
                        : 'Chronic conditions (diabetes, etc.)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bloodCtrl,
                  decoration: InputDecoration(
                    labelText: isSw ? 'Aina ya damu' : 'Blood type',
                    hintText: 'A+, B-, O+, AB+, …',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cake_rounded),
                  title: Text(isSw ? 'Tarehe ya kuzaliwa' : 'Date of birth'),
                  subtitle: Text(_dob == null
                      ? '—'
                      : '${_dob!.day}/${_dob!.month}/${_dob!.year}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dob ?? DateTime(1995, 1, 1),
                        firstDate: DateTime(1925, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                    child: Text(isSw ? 'Chagua' : 'Pick'),
                  ),
                ),
              ],
            ),
    );
  }
}
