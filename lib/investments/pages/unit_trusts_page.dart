// lib/investments/pages/unit_trusts_page.dart
import 'package:flutter/material.dart';
import '../models/investment_models.dart';
import '../services/investment_service.dart';
import '../widgets/investment_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class UnitTrustsPage extends StatefulWidget {
  final int userId;
  const UnitTrustsPage({super.key, required this.userId});
  @override
  State<UnitTrustsPage> createState() => _UnitTrustsPageState();
}

class _UnitTrustsPageState extends State<UnitTrustsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InvestmentService _service = InvestmentService();

  List<UnitTrustFund> _funds = [];
  List<UnitTrustHolding> _holdings = [];
  bool _isLoadingFunds = true;
  bool _isLoadingHoldings = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.wait([_loadFunds(), _loadHoldings()]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFunds() async {
    setState(() => _isLoadingFunds = true);
    final result = await _service.getUnitTrustFunds();
    if (mounted) {
      setState(() {
        _isLoadingFunds = false;
        if (result.success) _funds = result.items;
      });
    }
  }

  Future<void> _loadHoldings() async {
    setState(() => _isLoadingHoldings = true);
    final result = await _service.getMyUnitTrusts(widget.userId);
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

  Color _riskColor(String risk) {
    switch (risk) {
      case 'low': return const Color(0xFF4CAF50);
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      default: return _kSecondary;
    }
  }

  void _showInvestSheet(UnitTrustFund fund) {
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
                    fund.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fund.provider} • ${fund.fundTypeName} • ${fund.riskLabel}',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  if (fund.objective != null) ...[
                    const SizedBox(height: 8),
                    Text(fund.objective!, style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Kiwango cha chini: TZS ${_fmt(fund.minInitialInvestment)}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kiasi (TZS)',
                      hintText: '${fund.minInitialInvestment.toInt()}',
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
                        if (amount == null || amount < fund.minInitialInvestment) return;
                        setSheetState(() => isSubmitting = true);
                        final result = await _service.investInUnitTrust(
                          userId: widget.userId,
                          fundId: fund.id,
                          amount: amount,
                          paymentMethod: 'mobile_money',
                          phoneNumber: phoneController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(
                              result.success ? 'Uwekezaji umetumwa!' : (result.message ?? 'Imeshindwa'),
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
        title: const Text('Mifuko ya Uwekezaji', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [Tab(text: 'Mifuko'), Tab(text: 'Yangu')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Funds
          _isLoadingFunds
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
              : _funds.isEmpty
                  ? _buildEmpty('Hakuna mifuko')
                  : RefreshIndicator(
                      onRefresh: _loadFunds,
                      color: _kPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _funds.length,
                        itemBuilder: (context, index) {
                          final f = _funds[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _FundCard(
                              fund: f,
                              riskColor: _riskColor(f.riskLevel),
                              fmt: _fmt,
                              onInvest: () => _showInvestSheet(f),
                            ),
                          );
                        },
                      ),
                    ),
          // Holdings
          _isLoadingHoldings
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
              : _holdings.isEmpty
                  ? _buildEmpty('Huna mifuko bado')
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
                              icon: Icons.pie_chart_rounded,
                              title: h.fundName,
                              subtitle: '${h.provider} • ${h.units.toStringAsFixed(2)} units',
                              value: 'TZS ${_fmt(h.currentValue)}',
                              returnText: '${h.returnPercent >= 0 ? '+' : ''}${h.returnPercent.toStringAsFixed(1)}%',
                              isPositive: h.returnPercent >= 0,
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  final UnitTrustFund fund;
  final Color riskColor;
  final String Function(double) fmt;
  final VoidCallback onInvest;

  const _FundCard({
    required this.fund,
    required this.riskColor,
    required this.fmt,
    required this.onInvest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fund.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fund.riskLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: riskColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${fund.provider} • ${fund.fundTypeName}',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          if (fund.description != null) ...[
            const SizedBox(height: 6),
            Text(fund.description!, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(label: 'Mapato', value: '${fund.returnRate1Year.toStringAsFixed(1)}%/mwaka'),
              const SizedBox(width: 12),
              _InfoChip(label: 'Min', value: 'TZS ${fmt(fund.minInitialInvestment)}'),
              const Spacer(),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: onInvest,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Wekeza', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _kSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
      ],
    );
  }
}
