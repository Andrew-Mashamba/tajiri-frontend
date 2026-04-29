import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../consultations/models/consultation.dart';
import '../../consultations/services/consultation_service.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Partner-side consultation detail. NDA-gated reveal of the encrypted intake,
/// state-aware action bar (Accept/Reject → Start → Complete) and post-completion
/// append-only Notes / Prescription dialogs.
class ConsultationDetailPage extends StatefulWidget {
  final int userId;
  final int consultationId;

  const ConsultationDetailPage({
    super.key,
    required this.userId,
    required this.consultationId,
  });

  @override
  State<ConsultationDetailPage> createState() => _ConsultationDetailPageState();
}

class _ConsultationDetailPageState extends State<ConsultationDetailPage> {
  Consultation? _c;
  bool _loading = true;
  String? _error;

  /// Spec line 651: partner-side intake reveal is NDA-gated. Partner must
  /// re-acknowledge confidentiality before sensitive content shows.
  bool _ndaConfirmed = false;

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
    final res = await ConsultationService.get(
      id: widget.consultationId,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _c = res.consultation;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _accept() async {
    final res = await ConsultationService.accept(id: widget.consultationId, userId: widget.userId);
    _afterAction(res, _isSwahili ? 'Imekubaliwa' : 'Accepted');
  }

  Future<void> _reject() async {
    final reason = await _askReason(
      title: _isSwahili ? 'Sababu ya kukataa' : 'Reject reason',
    );
    if (reason == null) return;
    final res = await ConsultationService.reject(
      id: widget.consultationId,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    _afterAction(res, _isSwahili ? 'Imekataliwa' : 'Rejected');
  }

  Future<void> _start() async {
    final res = await ConsultationService.start(id: widget.consultationId, userId: widget.userId);
    _afterAction(res, _isSwahili ? 'Imeanza' : 'Started');
  }

  Future<void> _complete() async {
    final res = await ConsultationService.complete(id: widget.consultationId, userId: widget.userId);
    _afterAction(res, _isSwahili ? 'Imekamilika' : 'Completed');
  }

  Future<void> _cancel() async {
    final reason = await _askReason(
      title: _isSwahili ? 'Sababu ya kughairi' : 'Cancel reason',
    );
    if (reason == null) return;
    final res = await ConsultationService.cancel(
      id: widget.consultationId,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    _afterAction(res, _isSwahili ? 'Imeghairiwa' : 'Cancelled');
  }

  void _afterAction(ConsultationResult res, String okMsg) {
    if (!mounted) return;
    if (res.success) {
      _toast(okMsg);
      _load();
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
    }
  }

  Future<String?> _askReason({required String title}) {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: _isSwahili ? 'Sababu (hiari)' : 'Reason (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Tuma' : 'Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _appendFollowUp() async {
    final notes = await _askLongText(
      title: _isSwahili ? 'Maelezo ya kufuatilia' : 'Follow-up notes',
      minChars: 10,
    );
    if (notes == null || notes.isEmpty) return;
    final res = await ConsultationService.appendFollowUp(
      id: widget.consultationId,
      userId: widget.userId,
      notes: notes,
    );
    _afterAction(res, _isSwahili ? 'Maelezo yamehifadhiwa' : 'Notes saved');
  }

  Future<void> _appendPrescription() async {
    final rx = await _askLongText(
      title: _isSwahili ? 'Dawa za kuagiza' : 'Prescription',
      minChars: 5,
    );
    if (rx == null || rx.isEmpty) return;
    final res = await ConsultationService.appendPrescription(
      id: widget.consultationId,
      userId: widget.userId,
      prescription: rx,
    );
    _afterAction(res, _isSwahili ? 'Dawa zimehifadhiwa' : 'Prescription saved');
  }

  Future<String?> _askLongText({required String title, required int minChars}) {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: TextField(
          controller: ctrl,
          minLines: 4,
          maxLines: 12,
          maxLength: 5000,
          decoration: InputDecoration(
            hintText: _isSwahili ? 'Andika hapa...' : 'Write here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.length < minChars) return;
              Navigator.of(ctx).pop(text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isSwahili ? 'Mahojiano #${widget.consultationId}' : 'Consultation #${widget.consultationId}',
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
              : c == null
                  ? Center(
                      child: Text(_isSwahili ? 'Hapatikani' : 'Not found',
                          style: const TextStyle(color: _kMuted)),
                    )
                  : _buildBody(c),
      bottomNavigationBar: c == null ? null : _buildActionBar(c),
    );
  }

  Widget _buildBody(Consultation c) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          if (c.isPrivileged) _privilegeBanner(),
          if (c.isPrivileged) const SizedBox(height: 10),
          _statusBanner(c),
          const SizedBox(height: 10),
          _customerCard(c),
          const SizedBox(height: 10),
          _summaryCard(c),
          const SizedBox(height: 10),
          if (!_ndaConfirmed) _ndaGateCard() else _intakeRevealCard(c),
          if (c.followUpNotes != null) ...[
            const SizedBox(height: 10),
            _followUpCard(c),
          ],
          if (c.prescription != null) ...[
            const SizedBox(height: 10),
            _prescriptionCard(c),
          ],
        ],
      ),
    );
  }

  Widget _privilegeBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSwahili
                  ? 'Mawasiliano ya Wakili–Mteja'
                  : 'Attorney–Client Privileged Communication',
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(Consultation c) {
    final label = _isSwahili ? c.status.labelSwahili : c.status.label;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, size: 16, color: Color(0xFFB15400)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_isSwahili ? "Hali" : "Status"}: $label',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB15400)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerCard(Consultation c) {
    return _card([
      Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _kPrimary.withValues(alpha: 0.06),
            child: Text(
              (c.customerName ?? '?').characters.first,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.customerName ?? '—',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text(
                  _isSwahili
                      ? '${c.vertical.labelSwahili} • ${c.mode.labelSwahili}'
                      : '${c.vertical.label} • ${c.mode.label}',
                  style: const TextStyle(fontSize: 11, color: _kMuted),
                ),
              ],
            ),
          ),
          if ((c.customerPhone ?? '').isNotEmpty)
            IconButton(
              onPressed: () => _callCustomer(c.customerPhone!),
              icon: const Icon(Icons.phone_rounded, size: 18, color: _kPrimary),
              tooltip: _isSwahili ? 'Piga simu' : 'Call',
            ),
        ],
      ),
    ]);
  }

  Widget _summaryCard(Consultation c) {
    final fee = NumberFormat('#,##0', 'en_US').format(c.feeTzs);
    return _card([
      _kv(_isSwahili ? 'Muda' : 'Duration', '${c.durationMin} min', icon: Icons.timer_outlined),
      _kv(_isSwahili ? 'Tarehe' : 'When',
          DateFormat('EEE d MMM • HH:mm').format(c.startsAt),
          icon: Icons.event_rounded),
      _kv(_isSwahili ? 'Gharama' : 'Fee', 'TZS $fee', icon: Icons.payments_rounded),
      if (c.customerAddress != null && c.customerAddress!.isNotEmpty)
        _kv(_isSwahili ? 'Anwani' : 'Address', c.customerAddress!, icon: Icons.place_rounded),
    ]);
  }

  Widget _ndaGateCard() {
    return _card([
      Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 18, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSwahili ? 'Soma yaliyofungwa' : 'View confidential intake',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        _isSwahili
            ? 'Maelezo ya mteja ni ya siri. Ukifungua, unakubali kuyahifadhi kwa siri.'
            : 'Customer intake is confidential. Opening it acknowledges your duty of secrecy.',
        style: const TextStyle(fontSize: 11, color: _kMuted, height: 1.4),
      ),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        onPressed: () => setState(() => _ndaConfirmed = true),
        icon: const Icon(Icons.visibility_rounded, size: 16),
        label: Text(_isSwahili ? 'Fungua' : 'Reveal'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
        ),
      ),
    ]);
  }

  Widget _intakeRevealCard(Consultation c) {
    return _card([
      Row(
        children: [
          const Icon(Icons.description_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            _isSwahili ? 'Maelezo ya tatizo' : 'Case intake',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        c.intakeSummary ?? '',
        style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.5),
      ),
      if (c.attachments != null && c.attachments!.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          _isSwahili ? 'Viambatanisho' : 'Attachments',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted),
        ),
        const SizedBox(height: 4),
        ...c.attachments!.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.attachment_rounded, size: 14, color: _kMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.name ?? a.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _kPrimary),
                    ),
                  ),
                ],
              ),
            )),
      ],
    ]);
  }

  Widget _followUpCard(Consultation c) {
    return _card([
      Text(
        _isSwahili ? 'Maelezo ya kufuatilia' : 'Follow-up notes',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
      ),
      const SizedBox(height: 6),
      Text(c.followUpNotes!, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
    ]);
  }

  Widget _prescriptionCard(Consultation c) {
    return _card([
      Text(
        _isSwahili ? 'Dawa zilizoagizwa' : 'Prescription',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
      ),
      const SizedBox(height: 6),
      Text(c.prescription!, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
    ]);
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
          Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
    );
  }

  Widget? _buildActionBar(Consultation c) {
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

    switch (c.status) {
      case ConsultationStatus.pending:
        actions.add(btn(Icons.close_rounded, _isSwahili ? 'Kataa' : 'Reject', _reject, color: const Color(0xFFB71C1C)));
        actions.add(btn(Icons.check_rounded, _isSwahili ? 'Kubali' : 'Accept', _accept));
        break;
      case ConsultationStatus.confirmed:
        actions.add(btn(Icons.cancel_rounded, _isSwahili ? 'Ghairi' : 'Cancel', _cancel, color: const Color(0xFFB71C1C)));
        actions.add(btn(Icons.play_arrow_rounded, _isSwahili ? 'Anza' : 'Start', _start));
        break;
      case ConsultationStatus.inProgress:
        actions.add(btn(Icons.check_circle_rounded, _isSwahili ? 'Maliza' : 'Complete', _complete, color: const Color(0xFF1B5E20)));
        break;
      case ConsultationStatus.completed:
        if (c.followUpNotes == null) {
          actions.add(btn(Icons.note_alt_rounded, _isSwahili ? 'Maelezo' : 'Add notes', _appendFollowUp));
        }
        if (c.vertical == ConsultationVertical.medical && c.prescription == null) {
          actions.add(btn(Icons.medication_rounded, _isSwahili ? 'Dawa' : 'Rx', _appendPrescription));
        }
        if (actions.isEmpty) return null;
        break;
      case ConsultationStatus.cancelled:
      case ConsultationStatus.rejected:
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
}
