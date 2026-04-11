// lib/bills/pages/luku_page.dart
import 'package:flutter/material.dart';
import '../services/bills_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class LukuPage extends StatefulWidget {
  final int userId;
  const LukuPage({super.key, required this.userId});
  @override
  State<LukuPage> createState() => _LukuPageState();
}

class _LukuPageState extends State<LukuPage> {
  final BillsService _service = BillsService();
  final _meterCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isProcessing = false;
  String? _resultToken;

  final List<int> _quickAmounts = [5000, 10000, 20000, 50000, 100000];

  @override
  void dispose() {
    _meterCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    final meter = _meterCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (meter.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza namba ya mita na kiasi')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final result = await _service.buyLuku(
      userId: widget.userId,
      meterNumber: meter,
      amount: amount,
      paymentMethod: 'wallet',
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (result.success && result.data != null) {
        setState(() => _resultToken = result.data!.token);
        _showTokenDialog(result.data!.token ?? 'N/A', result.data!.reference ?? '');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kununua LUKU')),
        );
      }
    }
  }

  void _showTokenDialog(String token, String ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('LUKU Imefanikiwa!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Token yako:',
                style: TextStyle(fontSize: 14, color: _kSecondary)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(token,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                      letterSpacing: 2)),
            ),
            if (ref.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Ref: $ref',
                  style: const TextStyle(fontSize: 12, color: _kSecondary)),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Sawa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Nunua LUKU',
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
                Icon(Icons.bolt_rounded, color: _kPrimary, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ingiza namba ya mita yako na kiasi cha umeme unaotaka kununua.',
                    style: TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Meter number
          const Text('Namba ya Mita',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _meterCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Mfano: 12345678901',
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
              hintText: 'Mfano: 10000',
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

          if (_resultToken != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Token yako ya mwisho:',
                            style:
                                TextStyle(fontSize: 12, color: _kSecondary)),
                        Text(_resultToken!,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                  : const Text('Nunua LUKU', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
