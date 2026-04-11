// lib/investments/pages/bonds_page.dart
import 'package:flutter/material.dart';
import '../models/investment_models.dart';
import '../services/investment_service.dart';
import '../widgets/investment_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BondsPage extends StatefulWidget {
  final int userId;
  const BondsPage({super.key, required this.userId});
  @override
  State<BondsPage> createState() => _BondsPageState();
}

class _BondsPageState extends State<BondsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InvestmentService _service = InvestmentService();

  List<BondProduct> _products = [];
  List<BondHolding> _holdings = [];
  bool _isLoadingProducts = true;
  bool _isLoadingHoldings = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadProducts(), _loadHoldings()]);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    final result = await _service.getBondProducts();
    if (mounted) {
      setState(() {
        _isLoadingProducts = false;
        if (result.success) _products = result.items;
      });
    }
  }

  Future<void> _loadHoldings() async {
    setState(() => _isLoadingHoldings = true);
    final result = await _service.getMyBonds(widget.userId);
    if (mounted) {
      setState(() {
        _isLoadingHoldings = false;
        if (result.success) _holdings = result.items;
      });
    }
  }

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  void _showInvestSheet(BondProduct product) {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wekeza: ${product.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Riba: ${product.couponRate.toStringAsFixed(1)}% • Muda: ${product.tenorLabel}',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  Text(
                    'Kiwango cha chini: TZS ${_fmt(product.minInvestment)}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kiasi (TZS)',
                      hintText: '${product.minInvestment.toInt()}',
                      filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nambari ya M-Pesa',
                      hintText: '0712 345 678',
                      filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: FilledButton(
                      onPressed: isSubmitting ? null : () async {
                        final amount = double.tryParse(amountController.text.trim());
                        if (amount == null || amount < product.minInvestment) return;
                        setSheetState(() => isSubmitting = true);
                        final result = await _service.investInBond(
                          userId: widget.userId,
                          bondProductId: product.id,
                          amount: amount,
                          paymentMethod: 'mobile_money',
                          phoneNumber: phoneController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(
                              result.success ? 'Ombi limetumwa! Thibitisha kwenye simu.' : (result.message ?? 'Imeshindwa'),
                            )),
                          );
                          if (result.success) _loadHoldings();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Wekeza Sasa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Bondi za Serikali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [
            Tab(text: 'Bidhaa'),
            Tab(text: 'Bondi Zangu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Products tab
          _isLoadingProducts
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
              : _products.isEmpty
                  ? _buildEmpty('Hakuna bondi zinazopatikana', Icons.account_balance_rounded)
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
                              icon: p.isTreasuryBill ? Icons.receipt_long_rounded : Icons.account_balance_rounded,
                              title: p.name,
                              subtitle: 'Muda: ${p.tenorLabel} • Min: TZS ${_fmt(p.minInvestment)}',
                              value: '${p.couponRate.toStringAsFixed(1)}%',
                              returnText: p.isTreasuryBill ? 'Treasury Bill' : 'Treasury Bond',
                              onTap: () => _showInvestSheet(p),
                            ),
                          );
                        },
                      ),
                    ),
          // Holdings tab
          _isLoadingHoldings
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
              : _holdings.isEmpty
                  ? _buildEmpty('Huna bondi bado', Icons.account_balance_rounded)
                  : RefreshIndicator(
                      onRefresh: _loadHoldings,
                      color: _kPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _holdings.length,
                        itemBuilder: (context, index) {
                          final h = _holdings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InvestmentTile(
                              icon: Icons.account_balance_rounded,
                              title: h.bondName,
                              subtitle: 'Siku ${h.daysToMaturity} hadi mwisho',
                              value: 'TZS ${_fmt(h.currentValue)}',
                              returnText: '+TZS ${_fmt(h.accruedInterest)}',
                              isPositive: true,
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
