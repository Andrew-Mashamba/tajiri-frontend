// lib/invoices/pages/invoice_reports_page.dart
// Analytics and reports page for invoice performance — revenue trends,
// collection metrics, aging breakdown, top customers, and VAT summary.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import 'customer_statement_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

enum _Period { thisMonth, threeMonths, thisYear, custom }

class InvoiceReportsPage extends StatefulWidget {
  final int businessId;
  const InvoiceReportsPage({super.key, required this.businessId});

  @override
  State<InvoiceReportsPage> createState() => _InvoiceReportsPageState();
}

class _InvoiceReportsPageState extends State<InvoiceReportsPage> {
  List<Invoice> _allInvoices = [];
  bool _loading = true;
  String? _error;
  _Period _period = _Period.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  // Payment method breakdown
  Map<String, double> _paymentMethodTotals = {};
  Map<String, int> _paymentMethodCounts = {};
  bool _loadingPaymentMethods = false;

  final _currencyFmt = NumberFormat('#,##0', 'en');

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'No auth token';
        });
        return;
      }
      final result =
          await BusinessService.getInvoices(token, widget.businessId);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (result.success) {
          _allInvoices = result.data;
        } else {
          _error = result.message ?? 'Failed to load invoices';
        }
      });
      // Load payment method breakdown from paid invoices
      if (result.success) {
        _loadPaymentMethods(token);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadPaymentMethods(String token) async {
    // Get paid invoices with IDs, limited to 20 most recent
    final paidInvoices = _allInvoices
        .where((inv) =>
            inv.status == InvoiceStatus.paid && inv.id != null)
        .toList()
      ..sort((a, b) => (b.paidAt ?? b.createdAt ?? DateTime(2000))
          .compareTo(a.paidAt ?? a.createdAt ?? DateTime(2000)));
    final toFetch = paidInvoices.take(20).toList();
    if (toFetch.isEmpty) return;

    setState(() => _loadingPaymentMethods = true);
    try {
      final futures = toFetch.map((inv) =>
          BusinessService.getInvoicePayments(token, inv.id!));
      final results = await Future.wait(futures);
      if (!mounted) return;

      final totals = <String, double>{};
      final counts = <String, int>{};
      for (final res in results) {
        if (!res.success) continue;
        for (final payment in res.data) {
          final method = payment.method;
          totals[method] = (totals[method] ?? 0) + payment.amount;
          counts[method] = (counts[method] ?? 0) + 1;
        }
      }

      setState(() {
        _paymentMethodTotals = totals;
        _paymentMethodCounts = counts;
        _loadingPaymentMethods = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPaymentMethods = false);
    }
  }

  // ── Period helpers ──────────────────────────────────────────────────────

  DateTime _periodStart(_Period p) {
    final now = DateTime.now();
    switch (p) {
      case _Period.thisMonth:
        return DateTime(now.year, now.month, 1);
      case _Period.threeMonths:
        return DateTime(now.year, now.month - 2, 1);
      case _Period.thisYear:
        return DateTime(now.year, 1, 1);
      case _Period.custom:
        return _customStart ?? DateTime(now.year, now.month, 1);
    }
  }

  DateTime _periodEnd(_Period p) {
    if (p == _Period.custom && _customEnd != null) {
      return DateTime(_customEnd!.year, _customEnd!.month, _customEnd!.day, 23, 59, 59);
    }
    return DateTime.now();
  }

  DateTime _previousPeriodStart(_Period p) {
    final start = _periodStart(p);
    switch (p) {
      case _Period.thisMonth:
        return DateTime(start.year, start.month - 1, 1);
      case _Period.threeMonths:
        return DateTime(start.year, start.month - 3, 1);
      case _Period.thisYear:
        return DateTime(start.year - 1, 1, 1);
      case _Period.custom:
        final duration = (_customEnd ?? DateTime.now()).difference(start);
        return start.subtract(duration);
    }
  }

  DateTime _previousPeriodEnd(_Period p) {
    final start = _periodStart(p);
    return start.subtract(const Duration(days: 1));
  }

  List<Invoice> _filterByRange(DateTime start, DateTime end) {
    return _allInvoices.where((inv) {
      final d = inv.createdAt;
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  List<Invoice> _currentPeriodInvoices() {
    return _filterByRange(_periodStart(_period), _periodEnd(_period));
  }

  List<Invoice> _previousPeriodInvoices() {
    return _filterByRange(
        _previousPeriodStart(_period), _previousPeriodEnd(_period));
  }

  // ── Metric computations ────────────────────────────────────────────────

  double _totalRevenue(List<Invoice> invoices) {
    return invoices.fold<double>(0, (sum, inv) => sum + inv.amountPaid);
  }

  double _percentChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  double _avgDaysToPayment(List<Invoice> invoices) {
    final paid = invoices
        .where((inv) =>
            inv.status == InvoiceStatus.paid &&
            inv.paidAt != null &&
            inv.createdAt != null)
        .toList();
    if (paid.isEmpty) return 0;
    final totalDays = paid.fold<int>(
        0, (sum, inv) => sum + inv.paidAt!.difference(inv.createdAt!).inDays);
    return totalDays / paid.length;
  }

  double _collectionRate(List<Invoice> invoices) {
    final relevant = invoices
        .where((inv) =>
            inv.status == InvoiceStatus.paid && inv.dueDate != null && inv.paidAt != null)
        .toList();
    if (relevant.isEmpty) return 0;
    final onTime =
        relevant.where((inv) => !inv.paidAt!.isAfter(inv.dueDate!)).length;
    return (onTime / relevant.length) * 100;
  }

  double _overdueRate(List<Invoice> invoices) {
    final nonDraft = invoices
        .where((inv) =>
            inv.status != InvoiceStatus.draft &&
            inv.status != InvoiceStatus.void_status &&
            inv.status != InvoiceStatus.cancelled)
        .toList();
    if (nonDraft.isEmpty) return 0;
    final overdue = nonDraft.where((inv) => isInvoiceOverdue(inv)).length;
    return (overdue / nonDraft.length) * 100;
  }

  // ── Aging buckets ──────────────────────────────────────────────────────

  List<_AgingBucket> _agingBuckets() {
    final now = DateTime.now();
    final unpaid = _allInvoices.where((inv) {
      return inv.status != InvoiceStatus.paid &&
          inv.status != InvoiceStatus.void_status &&
          inv.status != InvoiceStatus.cancelled &&
          inv.status != InvoiceStatus.credit_noted &&
          inv.dueDate != null;
    }).toList();

    int c030 = 0, c3160 = 0, c6190 = 0, c90p = 0;
    double a030 = 0, a3160 = 0, a6190 = 0, a90p = 0;

    for (final inv in unpaid) {
      final daysOverdue = now.difference(inv.dueDate!).inDays;
      final bal = inv.balanceRemaining;
      if (daysOverdue <= 30) {
        c030++;
        a030 += bal;
      } else if (daysOverdue <= 60) {
        c3160++;
        a3160 += bal;
      } else if (daysOverdue <= 90) {
        c6190++;
        a6190 += bal;
      } else {
        c90p++;
        a90p += bal;
      }
    }

    final total = a030 + a3160 + a6190 + a90p;
    double pct(double v) => total > 0 ? (v / total) * 100 : 0;

    return [
      _AgingBucket('0-30', c030, a030, pct(a030), const Color(0xFF4CAF50)),
      _AgingBucket('31-60', c3160, a3160, pct(a3160), const Color(0xFFFFC107)),
      _AgingBucket('61-90', c6190, a6190, pct(a6190), const Color(0xFFFF9800)),
      _AgingBucket('90+', c90p, a90p, pct(a90p), const Color(0xFFF44336)),
    ];
  }

  // ── Top customers ──────────────────────────────────────────────────────

  List<_CustomerSummary> _topCustomers(List<Invoice> invoices) {
    final map = <String, _CustomerSummary>{};
    for (final inv in invoices) {
      final name = inv.customerName ?? 'Unknown';
      final existing = map[name];
      if (existing == null) {
        map[name] = _CustomerSummary(
          name: name,
          totalInvoiced: inv.totalAmount,
          totalPaid: inv.amountPaid,
          outstanding: inv.balanceRemaining,
          invoiceCount: 1,
          totalPayDays: (inv.status == InvoiceStatus.paid &&
                  inv.paidAt != null &&
                  inv.createdAt != null)
              ? inv.paidAt!.difference(inv.createdAt!).inDays
              : 0,
          paidCount: inv.status == InvoiceStatus.paid ? 1 : 0,
        );
      } else {
        map[name] = _CustomerSummary(
          name: name,
          totalInvoiced: existing.totalInvoiced + inv.totalAmount,
          totalPaid: existing.totalPaid + inv.amountPaid,
          outstanding: existing.outstanding + inv.balanceRemaining,
          invoiceCount: existing.invoiceCount + 1,
          totalPayDays: existing.totalPayDays +
              ((inv.status == InvoiceStatus.paid &&
                      inv.paidAt != null &&
                      inv.createdAt != null)
                  ? inv.paidAt!.difference(inv.createdAt!).inDays
                  : 0),
          paidCount: existing.paidCount +
              (inv.status == InvoiceStatus.paid ? 1 : 0),
        );
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.totalPaid.compareTo(a.totalPaid));
    return list.take(5).toList();
  }

  // ── VAT ────────────────────────────────────────────────────────────────

  double _totalVat(List<Invoice> invoices) {
    return invoices
        .where((inv) => inv.status == InvoiceStatus.paid)
        .fold<double>(0, (sum, inv) => sum + inv.vatAmount);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    final sw = strings?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: Text(
          sw ? 'Ripoti za Ankara' : 'Invoice Reports',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _buildError(sw)
              : _buildContent(sw),
    );
  }

  Widget _buildError(bool sw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kSecondary, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadInvoices,
              child: Text(sw ? 'Jaribu tena' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool sw) {
    final current = _currentPeriodInvoices();
    final previous = _previousPeriodInvoices();

    if (_allInvoices.isEmpty) {
      return _buildEmpty(sw);
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _loadInvoices,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodPicker(sw),
          const SizedBox(height: 16),
          if (current.isEmpty) ...[
            _buildEmpty(sw),
          ] else ...[
            _buildRevenueCard(current, previous, sw),
            const SizedBox(height: 16),
            _buildMonthlyRevenueChart(current, sw),
            const SizedBox(height: 16),
            _buildCollectionCard(current, previous, sw),
            const SizedBox(height: 16),
            _buildAgingCard(sw),
            const SizedBox(height: 16),
            _buildPaymentMethodsCard(sw),
            const SizedBox(height: 16),
            _buildTopCustomersCard(current, sw),
            const SizedBox(height: 16),
            _buildVatCard(current, sw),
            const SizedBox(height: 16),
            _buildExportButtons(sw),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(bool sw) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded, size: 56, color: _kSecondary),
            const SizedBox(height: 12),
            Text(
              sw
                  ? 'Hakuna ankara katika kipindi hiki'
                  : 'No invoices in this period',
              style: const TextStyle(color: _kSecondary, fontSize: 15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Period Picker ──────────────────────────────────────────────────────

  Future<void> _pickCustomDateRange(bool sw) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kPrimary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customStart = picked.start;
      _customEnd = picked.end;
      _period = _Period.custom;
    });
  }

  Widget _buildPeriodPicker(bool sw) {
    return Row(
      children: [
        _periodChip(_Period.thisMonth, sw ? 'Mwezi huu' : 'This Month'),
        const SizedBox(width: 8),
        _periodChip(_Period.threeMonths, sw ? 'Miezi 3' : '3 Months'),
        const SizedBox(width: 8),
        _periodChip(_Period.thisYear, sw ? 'Mwaka huu' : 'This Year'),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _pickCustomDateRange(sw),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _period == _Period.custom ? _kPrimary : _kCardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _period == _Period.custom ? _kPrimary : const Color(0xFFDDDDDD),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 14,
                  color: _period == _Period.custom ? Colors.white : _kSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  sw ? 'Desturi' : 'Custom',
                  style: TextStyle(
                    color: _period == _Period.custom ? Colors.white : _kSecondary,
                    fontSize: 13,
                    fontWeight: _period == _Period.custom
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _periodChip(_Period p, String label) {
    final selected = _period == p;
    return GestureDetector(
      onTap: () => setState(() => _period = p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kPrimary : const Color(0xFFDDDDDD)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _kSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ── Revenue Summary Card ───────────────────────────────────────────────

  Widget _buildRevenueCard(
      List<Invoice> current, List<Invoice> previous, bool sw) {
    final rev = _totalRevenue(current);
    final prevRev = _totalRevenue(previous);
    final change = _percentChange(rev, prevRev);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Mapato' : 'Revenue',
            style: const TextStyle(
                color: _kSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'TZS ${_currencyFmt.format(rev)}',
            style: const TextStyle(
                color: _kPrimary, fontSize: 28, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          _trendText(change, sw),
        ],
      ),
    );
  }

  Widget _trendText(double pct, bool sw) {
    final positive = pct >= 0;
    final arrow = positive ? '\u2191' : '\u2193';
    final color = positive ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final label =
        sw ? 'dhidi ya kipindi kilichopita' : 'vs previous period';
    return Text(
      '$arrow ${pct.abs().toStringAsFixed(1)}% $label',
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ── Monthly Revenue Bar Chart ───────────────────────────────────────────

  Widget _buildMonthlyRevenueChart(List<Invoice> invoices, bool sw) {
    // Group paid invoices by month
    final paid = invoices.where((inv) => inv.status == InvoiceStatus.paid).toList();
    if (paid.isEmpty) return const SizedBox.shrink();

    final monthTotals = <String, double>{};
    final monthKeys = <String>[]; // ordered
    final monthFmt = DateFormat('MMM');
    for (final inv in paid) {
      final d = inv.paidAt ?? inv.createdAt;
      if (d == null) continue;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      monthTotals[key] = (monthTotals[key] ?? 0) + inv.amountPaid;
      if (!monthKeys.contains(key)) monthKeys.add(key);
    }
    monthKeys.sort();
    // Show up to last 6 months
    final displayKeys = monthKeys.length > 6
        ? monthKeys.sublist(monthKeys.length - 6)
        : monthKeys;

    final maxVal = displayKeys.fold<double>(
        0, (mx, k) => (monthTotals[k] ?? 0) > mx ? (monthTotals[k] ?? 0) : mx);
    if (maxVal == 0) return const SizedBox.shrink();

    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Mapato kwa Mwezi' : 'Monthly Revenue',
            style: const TextStyle(
                color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: displayKeys.map((key) {
                final val = monthTotals[key] ?? 0;
                final barHeight = (val / maxVal) * 120;
                final isCurrent = key == currentMonthKey;
                final parts = key.split('-');
                final monthDate =
                    DateTime(int.parse(parts[0]), int.parse(parts[1]));
                final label = monthFmt.format(monthDate);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFmt.format(val),
                          style: const TextStyle(
                              color: _kSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight.clamp(4.0, 120.0),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? _kPrimary
                                : _kPrimary.withValues(alpha: 0.6),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: isCurrent ? _kPrimary : _kSecondary,
                            fontSize: 11,
                            fontWeight: isCurrent
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Collection Performance Card ────────────────────────────────────────

  Widget _buildCollectionCard(
      List<Invoice> current, List<Invoice> previous, bool sw) {
    final avgDays = _avgDaysToPayment(current);
    final prevAvgDays = _avgDaysToPayment(previous);
    final colRate = _collectionRate(current);
    final prevColRate = _collectionRate(previous);
    final ovrRate = _overdueRate(current);
    final prevOvrRate = _overdueRate(previous);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Utendaji wa Ukusanyaji' : 'Collection Performance',
            style: const TextStyle(
                color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _metricRow(
            label: sw ? 'Wastani siku za malipo' : 'Avg days to payment',
            value: '${avgDays.toStringAsFixed(1)} ${sw ? 'siku' : 'days'}',
            current: avgDays,
            previous: prevAvgDays,
            lowerIsBetter: true,
          ),
          const Divider(height: 20),
          _metricRow(
            label: sw ? 'Kiwango cha ukusanyaji' : 'Collection rate',
            value: '${colRate.toStringAsFixed(1)}%',
            current: colRate,
            previous: prevColRate,
            lowerIsBetter: false,
          ),
          const Divider(height: 20),
          _metricRow(
            label: sw ? 'Kiwango cha uchelewaji' : 'Overdue rate',
            value: '${ovrRate.toStringAsFixed(1)}%',
            current: ovrRate,
            previous: prevOvrRate,
            lowerIsBetter: true,
          ),
        ],
      ),
    );
  }

  Widget _metricRow({
    required String label,
    required String value,
    required double current,
    required double previous,
    required bool lowerIsBetter,
  }) {
    final diff = current - previous;
    final improved = lowerIsBetter ? diff <= 0 : diff >= 0;
    final color =
        improved ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final arrow = (diff == 0) ? '' : (improved ? '\u2191' : '\u2193');

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _kSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
              color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (arrow.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(arrow, style: TextStyle(color: color, fontSize: 14)),
        ],
      ],
    );
  }

  // ── Aging Report Card ──────────────────────────────────────────────────

  Widget _buildAgingCard(bool sw) {
    final buckets = _agingBuckets();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Ripoti ya Umri wa Deni' : 'Aging Report',
            style: const TextStyle(
                color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Header row
          Row(
            children: [
              const SizedBox(width: 6),
              Expanded(
                  flex: 2,
                  child: Text(sw ? 'Kipindi' : 'Age',
                      style: const TextStyle(
                          color: _kSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              Expanded(
                  child: Text(sw ? 'Idadi' : 'Count',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: _kSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              Expanded(
                  flex: 2,
                  child: Text(sw ? 'Kiasi' : 'Amount',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: _kSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              const Expanded(
                  child: Text('%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: _kSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Divider(height: 16),
          ...buckets.map((b) => _agingRow(b, sw)),
        ],
      ),
    );
  }

  Widget _agingRow(_AgingBucket b, bool sw) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: b.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Text(
              '${b.label} ${sw ? 'siku' : 'days'}',
              style: const TextStyle(color: _kPrimary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${b.count}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: _kPrimary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TZS ${_currencyFmt.format(b.amount)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${b.percent.toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(color: _kSecondary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment Methods Card ────────────────────────────────────────────────

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'mpesa':
      case 'tigo_pesa':
      case 'airtel_money':
        return Icons.phone_android_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.payments_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String _paymentMethodLabel(String method, bool sw) {
    switch (method) {
      case 'mpesa':
        return 'M-Pesa';
      case 'tigo_pesa':
        return 'Tigo Pesa';
      case 'airtel_money':
        return 'Airtel Money';
      case 'bank':
        return sw ? 'Benki' : 'Bank';
      case 'cash':
        return sw ? 'Taslimu' : 'Cash';
      case 'wallet':
        return 'Wallet';
      default:
        return method;
    }
  }

  Widget _buildPaymentMethodsCard(bool sw) {
    if (_loadingPaymentMethods) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sw ? 'Njia za Malipo' : 'Payment Methods',
              style: const TextStyle(
                  color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              ),
            ),
          ],
        ),
      );
    }

    if (_paymentMethodTotals.isEmpty) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sw ? 'Njia za Malipo' : 'Payment Methods',
              style: const TextStyle(
                  color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              sw ? 'Hakuna data ya malipo bado' : 'No payment data yet',
              style: const TextStyle(color: _kSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Sort by total descending
    final sortedMethods = _paymentMethodTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = sortedMethods.fold<double>(0, (s, e) => s + e.value);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Njia za Malipo' : 'Payment Methods',
            style: const TextStyle(
                color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sw
                ? 'Sampuli ya ankara 20 za hivi karibuni'
                : 'Sample of 20 most recent invoices',
            style: const TextStyle(color: _kSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ...sortedMethods.map((entry) {
            final method = entry.key;
            final total = entry.value;
            final count = _paymentMethodCounts[method] ?? 0;
            final pct = grandTotal > 0 ? (total / grandTotal) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_paymentMethodIcon(method), size: 16, color: _kSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _paymentMethodLabel(method, sw),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$count ${sw ? 'malipo' : 'payments'}',
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TZS ${_currencyFmt.format(total)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(pct * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Top Customers Card ─────────────────────────────────────────────────

  Widget _buildTopCustomersCard(List<Invoice> invoices, bool sw) {
    final customers = _topCustomers(invoices);
    if (customers.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Wateja Wakuu' : 'Top Customers',
            style: const TextStyle(
                color: _kPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ...customers.map((c) => _customerRow(c, sw)),
        ],
      ),
    );
  }

  Widget _customerRow(_CustomerSummary c, bool sw) {
    final avgDays =
        c.paidCount > 0 ? (c.totalPayDays / c.paidCount).round() : 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerStatementPage(
              businessId: widget.businessId,
              customerName: c.name,
            ),
          ),
        );
      },
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.name,
            style: const TextStyle(
                color: _kPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _miniStat(sw ? 'Ankara' : 'Invoiced',
                  'TZS ${_currencyFmt.format(c.totalInvoiced)}'),
              const SizedBox(width: 12),
              _miniStat(sw ? 'Limelipwa' : 'Paid',
                  'TZS ${_currencyFmt.format(c.totalPaid)}'),
              const SizedBox(width: 12),
              _miniStat(sw ? 'Baki' : 'Due',
                  'TZS ${_currencyFmt.format(c.outstanding)}'),
              const SizedBox(width: 12),
              _miniStat(
                  sw ? 'Wst. siku' : 'Avg days', '$avgDays'),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: _kSecondary, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── VAT Summary Card ───────────────────────────────────────────────────

  Widget _buildVatCard(List<Invoice> invoices, bool sw) {
    final vat = _totalVat(invoices);

    // Monthly VAT breakdown
    final paidInvoices =
        invoices.where((inv) => inv.status == InvoiceStatus.paid).toList();
    final monthlyVat = <String, _MonthlyVatEntry>{};
    final monthKeys = <String>[];
    for (final inv in paidInvoices) {
      final d = inv.paidAt ?? inv.createdAt;
      if (d == null) continue;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      final existing = monthlyVat[key];
      if (existing == null) {
        monthlyVat[key] = _MonthlyVatEntry(vatTotal: inv.vatAmount, count: 1);
        monthKeys.add(key);
      } else {
        monthlyVat[key] = _MonthlyVatEntry(
          vatTotal: existing.vatTotal + inv.vatAmount,
          count: existing.count + 1,
        );
      }
    }
    monthKeys.sort();
    final monthFmt = DateFormat('MMM yyyy');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  color: _kSecondary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw ? 'Jumla ya VAT Iliyokusanywa' : 'Total VAT Collected',
                      style: const TextStyle(
                          color: _kSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TZS ${_currencyFmt.format(vat)}',
                      style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (monthKeys.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Table header
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    sw ? 'Mwezi' : 'Month',
                    style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    sw ? 'VAT Iliyokusanywa' : 'VAT Collected',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    sw ? 'Ankara' : 'Invoices',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...monthKeys.map((key) {
              final entry = monthlyVat[key]!;
              final parts = key.split('-');
              final monthDate =
                  DateTime(int.parse(parts[0]), int.parse(parts[1]));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        monthFmt.format(monthDate),
                        style:
                            const TextStyle(color: _kPrimary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'TZS ${_currencyFmt.format(entry.vatTotal)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${entry.count}',
                        textAlign: TextAlign.right,
                        style:
                            const TextStyle(color: _kSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Export Buttons ──────────────────────────────────────────────────────

  Widget _buildExportButtons(bool sw) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sw
                      ? 'Inakuja hivi karibuni'
                      : 'Coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: Text(
              sw ? 'Pakua PDF' : 'Download PDF',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sw
                      ? 'Inakuja hivi karibuni'
                      : 'Coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.table_chart_rounded, size: 18),
            label: Text(
              sw ? 'Pakua CSV' : 'Download CSV',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sw
                      ? 'Inakuja hivi karibuni'
                      : 'Coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(
              sw ? 'Shiriki' : 'Share',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared card wrapper ────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: child,
    );
  }
}

// ── Helper models ──────────────────────────────────────────────────────────

class _AgingBucket {
  final String label;
  final int count;
  final double amount;
  final double percent;
  final Color color;
  const _AgingBucket(this.label, this.count, this.amount, this.percent, this.color);
}

class _MonthlyVatEntry {
  final double vatTotal;
  final int count;
  const _MonthlyVatEntry({required this.vatTotal, required this.count});
}

class _CustomerSummary {
  final String name;
  final double totalInvoiced;
  final double totalPaid;
  final double outstanding;
  final int invoiceCount;
  final int totalPayDays;
  final int paidCount;
  const _CustomerSummary({
    required this.name,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.outstanding,
    required this.invoiceCount,
    required this.totalPayDays,
    required this.paidCount,
  });
}
