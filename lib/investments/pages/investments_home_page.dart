// lib/investments/pages/investments_home_page.dart
import 'package:flutter/material.dart';
import '../models/investment_models.dart';
import '../services/investment_service.dart';
import '../widgets/portfolio_card.dart';
import '../widgets/asset_category_card.dart';
import 'bonds_page.dart';
import 'unit_trusts_page.dart';
import 'stocks_page.dart';
import 'real_estate_page.dart';
import 'agriculture_page.dart';
import 'savings_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class InvestmentsHomePage extends StatefulWidget {
  final int userId;
  final PortfolioSummary portfolio;

  const InvestmentsHomePage({
    super.key,
    required this.userId,
    required this.portfolio,
  });

  @override
  State<InvestmentsHomePage> createState() => _InvestmentsHomePageState();
}

class _InvestmentsHomePageState extends State<InvestmentsHomePage> {
  late PortfolioSummary _portfolio;
  final InvestmentService _service = InvestmentService();

  @override
  void initState() {
    super.initState();
    _portfolio = widget.portfolio;
  }

  Future<void> _refresh() async {
    final result = await _service.getPortfolio(widget.userId);
    if (mounted && result.success && result.data != null) {
      setState(() => _portfolio = result.data!);
    }
  }

  void _navigateAndRefresh(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Portfolio card
          PortfolioCard(portfolio: _portfolio),
          const SizedBox(height: 24),

          // Section: Soko la Fedha (Financial Markets)
          const _SectionHeader(title: 'Financial Markets', subtitle: 'Soko la Fedha'),
          const SizedBox(height: 10),
          AssetCategoryCard(
            icon: Icons.account_balance_rounded,
            title: 'Government Bonds',
            subtitle: 'Treasury Bills & Bonds — BoT / Bonyeza Uwekeze',
            onTap: () => _navigateAndRefresh(BondsPage(userId: widget.userId)),
          ),
          const SizedBox(height: 8),
          AssetCategoryCard(
            icon: Icons.pie_chart_rounded,
            title: 'Unit Trusts',
            subtitle: 'Unit Trusts — UTT AMIS (Umoja, Watoto, Jikimu)',
            onTap: () => _navigateAndRefresh(UnitTrustsPage(userId: widget.userId)),
          ),
          const SizedBox(height: 8),
          AssetCategoryCard(
            icon: Icons.candlestick_chart_rounded,
            title: 'DSE Stocks',
            subtitle: 'Dar es Salaam Stock Exchange — ~28 companies',
            onTap: () => _navigateAndRefresh(StocksPage(userId: widget.userId)),
          ),
          const SizedBox(height: 24),

          // Section: Uwekezaji Mbadala (Alternative Investments)
          const _SectionHeader(title: 'Alternative Investments', subtitle: 'Uwekezaji Mbadala'),
          const SizedBox(height: 10),
          AssetCategoryCard(
            icon: Icons.location_city_rounded,
            title: 'Real Estate',
            subtitle: 'REIT, Joint Investment — W-REIT / Crowdfunding',
            onTap: () => _navigateAndRefresh(RealEstatePage(userId: widget.userId)),
          ),
          const SizedBox(height: 8),
          AssetCategoryCard(
            icon: Icons.agriculture_rounded,
            title: 'Agriculture',
            subtitle: 'Cashew, Coffee, Tea — seasonal investment',
            onTap: () => _navigateAndRefresh(AgriculturePage(userId: widget.userId)),
          ),
          const SizedBox(height: 8),
          AssetCategoryCard(
            icon: Icons.savings_rounded,
            title: 'Savings & Deposits',
            subtitle: 'Fixed Deposits, Savings Bonds — CRDB, NMB',
            onTap: () => _navigateAndRefresh(SavingsPage(userId: widget.userId)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
      ],
    );
  }
}
