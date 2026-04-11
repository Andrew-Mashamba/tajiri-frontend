// lib/investments/pages/savings_page.dart
import 'package:flutter/material.dart';
import '../models/investment_models.dart';
import '../services/investment_service.dart';
import '../widgets/investment_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SavingsPage extends StatefulWidget {
  final int userId;
  const SavingsPage({super.key, required this.userId});
  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final InvestmentService _service = InvestmentService();
  List<SavingsProduct> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final result = await _service.getSavingsProducts();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _products = result.items;
      });
    }
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Akiba na Amana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Hakuna bidhaa za akiba kwa sasa', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text(
                        'Fixed deposits na savings bonds\nkutoka CRDB, NMB zitaonekana hapa.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InvestmentTile(
                          icon: p.type == 'fixed_deposit'
                              ? Icons.lock_clock_rounded
                              : Icons.savings_rounded,
                          title: p.name,
                          subtitle: '${p.provider} • ${p.termLabel} • Min: TZS ${_fmt(p.minAmount)}',
                          value: '${p.interestRate.toStringAsFixed(1)}%',
                          returnText: p.type == 'fixed_deposit' ? 'Fixed Deposit' : 'Savings Bond',
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
