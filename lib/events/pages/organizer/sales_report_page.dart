// lib/events/pages/organizer/sales_report_page.dart
import 'package:flutter/material.dart';
import '../../models/event_analytics.dart';
import '../../models/event_strings.dart';
import '../../services/event_organizer_service.dart';
import '../../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SalesReportPage extends StatefulWidget {
  final int eventId;

  const SalesReportPage({super.key, required this.eventId});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final _service = EventOrganizerService();
  late EventStrings _strings;
  SalesReport? _report;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await _service.getSalesReport(eventId: widget.eventId);
    if (!mounted) return;
    if (result.success) {
      setState(() { _report = result.data; _loading = false; });
    } else {
      setState(() { _error = result.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(_strings.salesReport, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(color: _kPrimary, onRefresh: _load, child: _Body(report: _report!, strings: _strings)),
    );
  }
}

class _Body extends StatelessWidget {
  final SalesReport report;
  final EventStrings strings;

  const _Body({required this.report, required this.strings});

  @override
  Widget build(BuildContext context) {
    final currency = report.currency;
    final summaryCards = [
      (strings.grossRevenue, '$currency ${report.grossRevenue.toStringAsFixed(0)}', Icons.trending_up_rounded),
      (strings.platformFees, '$currency ${report.platformFees.toStringAsFixed(0)}', Icons.receipt_long_rounded),
      (strings.netRevenue, '$currency ${report.netRevenue.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded),
      (strings.pendingPayout, '$currency ${report.pendingPayout.toStringAsFixed(0)}', Icons.hourglass_top_rounded),
      (strings.paidOut, '$currency ${report.paidOut.toStringAsFixed(0)}', Icons.check_circle_outline_rounded),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Revenue Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: summaryCards.length,
          itemBuilder: (_, i) => _SummaryCard(
            label: summaryCards[i].$1,
            value: summaryCards[i].$2,
            icon: summaryCards[i].$3,
            highlight: i == 2,
          ),
        ),
        const SizedBox(height: 24),
        const Text('Recent Sales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 12),
        if (report.recentSales.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No sales recorded yet.', style: TextStyle(color: _kSecondary)),
          )
        else
          ...report.recentSales.map((sale) => _SaleTile(sale: sale, currency: currency)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _SummaryCard({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? _kPrimary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: highlight ? null : Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: highlight ? Colors.white70 : _kSecondary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: highlight ? Colors.white : _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(label, style: TextStyle(fontSize: 11, color: highlight ? Colors.white70 : _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final TicketSale sale;
  final String currency;

  const _SaleTile({required this.sale, required this.currency});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTime(sale.purchasedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundColor: Color(0xFFEEEEEE), child: Icon(Icons.receipt_rounded, size: 18, color: _kSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sale.buyerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${sale.tierName}  ·  $timeAgo', style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
          Text('$currency ${sale.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _kSecondary)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry', style: TextStyle(color: _kPrimary))),
          ],
        ),
      ),
    );
  }
}
