// lib/suppliers/pages/supplier_analytics_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../business/models/business_models.dart';
import '../../business/services/business_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class SupplierAnalyticsPage extends StatefulWidget {
  final int businessId;
  final int supplierId;
  final String supplierName;
  final bool isSwahili;

  const SupplierAnalyticsPage({
    super.key,
    required this.businessId,
    required this.supplierId,
    required this.supplierName,
    required this.isSwahili,
  });

  @override
  State<SupplierAnalyticsPage> createState() => _SupplierAnalyticsPageState();
}

class _SupplierAnalyticsPageState extends State<SupplierAnalyticsPage> {
  String? _token;
  bool _loading = true;
  String? _error;
  SupplierAnalytics? _analytics;

  final _nf = NumberFormat('#,###', 'en');
  final _df = DateFormat('dd MMM yyyy');

  bool get _sw => widget.isSwahili;

  Future<void> _shareReport() async {
    final a = _analytics;
    if (a == null) return;
    final buffer = StringBuffer();
    buffer.writeln(_sw
        ? '📊 Ripoti ya Matumizi — ${widget.supplierName}'
        : '📊 Spending Report — ${widget.supplierName}');
    buffer.writeln();
    buffer.writeln('${_sw ? "Mwezi Huu" : "This Month"}: TZS ${_nf.format(a.currentMonthSpent)}');
    buffer.writeln('${_sw ? "Mwaka Huu" : "This Year"}: TZS ${_nf.format(a.thisYearSpent)}');
    buffer.writeln('${_sw ? "Jumla Iliyotumika" : "Total Spent"}: TZS ${_nf.format(a.totalSpent)}');
    buffer.writeln('${_sw ? "Maagizo Yote" : "Total Orders"}: ${a.poCount}');
    if (a.topItems.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_sw ? 'Bidhaa za Juu:' : 'Top Items:');
      for (final item in a.topItems.take(3)) {
        buffer.writeln('  • ${item.description} — TZS ${_nf.format(item.totalValue)}');
      }
    }
    buffer.writeln();
    buffer.writeln(_sw ? 'Imetolewa na TAJIRI' : 'Generated via TAJIRI');
    final encoded = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) {
      setState(() {
        _loading = false;
        _error = _sw ? 'Hujaingia' : 'Not authenticated';
      });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await BusinessService.getSupplierAnalytics(
          _token!, widget.businessId, widget.supplierId);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _analytics = res.data;
          } else {
            _error = res.message ??
                (_sw ? 'Imeshindikana kupata data' : 'Failed to load analytics');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = e.toString(); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sw ? 'Matumizi' : 'Spending',
              style: const TextStyle(
                  color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.supplierName,
              style: const TextStyle(color: _kSecondary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/tea'),
            icon: const Icon(Icons.psychology_rounded, color: _kSecondary),
            tooltip: _sw ? 'Omba Ushauri • Shangazi' : 'Ask Shangazi',
          ),
          if (_analytics != null)
            IconButton(
              onPressed: _shareReport,
              icon: const Icon(Icons.share_rounded, color: _kPrimary),
              tooltip: _sw ? 'Shiriki Ripoti' : 'Share Report',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: _kSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _load,
                          child: Text(_sw ? 'Jaribu tena' : 'Retry')),
                    ],
                  ),
                )
              : _analytics == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      color: _kPrimary,
                      onRefresh: _load,
                      child: _buildContent(_analytics!),
                    ),
    );
  }

  Widget _buildContent(SupplierAnalytics a) {
    // Compute month-over-month comparison
    final hasComparison = a.lastMonthSpent > 0 || a.currentMonthSpent > 0;
    double? changePercent;
    if (a.lastMonthSpent > 0) {
      changePercent =
          ((a.currentMonthSpent - a.lastMonthSpent) / a.lastMonthSpent) * 100;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stat cards row: This Month + This Year
        Row(
          children: [
            Expanded(
              child: _statCard(
                _sw ? 'Mwezi Huu' : 'This Month',
                'TZS ${_nf.format(a.currentMonthSpent)}',
                Icons.calendar_today_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                _sw ? 'Mwaka Huu' : 'This Year',
                'TZS ${_nf.format(a.thisYearSpent)}',
                Icons.calendar_month_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                _sw ? 'Maagizo Yote' : 'Total Orders',
                '${a.poCount}',
                Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                _sw ? 'Jumla Yote' : 'All-Time Spend',
                'TZS ${_nf.format(a.totalSpent)}',
                Icons.account_balance_wallet_rounded,
              ),
            ),
          ],
        ),

        // Month-over-month comparison note
        if (hasComparison) ...[
          const SizedBox(height: 12),
          _comparisonNote(a.currentMonthSpent, a.lastMonthSpent, changePercent),
        ],

        // 6-month trend chart
        if (a.monthlyTrend.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            _sw ? 'Mwenendo wa Miezi 6' : '6-Month Trend',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          _TappableBarChart(points: a.monthlyTrend, isSwahili: _sw),
        ],

        // Top items section
        if (a.topItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            _sw ? 'Bidhaa Zinazoonekana Zaidi' : 'Most Ordered Items',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: a.topItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final maxVal = a.topItems
                    .map((e) => e.totalValue)
                    .fold(0.0, (p, c) => c > p ? c : p);
                final ratio = maxVal > 0 ? item.totalValue / maxVal : 0.0;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _kPrimary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                    child: Text('${idx + 1}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimary))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(item.description,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('TZS ${_nf.format(item.totalValue)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary)),
                                  if (item.count > 0)
                                    Text(
                                      '${item.count} ${_sw ? "mara" : "times"}',
                                      style: const TextStyle(
                                          fontSize: 11, color: _kSecondary),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.grey.shade100,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(_kPrimary),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (idx < a.topItems.length - 1)
                      Divider(height: 1, color: Colors.grey.shade100),
                  ],
                );
              }).toList(),
            ),
          ),
        ],

        // PO history list
        if (a.recentPos.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            _sw ? 'Maagizo ya Hivi Karibuni' : 'Recent Orders',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: a.recentPos.asMap().entries.map((entry) {
                final idx = entry.key;
                final po = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  po.poNumber.isNotEmpty
                                      ? po.poNumber
                                      : 'PO-${po.id ?? ""}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPrimary),
                                ),
                                if (po.receivedDate != null)
                                  Text(
                                    _df.format(po.receivedDate!),
                                    style: const TextStyle(
                                        fontSize: 11, color: _kSecondary),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            'TZS ${_nf.format(po.totalAmount)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary),
                          ),
                        ],
                      ),
                    ),
                    if (idx < a.recentPos.length - 1)
                      Divider(height: 1, color: Colors.grey.shade100),
                  ],
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _comparisonNote(
      double current, double last, double? changePercent) {
    final isDown = (changePercent ?? 0) < 0;
    final isFlat = changePercent == null || changePercent == 0;
    final color = isFlat
        ? _kSecondary
        : isDown
            ? Colors.green.shade700
            : Colors.red.shade700;

    String label;
    if (isFlat) {
      label = _sw
          ? 'Mwezi huu vs mwezi uliopita: hakuna mabadiliko'
          : 'This month vs last month: no change';
    } else {
      final sign = isDown ? '' : '+';
      final pct = changePercent.abs().toStringAsFixed(1);
      label = _sw
          ? 'Mwezi huu vs mwezi uliopita: $sign${isDown ? "-" : ""}$pct%'
          : 'This month vs last month: $sign${changePercent.toStringAsFixed(1)}%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isFlat
                ? Icons.remove_circle_outline_rounded
                : isDown
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TappableBarChart extends StatefulWidget {
  final List<SupplierAnalyticsMonthPoint> points;
  final bool isSwahili;

  const _TappableBarChart({required this.points, required this.isSwahili});

  @override
  State<_TappableBarChart> createState() => _TappableBarChartState();
}

class _TappableBarChartState extends State<_TappableBarChart> {
  int? _tappedIndex;
  final _nf = NumberFormat('#,###', 'en');

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final maxVal =
        points.map((p) => p.spent).fold(0.0, (a, b) => b > a ? b : a);
    const barHeight = 120.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          SizedBox(
            height: barHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: points.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final ratio = maxVal > 0 ? p.spent / maxVal : 0.0;
                final h = ratio * (barHeight - 20);
                final isTapped = _tappedIndex == i;

                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _tappedIndex = isTapped ? null : i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isTapped)
                            Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kPrimary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TZS ${_nf.format(p.spent)}',
                                style: const TextStyle(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else if (p.spent > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                _compact(p.spent),
                                style: const TextStyle(
                                    fontSize: 9, color: _kSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          Container(
                            height: h > 4 ? h : 4,
                            decoration: BoxDecoration(
                              color: isTapped
                                  ? _kPrimary
                                  : _kPrimary.withValues(
                                      alpha: 0.5 + 0.5 * ratio),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: points.map((p) {
              final parts = p.month.split('-');
              final label = parts.length == 2
                  ? _monthAbbr(int.tryParse(parts[1]) ?? 1)
                  : p.month;
              return Expanded(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 9, color: _kSecondary)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _monthAbbr(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return m >= 1 && m <= 12 ? months[m - 1] : '$m';
  }
}
