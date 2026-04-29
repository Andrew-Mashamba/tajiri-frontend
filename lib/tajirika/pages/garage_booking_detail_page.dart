import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../service_garage/models/garage_booking.dart';
import '../../service_garage/services/garage_booking_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF2E7D32);
const Color _kDanger = Color(0xFFB71C1C);
const Color _kMuted = Color(0xFF9E9E9E);

class GarageBookingDetailPage extends StatefulWidget {
  final int userId;
  final int bookingId;

  const GarageBookingDetailPage({
    super.key,
    required this.userId,
    required this.bookingId,
  });

  @override
  State<GarageBookingDetailPage> createState() => _GarageBookingDetailPageState();
}

class _GarageBookingDetailPageState extends State<GarageBookingDetailPage> {
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

  Future<void> _accept() async {
    if (_busy || _booking == null) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.accept(id: _booking!.id, userId: widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imekubaliwa' : 'Accepted') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _reject() async {
    if (_busy || _booking == null) return;
    final reason = await _askReason(
      title: _isSwahili ? 'Sababu ya kukataa' : 'Reason for rejecting',
      hint: _isSwahili ? 'Hiari' : 'Optional',
      required: false,
    );
    if (!mounted) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.reject(
      id: _booking!.id,
      userId: widget.userId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imekataliwa' : 'Rejected') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _droppedOff() async {
    if (_busy || _booking == null) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.droppedOff(id: _booking!.id, userId: widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imefika' : 'Marked as dropped off') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _diagnose() async {
    if (_busy || _booking == null) return;
    final result = await _askDiagnosis();
    if (result == null) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.diagnose(
      id: _booking!.id,
      userId: widget.userId,
      diagnosis: result.$1,
      revisedCostTzs: result.$2,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imetumwa kwa mteja' : 'Sent to customer') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _startWork() async {
    if (_busy || _booking == null) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.startWork(id: _booking!.id, userId: widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Kazi imeanza' : 'Work started') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _readyForPickup() async {
    if (_busy || _booking == null) return;
    final cost = await _askFinalCost();
    if (cost == null) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.readyForPickup(
      id: _booking!.id,
      userId: widget.userId,
      finalCostTzs: cost,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Tayari kwa mteja' : 'Ready for pickup') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _complete() async {
    if (_busy || _booking == null) return;
    setState(() => _busy = true);
    final res = await GarageBookingService.complete(id: _booking!.id, userId: widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imekamilika' : 'Completed') : (res.message ?? 'Error'));
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

  Future<(String, int)?> _askDiagnosis() async {
    final diagCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    String? diagErr;
    String? costErr;

    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(_isSwahili ? 'Diagnosis' : 'Diagnosis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: diagCtrl,
                  maxLines: 5,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Tatizo & matengenezo' : 'Diagnosis & repairs',
                    hintText: _isSwahili
                        ? 'Eleza tatizo na kazi inayohitajika'
                        : 'Describe the fault and required work',
                    border: const OutlineInputBorder(),
                    errorText: diagErr,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Gharama (TZS)' : 'Revised cost (TZS)',
                    border: const OutlineInputBorder(),
                    errorText: costErr,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(_isSwahili ? 'Funga' : 'Close'),
            ),
            TextButton(
              onPressed: () {
                final diag = diagCtrl.text.trim();
                final cost = int.tryParse(costCtrl.text.trim());
                setLocal(() {
                  diagErr = diag.length < 10
                      ? (_isSwahili ? 'Andika maelezo zaidi' : 'Please add more detail')
                      : null;
                  costErr = (cost == null || cost <= 0)
                      ? (_isSwahili ? 'Weka gharama sahihi' : 'Enter a valid cost')
                      : null;
                });
                if (diagErr == null && costErr == null) {
                  Navigator.of(ctx).pop((diag, cost!));
                }
              },
              child: Text(_isSwahili ? 'Tuma' : 'Submit'),
            ),
          ],
        ),
      ),
    );
    diagCtrl.dispose();
    costCtrl.dispose();
    return result;
  }

  Future<int?> _askFinalCost() async {
    final ctrl = TextEditingController();
    final revised = _booking?.revisedCostTzs;
    if (revised != null) ctrl.text = '$revised';
    String? err;

    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(_isSwahili ? 'Gharama ya mwisho' : 'Final cost'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'TZS',
              border: const OutlineInputBorder(),
              errorText: err,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(_isSwahili ? 'Funga' : 'Close'),
            ),
            TextButton(
              onPressed: () {
                final cost = int.tryParse(ctrl.text.trim());
                setLocal(() {
                  err = (cost == null || cost <= 0)
                      ? (_isSwahili ? 'Weka gharama sahihi' : 'Enter a valid cost')
                      : null;
                });
                if (err == null) Navigator.of(ctx).pop(cost);
              },
              child: Text(_isSwahili ? 'Tuma' : 'Submit'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return result;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _callCustomer() async {
    final phone = _booking?.customerPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
          _isSwahili ? 'Booking ya Gari' : 'Garage Booking',
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
      bottomNavigationBar: _booking == null ? null : _buildActionBar(_booking!),
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
          const SizedBox(height: 16),
          if (b.photos.isNotEmpty) ...[
            _photoCarousel(b.photos),
            const SizedBox(height: 16),
          ],
          _customerCard(b),
          const SizedBox(height: 16),
          _vehicleCard(b),
          const SizedBox(height: 16),
          _faultCard(b),
          const SizedBox(height: 16),
          if (b.diagnosis != null && b.diagnosis!.isNotEmpty) ...[
            _diagnosisSummary(b),
            const SizedBox(height: 16),
          ],
          _scheduleCard(b),
          const SizedBox(height: 80),
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
                Text('#${b.id}', style: const TextStyle(color: _kSecondary, fontSize: 12)),
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

  Widget _photoCarousel(List<String> photos) {
    return SizedBox(
      height: 200,
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
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                width: 280,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 280,
                  height: 200,
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

  Widget _customerCard(GarageBooking b) {
    final photo = ApiConfig.sanitizeUrl(b.customerPhotoUrl);
    final phone = b.customerPhone;
    return _section(
      title: _isSwahili ? 'Mteja' : 'Customer',
      icon: Icons.person_rounded,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _kBorder,
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null ? const Icon(Icons.person, color: _kMuted) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.customerName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                    fontSize: 14,
                  ),
                ),
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: const TextStyle(color: _kSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: _kAccent),
              onPressed: _callCustomer,
              tooltip: _isSwahili ? 'Piga simu' : 'Call',
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
              Icon(b.skill.icon, size: 14, color: _kSecondary),
              const SizedBox(width: 6),
              Text(
                _isSwahili ? b.skill.labelSwahili : b.skill.label,
                style: const TextStyle(color: _kSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _faultCard(GarageBooking b) {
    return _section(
      title: _isSwahili ? 'Tatizo' : 'Customer report',
      icon: Icons.warning_amber_rounded,
      child: Text(
        b.faultSummary,
        style: const TextStyle(color: _kPrimary, fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _diagnosisSummary(GarageBooking b) {
    return _section(
      title: _isSwahili ? 'Diagnosis' : 'Your diagnosis',
      icon: Icons.fact_check_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            b.diagnosis ?? '',
            style: const TextStyle(color: _kPrimary, fontSize: 14, height: 1.4),
          ),
          if (b.revisedCostTzs != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _isSwahili ? 'Gharama: ' : 'Revised cost: ',
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                ),
                Text(
                  _money(b.revisedCostTzs!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (b.finalCostTzs != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _isSwahili ? 'Gharama ya mwisho: ' : 'Final cost: ',
                  style: const TextStyle(color: _kSecondary, fontSize: 13),
                ),
                Text(
                  _money(b.finalCostTzs!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _kAccent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (b.declineReason != null && b.declineReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.close_rounded, size: 16, color: _kDanger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_isSwahili ? 'Mteja amekataa' : 'Customer declined'}: ${b.declineReason}',
                      style: const TextStyle(color: _kDanger, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scheduleCard(GarageBooking b) {
    return _section(
      title: _isSwahili ? 'Ratiba' : 'Schedule',
      icon: Icons.event_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (b.dropOffAt != null)
            _kvRow(
              _isSwahili ? 'Atafika' : 'Drop-off',
              _formatDateTime(b.dropOffAt!),
            ),
          if (b.costCapTzs != null)
            _kvRow(
              _isSwahili ? 'Kikomo cha gharama' : 'Cost cap',
              _money(b.costCapTzs!),
            ),
          if (b.createdAt != null)
            _kvRow(
              _isSwahili ? 'Imeombwa' : 'Requested',
              _formatDateTime(b.createdAt!),
            ),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: _kSecondary, fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(color: _kPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActionBar(GarageBooking b) {
    final actions = _actionsFor(b.status);
    if (actions.isEmpty) return null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: actions[i]),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _actionsFor(GarageBookingStatus status) {
    switch (status) {
      case GarageBookingStatus.pending:
        return [
          OutlinedButton.icon(
            onPressed: _busy ? null : _reject,
            icon: const Icon(Icons.close_rounded),
            label: Text(_isSwahili ? 'Kataa' : 'Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kDanger,
              side: const BorderSide(color: _kDanger),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _accept,
            icon: const Icon(Icons.check_rounded),
            label: Text(_isSwahili ? 'Kubali' : 'Accept'),
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      case GarageBookingStatus.confirmed:
        return [
          FilledButton.icon(
            onPressed: _busy ? null : _droppedOff,
            icon: const Icon(Icons.directions_car_rounded),
            label: Text(_isSwahili ? 'Gari limefika' : 'Mark as dropped off'),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      case GarageBookingStatus.droppedOff:
        return [
          FilledButton.icon(
            onPressed: _busy ? null : _diagnose,
            icon: const Icon(Icons.fact_check_rounded),
            label: Text(_isSwahili ? 'Tuma diagnosis' : 'Send diagnosis'),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      case GarageBookingStatus.diagnosed:
        return [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(
              _isSwahili
                  ? 'Inasubiri uthibitisho wa mteja'
                  : 'Awaiting customer approval',
              style: const TextStyle(color: _kSecondary, fontSize: 13),
            ),
          ),
        ];
      case GarageBookingStatus.approved:
        return [
          FilledButton.icon(
            onPressed: _busy ? null : _startWork,
            icon: const Icon(Icons.handyman_rounded),
            label: Text(_isSwahili ? 'Anza kazi' : 'Start work'),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      case GarageBookingStatus.inProgress:
        return [
          FilledButton.icon(
            onPressed: _busy ? null : _readyForPickup,
            icon: const Icon(Icons.local_shipping_rounded),
            label: Text(_isSwahili ? 'Tayari kuchukuliwa' : 'Ready for pickup'),
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      case GarageBookingStatus.readyForPickup:
        return [
          FilledButton.icon(
            onPressed: _busy ? null : _complete,
            icon: const Icon(Icons.celebration_rounded),
            label: Text(_isSwahili ? 'Maliza' : 'Complete'),
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ];
      case GarageBookingStatus.completed:
      case GarageBookingStatus.cancelled:
      case GarageBookingStatus.rejected:
        return const [];
    }
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
