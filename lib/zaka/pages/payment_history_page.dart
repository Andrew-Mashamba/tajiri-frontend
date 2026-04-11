// lib/zaka/pages/payment_history_page.dart
import 'package:flutter/material.dart';
import '../models/zaka_models.dart';
import '../services/zaka_service.dart';
import '../../services/local_storage_service.dart';

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
  final _service = ZakaService();
  List<ZakatPayment> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken() ?? '';
    final result = await _service.getPaymentHistory(token: token);
    if (mounted) {
      setState(() {
        _payments = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context)),
        title: const Text('Historia ya Malipo',
            style: TextStyle(color: _kPrimary, fontSize: 18,
                fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary))
            : _payments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 48, color: _kSecondary),
                        SizedBox(height: 12),
                        Text('Hakuna malipo bado',
                            style: TextStyle(color: _kSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (context, i) {
                      final p = _payments[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: p.status == 'completed'
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10)),
                              child: Icon(
                                p.status == 'completed'
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_rounded,
                                color: p.status == 'completed'
                                    ? Colors.green
                                    : Colors.orange,
                                size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.recipientName,
                                      style: const TextStyle(color: _kPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                    '${p.paymentMethod} \u2022 '
                                    '${p.paidAt.toString().split(' ').first}',
                                    style: const TextStyle(
                                        color: _kSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Text(
                              '${p.amount.toStringAsFixed(0)} TZS',
                              style: const TextStyle(
                                  color: _kPrimary, fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
