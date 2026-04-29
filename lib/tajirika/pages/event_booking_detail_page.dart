import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/widgets/rate_partner_cta.dart';
import '../../events/models/event_booking.dart';
import '../../events/services/event_booking_service.dart';
import '../../customer_orders/widgets/lead_expiring_chip.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

/// Detail page for an event_booking. Used by the unified inbox dispatcher.
/// Supports both customer ('customer') and partner ('partner') roles.
class EventBookingDetailPage extends StatefulWidget {
  final int userId;
  final int bookingId;
  final String role;

  const EventBookingDetailPage({
    super.key,
    required this.userId,
    required this.bookingId,
    required this.role,
  });

  @override
  State<EventBookingDetailPage> createState() => _EventBookingDetailPageState();
}

class _EventBookingDetailPageState extends State<EventBookingDetailPage> {
  EventBooking? _b;
  bool _loading = true;
  String? _error;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isPartner => widget.role == 'partner';

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
    final res = await EventBookingService.get(id: widget.bookingId, userId: widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _b = res.booking;
      _error = res.success ? null : (res.message ?? 'Failed');
    });
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _accept() async {
    final res = await EventBookingService.accept(id: widget.bookingId, userId: widget.userId);
    _after(res, _isSwahili
        ? 'Tarehe imehifadhiwa. Mteja anatakiwa kulipa amana ndani ya saa 48.'
        : 'Date held. Customer must pay deposit within 48h.');
  }

  Future<void> _reject() async {
    final reason = await _askReason(_isSwahili ? 'Sababu ya kukataa' : 'Reject reason');
    if (reason == null) return;
    final res = await EventBookingService.reject(
      id: widget.bookingId,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    _after(res, _isSwahili ? 'Imekataliwa' : 'Rejected');
  }

  Future<void> _payDeposit() async {
    final res = await EventBookingService.payDeposit(id: widget.bookingId, userId: widget.userId);
    _after(res, _isSwahili
        ? 'Amana imepokelewa. Hafla imekubaliwa.'
        : 'Deposit captured. Event confirmed.');
  }

  Future<void> _markDayOf() async {
    final res = await EventBookingService.markDayOf(id: widget.bookingId, userId: widget.userId);
    _after(res, _isSwahili ? 'Siku ya hafla imeanza' : 'Day of started');
  }

  Future<void> _markForceMajeure() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Force majeure' : 'Force majeure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isSwahili
                  ? 'Eleza sababu (mfano: ugonjwa, ajali, hali ya hewa kali). Mteja atapata refund kamili.'
                  : 'Explain (illness, accident, severe weather, etc.). Customer gets a full refund.',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB15400),
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Thibitisha' : 'Confirm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null || reason.length < 5 || !mounted) return;
    final res = await EventBookingService.markForceMajeure(
      id: widget.bookingId,
      userId: widget.userId,
      reason: reason,
    );
    _after(res, _isSwahili ? 'Imerekodiwa' : 'Recorded');
  }

  Future<void> _markCompleted() async {
    final res = await EventBookingService.markCompleted(id: widget.bookingId, userId: widget.userId);
    _after(res, _isSwahili ? 'Hafla imekamilika' : 'Event complete');
  }

  Future<void> _cancel() async {
    final reason = await _askReason(_isSwahili ? 'Sababu ya kughairi' : 'Cancellation reason');
    if (reason == null) return;
    final res = await EventBookingService.cancel(
      id: widget.bookingId,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    _after(res, _isSwahili ? 'Imeghairiwa' : 'Cancelled');
  }

  void _after(EventBookingResult res, String okMsg) {
    if (!mounted) return;
    if (res.success) {
      _toast(okMsg);
      _load();
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'));
    }
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
          maxLength: 500,
          decoration: InputDecoration(hintText: _isSwahili ? 'Sababu (hiari)' : 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isSwahili ? 'Funga' : 'Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: Text(_isSwahili ? 'Tuma' : 'Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _callOther(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final b = _b;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          b?.eventTitle ?? (_isSwahili ? 'Hafla' : 'Event'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: _kMuted))),
                )
              : b == null
                  ? Center(
                      child: Text(_isSwahili ? 'Hapatikani' : 'Not found',
                          style: const TextStyle(color: _kMuted)),
                    )
                  : _buildBody(b),
      bottomNavigationBar: b == null ? null : _buildActionBar(b),
    );
  }

  Widget _buildBody(EventBooking b) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          _statusBanner(b),
          const SizedBox(height: 6),
          LeadExpiringChipFetcher(
            orderId: b.id,
            sourceApiValue: 'event_booking',
            isSwahili: _isSwahili,
          ),
          if (b.backupPerformerName != null && b.backupPerformerName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _backupPerformerChip(b),
          ],
          if (_hasResearchChips(b)) ...[
            const SizedBox(height: 8),
            _researchChipsRow(b),
          ],
          if (b.qrVoucherCode != null && b.qrVoucherCode!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _qrVoucherCard(b),
          ],
          if (b.refundPolicy != null && b.refundPolicy!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _refundPolicyCard(b),
          ],
          const SizedBox(height: 10),
          _eventCard(b),
          const SizedBox(height: 10),
          _moneyCard(b),
          const SizedBox(height: 10),
          _counterpartyCard(b),
          if (b.addOns.isNotEmpty) ...[
            const SizedBox(height: 10),
            _addOnsCard(b),
          ],
          if (b.itinerary.isNotEmpty) ...[
            const SizedBox(height: 10),
            _itineraryCard(b),
          ],
          if (b.travelers.isNotEmpty) ...[
            const SizedBox(height: 10),
            _travelersCard(b),
          ],
          const SizedBox(height: 10),
          _timelineCard(b),
          if (!_isPartner && b.status == EventBookingStatus.completed) ...[
            const SizedBox(height: 12),
            RatePartnerCta(
              reviewerUserId: widget.userId,
              source: CustomerOrderSource.eventBooking,
              sourceId: b.id,
              partnerName: b.partnerName,
              itemTitle: b.eventTitle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(EventBooking b) {
    final (bg, fg, msg) = _statusBlurb(b);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(_statusIcon(b.status), size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backupPerformerChip(EventBooking b) {
    final amt = b.backupPerformerAmountTzs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded,
              size: 16, color: Color(0xFF1B5E20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSwahili
                      ? 'Mwenza wa akiba: ${b.backupPerformerName}'
                      : 'Backup performer: ${b.backupPerformerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (amt != null && amt > 0)
                  Text(
                    _isSwahili
                        ? 'Akiba imehifadhiwa: TZS ${_fmtMoney(amt)}'
                        : 'Reserved: TZS ${_fmtMoney(amt)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1B5E20),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  bool _hasResearchChips(EventBooking b) {
    return b.packageTier != null ||
        b.travelInsuranceOptin ||
        b.earlyBirdApplied ||
        b.groupDiscountApplied ||
        b.travelRadiusKm != null;
  }

  Widget _researchChipsRow(EventBooking b) {
    final isSw = _isSwahili;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (b.packageTier != null && b.packageTier!.isNotEmpty)
          _eventChip(
            isSw ? 'Daraja: ${_tierLabel(b.packageTier!)}' : 'Tier: ${_tierLabel(b.packageTier!)}',
            const Color(0xFFE3F2FD),
            const Color(0xFF0D47A1),
            Icons.layers_rounded,
          ),
        if (b.travelRadiusKm != null && b.travelRadiusKm! > 0)
          _eventChip(
            isSw
                ? 'Safari hadi ${b.travelRadiusKm}km'
                : 'Travel up to ${b.travelRadiusKm}km',
            const Color(0xFFEEEEEE),
            const Color(0xFF666666),
            Icons.directions_car_rounded,
          ),
        if (b.travelInsuranceOptin)
          _eventChip(
            isSw ? 'Bima ya safari' : 'Travel insured',
            const Color(0xFFE8F5E9),
            const Color(0xFF1B5E20),
            Icons.health_and_safety_rounded,
          ),
        if (b.earlyBirdApplied)
          _eventChip(
            isSw ? 'Punguzo la mapema' : 'Early bird',
            const Color(0xFFE8F5E9),
            const Color(0xFF1B5E20),
            Icons.flutter_dash_rounded,
          ),
        if (b.groupDiscountApplied)
          _eventChip(
            isSw
                ? 'Punguzo la kikundi -${b.groupDiscountPct}%'
                : 'Group -${b.groupDiscountPct}%',
            const Color(0xFFE8F5E9),
            const Color(0xFF1B5E20),
            Icons.groups_rounded,
          ),
      ],
    );
  }

  String _tierLabel(String t) {
    switch (t) {
      case 'basix':
        return 'Basix';
      case 'original':
        return 'Original';
      case 'comfort':
        return 'Comfort';
      case 'premium':
        return 'Premium';
      default:
        return t;
    }
  }

  Widget _eventChip(String text, Color bg, Color fg, IconData icon) {
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

  Widget _qrVoucherCard(EventBooking b) {
    final isSw = _isSwahili;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        border: Border.all(color: const Color(0xFF0D47A1).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_rounded, size: 24, color: Color(0xFF0D47A1)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSw ? 'Voucha ya QR' : 'QR Voucher',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Text(
                  b.qrVoucherCode!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  isSw
                      ? 'Onyesha kabla ya kuanza ziara.'
                      : 'Show on arrival to start the tour.',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _refundPolicyCard(EventBooking b) {
    final isSw = _isSwahili;
    final policy = b.refundPolicy!;
    final tier60 = policy['tier_60'];
    final tier30 = policy['tier_30'];
    final tier0 = policy['tier_0'];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE).withValues(alpha: 0.4),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.policy_rounded, size: 14, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 6),
              Text(
                isSw ? 'Sera ya marejesho' : 'Refund policy',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (tier60 != null)
            _refundRow(
              isSw ? 'Siku 60+ kabla' : '60+ days',
              '${tier60.toString()}%',
            ),
          if (tier30 != null)
            _refundRow(
              isSw ? 'Siku 30–60 kabla' : '30–60 days',
              '${tier30.toString()}%',
            ),
          if (tier0 != null)
            _refundRow(
              isSw ? 'Siku <30 kabla' : '<30 days',
              '${tier0.toString()}%',
            ),
        ],
      ),
    );
  }

  Widget _refundRow(String label, String pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
            ),
          ),
          Text(
            pct,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(EventBookingStatus s) {
    switch (s) {
      case EventBookingStatus.pending: return Icons.hourglass_empty_rounded;
      case EventBookingStatus.held: return Icons.lock_clock_rounded;
      case EventBookingStatus.confirmed: return Icons.check_circle_outline_rounded;
      case EventBookingStatus.dayOf: return Icons.event_note_rounded;
      case EventBookingStatus.completed: return Icons.celebration_rounded;
      case EventBookingStatus.cancelled:
      case EventBookingStatus.rejected: return Icons.cancel_rounded;
    }
  }

  (Color, Color, String) _statusBlurb(EventBooking b) {
    switch (b.status) {
      case EventBookingStatus.pending:
        return (
          const Color(0xFFFFF4E5),
          const Color(0xFFB15400),
          _isSwahili
              ? 'Tarehe imewekwa. Subiri ${b.partnerName ?? "mshirika"} akubali.'
              : 'Date placed. Awaiting ${b.partnerName ?? "partner"} confirmation.',
        );
      case EventBookingStatus.held:
        final due = b.depositDueAt;
        return (
          const Color(0xFFE3F2FD),
          const Color(0xFF0D47A1),
          due == null
              ? (_isSwahili ? 'Tarehe imehifadhiwa. Lipa amana.' : 'Date held. Pay deposit.')
              : (_isSwahili
                  ? 'Tarehe imehifadhiwa. Lipa amana kabla ${DateFormat('d MMM HH:mm').format(due)}.'
                  : 'Date held. Pay deposit before ${DateFormat('d MMM HH:mm').format(due)}.'),
        );
      case EventBookingStatus.confirmed:
        return (
          const Color(0xFFEDE7F6),
          const Color(0xFF4527A0),
          _isSwahili
              ? 'Hafla imekubaliwa: ${DateFormat('EEE d MMM • HH:mm').format(b.eventStartsAt)}'
              : 'Confirmed: ${DateFormat('EEE d MMM • HH:mm').format(b.eventStartsAt)}',
        );
      case EventBookingStatus.dayOf:
        return (
          const Color(0xFFFFF8E1),
          const Color(0xFFE65100),
          _isSwahili ? 'Leo ni siku ya hafla!' : "Today's the day!",
        );
      case EventBookingStatus.completed:
        return (
          const Color(0xFFE8F5E9),
          const Color(0xFF1B5E20),
          _isSwahili ? 'Hafla imekamilika' : 'Event complete',
        );
      case EventBookingStatus.cancelled:
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFB71C1C),
          _isSwahili
              ? 'Imeghairiwa${b.cancellationReason != null ? ": ${b.cancellationReason}" : ""}'
              : 'Cancelled${b.cancellationReason != null ? ": ${b.cancellationReason}" : ""}',
        );
      case EventBookingStatus.rejected:
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFB71C1C),
          _isSwahili
              ? 'Imekataliwa${b.rejectionReason != null ? ": ${b.rejectionReason}" : ""}'
              : 'Rejected${b.rejectionReason != null ? ": ${b.rejectionReason}" : ""}',
        );
    }
  }

  Widget _eventCard(EventBooking b) {
    return _card([
      Row(
        children: [
          Icon(b.eventKind.icon, size: 18, color: _kPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(b.eventTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      _kv(_isSwahili ? 'Aina' : 'Kind',
          _isSwahili ? b.eventKind.labelSwahili : b.eventKind.label,
          icon: b.eventKind.icon),
      _kv(_isSwahili ? 'Tarehe' : 'When',
          DateFormat('EEE d MMM • HH:mm').format(b.eventStartsAt),
          icon: Icons.event_rounded),
      if (b.eventEndsAt != null)
        _kv(_isSwahili ? 'Maliza' : 'Ends',
            DateFormat('EEE d MMM • HH:mm').format(b.eventEndsAt!),
            icon: Icons.event_available_rounded),
      if (b.eventAddress != null && b.eventAddress!.isNotEmpty)
        _kv(_isSwahili ? 'Mahali' : 'Where', b.eventAddress!, icon: Icons.place_rounded),
      _kv(_isSwahili ? 'Watu' : 'Party size', '${b.partySize}', icon: Icons.people_rounded),
    ]);
  }

  Widget _moneyCard(EventBooking b) {
    return _card([
      Text(_isSwahili ? 'Malipo' : 'Money',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      const SizedBox(height: 8),
      _moneyRow(_isSwahili ? 'Bei ya msingi' : 'Base', b.basePriceTzs),
      if (b.addOns.isNotEmpty)
        _moneyRow(_isSwahili ? 'Ziada' : 'Add-ons', b.totalTzs - b.basePriceTzs),
      const Divider(height: 16),
      _moneyRow(_isSwahili ? 'Jumla' : 'Total', b.totalTzs, bold: true),
      _moneyRow(_isSwahili ? 'Amana' : 'Deposit', b.depositTzs, bold: b.depositPaidAt == null),
      _moneyRow(_isSwahili ? 'Salio' : 'Balance', b.balanceTzs),
      if (b.depositPaidAt != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${_isSwahili ? "Amana imepokelewa" : "Deposit paid"} • ${DateFormat('d MMM HH:mm').format(b.depositPaidAt!)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20)),
          ),
        ),
    ]);
  }

  Widget _moneyRow(String label, int amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary))),
          Text(
            'TZS ${NumberFormat('#,##0', 'en_US').format(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterpartyCard(EventBooking b) {
    final showName = _isPartner ? b.customerName : b.partnerName;
    final showRole = _isPartner ? (_isSwahili ? 'Mteja' : 'Customer') : (_isSwahili ? 'Mshirika' : 'Partner');
    final phone = _isPartner ? b.customerPhone : null;
    return _card([
      Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _kPrimary.withValues(alpha: 0.06),
            child: Text(
              (showName ?? '?').characters.first,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(showName ?? '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text(showRole, style: const TextStyle(fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              onPressed: () => _callOther(phone),
              icon: const Icon(Icons.phone_rounded, size: 18, color: _kPrimary),
              tooltip: _isSwahili ? 'Piga simu' : 'Call',
            ),
        ],
      ),
    ]);
  }

  Widget _addOnsCard(EventBooking b) {
    return _card([
      Text(_isSwahili ? 'Ziada' : 'Add-ons',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      const SizedBox(height: 6),
      ...b.addOns.map((a) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('${a.label} × ${a.qty}',
                      style: const TextStyle(fontSize: 12, color: _kPrimary)),
                ),
                Text(
                  'TZS ${NumberFormat('#,##0', 'en_US').format(a.subtotalTzs)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ],
            ),
          )),
    ]);
  }

  Widget _itineraryCard(EventBooking b) {
    return _card([
      Text(_isSwahili ? 'Ratiba ya safari' : 'Itinerary',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      const SizedBox(height: 6),
      ...b.itinerary.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_isSwahili ? "Siku" : "Day"} ${d.day}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (d.location != null)
                        Text(d.location!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
                      if (d.activity != null)
                        Text(d.activity!,
                            style: const TextStyle(fontSize: 11, color: _kPrimary)),
                      Row(
                        children: [
                          if (d.accommodation != null) ...[
                            const Icon(Icons.hotel_rounded, size: 11, color: _kMuted),
                            const SizedBox(width: 3),
                            Text(d.accommodation!,
                                style: const TextStyle(fontSize: 10, color: _kMuted)),
                            const SizedBox(width: 8),
                          ],
                          if (d.includedMeals != null) ...[
                            const Icon(Icons.restaurant_rounded, size: 11, color: _kMuted),
                            const SizedBox(width: 3),
                            Text(d.includedMeals!,
                                style: const TextStyle(fontSize: 10, color: _kMuted)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    ]);
  }

  Widget _travelersCard(EventBooking b) {
    return _card([
      Row(
        children: [
          const Icon(Icons.lock_rounded, size: 14, color: _kPrimary),
          const SizedBox(width: 6),
          Text(_isSwahili ? 'Wasafiri (siri)' : 'Travelers (confidential)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
        ],
      ),
      const SizedBox(height: 6),
      ...b.travelers.map((t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary)),
                if (t.nidaOrPassport != null && t.nidaOrPassport!.isNotEmpty)
                  Text('NIDA/Passport: ${t.nidaOrPassport}',
                      style: const TextStyle(fontSize: 11, color: _kMuted)),
                if (t.dietary != null && t.dietary!.isNotEmpty)
                  Text('${_isSwahili ? "Lishe" : "Dietary"}: ${t.dietary}',
                      style: const TextStyle(fontSize: 11, color: _kMuted)),
                if (t.medical != null && t.medical!.isNotEmpty)
                  Text('${_isSwahili ? "Afya" : "Medical"}: ${t.medical}',
                      style: const TextStyle(fontSize: 11, color: _kMuted)),
                if (t.emergencyContact != null && t.emergencyContact!.isNotEmpty)
                  Text('${_isSwahili ? "Dharura" : "Emergency"}: ${t.emergencyContact}',
                      style: const TextStyle(fontSize: 11, color: _kMuted)),
              ],
            ),
          )),
    ]);
  }

  Widget _timelineCard(EventBooking b) {
    final events = <(DateTime, String, bool)>[];
    void add(DateTime? t, String swLabel, String enLabel, {bool danger = false}) {
      if (t == null) return;
      events.add((t, _isSwahili ? swLabel : enLabel, danger));
    }
    add(b.createdAt, 'Imewekwa', 'Booked');
    add(b.heldAt, 'Tarehe imehifadhiwa', 'Date held');
    add(b.depositPaidAt, 'Amana imepokelewa', 'Deposit paid');
    add(b.dayOfAt, 'Siku ya hafla', 'Day of');
    add(b.completedAt, 'Imekamilika', 'Completed');
    add(b.cancelledAt, 'Imeghairiwa', 'Cancelled', danger: true);
    add(b.rejectedAt, 'Imekataliwa', 'Rejected', danger: true);
    events.sort((a, x) => a.$1.compareTo(x.$1));
    return _card([
      Text(_isSwahili ? 'Ratiba' : 'Timeline',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      const SizedBox(height: 6),
      ...events.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  e.$3 ? Icons.cancel_rounded : Icons.check_circle_rounded,
                  size: 14,
                  color: e.$3 ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.$2,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                ),
                Text(
                  DateFormat('d MMM HH:mm').format(e.$1),
                  style: const TextStyle(fontSize: 10, color: _kMuted),
                ),
              ],
            ),
          )),
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

  Widget? _buildActionBar(EventBooking b) {
    final List<Widget> actions = [];
    Widget btn(IconData icon, String label, VoidCallback onTap, {Color color = _kPrimary}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 16),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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

    if (b.hasFinalised) return null;

    if (_isPartner) {
      switch (b.status) {
        case EventBookingStatus.pending:
          actions.add(btn(Icons.close_rounded, _isSwahili ? 'Kataa' : 'Reject', _reject,
              color: const Color(0xFFB71C1C)));
          actions.add(btn(Icons.check_rounded, _isSwahili ? 'Hifadhi' : 'Hold', _accept));
          break;
        case EventBookingStatus.held:
          // Partner waits for deposit; can cancel.
          actions.add(btn(Icons.cancel_rounded, _isSwahili ? 'Ghairi' : 'Cancel', _cancel,
              color: const Color(0xFFB71C1C)));
          break;
        case EventBookingStatus.confirmed:
          actions.add(btn(Icons.warning_amber_rounded,
              _isSwahili ? 'Force majeure' : 'Force majeure', _markForceMajeure,
              color: const Color(0xFFB15400)));
          actions.add(btn(Icons.event_note_rounded, _isSwahili ? 'Anza siku' : 'Day of', _markDayOf));
          break;
        case EventBookingStatus.dayOf:
          actions.add(btn(Icons.warning_amber_rounded,
              _isSwahili ? 'Force majeure' : 'Force majeure', _markForceMajeure,
              color: const Color(0xFFB15400)));
          actions.add(btn(Icons.celebration_rounded, _isSwahili ? 'Imekamilika' : 'Complete',
              _markCompleted, color: const Color(0xFF1B5E20)));
          break;
        case EventBookingStatus.completed:
        case EventBookingStatus.cancelled:
        case EventBookingStatus.rejected:
          return null;
      }
    } else {
      switch (b.status) {
        case EventBookingStatus.pending:
          actions.add(btn(Icons.cancel_rounded, _isSwahili ? 'Ghairi' : 'Cancel', _cancel,
              color: const Color(0xFFB71C1C)));
          break;
        case EventBookingStatus.held:
          if (b.isDepositOverdue) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: Text(
                  _isSwahili ? 'Hifadhi imekwisha' : 'Hold expired',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.w700),
                ),
              ),
            );
          }
          actions.add(btn(Icons.cancel_rounded, _isSwahili ? 'Ghairi' : 'Cancel', _cancel,
              color: const Color(0xFFB71C1C)));
          actions.add(btn(Icons.payments_rounded, _isSwahili ? 'Lipa Amana' : 'Pay Deposit',
              _payDeposit, color: const Color(0xFF1B5E20)));
          break;
        case EventBookingStatus.confirmed:
        case EventBookingStatus.dayOf:
          actions.add(btn(Icons.cancel_rounded, _isSwahili ? 'Ghairi' : 'Cancel', _cancel,
              color: const Color(0xFFB71C1C)));
          break;
        case EventBookingStatus.completed:
        case EventBookingStatus.cancelled:
        case EventBookingStatus.rejected:
          return null;
      }
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
