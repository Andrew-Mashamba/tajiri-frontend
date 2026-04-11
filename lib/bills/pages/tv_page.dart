// lib/bills/pages/tv_page.dart
import 'package:flutter/material.dart';
import '../models/bills_models.dart';
import '../services/bills_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class TvPage extends StatefulWidget {
  final int userId;
  const TvPage({super.key, required this.userId});
  @override
  State<TvPage> createState() => _TvPageState();
}

class _TvPageState extends State<TvPage> {
  final BillsService _service = BillsService();
  final _smartcardCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  TvProvider _selectedProvider = TvProvider.dstv;
  bool _isProcessing = false;

  @override
  void dispose() {
    _smartcardCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final smartcard = _smartcardCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (smartcard.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza namba ya smartcard na kiasi')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final result = await _service.payTv(
      userId: widget.userId,
      provider: _selectedProvider.name,
      smartcardNumber: smartcard,
      amount: amount,
      paymentMethod: 'wallet',
    );
    if (mounted) {
      setState(() => _isProcessing = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Malipo ya TV yamefanikiwa!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ?? 'Imeshindwa kulipa TV')),
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
        title: const Text('Lipa TV',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider selection
          const Text('Mtoa Huduma',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 10),
          Row(
            children: TvProvider.values.map((p) {
              final selected = _selectedProvider == p;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedProvider = p),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.tv_rounded,
                            color: selected ? Colors.white : _kPrimary,
                            size: 24),
                        const SizedBox(height: 6),
                        Text(p.displayName,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    selected ? Colors.white : _kPrimary)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Smartcard number
          const Text('Namba ya Smartcard',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _smartcardCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Mfano: 1234567890',
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
              hintText: 'Mfano: 30000',
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
                  : const Text('Lipa TV', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
