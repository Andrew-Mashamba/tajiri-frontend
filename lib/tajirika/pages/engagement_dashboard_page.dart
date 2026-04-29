import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../engagements/models/engagement.dart';
import '../../engagements/pages/engagement_workspace_page.dart';
import '../../engagements/services/engagement_service.dart';
import '../../l10n/app_strings_scope.dart';
import 'propose_engagement_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Partner-side engagements list. FAB opens propose flow; tapping a row opens
/// the shared workspace with role=partner.
class EngagementDashboardPage extends StatefulWidget {
  final int userId;
  const EngagementDashboardPage({super.key, required this.userId});

  @override
  State<EngagementDashboardPage> createState() => _EngagementDashboardPageState();
}

class _EngagementDashboardPageState extends State<EngagementDashboardPage> {
  bool _loading = true;
  String? _error;
  List<Engagement> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await EngagementService.list(userId: widget.userId, role: 'partner');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.items;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  Future<void> _propose() async {
    final created = await Navigator.push<Engagement?>(
      context,
      MaterialPageRoute(
        builder: (_) => ProposeEngagementPage(userId: widget.userId),
      ),
    );
    if (!mounted) return;
    if (created != null) _load();
  }

  Future<void> _openWorkspace(Engagement e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EngagementWorkspacePage(
          userId: widget.userId,
          engagementId: e.id,
          role: 'partner',
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isSwahili ? 'Kazi za Mkataba' : 'Engagements',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _kMuted)),
                  ),
                )
              : _items.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                        itemCount: _items.length,
                        itemBuilder: (_, i) => _engagementRow(_items[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _propose,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(_isSwahili ? 'Pendekezo Mpya' : 'New Proposal'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline_rounded, size: 56, color: _kMuted),
            const SizedBox(height: 12),
            Text(
              _isSwahili ? 'Hakuna mikataba bado' : 'No engagements yet',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _isSwahili
                  ? 'Tuma pendekezo kwa mteja kuanza.'
                  : 'Send a proposal to a customer to begin.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _engagementRow(Engagement e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openWorkspace(e),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(e.contractType.icon, size: 16, color: _kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      e.title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statusBadge(e),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                e.customerName ?? '—',
                style: const TextStyle(fontSize: 11, color: _kMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'TZS ${NumberFormat('#,##0', 'en_US').format(e.totalEffectiveTzs)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isSwahili ? e.contractType.labelSwahili : e.contractType.label,
                    style: const TextStyle(fontSize: 10, color: _kMuted),
                  ),
                  const Spacer(),
                  Icon(Icons.event_rounded, size: 12, color: _kMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('d MMM').format(e.startDate),
                    style: const TextStyle(fontSize: 10, color: _kMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(Engagement e) {
    final (bg, fg) = _statusColors(e.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _isSwahili ? e.status.labelSwahili : e.status.label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  (Color, Color) _statusColors(EngagementStatus s) {
    switch (s) {
      case EngagementStatus.proposed:
        return (const Color(0xFFFFF4E5), const Color(0xFFB15400));
      case EngagementStatus.accepted:
        return (const Color(0xFFE3F2FD), const Color(0xFF0D47A1));
      case EngagementStatus.active:
        return (const Color(0xFFEDE7F6), const Color(0xFF4527A0));
      case EngagementStatus.paused:
        return (const Color(0xFFFFF8E1), const Color(0xFFE65100));
      case EngagementStatus.ended:
        return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20));
      case EngagementStatus.cancelled:
      case EngagementStatus.rejected:
        return (const Color(0xFFFFEBEE), const Color(0xFFB71C1C));
    }
  }
}
