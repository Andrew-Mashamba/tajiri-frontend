// lib/neighbourhood_watch/pages/report_incident_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../services/neighbourhood_watch_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});
  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  bool _isSwahili = true;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _type = 'suspicious';
  String _urgency = 'medium';

  final _types = ['suspicious', 'theft', 'break_in', 'noise', 'fire', 'other'];
  final _urgencies = ['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  String _typeLabel(String t) {
    if (_isSwahili) {
      switch (t) {
        case 'suspicious': return 'Tukio la Shaka';
        case 'theft': return 'Wizi';
        case 'break_in': return 'Kuvunja Nyumba';
        case 'noise': return 'Kelele';
        case 'fire': return 'Moto';
        default: return 'Mengineyo';
      }
    }
    return t.replaceAll('_', ' ').split(' ').map(
        (w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  String _urgLabel(String u) {
    if (_isSwahili) {
      switch (u) {
        case 'critical': return 'Dharura';
        case 'high': return 'Kubwa';
        case 'low': return 'Ndogo';
        default: return 'Wastani';
      }
    }
    return u[0].toUpperCase() + u.substring(1);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await NeighbourhoodWatchService.submitAlert({
      'type': _type,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'urgency': _urgency,
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Tahadhari imetumwa!' : 'Alert submitted!'),
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
        title: Text(_isSwahili ? 'Ripoti Tukio' : 'Report Incident',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label(_isSwahili ? 'Aina' : 'Type'),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _dec(''),
              items: _types
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_typeLabel(t))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? 'suspicious'),
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Dharura' : 'Urgency'),
            DropdownButtonFormField<String>(
              value: _urgency,
              decoration: _dec(''),
              items: _urgencies
                  .map((u) => DropdownMenuItem(
                      value: u, child: Text(_urgLabel(u))))
                  .toList(),
              onChanged: (v) => setState(() => _urgency = v ?? 'medium'),
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Kichwa' : 'Title'),
            TextFormField(
              controller: _titleCtrl,
              decoration: _dec(_isSwahili ? 'Kichwa cha tahadhari' : 'Alert title'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isSwahili ? 'Lazima' : 'Required')
                  : null,
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Maelezo' : 'Description'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: _dec(_isSwahili ? 'Elezea...' : 'Describe...'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isSwahili ? 'Lazima' : 'Required')
                  : null,
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Eneo' : 'Location'),
            TextFormField(
              controller: _locationCtrl,
              decoration: _dec(_isSwahili ? 'Eneo la tukio' : 'Incident location'),
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
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isSwahili ? 'Tuma Tahadhari' : 'Submit Alert'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
      );
}
