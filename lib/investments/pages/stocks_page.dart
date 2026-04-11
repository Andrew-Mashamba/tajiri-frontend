// lib/investments/pages/stocks_page.dart
import 'package:flutter/material.dart';
import '../models/investment_models.dart';
import '../services/investment_service.dart';
import '../widgets/investment_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class StocksPage extends StatefulWidget {
  final int userId;
  const StocksPage({super.key, required this.userId});
  @override
  State<StocksPage> createState() => _StocksPageState();
}

class _StocksPageState extends State<StocksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final InvestmentService _service = InvestmentService();

  List<Stock> _stocks = [];
  List<StockHolding> _holdings = [];
  bool _isLoadingStocks = true;
  bool _isLoadingHoldings = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.wait([_loadStocks(), _loadHoldings()]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    setState(() => _isLoadingStocks = true);
    final result = await _service.getStocks();
    if (mounted) {
      setState(() {
        _isLoadingStocks = false;
        if (result.success) _stocks = result.items;
      });
    }
  }

  Future<void> _loadHoldings() async {
    setState(() => _isLoadingHoldings = true);
    final result = await _service.getMyStocks(widget.userId);
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

  List<Stock> get _filteredStocks {
    if (_searchQuery.isEmpty) return _stocks;
    final q = _searchQuery.toLowerCase();
    return _stocks.where((s) =>
        s.symbol.toLowerCase().contains(q) ||
        s.name.toLowerCase().contains(q) ||
        s.sector.toLowerCase().contains(q)).toList();
  }

  void _showBuySheet(Stock stock) {
    final sharesController = TextEditingController();
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
            final shares = int.tryParse(sharesController.text.trim()) ?? 0;
            final total = shares * stock.lastPrice;
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
                    'Nunua: ${stock.symbol}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  Text(
                    '${stock.name} • TZS ${_fmt(stock.lastPrice)}/hisa',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sharesController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Idadi ya Hisa',
                      hintText: '10',
                      filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (shares > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Jumla: TZS ${_fmt(total)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                  ],
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
                      onPressed: (isSubmitting || shares <= 0) ? null : () async {
                        setSheetState(() => isSubmitting = true);
                        final result = await _service.buyStock(
                          userId: widget.userId,
                          stockId: stock.id,
                          shares: shares,
                          paymentMethod: 'mobile_money',
                          phoneNumber: phoneController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(
                              result.success ? 'Oda imetumwa kwa dalali!' : (result.message ?? 'Imeshindwa'),
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
                          : const Text('Nunua Hisa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
        title: const Text('Hisa za DSE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [Tab(text: 'Soko'), Tab(text: 'Hisa Zangu')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Market tab
          Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tafuta hisa... (CRDB, NMB, TBL)',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: _kSecondary),
                    filled: true, fillColor: _kCardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: _isLoadingStocks
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                    : _filteredStocks.isEmpty
                        ? Center(child: Text('Hakuna hisa', style: TextStyle(color: Colors.grey.shade500)))
                        : RefreshIndicator(
                            onRefresh: _loadStocks,
                            color: _kPrimary,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredStocks.length,
                              itemBuilder: (context, index) {
                                final s = _filteredStocks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InvestmentTile(
                                    icon: Icons.candlestick_chart_rounded,
                                    title: s.symbol,
                                    subtitle: '${s.name} • ${s.sector}',
                                    value: 'TZS ${_fmt(s.lastPrice)}',
                                    returnText: '${s.isUp ? '+' : ''}${s.changePercent.toStringAsFixed(1)}%',
                                    isPositive: s.isUp ? true : s.isDown ? false : null,
                                    onTap: () => _showBuySheet(s),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          // Holdings
          _isLoadingHoldings
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
              : _holdings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.candlestick_chart_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Huna hisa bado', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                        ],
                      ),
                    )
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
                              icon: Icons.candlestick_chart_rounded,
                              title: '${h.symbol} × ${h.shares}',
                              subtitle: h.name,
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
}
