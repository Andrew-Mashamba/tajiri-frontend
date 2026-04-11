// lib/latra/pages/complaint_form_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../services/latra_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({super.key});
  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  bool _isSwahili = true;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();
  String _type = 'overcharging';

  final _types = ['overcharging', 'reckless', 'harassment', 'other'];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _plateCtrl.dispose();
    _routeCtrl.dispose();
    super.dispose();
  }

  String _typeLabel(String t) {
    if (_isSwahili) {
      switch (t) {
        case 'overcharging': return 'Kupandisha Bei';
        case 'reckless': return 'Uendeshaji Hatari';
        case 'harassment': return 'Unyanyasaji';
        default: return 'Mengineyo';
      }
    }
    return t[0].toUpperCase() + t.substring(1);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final result = await LatraService.submitComplaint({
      'type': _type,
      'description': _descCtrl.text.trim(),
      if (_plateCtrl.text.isNotEmpty) 'plate_number': _plateCtrl.text.trim(),
      if (_routeCtrl.text.isNotEmpty) 'route_name': _routeCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      messenger.showSnackBar(SnackBar(
        content: Text(
            _isSwahili ? 'Lalamiko limetumwa!' : 'Complaint submitted!'),
      ));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')));
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
        title: Text(_isSwahili ? 'Lalamiko' : 'File Complaint',
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
              onChanged: (v) =>
                  setState(() => _type = v ?? 'overcharging'),
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Namba ya Gari' : 'Plate Number'),
            TextFormField(
              controller: _plateCtrl,
              decoration: _dec('T 123 ABC'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Njia' : 'Route'),
            TextFormField(
              controller: _routeCtrl,
              decoration: _dec(
                  _isSwahili ? 'Mfano: Ubungo - Posta' : 'e.g. Ubungo - Posta'),
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
                  : Text(_isSwahili ? 'Tuma Lalamiko' : 'Submit Complaint'),
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
