// lib/bills/pages/airtime_page.dart
import 'package:flutter/material.dart';
import '../models/bills_models.dart';
import '../services/bills_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AirtimePage extends StatefulWidget {
  final int userId;
  const AirtimePage({super.key, required this.userId});
  @override
  State<AirtimePage> createState() => _AirtimePageState();
}

class _AirtimePageState extends State<AirtimePage> {
  final BillsService _service = BillsService();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  MobileOperator _selectedOperator = MobileOperator.vodacom;
  bool _isProcessing = false;

  final List<int> _quickAmounts = [1000, 2000, 5000, 10000, 20000, 50000];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    final phone = _phoneCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (phone.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza namba ya simu na kiasi')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final result = await _service.buyAirtime(
      userId: widget.userId,
      operator: _selectedOperator.name,
      phoneNumber: phone,
      amount: amount,
      paymentMethod: 'wallet',
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vocha imetumwa!')),
        );
        _phoneCtrl.clear();
        _amountCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ?? 'Imeshindwa kununua vocha')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Nunua Vocha',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Operator selection
          const Text('Mtandao',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 10),
          Row(
            children: MobileOperator.values.map((op) {
              final selected = _selectedOperator == op;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedOperator = op),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(op.displayName,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : _kPrimary)),
                        Text(op.prefix,
                            style: TextStyle(
                                fontSize: 10,
                                color: selected
                                    ? Colors.white70
                                    : _kSecondary)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Phone number
          const Text('Namba ya Simu',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Mfano: 0751234567',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
              prefixIcon:
                  const Icon(Icons.phone_rounded, color: _kSecondary),
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Amount
          const Text('Kiasi (TZS)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Mfano: 5000',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
              filled: true,
              fillColor: _kCardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),

          // Quick amounts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((a) {
              return GestureDetector(
                onTap: () => _amountCtrl.text = a.toString(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('TZS ${a >= 1000 ? '${a ~/ 1000}K' : a}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kPrimary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Buy button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isProcessing ? null : _buy,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Nunua Vocha', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
