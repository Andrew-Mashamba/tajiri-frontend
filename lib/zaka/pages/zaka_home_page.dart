// lib/zaka/pages/zaka_home_page.dart
import 'package:flutter/material.dart';
import '../models/zaka_models.dart';
import '../services/zaka_service.dart';
import '../../services/local_storage_service.dart';
import 'zaka_calculator_page.dart';
import 'payment_history_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class ZakaHomePage extends StatefulWidget {
  final int userId;
  const ZakaHomePage({super.key, required this.userId});

  @override
  State<ZakaHomePage> createState() => _ZakaHomePageState();
}

class _ZakaHomePageState extends State<ZakaHomePage> {
  final _service = ZakaService();
  NisabInfo? _nisab;
  List<ZakatPayment> _recentPayments = [];
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

    final results = await Future.wait([
      _service.getNisabInfo(),
      _service.getPaymentHistory(token: token),
    ]);

    if (mounted) {
      final nisabResult = results[0] as SingleResult<NisabInfo>;
      final historyResult = results[1] as PaginatedResult<ZakatPayment>;
      setState(() {
        _nisab = nisabResult.data;
        _recentPayments = historyResult.items;
        _loading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M TZS';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K TZS';
    }
    return '${amount.toStringAsFixed(0)} TZS';
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(
            strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            color: _kPrimary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                    // ─── Nisab Card ───────────────────────
                    _buildNisabCard(),
                    const SizedBox(height: 16),

                    // ─── Calculator Button ────────────────
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                                ZakaCalculatorPage(userId: widget.userId))),
                        icon: const Icon(Icons.calculate_rounded, size: 20),
                        label: const Text('Hesabu Zaka Yako'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Info Cards ───────────────────────
                    const Text('Habari Muhimu',
                        style: TextStyle(color: _kPrimary, fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _infoCard('Kiwango cha Zaka', '2.5% ya utajiri unaostahili',
                        Icons.percent_rounded),
                    _infoCard('Nisab ya Dhahabu', '85 gramu za dhahabu',
                        Icons.diamond_rounded),
                    _infoCard('Nisab ya Fedha', '595 gramu za fedha',
                        Icons.monetization_on_rounded),
                    const SizedBox(height: 24),

                    // ─── Recent Payments ──────────────────
                    Row(
                      children: [
                        const Expanded(child: Text('Malipo ya Hivi Karibuni',
                            style: TextStyle(color: _kPrimary, fontSize: 16,
                                fontWeight: FontWeight.w600))),
                        TextButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) =>
                                  PaymentHistoryPage(userId: widget.userId))),
                          child: const Text('Ona yote',
                              style: TextStyle(color: _kSecondary, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_recentPayments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Hakuna malipo bado',
                            style: TextStyle(color: _kSecondary, fontSize: 14),
                            textAlign: TextAlign.center),
                      )
                    else
                      ..._recentPayments.take(5).map(_buildPaymentTile),
                  ],
                ),
              );
  }

  Widget _buildNisabCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Text('Nisab ya Sasa',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            _nisab != null ? _formatAmount(_nisab!.nisabGold) : '--',
            style: const TextStyle(color: Colors.white, fontSize: 28,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text('(kwa msingi wa dhahabu)',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Icon(icon, color: _kSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _kPrimary,
                    fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(
                    color: _kSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(ZakatPayment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          const Icon(Icons.payment_rounded, color: _kSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.recipientName,
                    style: const TextStyle(color: _kPrimary, fontSize: 14,
                        fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(payment.paidAt.toString().split(' ').first,
                    style: const TextStyle(color: _kSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(_formatAmount(payment.amount),
              style: const TextStyle(color: _kPrimary, fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
