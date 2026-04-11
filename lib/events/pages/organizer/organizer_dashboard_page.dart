// lib/events/pages/organizer/organizer_dashboard_page.dart
import 'package:flutter/material.dart';
import '../../models/event_analytics.dart';
import '../../models/event_strings.dart';
import '../../services/event_organizer_service.dart';
import '../../../services/local_storage_service.dart';
import 'attendee_management_page.dart';
import 'ticket_management_page.dart';
import 'team_management_page.dart';
import 'announcement_page.dart';
import 'sales_report_page.dart';
import 'payout_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class OrganizerDashboardPage extends StatefulWidget {
  final int eventId;
  final String eventName;

  const OrganizerDashboardPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<OrganizerDashboardPage> createState() => _OrganizerDashboardPageState();
}

class _OrganizerDashboardPageState extends State<OrganizerDashboardPage> {
  final _service = EventOrganizerService();
  late EventStrings _strings;
  EventAnalytics? _analytics;
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
    final result = await _service.getAnalytics(eventId: widget.eventId);
    if (!mounted) return;
    if (result.success) {
      setState(() { _analytics = result.data; _loading = false; });
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_strings.organizerDashboard, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(widget.eventName, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(color: _kPrimary, onRefresh: _load, child: _Body(analytics: _analytics!, eventId: widget.eventId, strings: _strings)),
    );
  }
}

class _Body extends StatelessWidget {
  final EventAnalytics analytics;
  final int eventId;
  final EventStrings strings;

  const _Body({required this.analytics, required this.eventId, required this.strings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionLabel(strings.overview),
        const SizedBox(height: 12),
        _MetricsGrid(analytics: analytics, strings: strings),
        const SizedBox(height: 24),
        _SectionLabel(strings.quickActions),
        const SizedBox(height: 12),
        _QuickActions(eventId: eventId, strings: strings),
        const SizedBox(height: 24),
        _SectionLabel(strings.recentSales),
        const SizedBox(height: 12),
        _RecentSalesList(eventId: eventId),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final EventAnalytics analytics;
  final EventStrings strings;

  const _MetricsGrid({required this.analytics, required this.strings});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (Icons.visibility_rounded, strings.views, '${analytics.totalViews}'),
      (Icons.check_circle_rounded, strings.going, '${analytics.goingCount}'),
      (Icons.confirmation_number_rounded, strings.ticketsSold, '${analytics.ticketsSold}'),
      (Icons.attach_money_rounded, strings.revenue, '${analytics.currency} ${analytics.totalRevenue.toStringAsFixed(0)}'),
      (Icons.how_to_reg_rounded, strings.checkInRate, '${analytics.checkInRate.toStringAsFixed(1)}%'),
      (Icons.share_rounded, strings.shares, '${analytics.sharesCount}'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, i) => _MetricCard(icon: metrics[i].$1, label: metrics[i].$2, value: metrics[i].$3),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: _kSecondary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final int eventId;
  final EventStrings strings;

  const _QuickActions({required this.eventId, required this.strings});

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, Widget Function())>[
      (Icons.group_rounded, strings.attendees, () => AttendeeManagementPage(eventId: eventId)),
      (Icons.confirmation_number_rounded, strings.tickets, () => TicketManagementPage(eventId: eventId)),
      (Icons.people_alt_rounded, strings.team, () => TeamManagementPage(eventId: eventId)),
      (Icons.campaign_rounded, strings.announcements, () => AnnouncementPage(eventId: eventId)),
      (Icons.bar_chart_rounded, strings.salesReport, () => SalesReportPage(eventId: eventId)),
      (Icons.payments_rounded, strings.payout, () => PayoutPage(eventId: eventId)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((a) => _ActionChip(
        icon: a.$1,
        label: a.$2,
        onTap: () => _navigate(context, a.$3()),
      )).toList(),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _RecentSalesList extends StatelessWidget {
  final int eventId;
  const _RecentSalesList({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: EventOrganizerService().getSalesReport(eventId: eventId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kPrimary));
        }
        final data = snap.data;
        if (data == null || !data.success || data.data == null) return const SizedBox.shrink();
        final sales = data.data!.recentSales;
        if (sales.isEmpty) return const SizedBox.shrink();
        return Column(children: sales.take(5).map((s) => _SaleTile(sale: s)).toList());
      },
    );
  }
}

class _SaleTile extends StatelessWidget {
  final TicketSale sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundColor: Color(0xFFEEEEEE), child: Icon(Icons.person_rounded, size: 18, color: _kSecondary)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sale.buyerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(sale.tierName, style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
          Text(sale.amount.toStringAsFixed(0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary));
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
