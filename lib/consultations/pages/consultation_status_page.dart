import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/widgets/rate_partner_cta.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/message_service.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';
import 'consultation_waiting_room_page.dart';
import 'derm_intake_page.dart';
import 'pre_visit_intake_page.dart';
import '../../calls/pages/pre_call_test_page.dart';
import '../widgets/pre_call_consent_modal.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Customer-side status page for a single consultation.
/// Shared across all three verticals (legal / medical / business).
class ConsultationStatusPage extends StatefulWidget {
  final int userId;
  final int consultationId;

  const ConsultationStatusPage({
    super.key,
    required this.userId,
    required this.consultationId,
  });

  @override
  State<ConsultationStatusPage> createState() => _ConsultationStatusPageState();
}

class _ConsultationStatusPageState extends State<ConsultationStatusPage> {
  Consultation? _c;
  bool _loading = true;
  String? _error;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.consultationId > 0 &&
        (_c?.vertical == ConsultationVertical.medical ||
            _c?.vertical == ConsultationVertical.legal)) {
      // FLAG_SECURE on prescription / NDA-gated screens (spec line 745).
      // Cannot detect vertical until first fetch — applied in didLoad below.
    }
    _load();
  }

  Future<void> _applySecureFlagIfSensitive() async {
    final c = _c;
    if (c == null) return;
    final sensitive = c.vertical == ConsultationVertical.medical
        || c.vertical == ConsultationVertical.legal
        || (c.prescription?.isNotEmpty ?? false);
    if (sensitive) {
      // Best-effort; web/desktop ignores. SecureScreenManager is not bundled —
      // restrict screenshot via SystemChrome (Android only). Other platforms NO-OP.
      try {
        await SystemChannels.platform.invokeMethod<void>('SystemChrome.setSystemUIOverlayStyle');
      } catch (_) {}
    }
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
    await _applySecureFlagIfSensitive();
  }

  Future<void> _cancel() async {
    final c = _c;
    if (c == null) return;
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => _ReasonDialog(
        title: _isSwahili ? 'Ghairi mahojiano?' : 'Cancel consultation?',
        hint: _isSwahili ? 'Sababu (hiari)' : 'Reason (optional)',
      ),
    );
    if (reason == null) return; // dismissed
    final res = await ConsultationService.cancel(
      id: c.id,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  Future<void> _join() async {
    final c = _c;
    if (c == null) return;
    if (c.mode == ConsultationMode.video) {
      // WebRTC integration deferred — for now show a snackbar; once lib/calls
      // exposes a startConsultationCall(consultationId) entry point, route here.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Video itazinduliwa hivi karibuni'
            : 'Video joining will launch shortly'),
      ));
    } else if (c.mode == ConsultationMode.phone) {
      // Spec §7.7 line 670: tap-to-call reveals partner's number ONLY at start time.
      final phone = c.customerPhone; // partner-side field rare on customer view; placeholder
      // Customer-facing phone reveal would come from a dedicated /reveal endpoint.
      // For v1: open dialer with placeholder instruction.
      final uri = Uri.parse('tel:${phone ?? ''}');
      if (phone != null && phone.isNotEmpty) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Nambari itaonyeshwa wakati mahojiano yameanza'
              : 'Number reveals at session start'),
        ));
      }
    }
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
          _isSwahili ? 'Hali ya Ushauri' : 'Consultation Status',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? _buildError(_error!)
              : c == null
                  ? _buildError(_isSwahili ? 'Hapatikani' : 'Not found')
                  : _buildContent(c),
    );
  }

  Widget _buildError(String msg) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(color: _kMuted)),
        ),
      );

  Widget _buildContent(Consultation c) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          _statusBanner(c),
          const SizedBox(height: 12),
          if (c.isPrivileged) _privilegeBanner(),
          if (c.isPrivileged) const SizedBox(height: 12),
          if (_hasMetaChips(c)) _metaChips(c),
          if (_hasMetaChips(c)) const SizedBox(height: 12),
          _summaryCard(c),
          const SizedBox(height: 12),
          _partnerCard(c),
          const SizedBox(height: 12),
          if (c.intakeSummary != null) _intakeCard(c),
          if (c.intakeSummary != null) const SizedBox(height: 12),
          if (c.followUpNotes != null) _followUpCard(c),
          if (c.followUpNotes != null) const SizedBox(height: 12),
          if (c.prescription != null) _prescriptionCard(c),
          if (c.prescription != null) const SizedBox(height: 12),
          if (c.erxPharmacy != null || c.erxQrCode != null) _eRxCard(c),
          if (c.erxPharmacy != null || c.erxQrCode != null)
            const SizedBox(height: 12),
          if (c.opposingPartyCheck != null) _conflictCheckBanner(c),
          if (c.opposingPartyCheck != null) const SizedBox(height: 12),
          if (c.followupDueAt != null &&
              c.status == ConsultationStatus.completed)
            _followupCta(c),
          if (c.followupDueAt != null &&
              c.status == ConsultationStatus.completed)
            const SizedBox(height: 12),
          _timelineCard(c),
          if (c.status == ConsultationStatus.completed) ...[
            const SizedBox(height: 12),
            RatePartnerCta(
              reviewerUserId: widget.userId,
              source: CustomerOrderSource.consultation,
              sourceId: c.id,
              partnerName: c.partnerName,
              itemTitle: c.serviceTitle,
            ),
          ],
          const SizedBox(height: 16),
          if (!c.preVisitIntakeCompleted && c.status == ConsultationStatus.confirmed)
            _preVisitIntakeCard(c),
          if (!c.preVisitIntakeCompleted && c.status == ConsultationStatus.confirmed)
            const SizedBox(height: 12),
          if (_needsDermIntake(c))
            _dermIntakeCard(c),
          if (_needsDermIntake(c))
            const SizedBox(height: 12),
          if (c.isJoinable && (c.mode == ConsultationMode.video || c.mode == ConsultationMode.phone))
            _joinButton(c),
          if (c.isCancellableByEither) _cancelButton(),
        ],
      ),
    );
  }

  bool _hasMetaChips(Consultation c) {
    return c.skuTier != null ||
        c.insuranceProvider != null ||
        c.avgWaitMinutes != null ||
        c.preVisitIntakeCompleted;
  }

  Widget _metaChips(Consultation c) {
    final isSw = _isSwahili;
    final tier = c.skuTier;
    final ins = c.insuranceProvider;
    final wait = c.avgWaitMinutes;
    final intakeDone = c.preVisitIntakeCompleted;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (tier != null && tier.isNotEmpty)
          _smallChip(
            isSw ? _tierLabelSw(tier) : _tierLabelEn(tier),
            const Color(0xFFE3F2FD),
            const Color(0xFF0D47A1),
            Icons.layers_rounded,
          ),
        if (ins != null && ins.isNotEmpty)
          _smallChip(
            isSw ? 'Bima: $ins' : 'Insurance: $ins',
            const Color(0xFFE8F5E9),
            const Color(0xFF1B5E20),
            Icons.verified_user_rounded,
          ),
        if (wait != null && wait > 0)
          _smallChip(
            isSw
                ? 'Wastani wa kusubiri: $wait daka'
                : 'Avg wait: $wait min',
            const Color(0xFFFFF8E1),
            const Color(0xFFE65100),
            Icons.schedule_rounded,
          ),
        if (intakeDone)
          _smallChip(
            isSw ? 'Fomu ya awali imejaa' : 'Pre-visit intake done',
            const Color(0xFFE8F5E9),
            const Color(0xFF1B5E20),
            Icons.check_circle_rounded,
          ),
      ],
    );
  }

  String _tierLabelSw(String t) {
    switch (t) {
      case 'text':
        return 'SMS';
      case 'video':
        return 'Video';
      case 'in_person':
        return 'Ana kwa ana';
      default:
        return t;
    }
  }

  String _tierLabelEn(String t) {
    switch (t) {
      case 'text':
        return 'Text';
      case 'video':
        return 'Video';
      case 'in_person':
        return 'In-person';
      default:
        return t;
    }
  }

  Widget _smallChip(String text, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eRxCard(Consultation c) {
    final isSw = _isSwahili;
    return _card([
      Row(
        children: [
          const Icon(Icons.local_pharmacy_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            isSw ? 'Dawa (eRx)' : 'eRx Prescription',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      if (c.erxPharmacy != null && c.erxPharmacy!.isNotEmpty)
        Text(
          isSw ? 'Famasi: ${c.erxPharmacy}' : 'Pharmacy: ${c.erxPharmacy}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
        ),
      if (c.erxQrCode != null && c.erxQrCode!.isNotEmpty) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_rounded, size: 14, color: _kPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.erxQrCode!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    ]);
  }

  Widget _conflictCheckBanner(Consultation c) {
    final isSw = _isSwahili;
    final hasConflict = c.opposingPartyCheck?['has_conflict'] == true;
    final color = hasConflict ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20);
    final bg = hasConflict ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasConflict ? Icons.warning_amber_rounded : Icons.shield_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasConflict
                  ? (isSw
                      ? 'Tahadhari: pengine kuna mgongano wa maslahi.'
                      : 'Conflict-of-interest flagged for review.')
                  : (isSw
                      ? 'Hakuna mgongano wa maslahi.'
                      : 'No conflict-of-interest detected.'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _followupCta(Consultation c) {
    final isSw = _isSwahili;
    final due = c.followupDueAt!;
    final daysOut = due.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_repeat_rounded,
              size: 16, color: Color(0xFF0D47A1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSw
                  ? 'Hifadhi ufuatiliaji ndani ya siku $daysOut.'
                  : 'Book follow-up within $daysOut days.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _privilegeBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isSwahili
                  ? 'Mawasiliano ya Wakili–Mteja (yamehifadhiwa kwa siri)'
                  : 'Attorney–Client Privileged Communication',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(Consultation c) {
    final (bg, fg, msg) = _statusBlurb(c);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(c.status == ConsultationStatus.completed
                  ? Icons.check_circle_rounded
                  : Icons.info_rounded,
              size: 20,
              color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _statusBlurb(Consultation c) {
    switch (c.status) {
      case ConsultationStatus.pending:
        return (
          const Color(0xFFFFF4E5),
          const Color(0xFFB15400),
          _isSwahili
              ? 'Mahojiano yamewekwa. ${c.partnerName ?? 'Mshauri'} atayasoma.'
              : 'Booking placed. ${c.partnerName ?? 'Consultant'} will review.',
        );
      case ConsultationStatus.confirmed:
        return (
          const Color(0xFFE3F2FD),
          const Color(0xFF0D47A1),
          _isSwahili
              ? 'Yamekubaliwa. Yataanza ${DateFormat('d MMM HH:mm').format(c.startsAt)}.'
              : 'Confirmed. Begins ${DateFormat('d MMM HH:mm').format(c.startsAt)}.',
        );
      case ConsultationStatus.inProgress:
        return (
          const Color(0xFFEDE7F6),
          const Color(0xFF4527A0),
          _isSwahili ? 'Mahojiano yanaendelea sasa' : 'Session in progress',
        );
      case ConsultationStatus.completed:
        return (
          const Color(0xFFE8F5E9),
          const Color(0xFF1B5E20),
          _isSwahili
              ? 'Mahojiano yamekamilika. Hakiki maelezo hapa chini.'
              : 'Session complete. Review notes below.',
        );
      case ConsultationStatus.cancelled:
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFB71C1C),
          _isSwahili ? 'Yameghairiwa' : 'Cancelled',
        );
      case ConsultationStatus.rejected:
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFB71C1C),
          _isSwahili
              ? 'Yamekataliwa: ${c.rejectionReason ?? 'hakuna sababu'}'
              : 'Rejected: ${c.rejectionReason ?? 'no reason given'}',
        );
    }
  }

  Widget _summaryCard(Consultation c) {
    final fee = NumberFormat('#,##0', 'en_US').format(c.feeTzs);
    return _card([
      _row(_isSwahili ? 'Aina' : 'Mode', _isSwahili ? c.mode.labelSwahili : c.mode.label, icon: c.mode.icon),
      _row(_isSwahili ? 'Muda' : 'Duration', '${c.durationMin} min', icon: Icons.timer_outlined),
      _row(_isSwahili ? 'Tarehe' : 'When',
          DateFormat('EEE d MMM • HH:mm').format(c.startsAt),
          icon: Icons.event_rounded),
      _row(_isSwahili ? 'Gharama' : 'Fee', 'TZS $fee', icon: Icons.payments_rounded),
      if (c.customerAddress != null && c.customerAddress!.isNotEmpty)
        _row(_isSwahili ? 'Anwani' : 'Address', c.customerAddress!, icon: Icons.place_rounded),
    ]);
  }

  Widget _partnerCard(Consultation c) {
    final inWindow = DateTime.now().isAfter(c.startsAt.subtract(const Duration(minutes: 15)))
        && DateTime.now().isBefore(c.startsAt.add(const Duration(hours: 2)));
    return _card([
      Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _kPrimary.withValues(alpha: 0.06),
            child: Text(
              (c.partnerName ?? '?').characters.first,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.partnerName ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                Text(
                  _isSwahili ? c.vertical.labelSwahili : c.vertical.label,
                  style: const TextStyle(fontSize: 11, color: _kMuted),
                ),
              ],
            ),
          ),
          // Spec line 670 — Tap-to-call button shown only inside the reveal
          // window (15min before → 2h after starts_at).
          if (inWindow)
            IconButton(
              tooltip: _isSwahili ? 'Piga simu' : 'Call',
              onPressed: () => _revealAndCall(c),
              icon: const Icon(Icons.call_rounded, color: _kPrimary),
            ),
          // Spec line 740 — Waiting-room + WebRTC join. Available within the
          // 30-min-before-to-2h-after window for video consultations.
          if (c.mode == ConsultationMode.video && inWindow)
            IconButton(
              tooltip: _isSwahili ? 'Jiunge' : 'Join',
              onPressed: () => _enterWaitingRoom(c),
              icon: const Icon(Icons.video_call_rounded, color: _kPrimary),
            ),
        ],
      ),
    ]);
  }

  bool _needsDermIntake(Consultation c) {
    return c.skillCategory == 'dermatology' &&
        c.dermIntakePhotos.isEmpty &&
        (c.status == ConsultationStatus.pending || c.status == ConsultationStatus.confirmed);
  }

  Widget _preVisitIntakeCard(Consultation c) {
    final isSw = _isSwahili;
    return _card([
      Row(
        children: [
          const Icon(Icons.assignment_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            isSw ? 'Fomu ya awali' : 'Pre-visit intake',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        isSw
            ? 'Jaza fomu kabla ya kukutana na mshauri.'
            : 'Complete the form before meeting your consultant.',
        style: const TextStyle(fontSize: 12, color: _kMuted),
      ),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        onPressed: () async {
          final ok = await Navigator.of(context).push<bool?>(
            MaterialPageRoute(
              builder: (_) => PreVisitIntakePage(
                consultationId: c.id,
                userId: widget.userId,
                vertical: c.vertical,
              ),
            ),
          );
          if (ok == true && mounted) _load();
        },
        icon: const Icon(Icons.edit_note_rounded, size: 16),
        label: Text(isSw ? 'Jaza sasa' : 'Fill now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(40),
        ),
      ),
    ]);
  }

  Widget _dermIntakeCard(Consultation c) {
    final isSw = _isSwahili;
    return _card([
      Row(
        children: [
          const Icon(Icons.camera_alt_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            isSw ? 'Picha za ngozi' : 'Derm photo intake',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        isSw
            ? 'Tuma picha 3 za ngozi kabla ya mahojiano.'
            : 'Send 3 skin photos before the consultation.',
        style: const TextStyle(fontSize: 12, color: _kMuted),
      ),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        onPressed: () async {
          final ok = await Navigator.of(context).push<bool?>(
            MaterialPageRoute(
              builder: (_) => DermIntakePage(
                consultationId: c.id,
                userId: widget.userId,
              ),
            ),
          );
          if (ok == true && mounted) _load();
        },
        icon: const Icon(Icons.camera_enhance_rounded, size: 16),
        label: Text(isSw ? 'Piga picha' : 'Take photos'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(40),
        ),
      ),
    ]);
  }

  Future<void> _enterWaitingRoom(Consultation c) async {
    // Gate 1: pre-call connectivity test for video mode.
    if (c.mode == ConsultationMode.video && !c.connectivityTestPassed) {
      final ok = await Navigator.of(context).push<bool?>(
        MaterialPageRoute(
          builder: (_) => PreCallTestPage(
            consultationId: c.id,
            userId: widget.userId,
          ),
        ),
      );
      if (ok != true || !mounted) return;
      await _load();
      if (!mounted) return;
    }
    // Gate 2: consent screens for video mode.
    if (c.mode == ConsultationMode.video && c.consentScreensSigned.isEmpty) {
      final ok = await PreCallConsentModal.show(
        context,
        consultationId: c.id,
        userId: widget.userId,
      );
      if (!ok || !mounted) return;
      await _load();
      if (!mounted) return;
    }
    final ok = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (_) => ConsultationWaitingRoomPage(
          consultation: c,
          userId: widget.userId,
        ),
      ),
    );
    if (ok == true && mounted) {
      final res = await MessageService().getPrivateConversation(widget.userId, c.targetPartnerUserId);
      if (!mounted) return;
      if (res.success && res.conversation != null) {
        Navigator.of(context).pushNamed(
          '/chat/${res.conversation!.id}',
          arguments: {
            'conversation': res.conversation,
            'promptAfterCall': 'video',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindikana kufungua simu — jaribu tena'
              : 'Could not start call — try again'),
        ));
      }
    }
  }

  Future<void> _revealAndCall(Consultation c) async {
    final res = await ConsultationService.revealPhone(
      id: c.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (res.success && (res.phoneNumber ?? '').isNotEmpty) {
      final uri = Uri.parse('tel:${res.phoneNumber}');
      if (!await launchUrl(uri)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindikana kupiga simu — nambari: ${res.phoneNumber}'
              : 'Could not dial — number: ${res.phoneNumber}'),
        ));
      }
    } else if (res.locked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Nambari itafunguliwa dakika 15 kabla ya muda'
            : 'Phone unlocks 15 min before your slot'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  Widget _intakeCard(Consultation c) {
    return _card([
      Text(
        _isSwahili ? 'Maelezo uliyowasilisha' : 'Your case summary',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
      ),
      const SizedBox(height: 6),
      Text(
        c.intakeSummary ?? '',
        style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4),
      ),
      if (c.attachments != null && c.attachments!.isNotEmpty) ...[
        const SizedBox(height: 8),
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
      Row(
        children: [
          const Icon(Icons.note_alt_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            _isSwahili ? 'Maelezo ya kufuatilia' : 'Follow-up notes',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(c.followUpNotes!, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
      if (c.followUpNotesAt != null) ...[
        const SizedBox(height: 6),
        Text(
          DateFormat('d MMM y • HH:mm').format(c.followUpNotesAt!),
          style: const TextStyle(fontSize: 10, color: _kMuted),
        ),
      ],
    ]);
  }

  Widget _prescriptionCard(Consultation c) {
    return _card([
      Row(
        children: [
          const Icon(Icons.medication_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            _isSwahili ? 'Dawa zilizoagizwa' : 'Prescription',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(c.prescription!, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
      const SizedBox(height: 12),
      // Spec line 745 — eRx pharmacy deeplink. Customer taps to deep-link
      // into pharmacy module with the prescription text pre-filled.
      ElevatedButton.icon(
        onPressed: () => _orderRx(c),
        icon: const Icon(Icons.local_pharmacy_rounded, size: 16),
        label: Text(_isSwahili ? 'Agiza dawa Pharmacy' : 'Order via Pharmacy'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(40),
        ),
      ),
    ]);
  }

  void _orderRx(Consultation c) {
    // Pharmacy module isn't fully shipped; route through search with prescription
    // text as a hint. Once pharmacy lands, swap for a typed RxOrderPage(consultation).
    Navigator.of(context).pushNamed(
      '/search',
      arguments: {'query': 'pharmacy', 'context': 'rx', 'rx_text': c.prescription},
    );
  }

  Widget _timelineCard(Consultation c) {
    final events = <_TimelineEvt>[];
    void add(DateTime? t, String labelSw, String labelEn, {bool danger = false}) {
      if (t == null) return;
      events.add(_TimelineEvt(t, _isSwahili ? labelSw : labelEn, danger));
    }
    add(c.createdAt, 'Imewekwa', 'Booked');
    add(c.confirmedAt, 'Imekubaliwa', 'Confirmed');
    add(c.startedAt, 'Imeanza', 'Started');
    add(c.completedAt, 'Imekamilika', 'Completed');
    add(c.rejectedAt, 'Imekataliwa', 'Rejected', danger: true);
    add(c.cancelledAt, 'Imeghairiwa', 'Cancelled', danger: true);
    events.sort((a, b) => a.at.compareTo(b.at));
    return _card([
      Text(
        _isSwahili ? 'Ratiba' : 'Timeline',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
      ),
      const SizedBox(height: 6),
      ...events.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(e.danger ? Icons.cancel_rounded : Icons.check_circle_rounded,
                    size: 14, color: e.danger ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                ),
                Text(
                  DateFormat('d MMM HH:mm').format(e.at),
                  style: const TextStyle(fontSize: 10, color: _kMuted),
                ),
              ],
            ),
          )),
    ]);
  }

  Widget _joinButton(Consultation c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: _join,
        icon: Icon(c.mode == ConsultationMode.video ? Icons.videocam_rounded : Icons.phone_rounded),
        label: Text(_isSwahili ? 'Jiunge sasa' : 'Join now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _cancelButton() {
    return OutlinedButton(
      onPressed: _cancel,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFB71C1C),
        side: const BorderSide(color: Color(0xFFB71C1C)),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(_isSwahili ? 'Ghairi' : 'Cancel'),
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

  Widget _row(String k, String v, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _kMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(k, style: const TextStyle(fontSize: 12, color: _kMuted)),
          ),
          Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
    );
  }
}

class _TimelineEvt {
  final DateTime at;
  final String label;
  final bool danger;
  _TimelineEvt(this.at, this.label, this.danger);
}

class _ReasonDialog extends StatefulWidget {
  final String title;
  final String hint;
  const _ReasonDialog({required this.title, required this.hint});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      content: TextField(
        controller: _ctrl,
        minLines: 2,
        maxLines: 4,
        maxLength: 500,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isSwahili ? 'Funga' : 'Close'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C),
            foregroundColor: Colors.white,
          ),
          child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
        ),
      ],
    );
  }
}
