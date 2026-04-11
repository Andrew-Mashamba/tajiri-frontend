// lib/bills/pages/bills_home_page.dart
import 'package:flutter/material.dart';
import '../models/bills_models.dart';
import '../services/bills_service.dart';
import '../widgets/bill_card.dart';
import '../widgets/quick_pay_tile.dart';
import 'luku_page.dart';
import 'airtime_page.dart';
import 'water_page.dart';
import 'tv_page.dart';
import 'bill_history_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class BillsHomePage extends StatefulWidget {
  final int userId;
  const BillsHomePage({super.key, required this.userId});
  @override
  State<BillsHomePage> createState() => _BillsHomePageState();
}

class _BillsHomePageState extends State<BillsHomePage> {
  final BillsService _service = BillsService();
  List<BillPayment> _recentPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await _service.getPaymentHistory(widget.userId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _recentPayments = result.items;
      });
    }
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Text('Bili Tajiri',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Lipa umeme, maji, vocha, TV — mahali pamoja.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _HeaderStat(
                        value: '${_recentPayments.length}',
                        label: 'Malipo ya Hivi Karibuni'),
                    const SizedBox(width: 20),
                    _HeaderStat(
                        value: _recentPayments
                            .where(
                                (p) => p.status == BillPaymentStatus.success)
                            .length
                            .toString(),
                        label: 'Yamefanikiwa'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick pay grid
          const Text('Lipa Haraka',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              QuickPayTile(
                icon: Icons.bolt_rounded,
                label: 'Nunua LUKU',
                subtitle: 'Umeme',
                onTap: () => _nav(LukuPage(userId: widget.userId)),
              ),
              QuickPayTile(
                icon: Icons.phone_android_rounded,
                label: 'Nunua Vocha',
                subtitle: 'Airtime & Data',
                onTap: () => _nav(AirtimePage(userId: widget.userId)),
              ),
              QuickPayTile(
                icon: Icons.water_drop_rounded,
                label: 'Lipa Maji',
                subtitle: 'DAWASCO',
                onTap: () => _nav(WaterPage(userId: widget.userId)),
              ),
              QuickPayTile(
                icon: Icons.tv_rounded,
                label: 'Lipa TV',
                subtitle: 'DStv, Azam, StarTimes',
                onTap: () => _nav(TvPage(userId: widget.userId)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Recent payments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Malipo ya Hivi Karibuni',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
              TextButton(
                onPressed: () =>
                    _nav(BillHistoryPage(userId: widget.userId)),
                child: const Text('Yote',
                    style: TextStyle(fontSize: 13, color: _kSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_recentPayments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        size: 48, color: _kSecondary),
                    const SizedBox(height: 12),
                    const Text('Hakuna malipo bado',
                        style: TextStyle(fontSize: 15, color: _kSecondary)),
                    const SizedBox(height: 6),
                    const Text('Lipa bili yako ya kwanza kupitia Tajiri',
                        style: TextStyle(fontSize: 13, color: _kSecondary),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ..._recentPayments.take(5).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BillCard(payment: p),
                )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }
}
