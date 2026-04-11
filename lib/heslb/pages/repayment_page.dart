// lib/heslb/pages/repayment_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../services/heslb_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RepaymentPage extends StatefulWidget {
  const RepaymentPage({super.key});
  @override
  State<RepaymentPage> createState() => _RepaymentPageState();
}

class _RepaymentPageState extends State<RepaymentPage> {
  bool _isSwahili = true;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    final r = await HeslbService.initiateRepayment(
      amount: amount,
      phone: _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (r.success) {
      messenger.showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Malipo yameanzishwa! Angalia M-Pesa.'
            : 'Payment initiated! Check M-Pesa.'),
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
        title: Text(
            _isSwahili ? 'Lipa Mkopo (M-Pesa)' : 'Repay Loan (M-Pesa)',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded,
                      color: Colors.blue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isSwahili
                          ? 'Utapokea ombi la M-Pesa kwenye simu yako.'
                          : 'You will receive an M-Pesa prompt on your phone.',
                      style: const TextStyle(fontSize: 12, color: _kPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _label(_isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)'),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec('50000'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return _isSwahili ? 'Lazima' : 'Required';
                }
                final n = double.tryParse(v);
                if (n == null || n <= 0) {
                  return _isSwahili ? 'Kiasi batili' : 'Invalid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _label(_isSwahili ? 'Namba ya Simu' : 'Phone Number'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec('0712 345 678'),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? (_isSwahili ? 'Namba batili' : 'Invalid phone')
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
                  : Text(_isSwahili ? 'Lipa Sasa' : 'Pay Now'),
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
