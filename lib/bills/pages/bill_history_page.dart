// lib/bills/pages/bill_history_page.dart
import 'package:flutter/material.dart';
import '../models/bills_models.dart';
import '../services/bills_service.dart';
import '../widgets/bill_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class BillHistoryPage extends StatefulWidget {
  final int userId;
  const BillHistoryPage({super.key, required this.userId});
  @override
  State<BillHistoryPage> createState() => _BillHistoryPageState();
}

class _BillHistoryPageState extends State<BillHistoryPage> {
  final BillsService _service = BillsService();
  List<BillPayment> _payments = [];
  bool _isLoading = true;
  BillType? _filterType;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getPaymentHistory(
      widget.userId,
      type: _filterType?.name,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _payments = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Historia ya Malipo',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('Zote', _filterType == null, () {
                  setState(() => _filterType = null);
                  _load();
                }),
                ...BillType.values.map((t) => _chip(t.displayName,
                    _filterType == t, () {
                  setState(() => _filterType = t);
                  _load();
                })),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _payments.isEmpty
                    ? const Center(
                        child: Text('Hakuna malipo',
                            style: TextStyle(color: _kSecondary)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _payments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              BillCard(payment: _payments[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : _kPrimary)),
          backgroundColor: selected ? _kPrimary : _kPrimary.withValues(alpha: 0.06),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}
