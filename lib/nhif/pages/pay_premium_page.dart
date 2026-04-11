// lib/nhif/pages/pay_premium_page.dart
import 'package:flutter/material.dart';
import '../services/nhif_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PayPremiumPage extends StatefulWidget {
  const PayPremiumPage({super.key});
  @override
  State<PayPremiumPage> createState() => _PayPremiumPageState();
}

class _PayPremiumPageState extends State<PayPremiumPage> {
  final _amountCtrl = TextEditingController();
  String _method = 'mpesa';
  bool _paying = false;

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;
    setState(() => _paying = true);
    final result = await NhifService.payPremium({'amount': amount, 'method': _method});
    if (!mounted) return;
    setState(() => _paying = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
        content: Text(result.success ? 'Malipo yamefanikiwa' : (result.message ?? 'Imeshindwa'))));
    if (result.success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _kBg,
      appBar: AppBar(title: const Text('Lipa Michango',
          style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Kiasi / Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        TextField(controller: _amountCtrl, keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'TZS', hintStyle: const TextStyle(color: _kSecondary),
            prefixText: 'TZS ', filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 16),
        const Text('Njia ya Malipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 8),
        ...['mpesa', 'tigopesa', 'airtelmoney'].map((m) {
          final labels = {'mpesa': 'M-Pesa', 'tigopesa': 'Tigo Pesa', 'airtelmoney': 'Airtel Money'};
          return RadioListTile<String>(
            title: Text(labels[m]!, style: const TextStyle(fontSize: 14, color: _kPrimary)),
            value: m, groupValue: _method,
            onChanged: (v) => setState(() => _method = v!),
            activeColor: _kPrimary, contentPadding: EdgeInsets.zero);
        }),
        const SizedBox(height: 20),
        SizedBox(height: 48, width: double.infinity, child: ElevatedButton(
          onPressed: _paying ? null : _pay,
          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _paying
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Lipa Sasa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
      ]),
    );
  }
}
