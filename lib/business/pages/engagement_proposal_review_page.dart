import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../engagements/models/engagement.dart';
import '../../engagements/pages/engagement_workspace_page.dart';
import '../../engagements/services/engagement_service.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Customer-side proposal review (spec §8 line 773–776).
/// Three actions: Accept / Counter-propose (PATCH while proposed) / Reject.
class EngagementProposalReviewPage extends StatefulWidget {
  final int userId;
  final int engagementId;

  const EngagementProposalReviewPage({
    super.key,
    required this.userId,
    required this.engagementId,
  });

  @override
  State<EngagementProposalReviewPage> createState() => _EngagementProposalReviewPageState();
}

class _EngagementProposalReviewPageState extends State<EngagementProposalReviewPage> {
  Engagement? _e;
  bool _loading = true;
  String? _error;

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
    final res = await EngagementService.get(id: widget.engagementId, userId: widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _e = res.engagement;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _accept() async {
    final res = await EngagementService.accept(id: widget.engagementId, userId: widget.userId);
    if (!mounted) return;
    if (res.success) {
      _toast(_isSwahili
          ? 'Pendekezo limekubaliwa. Kazi itaanza ${DateFormat('d MMM').format(res.engagement!.startDate)}.'
          : 'Proposal accepted. Engagement starts ${DateFormat('d MMM').format(res.engagement!.startDate)}.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EngagementWorkspacePage(
            userId: widget.userId,
            engagementId: widget.engagementId,
            role: 'customer',
          ),
        ),
      );
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  Future<void> _reject() async {
    final reason = await _askReason(_isSwahili ? 'Sababu ya kukataa' : 'Reject reason');
    if (reason == null) return;
    final res = await EngagementService.reject(
      id: widget.engagementId,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    if (!mounted) return;
    if (res.success) {
      _toast(_isSwahili ? 'Imekataliwa' : 'Rejected');
      Navigator.of(context).pop(true);
    } else {
      _toast(res.message ?? 'Failed');
    }
  }

  Future<void> _counter() async {
    final e = _e;
    if (e == null) return;
    final result = await Navigator.push<Engagement?>(
      context,
      MaterialPageRoute(
        builder: (_) => _CounterProposalForm(userId: widget.userId, engagement: e),
      ),
    );
    if (!mounted) return;
    if (result != null) _load();
  }

  Future<String?> _askReason(String title) {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(hintText: _isSwahili ? 'Sababu (hiari)' : 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Kataa' : 'Reject'),
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
          _isSwahili ? 'Pendekezo la Kazi' : 'Engagement Proposal',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
      bottomNavigationBar: _e == null ? null : _buildActionBar(_e!),
    );
  }

  Widget _buildBody(Engagement e) {
    final fee = NumberFormat('#,##0', 'en_US').format(e.totalEffectiveTzs);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          if (e.counterRound > 0) _counterBadge(e.counterRound),
          if (e.counterRound > 0) const SizedBox(height: 8),
          _card([
            Row(
              children: [
                Icon(e.contractType.icon, size: 18, color: _kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${e.partnerName ?? "—"} • ${_isSwahili ? e.contractType.labelSwahili : e.contractType.label}',
              style: const TextStyle(fontSize: 11, color: _kMuted),
            ),
          ]),
          const SizedBox(height: 10),
          _card([
            Text(_isSwahili ? 'Wigo wa kazi' : 'Scope brief',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 6),
            Text(e.scopeBrief, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
          ]),
          const SizedBox(height: 10),
          _card([
            _kv(_isSwahili ? 'Aina' : 'Type', _isSwahili ? e.contractType.labelSwahili : e.contractType.label, icon: e.contractType.icon),
            if (e.hourlyRateTzs != null)
              _kv(_isSwahili ? 'Kwa saa' : 'Hourly', 'TZS ${NumberFormat('#,##0', 'en_US').format(e.hourlyRateTzs)}', icon: Icons.schedule_rounded),
            if (e.retainerTzs != null)
              _kv(_isSwahili ? 'Kwa mwezi' : 'Monthly', 'TZS ${NumberFormat('#,##0', 'en_US').format(e.retainerTzs)}', icon: Icons.repeat_rounded),
            if (e.fixedTotalTzs != null)
              _kv(_isSwahili ? 'Bei thabiti' : 'Fixed', 'TZS ${NumberFormat('#,##0', 'en_US').format(e.fixedTotalTzs)}', icon: Icons.attach_money_rounded),
            _kv(_isSwahili ? 'Anza' : 'Start', DateFormat('d MMM y').format(e.startDate), icon: Icons.event_rounded),
            if (e.endDate != null)
              _kv(_isSwahili ? 'Maliza' : 'End', DateFormat('d MMM y').format(e.endDate!), icon: Icons.event_available_rounded),
            if (e.ndaRequired)
              _kv(_isSwahili ? 'NDA' : 'NDA', _isSwahili ? 'Inahitajika' : 'Required', icon: Icons.lock_outline_rounded),
            _kv(_isSwahili ? 'Jumla ya makisio' : 'Estimated total', 'TZS $fee', icon: Icons.payments_rounded),
          ]),
          if (e.milestones.isNotEmpty) ...[
            const SizedBox(height: 10),
            _milestonesCard(e),
          ],
        ],
      ),
    );
  }

  Widget _counterBadge(int round) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _isSwahili
            ? 'Pendekezo limesasishwa (raundi $round)'
            : 'Updated proposal (round $round)',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB15400)),
      ),
    );
  }

