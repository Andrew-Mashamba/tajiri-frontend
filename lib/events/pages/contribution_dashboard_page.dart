// lib/events/pages/contribution_dashboard_page.dart
import 'package:flutter/material.dart';
import '../models/contribution.dart';
import '../models/event_strings.dart';
import '../services/event_contribution_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ContributionDashboardPage extends StatefulWidget {
  final int eventId;
  final String eventName;

  const ContributionDashboardPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<ContributionDashboardPage> createState() => _ContributionDashboardPageState();
}

class _ContributionDashboardPageState extends State<ContributionDashboardPage> {
  final _service = EventContributionService();
  late EventStrings _strings;

  ContributionSummary? _summary;
  List<Contribution> _contributions = [];
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
    final summaryResult = await _service.getSummary(eventId: widget.eventId);
    final contribResult = await _service.getContributions(eventId: widget.eventId);
    if (!mounted) return;
    if (summaryResult.success) {
      setState(() {
        _summary = summaryResult.data;
        _contributions = contribResult.success ? contribResult.items : [];
        _loading = false;
      });
    } else {
      setState(() { _error = summaryResult.message; _loading = false; });
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
            Text(_strings.isSwahili ? 'Michango' : 'Contributions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(widget.eventName,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_strings.isSwahili ? 'Rekodi Mchango' : 'Record Cash'),
        onPressed: _showRecordDialog,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: _Body(
                    summary: _summary!,
                    contributions: _contributions,
                    strings: _strings,
                    service: _service,
                    eventId: widget.eventId,
                    onRefresh: _load,
                  ),
                ),
    );
  }

  void _showRecordDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    ContributorCategory category = ContributorCategory.wengine;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: _kBg,
          title: Text(
            _strings.isSwahili ? 'Rekodi Mchango' : 'Record Contribution',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(controller: nameCtrl,
                    label: _strings.isSwahili ? 'Jina la Mchangiaji' : 'Contributor Name'),
                const SizedBox(height: 10),
                _Field(controller: phoneCtrl,
                    label: _strings.isSwahili ? 'Simu (Hiari)' : 'Phone (Optional)',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _Field(controller: amountCtrl,
                    label: _strings.isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                DropdownButtonFormField<ContributorCategory>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: _strings.isSwahili ? 'Kundi' : 'Category',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: ContributorCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setSt(() => category = v ?? ContributorCategory.wengine),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_strings.back, style: const TextStyle(color: _kSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text.trim());
                if (name.isEmpty || amount == null || amount <= 0) return;
                Navigator.pop(ctx);
                await _service.recordContribution(
                  eventId: widget.eventId,
                  contributorName: name,
                  contributorPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  amount: amount,
                  category: category,
                );
                _load();
              },
              child: Text(_strings.isSwahili ? 'Hifadhi' : 'Save',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final ContributionSummary summary;
  final List<Contribution> contributions;
  final EventStrings strings;
  final EventContributionService service;
  final int eventId;
  final VoidCallback onRefresh;

  const _Body({
    required this.summary, required this.contributions, required this.strings,
    required this.service, required this.eventId, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProgressCard(summary: summary, strings: strings),
        const SizedBox(height: 16),
        _StatsRow(summary: summary, strings: strings),
        const SizedBox(height: 20),
        _SectionLabel(strings.isSwahili ? 'Vitendo vya Haraka' : 'Quick Actions'),
        const SizedBox(height: 10),
        _QuickActions(
          eventId: eventId, service: service,
          strings: strings, onRefresh: onRefresh,
        ),
        const SizedBox(height: 20),
        _SectionLabel(strings.isSwahili ? 'Wachangiaji' : 'Contributors'),
        const SizedBox(height: 10),
        if (contributions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                strings.isSwahili ? 'Hakuna michango bado' : 'No contributions yet',
                style: const TextStyle(color: _kSecondary),
              ),
            ),
          )
        else
          ...contributions.map((c) => _ContributorTile(contribution: c, strings: strings)),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ContributionSummary summary;
  final EventStrings strings;
  const _ProgressCard({required this.summary, required this.strings});

  @override
  Widget build(BuildContext context) {
    final pct = summary.progressPercent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.isSwahili ? 'Maendeleo ya Mkusanyo' : 'Collection Progress',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8E8E8),
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.formatPrice(summary.totalCollected, summary.currency),
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              Text(
                strings.formatPrice(summary.goalAmount, summary.currency),
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final ContributionSummary summary;
  final EventStrings strings;
  const _StatsRow({required this.summary, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: strings.isSwahili ? 'Zilizolipwa' : 'Collected',
          value: strings.formatPrice(summary.totalCollected, summary.currency),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: strings.isSwahili ? 'Zilizoahidiwa' : 'Pledged',
          value: strings.formatPrice(summary.totalPledged, summary.currency),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: strings.isSwahili ? 'Zinazobaki' : 'Outstanding',
          value: strings.formatPrice(summary.outstanding, summary.currency),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: _kSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final int eventId;
  final EventContributionService service;
  final EventStrings strings;
  final VoidCallback onRefresh;

  const _QuickActions({
    required this.eventId, required this.service,
    required this.strings, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionChip(
          icon: Icons.notifications_rounded,
          label: strings.isSwahili ? 'Kumbusho' : 'Remind All',
          onTap: () async {
            await service.sendBulkReminder(eventId: eventId, status: ContributionStatus.pledged);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(strings.isSwahili ? 'Kumbusho zimetumwa' : 'Reminders sent'),
                backgroundColor: _kPrimary,
              ));
            }
          },
        ),
        const SizedBox(width: 8),
        _ActionChip(
          icon: Icons.category_rounded,
          label: strings.isSwahili ? 'Kwa Kundi' : 'By Category',
          onTap: () => _showCategorySheet(context),
        ),
      ],
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                strings.isSwahili ? 'Chagua Kundi' : 'View by Category',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ),
            ...ContributorCategory.values.map((c) => ListTile(
              title: Text(c.displayName, style: const TextStyle(fontSize: 13, color: _kPrimary)),
              subtitle: Text(c.subtitle, style: const TextStyle(fontSize: 11, color: _kSecondary)),
              onTap: () => Navigator.pop(context),
            )),
          ],
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _kPrimary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ContributorTile extends StatelessWidget {
  final Contribution contribution;
  final EventStrings strings;
  const _ContributorTile({required this.contribution, required this.strings});

  Color get _statusColor {
    switch (contribution.status) {
      case ContributionStatus.paid: return const Color(0xFF4CAF50);
      case ContributionStatus.overdue: return const Color(0xFFF44336);
      case ContributionStatus.partiallyPaid: return const Color(0xFFFF9800);
      default: return _kSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8E8E8),
            backgroundImage: contribution.avatarUrl != null ? NetworkImage(contribution.avatarUrl!) : null,
            child: contribution.avatarUrl == null
                ? Text(
                    contribution.contributorName.isNotEmpty ? contribution.contributorName[0].toUpperCase() : '?',
                    style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contribution.contributorName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(contribution.category.displayName,
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                strings.formatPrice(contribution.amountPaid, 'TZS'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  contribution.status.displayName,
                  style: TextStyle(fontSize: 9, color: _statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kSecondary, letterSpacing: 0.5));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _Field({required this.controller, required this.label, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kSecondary, fontSize: 13),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: _kSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Jaribu tena' : 'Try again')),
        ],
      ),
    );
  }
}
