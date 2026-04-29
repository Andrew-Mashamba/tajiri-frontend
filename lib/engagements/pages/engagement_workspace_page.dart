import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/widgets/rate_partner_cta.dart';
import '../../customer_orders/widgets/lead_expiring_chip.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/engagement.dart';
import '../services/engagement_service.dart';
import '../widgets/engagement_extra_tabs.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Shared engagement workspace per spec line 780. Same widget used by both:
///   • lib/business/pages/engagement_workspace_page.dart (customer wrapper)
///   • lib/tajirika/pages/engagement_dashboard_page.dart (partner deeplinks)
///
/// Two tabs in v1: Milestones, Time. Files / Invoices / Chat tabs ship with
/// their own pattern groups (deferred — see audit).
class EngagementWorkspacePage extends StatefulWidget {
  final int userId;
  final int engagementId;
  final String role; // 'customer' | 'partner'

  const EngagementWorkspacePage({
    super.key,
    required this.userId,
    required this.engagementId,
    required this.role,
  });

  @override
  State<EngagementWorkspacePage> createState() => _EngagementWorkspacePageState();
}

class _EngagementWorkspacePageState extends State<EngagementWorkspacePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Engagement? _e;
  List<EngagementTimeEntry> _timeEntries = const [];
  bool _loading = true;
  String? _error;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isPartner => widget.role == 'partner';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await EngagementService.get(id: widget.engagementId, userId: widget.userId);
    final times = await EngagementService.listTimeEntries(
      engagementId: widget.engagementId,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _e = res.engagement;
      _timeEntries = times.items;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  // ──────────────── Engagement-level actions ────────────────

  Future<void> _start() async {
    final res = await EngagementService.start(id: widget.engagementId, userId: widget.userId);
    _afterEngagementAction(res, _isSwahili ? 'Imeanza' : 'Started');
  }

  Future<void> _pause() async {
    final res = await EngagementService.pause(id: widget.engagementId, userId: widget.userId);
    _afterEngagementAction(res, _isSwahili ? 'Imesimama' : 'Paused');
  }

  Future<void> _resume() async {
    final res = await EngagementService.resume(id: widget.engagementId, userId: widget.userId);
    _afterEngagementAction(res, _isSwahili ? 'Imeanza tena' : 'Resumed');
  }

  Future<void> _end() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Maliza kazi?' : 'End engagement?'),
        content: Text(_isSwahili
            ? 'Hii itafunga kazi rasmi.'
            : 'This closes the engagement gracefully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(_isSwahili ? 'Maliza' : 'End'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await EngagementService.end(id: widget.engagementId, userId: widget.userId);
    _afterEngagementAction(res, _isSwahili ? 'Imekamilika' : 'Ended');
  }

  Future<void> _cancel() async {
    final reason = await _askText(_isSwahili ? 'Sababu ya kughairi' : 'Cancellation reason', 1000);
    if (reason == null) return;
    final res = await EngagementService.cancel(
      id: widget.engagementId,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    _afterEngagementAction(res, _isSwahili ? 'Imeghairiwa' : 'Cancelled');
  }

  void _afterEngagementAction(EngagementResult res, String okMsg) {
    if (!mounted) return;
    if (res.success) {
      _toast(okMsg);
      _load();
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
    }
  }

  // ──────────────── Amendment workflow (spec line 791) ──────────────────────

  Future<void> _proposeAmendment(Engagement e) async {
    final result = await showDialog<_AmendmentInput?>(
      context: context,
      builder: (_) => _AmendmentDialog(current: e, isSwahili: _isSwahili),
    );
    if (result == null || !mounted) return;
    final res = await EngagementService.proposeAmendment(
      id: e.id,
      userId: widget.userId,
      scopeSummary: result.scopeSummary,
      totalAmountTzs: result.totalAmountTzs,
      feeModel: result.feeModel,
      notes: result.notes,
    );
    if (!mounted) return;
    _afterEngagementAction(
      res,
      _isSwahili ? 'Mabadiliko yamependekezwa' : 'Amendment proposed',
    );
  }

  Future<void> _respondToAmendment({required bool approve}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve
            ? (_isSwahili ? 'Kubali mabadiliko?' : 'Approve amendment?')
            : (_isSwahili ? 'Kataa mabadiliko?' : 'Reject amendment?')),
        content: Text(approve
            ? (_isSwahili
                ? 'Yataweka kazini mara moja.'
                : 'Will be applied to the engagement immediately.')
            : (_isSwahili
                ? 'Mabadiliko yatafutwa.'
                : 'The amendment will be discarded.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: Text(approve
                ? (_isSwahili ? 'Kubali' : 'Approve')
                : (_isSwahili ? 'Kataa' : 'Reject')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await EngagementService.respondToAmendment(
      id: widget.engagementId,
      userId: widget.userId,
      approve: approve,
    );
    if (!mounted) return;
    _afterEngagementAction(
      res,
      approve
          ? (_isSwahili ? 'Mabadiliko yamekubaliwa' : 'Amendment approved')
          : (_isSwahili ? 'Mabadiliko yamekataliwa' : 'Amendment rejected'),
    );
  }

  // ──────────────── Milestone actions ────────────────

  Future<void> _addMilestone() async {
    final result = await showDialog<_MilestoneInput?>(
      context: context,
      builder: (_) => const _MilestoneDialog(),
    );
    if (result == null) return;
    final res = await EngagementService.addMilestone(
      engagementId: widget.engagementId,
      userId: widget.userId,
      title: result.title,
      amountTzs: result.amountTzs,
      dueDate: result.dueDate,
    );
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  Future<void> _submitMilestone(EngagementMilestone m) async {
    final note = await _askText(_isSwahili ? 'Maelezo ya kazi iliyokamilika' : 'Deliverable note', 2000);
    if (note == null) return;
    final res = await EngagementService.submitMilestone(
      engagementId: widget.engagementId,
      milestoneId: m.id,
      userId: widget.userId,
      deliverableNote: note.isEmpty ? null : note,
    );
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  Future<void> _approveMilestone(EngagementMilestone m) async {
    final res = await EngagementService.approveMilestone(
      engagementId: widget.engagementId,
      milestoneId: m.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (res.success) {
      _toast(_isSwahili ? 'Imekubaliwa na kulipwa' : 'Approved and released');
      _load();
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  Future<void> _disputeMilestone(EngagementMilestone m) async {
    final reason = await _askText(_isSwahili ? 'Sababu ya kupinga' : 'Dispute reason', 1000);
    if (reason == null || reason.isEmpty) return;
    final res = await EngagementService.disputeMilestone(
      engagementId: widget.engagementId,
      milestoneId: m.id,
      userId: widget.userId,
      reason: reason,
    );
    if (!mounted) return;
    if (res.success) {
      _toast(_isSwahili ? 'Imepingwa' : 'Disputed');
      _load();
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  // ──────────────── Time entry actions ────────────────

  Future<void> _addTimeEntry() async {
    final result = await showDialog<_TimeEntryInput?>(
      context: context,
      builder: (_) => const _TimeEntryDialog(),
    );
    if (result == null) return;
    final res = await EngagementService.addTimeEntry(
      engagementId: widget.engagementId,
      userId: widget.userId,
      entryDate: result.date,
      minutes: result.minutes,
      description: result.description,
      billable: result.billable,
    );
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  Future<void> _deleteTimeEntry(EngagementTimeEntry t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa kuingia?' : 'Delete entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
            child: Text(_isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await EngagementService.deleteTimeEntry(
      engagementId: widget.engagementId,
      entryId: t.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (success) {
      _load();
    } else {
      _toast(_isSwahili ? 'Imeshindikana' : 'Failed');
    }
  }

  Future<String?> _askText(String title, int maxLen) {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          minLines: 3,
          maxLines: 8,
          maxLength: maxLen,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
            child: Text(_isSwahili ? 'Tuma' : 'Submit'),
          ),
        ],
      ),
    );
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
          _e?.title ?? (_isSwahili ? 'Workspace' : 'Workspace'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: _kPrimary,
          unselectedLabelColor: _kMuted,
          indicatorColor: _kPrimary,
          isScrollable: true,
          tabs: [
            Tab(text: _isSwahili ? 'Hatua' : 'Milestones'),
            Tab(text: _isSwahili ? 'Saa' : 'Time'),
            Tab(text: _isSwahili ? 'Faili' : 'Files'),
            Tab(text: _isSwahili ? 'Ankara' : 'Invoices'),
            Tab(text: _isSwahili ? 'Maongezi' : 'Chat'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: _kMuted))),
                )
              : _e == null
                  ? Center(child: Text(_isSwahili ? 'Hapatikani' : 'Not found',
                      style: const TextStyle(color: _kMuted)))
                  : _buildBody(_e!),
      bottomNavigationBar: _e == null ? null : _buildEngagementActionBar(_e!),
    );
  }

  Widget _buildBody(Engagement e) {
    return Column(
      children: [
        _statusStrip(e),
        if (e.hasPendingAmendment)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _amendmentBanner(e),
          ),
        if (!_isPartner && e.status == EngagementStatus.ended)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: RatePartnerCta(
              reviewerUserId: widget.userId,
              source: CustomerOrderSource.engagement,
              sourceId: e.id,
              partnerName: e.partnerName,
              itemTitle: e.title,
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _milestonesTab(e),
              _timeTab(e),
              EngagementFilesTab(engagementId: e.id, userId: widget.userId),
              EngagementInvoicesTab(engagementId: e.id, userId: widget.userId, isPartner: _isPartner),
              EngagementChatTab(engagement: e, userId: widget.userId, isPartner: _isPartner),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusStrip(Engagement e) {
    final fee = NumberFormat('#,##0', 'en_US').format(e.totalEffectiveTzs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusBg(e.status),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _isSwahili ? e.status.labelSwahili : e.status.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _statusFg(e.status),
              ),
            ),
          ),
          const SizedBox(width: 8),
          LeadExpiringChipFetcher(
            orderId: e.id,
            sourceApiValue: 'engagement',
            isSwahili: _isSwahili,
          ),
          const SizedBox(width: 8),
          Icon(e.contractType.icon, size: 13, color: _kMuted),
          const SizedBox(width: 4),
          Text(
            _isSwahili ? e.contractType.labelSwahili : e.contractType.label,
            style: const TextStyle(fontSize: 11, color: _kMuted),
          ),
          const Spacer(),
          if ((e.leadCreditTzs ?? 0) > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.discount_rounded,
                      size: 10, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 3),
                  Text(
                    _isSwahili
                        ? 'Krediti -TZS ${NumberFormat('#,##0').format(e.leadCreditTzs)}'
                        : '-TZS ${NumberFormat('#,##0').format(e.leadCreditTzs)} credit',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (e.isRetainer) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.subscriptions_rounded,
                      size: 10, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 3),
                  Text(
                    e.retainerHoursPerMonth != null
                        ? (_isSwahili
                            ? 'Retainer ${e.retainerHoursPerMonth}h/mwezi'
                            : 'Retainer ${e.retainerHoursPerMonth}h/mo')
                        : (_isSwahili ? 'Retainer' : 'Retainer'),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (e.disputeWindowStartedAt != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    e.disputeEscalatedAt != null
                        ? Icons.gavel_rounded
                        : Icons.flag_rounded,
                    size: 10,
                    color: const Color(0xFFB71C1C),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    e.disputeEscalatedAt != null
                        ? (_isSwahili ? 'Mzozo umetolewa' : 'Dispute escalated')
                        : (_isSwahili ? 'Mzozo' : 'Dispute'),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            'TZS $fee',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  // ──────────────── Tabs ────────────────

  Widget _milestonesTab(Engagement e) {
    if (e.milestones.isEmpty) {
      return _emptyTab(
        icon: Icons.flag_outlined,
        text: _isSwahili ? 'Hakuna hatua bado' : 'No milestones yet',
        cta: _isPartner && !e.hasFinalised
            ? FilledButton.icon(
                onPressed: _addMilestone,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(_isSwahili ? 'Ongeza hatua' : 'Add milestone'),
                style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              )
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ...e.milestones.map((m) => _milestoneRow(e, m)),
          if (_isPartner && !e.hasFinalised && e.status != EngagementStatus.proposed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _addMilestone,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(_isSwahili ? 'Ongeza hatua' : 'Add milestone'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kBorder),
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _milestoneRow(Engagement e, EngagementMilestone m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              _milestoneBadge(m.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'TZS ${NumberFormat('#,##0', 'en_US').format(m.amountTzs)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              if (m.dueDate != null) ...[
                const Spacer(),
                Icon(Icons.event_rounded, size: 11, color: _kMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d MMM').format(m.dueDate!),
                  style: const TextStyle(fontSize: 10, color: _kMuted),
                ),
              ],
            ],
          ),
          if (m.deliverableNote != null && m.deliverableNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              m.deliverableNote!,
              style: const TextStyle(fontSize: 11, color: _kPrimary, height: 1.4),
            ),
          ],
          if (m.disputeReason != null && m.disputeReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${_isSwahili ? "Sababu ya kupinga" : "Dispute"}: ${m.disputeReason}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFB71C1C)),
            ),
          ],
          const SizedBox(height: 8),
          _milestoneActionRow(e, m),
        ],
      ),
    );
  }

  Widget _milestoneActionRow(Engagement e, EngagementMilestone m) {
    final List<Widget> actions = [];
    // Spec line 781 — escrow phase split. Customer must fund (places wallet
    // hold) before partner can submit; approval captures the held funds.
    if (!_isPartner && m.status == MilestoneStatus.pending
        && (e.status == EngagementStatus.active || e.status == EngagementStatus.paused)) {
      actions.add(_smallBtn(_isSwahili ? 'Lipa' : 'Fund', Icons.payments_rounded,
          () => _fundMilestone(m), color: const Color(0xFF1565C0)));
    }
    if (_isPartner && (m.status == MilestoneStatus.pending || m.status == MilestoneStatus.funded)
        && (e.status == EngagementStatus.active || e.status == EngagementStatus.paused)) {
      actions.add(_smallBtn(_isSwahili ? 'Wasilisha' : 'Submit', Icons.upload_rounded, () => _submitMilestone(m)));
    }
    if (!_isPartner && m.status == MilestoneStatus.submitted) {
      actions.add(_smallBtn(_isSwahili ? 'Kubali' : 'Approve', Icons.check_rounded, () => _approveMilestone(m), color: const Color(0xFF1B5E20)));
      actions.add(_smallBtn(_isSwahili ? 'Pinga' : 'Dispute', Icons.report_rounded, () => _disputeMilestone(m), color: const Color(0xFFB71C1C)));
    }
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: actions);
  }

  Future<void> _fundMilestone(EngagementMilestone m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Lipa kufunga hatua?' : 'Fund this milestone?'),
        content: Text(_isSwahili
            ? 'Pesa zitazuiliwa hadi mshirika atakapokamilisha kazi.'
            : 'Funds will be held until the partner submits and you approve.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Lipa' : 'Fund'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final res = await EngagementService.fundMilestone(
      engagementId: widget.engagementId,
      milestoneId: m.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    _toast(res.success
        ? (_isSwahili ? 'Imelipwa' : 'Funded')
        : (res.message ?? 'Failed'));
    if (res.success) _load();
  }

  Widget _smallBtn(String label, IconData icon, VoidCallback onTap, {Color color = _kPrimary}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _milestoneBadge(MilestoneStatus s) {
    final (bg, fg) = _milestoneColors(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        _isSwahili ? s.labelSwahili : s.label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  (Color, Color) _milestoneColors(MilestoneStatus s) {
    switch (s) {
      case MilestoneStatus.pending: return (const Color(0xFFFFF4E5), const Color(0xFFB15400));
      case MilestoneStatus.funded: return (const Color(0xFFE3F2FD), const Color(0xFF0D47A1));
      case MilestoneStatus.submitted: return (const Color(0xFFEDE7F6), const Color(0xFF4527A0));
      case MilestoneStatus.approved: return (const Color(0xFFE0F7FA), const Color(0xFF006064));
      case MilestoneStatus.released: return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20));
      case MilestoneStatus.disputed: return (const Color(0xFFFFEBEE), const Color(0xFFB71C1C));
    }
  }

  Widget _timeTab(Engagement e) {
    final totalMin = _timeEntries.fold<int>(0, (s, t) => s + (t.billable ? t.minutes : 0));
    final billed = NumberFormat('#,##0', 'en_US')
        .format(((e.hourlyRateTzs ?? 0) * totalMin / 60).round());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (e.contractType == EngagementContractType.hourly && _timeEntries.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.summarize_rounded, size: 16, color: _kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isSwahili
                          ? 'Saa za kulipwa: ${(totalMin / 60).toStringAsFixed(1)} h'
                          : 'Billable: ${(totalMin / 60).toStringAsFixed(1)} h',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ),
                  Text('TZS $billed',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                ],
              ),
            ),
          if (_timeEntries.isEmpty)
            _emptyTab(
              icon: Icons.access_time_rounded,
              text: _isSwahili ? 'Hakuna saa zilizorekodiwa' : 'No time logged yet',
              cta: _isPartner && (e.status == EngagementStatus.active || e.status == EngagementStatus.paused)
                  ? FilledButton.icon(
                      onPressed: _addTimeEntry,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(_isSwahili ? 'Rekodi saa' : 'Log time'),
                      style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                    )
                  : null,
            )
          else
            ..._timeEntries.map((t) => _timeRow(t)),
          if (_timeEntries.isNotEmpty
              && _isPartner
              && (e.status == EngagementStatus.active || e.status == EngagementStatus.paused))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _addTimeEntry,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(_isSwahili ? 'Rekodi saa' : 'Log time'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kBorder),
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeRow(EngagementTimeEntry t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(t.minutes / 60).toStringAsFixed(1)} h',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              Text(
                DateFormat('EEE d MMM').format(t.entryDate),
                style: const TextStyle(fontSize: 10, color: _kMuted),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.description != null && t.description!.isNotEmpty)
                  Text(
                    t.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _kPrimary),
                  ),
                if (!t.billable)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _isSwahili ? 'Si ya kulipwa' : 'Non-billable',
                      style: const TextStyle(fontSize: 10, color: _kMuted),
                    ),
                  ),
              ],
            ),
          ),
          if (_isPartner && t.billedInvoiceId == null)
            IconButton(
              onPressed: () => _deleteTimeEntry(t),
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFB71C1C)),
              tooltip: _isSwahili ? 'Futa' : 'Delete',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }

  Widget _emptyTab({required IconData icon, required String text, Widget? cta}) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(icon, size: 48, color: _kMuted),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _kMuted)),
        if (cta != null) ...[
          const SizedBox(height: 16),
          Center(child: cta),
        ],
      ],
    );
  }

  Widget? _buildEngagementActionBar(Engagement e) {
    final List<Widget> actions = [];
    Widget btn(IconData icon, String label, VoidCallback onTap, {Color color = _kPrimary}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    }
    switch (e.status) {
      case EngagementStatus.accepted:
        // either party can start (auto-active on start_date is a deferred cron;
        // for now manual start by either side is simplest).
        actions.add(btn(Icons.play_arrow_rounded, _isSwahili ? 'Anza' : 'Start', _start));
        actions.add(btn(Icons.cancel_rounded, _isSwahili ? 'Ghairi' : 'Cancel', _cancel, color: const Color(0xFFB71C1C)));
        break;
      case EngagementStatus.active:
        if (!e.hasPendingAmendment) {
          actions.add(btn(Icons.edit_note_rounded,
              _isSwahili ? 'Pendekeza' : 'Amend', () => _proposeAmendment(e)));
        }
        actions.add(btn(Icons.pause_rounded, _isSwahili ? 'Simamisha' : 'Pause', _pause));
        actions.add(btn(Icons.check_circle_rounded, _isSwahili ? 'Maliza' : 'End', _end, color: const Color(0xFF1B5E20)));
        break;
      case EngagementStatus.paused:
        if (!e.hasPendingAmendment) {
          actions.add(btn(Icons.edit_note_rounded,
              _isSwahili ? 'Pendekeza' : 'Amend', () => _proposeAmendment(e)));
        }
        actions.add(btn(Icons.play_arrow_rounded, _isSwahili ? 'Endelea' : 'Resume', _resume));
        actions.add(btn(Icons.check_circle_rounded, _isSwahili ? 'Maliza' : 'End', _end, color: const Color(0xFF1B5E20)));
        break;
      case EngagementStatus.proposed:
      case EngagementStatus.ended:
      case EngagementStatus.cancelled:
      case EngagementStatus.rejected:
        return null;
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(children: actions),
      ),
    );
  }

  Color _statusBg(EngagementStatus s) {
    switch (s) {
      case EngagementStatus.proposed: return const Color(0xFFFFF4E5);
      case EngagementStatus.accepted: return const Color(0xFFE3F2FD);
      case EngagementStatus.active: return const Color(0xFFEDE7F6);
      case EngagementStatus.paused: return const Color(0xFFFFF8E1);
      case EngagementStatus.ended: return const Color(0xFFE8F5E9);
      case EngagementStatus.cancelled:
      case EngagementStatus.rejected: return const Color(0xFFFFEBEE);
    }
  }

  Color _statusFg(EngagementStatus s) {
    switch (s) {
      case EngagementStatus.proposed: return const Color(0xFFB15400);
      case EngagementStatus.accepted: return const Color(0xFF0D47A1);
      case EngagementStatus.active: return const Color(0xFF4527A0);
      case EngagementStatus.paused: return const Color(0xFFE65100);
      case EngagementStatus.ended: return const Color(0xFF1B5E20);
      case EngagementStatus.cancelled:
      case EngagementStatus.rejected: return const Color(0xFFB71C1C);
    }
  }

  Widget _amendmentBanner(Engagement e) {
    final amendment = e.pendingAmendment ?? const <String, dynamic>{};
    final isProposer = e.amendmentProposedBy == widget.userId;
    final canRespond = e.isAmendmentApprovableBy(widget.userId);
    final lines = <String>[];
    if (amendment['scope_summary'] is String) {
      lines.add('${_isSwahili ? "Wigo" : "Scope"}: ${amendment['scope_summary']}');
    }
    if (amendment['total_amount_tzs'] != null) {
      lines.add('${_isSwahili ? "Bei mpya" : "New total"}: '
          'TZS ${NumberFormat('#,##0').format(amendment['total_amount_tzs'] is int ? amendment['total_amount_tzs'] : int.tryParse('${amendment['total_amount_tzs']}') ?? 0)}');
    }
    if (amendment['fee_model'] is String) {
      lines.add('${_isSwahili ? "Aina" : "Fee model"}: ${amendment['fee_model']}');
    }
    if (amendment['notes'] is String && (amendment['notes'] as String).trim().isNotEmpty) {
      lines.add(amendment['notes'].toString());
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFFFB300)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFFB15400)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isProposer
                      ? (_isSwahili
                          ? 'Pendekezo lako linasubiri jibu'
                          : 'Your amendment is awaiting a response')
                      : (_isSwahili
                          ? 'Mabadiliko yamependekezwa'
                          : 'An amendment has been proposed'),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB15400)),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...lines.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(l,
                      style: const TextStyle(fontSize: 12, color: _kPrimary)),
                )),
          ],
          if (canRespond) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respondToAmendment(approve: true),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(_isSwahili ? 'Kubali' : 'Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _respondToAmendment(approve: false),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(_isSwahili ? 'Kataa' : 'Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB71C1C),
                      side: const BorderSide(color: Color(0xFFB71C1C)),
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isProposer) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _respondToAmendment(approve: false),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text(_isSwahili ? 'Futa pendekezo' : 'Withdraw proposal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB71C1C),
                side: const BorderSide(color: Color(0xFFB71C1C)),
                minimumSize: const Size.fromHeight(40),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmendmentInput {
  final String? scopeSummary;
  final int? totalAmountTzs;
  final String? feeModel;
  final String? notes;
  const _AmendmentInput({
    this.scopeSummary,
    this.totalAmountTzs,
    this.feeModel,
    this.notes,
  });
}

class _AmendmentDialog extends StatefulWidget {
  final Engagement current;
  final bool isSwahili;
  const _AmendmentDialog({required this.current, required this.isSwahili});

  @override
  State<_AmendmentDialog> createState() => _AmendmentDialogState();
}

class _AmendmentDialogState extends State<_AmendmentDialog> {
  late final TextEditingController _scope;
  late final TextEditingController _total;
  late final TextEditingController _notes;
  String? _feeModel;

  static const _models = ['hourly', 'retainer', 'fixed_price', 'productized'];

  @override
  void initState() {
    super.initState();
    _scope = TextEditingController(text: widget.current.scopeBrief);
    _total = TextEditingController(
      text: (widget.current.fixedTotalTzs ?? widget.current.retainerTzs ?? widget.current.hourlyRateTzs ?? 0).toString(),
    );
    _notes = TextEditingController();
    _feeModel = widget.current.contractType.apiValue;
  }

  @override
  void dispose() {
    _scope.dispose();
    _total.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return AlertDialog(
      title: Text(sw ? 'Pendekeza Mabadiliko' : 'Propose Amendment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _scope,
              maxLines: 4,
              maxLength: 5000,
              decoration: InputDecoration(
                labelText: sw ? 'Wigo mpya (hiari)' : 'New scope (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _total,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: sw ? 'Bei mpya TZS (hiari)' : 'New total TZS (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _feeModel,
              decoration: InputDecoration(
                labelText: sw ? 'Aina ya malipo' : 'Fee model',
                border: const OutlineInputBorder(),
              ),
              items: _models
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _feeModel = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: sw ? 'Maelezo (hiari)' : 'Notes (optional)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(sw ? 'Funga' : 'Close'),
        ),
        ElevatedButton(
          onPressed: () {
            final scope = _scope.text.trim();
            final total = int.tryParse(_total.text.trim());
            final notes = _notes.text.trim();
            // Only send fields that differ from current state.
            final input = _AmendmentInput(
              scopeSummary: scope.isEmpty || scope == widget.current.scopeBrief
                  ? null
                  : scope,
              totalAmountTzs: total != null && total > 0 ? total : null,
              feeModel: _feeModel == widget.current.contractType.apiValue
                  ? null
                  : _feeModel,
              notes: notes.isEmpty ? null : notes,
            );
            if (input.scopeSummary == null &&
                input.totalAmountTzs == null &&
                input.feeModel == null &&
                input.notes == null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(sw
                    ? 'Hakuna mabadiliko ya kupendekeza'
                    : 'Nothing to amend'),
              ));
              return;
            }
            Navigator.pop(context, input);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
          ),
          child: Text(sw ? 'Tuma' : 'Submit'),
        ),
      ],
    );
  }
}

