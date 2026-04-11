// lib/fee_status/pages/payment_history_page.dart
import 'package:flutter/material.dart';
import '../models/fee_status_models.dart';
import '../services/fee_status_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PaymentHistoryPage extends StatefulWidget {
  final int userId;
  const PaymentHistoryPage({super.key, required this.userId});
  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<FeePayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await FeeStatusService().getPaymentHistory();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _payments = result.items;
      });
    }
  }

  String _fmtAmount(double v) => 'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Historia ya Malipo / Payment History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _payments.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.receipt_long_rounded, size: 48, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Hakuna malipo / No payments', style: TextStyle(color: _kSecondary)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (_, i) {
                    final p = _payments[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        Icon(p.status == 'confirmed' ? Icons.check_circle_rounded : Icons.pending_rounded, size: 20, color: p.status == 'confirmed' ? Colors.green : Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_fmtAmount(p.amount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                          Text('${p.methodDisplay} · ${p.referenceNumber}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Text('${p.paidAt.day}/${p.paidAt.month}/${p.paidAt.year}', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                      ]),
                    );
                  },
                ),
    );
  }
}
