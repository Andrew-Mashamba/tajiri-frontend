// lib/traffic/pages/submit_report_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../services/traffic_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({super.key});
  @override
  State<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  bool _isSwahili = true;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _type = 'congestion';
  String _severity = 'medium';

  final _types = ['congestion', 'accident', 'roadwork', 'closure', 'hazard'];
  final _severities = ['low', 'medium', 'high'];

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

  String _typeLabel(String t) {
    if (_isSwahili) {
      switch (t) {
        case 'accident': return 'Ajali';
        case 'roadwork': return 'Ujenzi';
        case 'closure': return 'Barabara Imefungwa';
        case 'hazard': return 'Hatari';
        default: return 'Msongamano';
      }
    }
    return t[0].toUpperCase() + t.substring(1);
  }

  String _sevLabel(String s) {
    if (_isSwahili) {
      switch (s) {
        case 'high': return 'Kubwa';
        case 'low': return 'Ndogo';
        default: return 'Wastani';
      }
    }
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await TrafficService.submitReport({
      'type': _type,
      'description': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'severity': _severity,
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            _isSwahili ? 'Ripoti imetumwa!' : 'Report submitted!'),
      ));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(result.message ?? 'Error'),
      ));
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
            _isSwahili ? 'Ripoti Trafiki' : 'Report Traffic',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_isSwahili ? 'Aina' : 'Type',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _dec(''),
              items: _types
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'congestion'),
            ),
            const SizedBox(height: 16),
            Text(_isSwahili ? 'Ukubwa' : 'Severity',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _severity,
              decoration: _dec(''),
              items: _severities
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(_sevLabel(s))))
                  .toList(),
              onChanged: (v) => setState(() => _severity = v ?? 'medium'),
            ),
            const SizedBox(height: 16),
            Text(_isSwahili ? 'Eneo' : 'Location',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            TextFormField(controller: _locationCtrl, decoration: _dec(
                _isSwahili ? 'Mfano: Bagamoyo Rd, Kijitonyama' : 'e.g. Bagamoyo Rd, Kijitonyama')),
            const SizedBox(height: 16),
            Text(_isSwahili ? 'Maelezo' : 'Description',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: _dec(_isSwahili
                  ? 'Elezea hali ya barabara...'
                  : 'Describe the situation...'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isSwahili ? 'Tafadhali elezea' : 'Required')
                  : null,
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
}
