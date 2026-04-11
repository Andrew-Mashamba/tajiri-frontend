// lib/tira/pages/tira_complaint_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../services/tira_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TiraComplaintPage extends StatefulWidget {
  const TiraComplaintPage({super.key});
  @override
  State<TiraComplaintPage> createState() => _TiraComplaintPageState();
}

class _TiraComplaintPageState extends State<TiraComplaintPage> {
  bool _isSwahili = true;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _insurerCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'claim_delay';

  final _types = ['claim_delay', 'claim_denial', 'premium_dispute', 'other'];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _insurerCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _typeLabel(String t) {
    if (_isSwahili) {
      switch (t) {
        case 'claim_delay': return 'Kucheleweshwa Dai';
        case 'claim_denial': return 'Kukataliwa Dai';
        case 'premium_dispute': return 'Mgogoro wa Ada';
        default: return 'Mengineyo';
      }
    }
    return t.replaceAll('_', ' ').split(' ').map(
        (w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final r = await TiraService.submitComplaint({
      'type': _type,
      'insurer_name': _insurerCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (r.success) {
      messenger.showSnackBar(SnackBar(
        content:
            Text(_isSwahili ? 'Lalamiko limetumwa!' : 'Complaint submitted!'),
      ));
      Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text(r.message ?? 'Error')));
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
        title: Text(_isSwahili ? 'Lalamiko la TIRA' : 'TIRA Complaint',
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
                  setState(() => _type = v ?? 'claim_delay'),
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Kampuni ya Bima' : 'Insurer Name'),
            TextFormField(
              controller: _insurerCtrl,
              decoration: _dec(
                  _isSwahili ? 'Jina la kampuni' : 'Insurance company name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (_isSwahili ? 'Lazima' : 'Required')
                  : null,
            ),
            const SizedBox(height: 16),
            _label(_isSwahili ? 'Maelezo' : 'Description'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
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
