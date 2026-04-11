// lib/tra/pages/payment_history_page.dart
import 'package:flutter/material.dart';
import '../models/tra_models.dart';
import '../services/tra_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});
  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<TaxPayment> _payments = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await TraService.getPaymentHistory(page: _page);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _payments = result.items;
        _hasMore = result.hasMore;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Historia ya Malipo',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _payments.isEmpty
              ? const Center(child: Text('Hakuna malipo bado',
                  style: TextStyle(color: _kSecondary, fontSize: 14)))
              : RefreshIndicator(
                  onRefresh: _load, color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = _payments[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.payment_rounded, size: 20, color: _kPrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.taxType, style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600, color: _kPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Ref: ${p.referenceNumber}',
                                style: const TextStyle(fontSize: 11, color: _kSecondary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('TZS ${p.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w700, color: _kPrimary)),
                            Text('${p.paidAt.day}/${p.paidAt.month}/${p.paidAt.year}',
                                style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