class _MilestoneInput {
  final String title;
  final int amountTzs;
  final DateTime? dueDate;
  _MilestoneInput({required this.title, required this.amountTzs, this.dueDate});
}

class _MilestoneDialog extends StatefulWidget {
  const _MilestoneDialog();

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _due;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSwahili ? 'Hatua mpya' : 'New milestone',
          style: const TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: _isSwahili ? 'Kichwa' : 'Title',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDue,
            icon: const Icon(Icons.event_rounded, size: 14),
            label: Text(_due == null
                ? (_isSwahili ? 'Tarehe ya mwisho' : 'Due date')
                : DateFormat('d MMM y').format(_due!)),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_isSwahili ? 'Funga' : 'Close')),
        ElevatedButton(
          onPressed: () {
            final t = _title.text.trim();
            final a = int.tryParse(_amount.text.replaceAll(',', '').trim());
            if (t.isEmpty || a == null) return;
            Navigator.pop(context, _MilestoneInput(title: t, amountTzs: a, dueDate: _due));
          },
          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
          child: Text(_isSwahili ? 'Hifadhi' : 'Save'),
        ),
      ],
    );
  }
}

class _TimeEntryInput {
  final DateTime date;
  final int minutes;
  final String? description;
  final bool billable;
  _TimeEntryInput({
    required this.date,
    required this.minutes,
    required this.description,
    required this.billable,
  });
}