  Widget _milestonesCard(Engagement e) {
    return _card([
      Text(_isSwahili ? 'Hatua' : 'Milestones',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      const SizedBox(height: 6),
      ...e.milestones.map((m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_outlined, size: 14, color: _kMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.title,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                      if (m.dueDate != null)
                        Text(
                          DateFormat('d MMM y').format(m.dueDate!),
                          style: const TextStyle(fontSize: 10, color: _kMuted),
                        ),
                    ],
                  ),
                ),
                Text(
                  'TZS ${NumberFormat('#,##0', 'en_US').format(m.amountTzs)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ],
            ),
          )),
    ]);
  }

  Widget? _buildActionBar(Engagement e) {
    if (e.status != EngagementStatus.proposed) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _kBorder)),
          ),
          child: ElevatedButton.icon(
            onPressed: e.isWorkspaceOpen
                ? () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => EngagementWorkspacePage(
                          userId: widget.userId,
                          engagementId: e.id,
                          role: 'customer',
                        ),
                      ),
                    )
                : null,
            icon: const Icon(Icons.workspaces_rounded, size: 16),
            label: Text(_isSwahili ? 'Fungua workspace' : 'Open workspace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton.icon(
                  onPressed: _reject,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(_isSwahili ? 'Kataa' : 'Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB71C1C),
                    side: const BorderSide(color: Color(0xFFB71C1C)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton.icon(
                  onPressed: _counter,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(_isSwahili ? 'Pendekeza' : 'Counter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kBorder),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: _accept,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(_isSwahili ? 'Kubali' : 'Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _kv(String k, String v, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _kMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(k, style: const TextStyle(fontSize: 12, color: _kMuted))),
          Text(v,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
    );
  }
}

/// Customer counter-proposal mini-form. Lets customer edit scope + pricing
/// fields; PATCH /engagements/{id} bumps `counter_round`.
class _CounterProposalForm extends StatefulWidget {
  final int userId;
  final Engagement engagement;
  const _CounterProposalForm({required this.userId, required this.engagement});

  @override
  State<_CounterProposalForm> createState() => _CounterProposalFormState();
}

class _CounterProposalFormState extends State<_CounterProposalForm> {
  late final TextEditingController _scope;
  late final TextEditingController _hourly;
  late final TextEditingController _retainer;
  late final TextEditingController _fixed;
  bool _saving = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    final e = widget.engagement;
    _scope = TextEditingController(text: e.scopeBrief);
    _hourly = TextEditingController(text: e.hourlyRateTzs?.toString() ?? '');
    _retainer = TextEditingController(text: e.retainerTzs?.toString() ?? '');
    _fixed = TextEditingController(text: e.fixedTotalTzs?.toString() ?? '');
  }

  @override
  void dispose() {
    _scope.dispose();
    _hourly.dispose();
    _retainer.dispose();
    _fixed.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final e = widget.engagement;
    final res = await EngagementService.counter(
      id: e.id,
      userId: widget.userId,
      scopeBrief: _scope.text.trim(),
      hourlyRateTzs: e.contractType == EngagementContractType.hourly
          ? int.tryParse(_hourly.text.replaceAll(',', '').trim())
          : null,
      retainerTzs: e.contractType == EngagementContractType.retainer
          ? int.tryParse(_retainer.text.replaceAll(',', '').trim())
          : null,
      fixedTotalTzs: e.contractType == EngagementContractType.fixedPrice
          ? int.tryParse(_fixed.text.replaceAll(',', '').trim())
          : null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Pendekezo lako limetumwa' : 'Counter sent'),
      ));
      Navigator.of(context).pop(res.engagement);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? 'Failed'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.engagement;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isSwahili ? 'Pendekeza Mabadiliko' : 'Counter Proposal',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(_isSwahili ? 'Wigo wa kazi' : 'Scope brief',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _scope,
              minLines: 4,
              maxLines: 12,
              maxLength: 5000,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            if (e.contractType == EngagementContractType.hourly) ...[
              const SizedBox(height: 12),
              Text(_isSwahili ? 'Gharama kwa saa (TZS)' : 'Hourly rate (TZS)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _hourly,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
            ],
            if (e.contractType == EngagementContractType.retainer) ...[
              const SizedBox(height: 12),
              Text(_isSwahili ? 'Mkataba wa mwezi (TZS)' : 'Monthly retainer (TZS)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _retainer,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
            ],
            if (e.contractType == EngagementContractType.fixedPrice) ...[
              const SizedBox(height: 12),
              Text(_isSwahili ? 'Bei thabiti (TZS)' : 'Fixed total (TZS)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _fixed,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_isSwahili ? 'Tuma pendekezo' : 'Send counter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
