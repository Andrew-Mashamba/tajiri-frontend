// lib/income/pages/business_income_page.dart
//
// Single-business net income (collected invoice payments − expenses).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../transactions/transactions.dart';
import '../models/income_models.dart';
import '../services/income_summary_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class BusinessIncomePage extends StatefulWidget {
  final int businessId;
  final RevenuePeriodScope initialPeriod;

  const BusinessIncomePage({
    super.key,
    required this.businessId,
    this.initialPeriod = RevenuePeriodScope.allTime,
  });

  @override
  State<BusinessIncomePage> createState() => _BusinessIncomePageState();
}

class _BusinessIncomePageState extends State<BusinessIncomePage> {
  final NumberFormat _nf = NumberFormat('#,###', 'en');

  RevenuePeriodScope _scope = RevenuePeriodScope.allTime;
  bool _loading = true;
  String? _loadError;
  IncomeTotals _totals = const IncomeTotals(collectedRevenue: 0, totalExpenses: 0, netIncome: 0);

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _scope = widget.initialPeriod;
    _load();
  }

  @override
  void didUpdateWidget(covariant BusinessIncomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId || oldWidget.initialPeriod != widget.initialPeriod) {
      _scope = widget.initialPeriod;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = _sw ? 'Ingia ili kuona faida' : 'Sign in to view income';
      });
      return;
    }
    final out = await IncomeSummaryService.loadBusinessTotals(token, widget.businessId, _scope);
    if (!mounted) return;
    if (!out.success) {
      setState(() {
        _loading = false;
        _loadError = out.message ?? (_sw ? 'Imeshindwa kupakia' : 'Failed to load');
      });
      return;
    }
    setState(() {
      _totals = out.totals;
      _loadError = null;
      _loading = false;
    });
  }

  void _setScope(RevenuePeriodScope s) {
    if (s == _scope) return;
    setState(() => _scope = s);
    _load();
  }

  String _money(double v) => 'TZS ${_nf.format(v)}';

  String _periodChipLabel(RevenuePeriodScope s) {
    switch (s) {
      case RevenuePeriodScope.allTime:
        return _sw ? 'Muda wote' : 'All time';
      case RevenuePeriodScope.thisMonth:
        return _sw ? 'Mwezi huu' : 'This month';
      case RevenuePeriodScope.last30Days:
        return _sw ? 'Siku 30' : 'Last 30 days';
    }
  }

  void _openLedger() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          backgroundColor: _kBackground,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _kBackground,
            foregroundColor: _kPrimary,
            title: Text(
              _sw ? 'Miamala' : 'Transactions',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ),
          body: BusinessTransactionsPage(businessId: widget.businessId),
        ),
      ),
    );
  }

  Widget _periodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: RevenuePeriodScope.values.map((s) {
          final selected = _scope == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _periodChipLabel(s),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _kPrimary,
                ),
              ),
              selected: selected,
              onSelected: (_) => _setScope(s),
              selectedColor: _kPrimary,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _metricCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _kSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_sw ? 'Jaribu tena' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: _kBackground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _sw ? 'Kipindi' : 'Period',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondary),
            ),
            const SizedBox(height: 6),
            _periodChips(),
            Text(
              _sw
                  ? 'Ankara zisizo rasimu/zilizofutwa: mapato yaliyokusanywa. Matumizi yanategemea tarehe ya matumizi. Kipindi cha ankara kinategemea tarehe ya kuundwa.'
                  : 'Draft/void/cancelled invoices excluded for collected amounts. Expenses use expense date (or created date). Invoice period uses issue date.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
            ),
            const SizedBox(height: 16),
            _metricCard(_sw ? 'Mapato yaliyokusanywa' : 'Collected revenue', _money(_totals.collectedRevenue)),
            const SizedBox(height: 12),
            _metricCard(_sw ? 'Jumla ya matumizi' : 'Total expenses', _money(_totals.totalExpenses)),
            const SizedBox(height: 12),
            _metricCard(_sw ? 'Faida halisi' : 'Net income', _money(_totals.netIncome)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openLedger,
                icon: const Icon(Icons.receipt_long_rounded, color: _kPrimary, size: 22),
                label: Text(
                  _sw ? 'Angalia orodha ya miamala' : 'View transaction ledger',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