class _TimeEntryDialog extends StatefulWidget {
  const _TimeEntryDialog();

  @override
  State<_TimeEntryDialog> createState() => _TimeEntryDialogState();
}

class _TimeEntryDialogState extends State<_TimeEntryDialog> {
  DateTime _date = DateTime.now();
  final _minutes = TextEditingController();
  final _desc = TextEditingController();
  bool _billable = true;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _minutes.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSwahili ? 'Rekodi saa' : 'Log time', style: const TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_rounded, size: 14),
            label: Text(DateFormat('EEE d MMM').format(_date)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _isSwahili ? 'Dakika' : 'Minutes',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _desc,
            minLines: 2,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: _isSwahili ? 'Maelezo' : 'Description',
              border: const OutlineInputBorder(),
            ),
          ),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(_isSwahili ? 'Ya kulipwa' : 'Billable'),
            value: _billable,
            onChanged: (v) => setState(() => _billable = v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_isSwahili ? 'Funga' : 'Close')),
        ElevatedButton(
          onPressed: () {
            final m = int.tryParse(_minutes.text.trim());
            if (m == null || m <= 0) return;
            Navigator.pop(context, _TimeEntryInput(
              date: _date,
              minutes: m,
              description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
              billable: _billable,
            ));
          },
          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
          child: Text(_isSwahili ? 'Hifadhi' : 'Save'),
        ),
      ],
    );
  }
}
