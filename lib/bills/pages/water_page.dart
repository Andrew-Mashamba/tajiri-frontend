// lib/bills/pages/water_page.dart
import 'package:flutter/material.dart';
import '../services/bills_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class WaterPage extends StatefulWidget {
  final int userId;
  const WaterPage({super.key, required this.userId});
  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> {
  final BillsService _service = BillsService();
  final _accountCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final account = _accountCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (account.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza namba ya akaunti na kiasi')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final result = await _service.payWater(
      userId: widget.userId,
      accountNumber: account,
      amount: amount,
      paymentMethod: 'wallet',
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Malipo ya maji yamefanikiwa!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result.message ?? 'Imeshindwa kulipa bili ya maji')),
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
        title: const Text('Lipa Maji',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.water_drop_rounded, color: _kPrimary, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lipa bili yako ya DAWASCO kwa urahisi. Ingiza namba ya akaunti yako na kiasi.',
                    style: TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Account number
          const Text('Namba ya Akaunti (DAWASCO)',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _accountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Mfano: 1234567',
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
              hintText: 'Mfano: 15000',
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
          const SizedBox(height: 24),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isProcessing ? null : _pay,
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
                  : const Text('Lipa Maji', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
