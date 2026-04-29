import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/widgets/rate_partner_cta.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/garage_booking.dart';
import '../services/garage_booking_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF2E7D32);
const Color _kDanger = Color(0xFFB71C1C);
const Color _kMuted = Color(0xFF9E9E9E);

class GarageStatusPage extends StatefulWidget {
  final int userId;
  final int bookingId;

  const GarageStatusPage({
    super.key,
    required this.userId,
    required this.bookingId,
  });

  @override
  State<GarageStatusPage> createState() => _GarageStatusPageState();
}

class _GarageStatusPageState extends State<GarageStatusPage> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  GarageBooking? _booking;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await GarageBookingService.get(
      id: widget.bookingId,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.booking != null) {
        _booking = res.booking;
        _error = null;
      } else {
        _error = res.message ?? (_isSwahili ? 'Imeshindikana kupakia' : 'Failed to load');
      }
    });
  }

  Future<void> _approveDiagnosis() async {
    if (_busy || _booking == null) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.approve(
      id: _booking!.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success
        ? (_isSwahili ? 'Umekubali' : 'Approved')
        : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _declineDiagnosis() async {
    if (_busy || _booking == null) return;
    final reason = await _askReason(
      title: _isSwahili ? 'Sababu ya kukataa' : 'Reason for declining',
      hint: _isSwahili ? 'Mfano: gharama ni kubwa sana' : 'e.g. cost too high',
    );
    if (reason == null) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.decline(
      id: _booking!.id,
      userId: widget.userId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success
        ? (_isSwahili ? 'Umekataa' : 'Declined')
        : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _cancelBooking() async {
    if (_busy || _booking == null) return;
    final reason = await _askReason(
      title: _isSwahili ? 'Sababu ya kughairi' : 'Reason for cancelling',
      hint: _isSwahili ? 'Hiari' : 'Optional',
      required: false,
    );
    if (reason == null && !mounted) return;
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Ghairi booking?' : 'Cancel booking?'),
        content: Text(_isSwahili
            ? 'Una uhakika unataka kughairi?'
            : 'Are you sure you want to cancel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_isSwahili ? 'Hapana' : 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: _kDanger),
            child: Text(_isSwahili ? 'Ndiyo, ghairi' : 'Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.cancel(
      id: _booking!.id,
      userId: widget.userId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success
        ? (_isSwahili ? 'Imeghairiwa' : 'Cancelled')
        : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<String?> _askReason({
    required String title,
    required String hint,
    bool required = true,
  }) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          TextButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (required && text.isEmpty) return;
              Navigator.of(ctx).pop(text);
            },
            child: Text(_isSwahili ? 'Tuma' : 'Submit'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          _isSwahili ? 'Hali ya Booking' : 'Booking Status',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (_error != null || _booking == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: _kDanger, size: 48),
              const SizedBox(height: 12),
              Text(
                _error ?? (_isSwahili ? 'Hakuna data' : 'No data'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: Text(_isSwahili ? 'Jaribu tena' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final b = _booking!;
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusBanner(b),
          if (_hasResearchChips(b)) ...[
            const SizedBox(height: 8),
            _researchChips(b),
          ],
          const SizedBox(height: 16),
          if (b.awaitingDiagnosisApproval) ...[
            _diagnosisCard(b),
            const SizedBox(height: 16),
          ],
          if (b.status == GarageBookingStatus.completed &&
              b.warrantyExpiresAt != null) ...[
            _warrantyCard(b),
            const SizedBox(height: 16),
          ],
          _vehicleCard(b),
          const SizedBox(height: 16),
          if (b.photos.isNotEmpty) ...[
            _photoStrip(b.photos),
            const SizedBox(height: 16),
          ],
          _faultCard(b),
          const SizedBox(height: 16),
          _partnerCard(b),
          const SizedBox(height: 16),
          _timelineCard(b),
          if (b.status == GarageBookingStatus.completed) ...[
            const SizedBox(height: 16),
            RatePartnerCta(
              reviewerUserId: widget.userId,
              source: CustomerOrderSource.garageBooking,
              sourceId: b.id,
              partnerName: b.partnerName,
              itemTitle: b.faultSummary,
            ),
          ],
          const SizedBox(height: 16),
          if (!b.hasFinalised) _cancelButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  bool _hasResearchChips(GarageBooking b) {
    return b.dropOffMode != null ||
        b.pickupDropOffered ||
        b.obd2Photos.isNotEmpty;
  }

  Widget _researchChips(GarageBooking b) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (b.dropOffMode != null && b.dropOffMode!.isNotEmpty)
          _miniChip(
            isSw ? _dropOffLabelSw(b.dropOffMode!) : _dropOffLabelEn(b.dropOffMode!),
            const Color(0xFFE3F2FD),
            const Color(0xFF0D47A1),
            Icons.location_on_rounded,
          ),
        if (b.pickupDropOffered)
          _miniChip(
            isSw ? 'Anachukua na kurudisha' : 'Pickup & drop',
            const Color(0xFFE8F5E9),
            const Color(0xFF1B5E20),
            Icons.airport_shuttle_rounded,
          ),
        if (b.obd2Photos.isNotEmpty)
          _miniChip(
            isSw ? 'OBD2 zimepakiwa' : 'OBD2 uploaded',
            const Color(0xFFEEEEEE),
            const Color(0xFF666666),
            Icons.photo_camera_rounded,
          ),
      ],
    );
  }

  String _dropOffLabelSw(String m) {
    switch (m) {
      case 'driveway':
        return 'Nyumbani';
      case 'office':
        return 'Ofisini';
      case 'shop':
        return 'Karakana';
      default:
        return m;
    }
  }

  String _dropOffLabelEn(String m) {
    switch (m) {
      case 'driveway':
        return 'At home';
      case 'office':
        return 'Office';
      case 'shop':
        return 'Shop';
      default:
        return m;
    }
  }

  Widget _miniChip(String text, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
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

  Widget _warrantyCard(GarageBooking b) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final exp = b.warrantyExpiresAt!;
    final active = b.isWarrantyActive;
    final daysLeft = exp.difference(DateTime.now()).inDays;
    final fg = active ? const Color(0xFF1B5E20) : const Color(0xFF666666);
    final bg = active ? const Color(0xFFE8F5E9) : const Color(0xFFEEEEEE);
    String two(int n) => n.toString().padLeft(2, '0');
    final dateStr = '${two(exp.day)}/${two(exp.month)}/${exp.year}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: fg.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.verified_user_rounded : Icons.shield_outlined,
            size: 20,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active
                      ? (isSw
                          ? 'Dhamana hai · siku $daysLeft zilizobaki'
                          : 'Warranty active · $daysLeft days left')
                      : (isSw ? 'Dhamana imeisha' : 'Warranty expired'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                Text(
                  isSw
                      ? 'Inaisha $dateStr · ${b.warrantyKm} km'
                      : 'Expires $dateStr · ${b.warrantyKm} km',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          if (active && !b.warrantyClaimed)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isSw
                      ? 'Imeshaombwa. Mshirika atapata taarifa.'
                      : 'Claim submitted. Partner has been notified.'),
                ));
              },
              child: Text(isSw ? 'Dai' : 'Claim'),
            ),
        ],
      ),
    );
  }

  Widget _statusBanner(GarageBooking b) {
    final colors = _statusColors(b.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.$2),
      ),
      child: Row(
        children: [
          Icon(colors.$3, color: colors.$2, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSwahili ? b.status.labelSwahili : b.status.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: colors.$2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${b.id}',
                  style: const TextStyle(
                    color: _kSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _statusColors(GarageBookingStatus s) {
    switch (s) {
      case GarageBookingStatus.pending:
        return (const Color(0xFFFFF8E1), const Color(0xFFE65100), Icons.hourglass_top_rounded);
      case GarageBookingStatus.confirmed:
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.check_rounded);
      case GarageBookingStatus.droppedOff:
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.directions_car_rounded);
      case GarageBookingStatus.diagnosed:
        return (const Color(0xFFFFF8E1), const Color(0xFFE65100), Icons.fact_check_rounded);
      case GarageBookingStatus.approved:
        return (const Color(0xFFE8F5E9), _kAccent, Icons.thumb_up_rounded);
      case GarageBookingStatus.inProgress:
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.handyman_rounded);
      case GarageBookingStatus.readyForPickup:
        return (const Color(0xFFE8F5E9), _kAccent, Icons.local_shipping_rounded);
      case GarageBookingStatus.completed:
        return (const Color(0xFFE8F5E9), _kAccent, Icons.celebration_rounded);
      case GarageBookingStatus.cancelled:
        return (const Color(0xFFFFEBEE), _kDanger, Icons.cancel_rounded);
      case GarageBookingStatus.rejected:
        return (const Color(0xFFFFEBEE), _kDanger, Icons.block_rounded);
    }
  }

  Widget _diagnosisCard(GarageBooking b) {
    final cap = b.costCapTzs;
    final revised = b.revisedCostTzs;
    final overCap = cap != null && revised != null && revised > cap;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE65100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Text(
                _isSwahili ? 'Tatizo limepatikana' : 'Diagnosis ready',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (b.diagnosis != null && b.diagnosis!.isNotEmpty) ...[
            Text(
              b.diagnosis!,
              style: const TextStyle(color: _kPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
          ],
          if (revised != null) ...[
            Row(
              children: [
                Text(
                  _isSwahili ? 'Gharama mpya: ' : 'Revised cost: ',
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                ),
                Text(
                  _money(revised),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (cap != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _isSwahili ? 'Kikomo chako: ' : 'Your cap: ',
                    style: const TextStyle(color: _kSecondary, fontSize: 13),
                  ),
                  Text(
                    _money(cap),
                    style: const TextStyle(color: _kSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
            if (overCap) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: _kDanger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isSwahili
                            ? 'Imezidi kikomo chako'
                            : 'Exceeds your cost cap',
                        style: const TextStyle(color: _kDanger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _declineDiagnosis,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(_isSwahili ? 'Kataa' : 'Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kDanger,
                    side: const BorderSide(color: _kDanger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _approveDiagnosis,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_isSwahili ? 'Kubali' : 'Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(GarageBooking b) {
    return _section(
      title: _isSwahili ? 'Gari' : 'Vehicle',
      icon: Icons.directions_car_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${b.vehicleMake} ${b.vehicleModel}'
                '${b.vehicleYear != null ? ' (${b.vehicleYear})' : ''}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _kPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              b.vehiclePlate,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.build_rounded, size: 14, color: _kSecondary),
              const SizedBox(width: 6),
              Text(
                _isSwahili ? b.skill.labelSwahili : b.skill.label,
                style: const TextStyle(color: _kSecondary, fontSize: 13),
              ),
            ],
          ),
          if (b.dropOffAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 6),
                Text(
                  _formatDateTime(b.dropOffAt!),
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
          if (b.costCapTzs != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.payments_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 6),
                Text(
                  '${_isSwahili ? 'Kikomo cha gharama' : 'Cost cap'}: ${_money(b.costCapTzs!)}',
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoStrip(List<String> photos) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final url = ApiConfig.sanitizeUrl(photos[i]) ?? photos[i];
          return GestureDetector(
            onTap: () => _showPhoto(url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 96,
                  height: 96,
                  color: _kBorder,
                  child: const Icon(Icons.broken_image_outlined, color: _kMuted),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPhoto(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(40),
                child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _faultCard(GarageBooking b) {
    return _section(
      title: _isSwahili ? 'Tatizo' : 'Fault',
      icon: Icons.warning_amber_rounded,
      child: Text(
        b.faultSummary,
        style: const TextStyle(color: _kPrimary, fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _partnerCard(GarageBooking b) {
    final name = b.partnerName ?? (_isSwahili ? 'Mafundi' : 'Partner');
    final photo = ApiConfig.sanitizeUrl(b.partnerPhotoUrl);
    return _section(
      title: _isSwahili ? 'Mafundi' : 'Mechanic',
      icon: Icons.engineering_rounded,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _kBorder,
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? const Icon(Icons.person, color: _kMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _kPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineCard(GarageBooking b) {
    final events = _buildTimeline(b);
    return _section(
      title: _isSwahili ? 'Hatua' : 'Timeline',
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          for (int i = 0; i < events.length; i++)
            _TimelineRow(
              icon: events[i].icon,
              title: events[i].title,
              subtitle: events[i].subtitle,
              time: events[i].time,
              done: events[i].done,
              isLast: i == events.length - 1,
              isDanger: events[i].isDanger,
            ),
        ],
      ),
    );
  }

  List<_TimelineEvent> _buildTimeline(GarageBooking b) {
    final events = <_TimelineEvent>[];

    events.add(_TimelineEvent(
      icon: Icons.send_rounded,
      title: _isSwahili ? 'Imetumwa' : 'Submitted',
      time: b.createdAt,
      done: true,
    ));

    events.add(_TimelineEvent(
      icon: Icons.check_rounded,
      title: _isSwahili ? 'Imethibitishwa' : 'Confirmed by mechanic',
      time: b.confirmedAt,
      done: b.confirmedAt != null,
    ));

    if (b.rejectedAt != null) {
      events.add(_TimelineEvent(
        icon: Icons.block_rounded,
        title: _isSwahili ? 'Imekataliwa' : 'Rejected',
        subtitle: b.rejectionReason,
        time: b.rejectedAt,
        done: true,
        isDanger: true,
      ));
      return events;
    }

    events.add(_TimelineEvent(
      icon: Icons.directions_car_rounded,
      title: _isSwahili ? 'Imefika gereji' : 'Dropped off',
      time: b.droppedOffAt,
      done: b.droppedOffAt != null,
    ));

    events.add(_TimelineEvent(
      icon: Icons.fact_check_rounded,
      title: _isSwahili ? 'Tatizo limepatikana' : 'Diagnosed',
      subtitle: b.diagnosis,
      time: b.diagnosedAt,
      done: b.diagnosedAt != null,
    ));

    if (b.declinedAt != null) {
      events.add(_TimelineEvent(
        icon: Icons.close_rounded,
        title: _isSwahili ? 'Umekataa diagnosis' : 'Diagnosis declined',
        subtitle: b.declineReason,
        time: b.declinedAt,
        done: true,
        isDanger: true,
      ));
    } else {
      events.add(_TimelineEvent(
        icon: Icons.thumb_up_rounded,
        title: _isSwahili ? 'Umekubali' : 'Approved',
        time: b.approvedAt,
        done: b.approvedAt != null,
      ));

      events.add(_TimelineEvent(
        icon: Icons.handyman_rounded,
        title: _isSwahili ? 'Inafanyiwa kazi' : 'Work in progress',
        time: b.inProgressAt,
        done: b.inProgressAt != null,
      ));

      events.add(_TimelineEvent(
        icon: Icons.local_shipping_rounded,
        title: _isSwahili ? 'Tayari kuchukuliwa' : 'Ready for pickup',
        subtitle: b.finalCostTzs != null
            ? '${_isSwahili ? 'Gharama ya mwisho' : 'Final cost'}: ${_money(b.finalCostTzs!)}'
            : null,
        time: b.readyForPickupAt,
        done: b.readyForPickupAt != null,
      ));

      events.add(_TimelineEvent(
        icon: Icons.celebration_rounded,
        title: _isSwahili ? 'Imekamilika' : 'Completed',
        time: b.completedAt,
        done: b.completedAt != null,
      ));
    }

    if (b.cancelledAt != null) {
      events.add(_TimelineEvent(
        icon: Icons.cancel_rounded,
        title: _isSwahili ? 'Imeghairiwa' : 'Cancelled',
        subtitle: b.cancellationReason,
        time: b.cancelledAt,
        done: true,
        isDanger: true,
      ));
    }

    return events;
  }

  Widget _cancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _cancelBooking,
        icon: const Icon(Icons.cancel_rounded),
        label: Text(_isSwahili ? 'Ghairi booking' : 'Cancel booking'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kDanger,
          side: const BorderSide(color: _kDanger),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _kSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  String _money(int tzs) {
    final f = NumberFormat.decimalPattern();
    return 'TZS ${f.format(tzs)}';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return DateFormat('d MMM yyyy, HH:mm').format(local);
  }
}

class _TimelineEvent {
  final IconData icon;
  final String title;
  final String? subtitle;
  final DateTime? time;
  final bool done;
  final bool isDanger;

  _TimelineEvent({
    required this.icon,
    required this.title,
    this.subtitle,
    this.time,
    required this.done,
    this.isDanger = false,
  });
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final DateTime? time;
  final bool done;
  final bool isLast;
  final bool isDanger;

  const _TimelineRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.time,
    required this.done,
    required this.isLast,
    required this.isDanger,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? _kDanger
        : (done ? _kAccent : _kMuted);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? color : Colors.white,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: done ? Colors.white : color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? color.withValues(alpha: 0.4) : _kBorder,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: done ? _kPrimary : _kMuted,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM, HH:mm').format(time!.toLocal()),
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
