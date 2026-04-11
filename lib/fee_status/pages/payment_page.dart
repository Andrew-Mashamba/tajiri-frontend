// lib/fee_status/pages/payment_page.dart
import 'package:flutter/material.dart';
import '../services/fee_status_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PaymentPage extends StatefulWidget {
  final int userId;
  const PaymentPage({super.key, required this.userId});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _amountC = TextEditingController();
  final _phoneC = TextEditingController();
  final _refC = TextEditingController();
  String _method = 'mpesa';
  bool _isPaying = false;

  @override
  void dispose() {
    _amountC.dispose();
    _phoneC.dispose();
    _refC.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountC.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weka kiasi sahihi')));
      return;
    }
    setState(() => _isPaying = true);
    final result = await FeeStatusService().payViaMpesa(
      amount: amount,
      phoneNumber: _phoneC.text.trim(),
      studentRef: _refC.text.trim(),
    );
    if (mounted) {
      setState(() => _isPaying = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Malipo yametumwa! Subiri M-Pesa prompt.')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Imeshindwa')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Lipa Ada / Pay Fees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Method selector
          const Text('Njia ya Malipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            _methodChip('mpesa', 'M-Pesa'),
            const SizedBox(width: 8),
            _methodChip('bank', 'Benki'),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountC,
            decoration: const InputDecoration(labelText: 'Kiasi (TZS) / Amount', border: OutlineInputBorder(), prefixText: 'TZS '),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          if (_method == 'mpesa') ...[
            TextFormField(controller: _phoneC, decoration: const InputDecoration(labelText: 'Namba ya Simu / Phone Number', border: OutlineInputBorder(), hintText: '0712345678'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
          ],
          TextFormField(controller: _refC, decoration: const InputDecoration(labelText: 'Namba ya Mwanafunzi / Student Ref', border: OutlineInputBorder())),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isPaying ? null : _pay,
            style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
            child: _isPaying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_method == 'mpesa' ? 'Lipa kwa M-Pesa' : 'Lipa kwa Benki'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, size: 16, color: _kSecondary),
              SizedBox(width: 8),
              Expanded(child: Text('Utapokea M-Pesa pop-up kwenye simu yako. Thibitisha kulipa.', style: TextStyle(fontSize: 12, color: _kSecondary))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _methodChip(String value, String label) {
    final selected = _method == value;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _method = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _kPrimary : Colors.grey.shade300),
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : _kPrimary))),
      ),
    ));
  }
}
