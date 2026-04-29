// lib/revenue/pages/revenue_overview_page.dart
//
// Portfolio revenue across all businesses (My Businesses) + per-business drill-down.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../business/business_notifier.dart';
import '../../business/models/business_models.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/revenue_models.dart';
import '../services/revenue_service.dart';
import 'business_revenue_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class RevenueOverviewPage extends StatefulWidget {
  final int userId;
  final List<Business> businesses;
  final int? featureBusinessId;

  const RevenueOverviewPage({
    super.key,
    required this.userId,
    required this.businesses,
    this.featureBusinessId,
  });

  @override
  State<RevenueOverviewPage> createState() => _RevenueOverviewPageState();
}

class _RevenueOverviewPageState extends State<RevenueOverviewPage> {
  final NumberFormat _nf = NumberFormat('#,###', 'en');

  RevenuePeriodScope _scope = RevenuePeriodScope.allTime;
  PortfolioRevenueLoadResult? _result;
  bool _loading = true;
  String? _error;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RevenueOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey = oldWidget.businesses.map((b) => b.id).join(',');
    final newKey = widget.businesses.map((b) => b.id).join(',');
    if (oldKey != newKey) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _sw ? 'Ingia ili kuona mapato' : 'Sign in to view revenue';
      });
      return;
    }
    try {
      final businesses = BusinessNotifier.instance.businesses;
      final result = await RevenueService.loadPortfolio(token, businesses, _scope);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
        _error = result.success ? null : (result.message ?? (_sw ? 'Imeshindwa' : 'Failed to load'));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _sw ? 'Hitilafu: $e' : 'Error: $e';
      });
    }
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

  void _openBusinessDetail(int businessId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          backgroundColor: _kBackground,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _kBackground,
            foregroundColor: _kPrimary,
            title: Text(
              _sw ? 'Mapato — biashara' : 'Revenue — business',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ),
          body: BusinessRevenuePage(
            businessId: businessId,
            initialPeriod: _scope,
          ),
        ),
      ),
    );
  }

  Widget _periodChips() {
    // FilterChip requires a Material ancestor; this page uses ColoredBox + scroll view
    // without Scaffold, so Material must wrap the chip row.
    return Material(
      color: _kBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
    if (_loading && _result == null) {
      return const ColoredBox(
        color: _kBackground,
        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (_error != null && _result == null) {
      return ColoredBox(
        color: _kBackground,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _kPrimary)),
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
        ),
      );
    }

    final res = _result!;
    final totals = res.totals;
    final multi = BusinessNotifier.instance.businesses.length > 1;

    return ColoredBox(
      color: _kBackground,
      child: SafeArea(
        child: RefreshIndicator(
          color: _kPrimary,
          onRefresh: () async {
            await BusinessNotifier.instance.refresh(widget.userId);
            await _load();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _periodChips()),
              if (multi)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Material(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 20, color: _kPrimary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _sw
                                    ? 'Muhtasari huu unajumlisha mapato ya ankara kwa biashara zako zote. Gusa biashara kuona maelezo na orodha ya miamala.'
                                    : 'This summary adds invoice revenue across all your businesses. Tap a business for detail and the transaction ledger.',
                                style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.35),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sw ? 'Jumla (ankara)' : 'Portfolio (invoices)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                      const SizedBox(height: 10),
                      _metricCard(
                        _sw ? 'Mapato jumla (ankara)' : 'Gross billed',
                        _money(totals.gross),
                      ),
                      const SizedBox(height: 10),
                      _metricCard(
                        _sw ? 'Mapato yaliyokusanywa' : 'Collected',
                        _money(totals.collected),
                      ),
                      const SizedBox(height: 10),
                      _metricCard(
                        _sw ? 'Baki' : 'Outstanding',
                        _money(totals.outstanding),
                      ),
                      if (res.ledgerHint != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 20, color: _kPrimary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _sw
                                      ? 'Orodha ya miamala (mapato yaliyofanikiwa, mwelekeo wa ndani): TZS ${_nf.format(res.ledgerHint!.incomingSuccessTotal)} — mistari ${res.ledgerHint!.rowCount}.'
                                      : 'Ledger hint (successful incoming): TZS ${_nf.format(res.ledgerHint!.incomingSuccessTotal)} across ${res.ledgerHint!.rowCount} row(s). Recognition uses completed_at on the server.',
                                  style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.35),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        _sw ? 'Kwa biashara' : 'By business',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final row = res.rows[index];
                    final highlight = widget.featureBusinessId != null &&
                        row.businessId == widget.featureBusinessId;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: highlight ? _kPrimary : Colors.black12,
                            width: highlight ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: row.canOpenDetail ? () => _openBusinessDetail(row.businessId!) : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        row.businessName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (row.canOpenDetail)
                                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
                                  ],
                                ),
                                if (row.loadFailed) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    row.loadError ?? (_sw ? 'Imeshindwa' : 'Failed'),
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_sw ? 'Jumla' : 'Gross'} · ${_money(row.gross)}',
                                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_sw ? 'Yaliyokusanywa' : 'Collected'} · ${_money(row.collected)} · ${_sw ? 'Baki' : 'Due'} · ${_money(row.outstanding)}',
                                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: res.rows.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
