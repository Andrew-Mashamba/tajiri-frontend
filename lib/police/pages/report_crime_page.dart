// lib/police/pages/report_crime_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../services/police_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ReportCrimePage extends StatefulWidget {
  const ReportCrimePage({super.key});
  @override
  State<ReportCrimePage> createState() => _ReportCrimePageState();
}

class _ReportCrimePageState extends State<ReportCrimePage> {
  bool _isSwahili = true;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _incidentType = 'theft';

  final _incidentTypes = [
    'theft',
    'assault',
    'robbery',
    'burglary',
    'fraud',
    'vandalism',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _typeLabel(String type) {
    if (_isSwahili) {
      switch (type) {
        case 'theft':
          return 'Wizi';
        case 'assault':
          return 'Shambulio';
        case 'robbery':
          return 'Ujambazi';
        case 'burglary':
          return 'Kuvunja Nyumba';
        case 'fraud':
          return 'Ulaghai';
        case 'vandalism':
          return 'Uharibifu';
        default:
          return 'Mengineyo';
      }
    }
    return type[0].toUpperCase() + type.substring(1);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await PoliceService.submitReport({
      'incident_type': _incidentType,
      'description': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Ripoti imetumwa kikamilifu!'
            : 'Report submitted successfully!'),
      ));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(result.message ??
            (_isSwahili ? 'Imeshindwa kutuma' : 'Failed to submit')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(_isSwahili ? 'Ripoti Tukio' : 'Report Crime',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_isSwahili ? 'Aina ya Tukio' : 'Incident Type',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _incidentType,
              decoration: _inputDecoration(''),
              items: _incidentTypes
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_typeLabel(t))))
                  .toList(),
              onChanged: (v) => setState(() => _incidentType = v ?? 'theft'),
            ),
            const SizedBox(height: 16),
            Text(_isSwahili ? 'Maelezo' : 'Description',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: _inputDecoration(_isSwahili
                  ? 'Elezea tukio kwa kina...'
                  : 'Describe the incident in detail...'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isSwahili ? 'Tafadhali elezea' : 'Please describe')
                  : null,
            ),
            const SizedBox(height: 16),
            Text(_isSwahili ? 'Eneo' : 'Location',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              decoration: _inputDecoration(
                  _isSwahili ? 'Wapi tukio lilitokea?' : 'Where did it happen?'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isSwahili ? 'Tuma Ripoti' : 'Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
