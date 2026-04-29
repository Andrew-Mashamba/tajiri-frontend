import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../service_garage/models/garage_booking.dart';
import '../../service_garage/services/garage_booking_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kSuccess = Color(0xFF1B5E20);
const Color _kWarning = Color(0xFFE65100);
const Color _kError = Color(0xFFB71C1C);
const Color _kInfo = Color(0xFF0D47A1);

/// Partner-facing garage-booking inbox.
///
/// Lists all garage bookings directed at the partner,
/// with vehicle info, skill icon, status pill, and quick actions.
class IncomingGarageBookingsPage extends StatefulWidget {
  final int userId;
  const IncomingGarageBookingsPage({super.key, required this.userId});

  @override
  State<IncomingGarageBookingsPage> createState() =>
      _IncomingGarageBookingsPageState();
}

class _IncomingGarageBookingsPageState
    extends State<IncomingGarageBookingsPage> {
  bool _isLoading = true;
  String? _error;
  List<GarageBooking> _bookings = [];
  GarageBookingStatus? _filter;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await GarageBookingService.list(
      userId: widget.userId,
      role: 'partner',
      status: _filter?.apiValue,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (res.success) {
        _bookings = res.bookings;
      } else {
        _error = res.message ??
            (_isSwahili ? 'Imeshindwa kupakia' : 'Failed to load');
      }
    });
  }

  List<GarageBooking> get _filtered {
    if (_filter == null) return _bookings;
    return _bookings.where((b) => b.status == _filter).toList();
  }

  String _statusLabel(GarageBookingStatus s) {
    return _isSwahili ? s.labelSwahili : s.label;
  }

  Color _statusColor(GarageBookingStatus s) {
    switch (s) {
      case GarageBookingStatus.pending:
        return _kWarning;
      case GarageBookingStatus.confirmed:
        return _kInfo;
      case GarageBookingStatus.droppedOff:
        return const Color(0xFF6A1B9A);
      case GarageBookingStatus.diagnosed:
        return const Color(0xFF00695C);
      case GarageBookingStatus.approved:
        return const Color(0xFF0277BD);
      case GarageBookingStatus.inProgress:
        return const Color(0xFFF57F17);
      case GarageBookingStatus.readyForPickup:
        return _kSuccess;
      case GarageBookingStatus.completed:
        return _kPrimary;
      case GarageBookingStatus.cancelled:
      case GarageBookingStatus.rejected:
        return _kMuted;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return _isSwahili ? 'Sasa' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ${_isSwahili ? '' : 'ago'}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ${_isSwahili ? '' : 'ago'}';
    }
    return '${diff.inDays}d ${_isSwahili ? '' : 'ago'}';
  }

  String _formatTzs(int? v) {
    if (v == null) return '';
    final s = v.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return 'TSh ${buffer.toString()}';
  }

  Future<void> _accept(GarageBooking b) async {
    final res = await GarageBookingService.accept(
      id: b.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (res.success) {
      _showSnack(_isSwahili ? 'Imekubaliwa' : 'Booking accepted');
      await _load();
    } else {
      _showSnack(res.message ?? (_isSwahili ? 'Imeshindwa' : 'Failed'));
    }
  }

  Future<void> _reject(GarageBooking b) async {
    final reason = await _showReasonDialog(
      title: _isSwahili ? 'Kataa Booking' : 'Reject Booking',
      hint: _isSwahili ? 'Sababu (hiari)' : 'Reason (optional)',
    );
    if (reason == null) return;
    final res = await GarageBookingService.reject(
      id: b.id,
      userId: widget.userId,
      reason: reason.isEmpty ? null : reason,
    );
    if (!mounted) return;
    if (res.success) {
      _showSnack(_isSwahili ? 'Imekataliwa' : 'Booking rejected');
      await _load();
    } else {
      _showSnack(res.message ?? (_isSwahili ? 'Imeshindwa' : 'Failed'));
    }
  }

  Future<void> _diagnose(GarageBooking b) async {
    final result = await _showDiagnoseDialog(b);
    if (result == null) return;
    final res = await GarageBookingService.diagnose(
      id: b.id,
      userId: widget.userId,
      diagnosis: result.$1,
      revisedCostTzs: result.$2,
    );
    if (!mounted) return;
    if (res.success) {
      _showSnack(_isSwahili
          ? 'Tathmini imewekwa'
          : 'Diagnosis submitted');
      await _load();
    } else {
      _showSnack(res.message ?? (_isSwahili ? 'Imeshindwa' : 'Failed'));
    }
  }

  Future<void> _startWork(GarageBooking b) async {
    final res = await GarageBookingService.startWork(
      id: b.id,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (res.success) {
      _showSnack(
          _isSwahili ? 'Kazi imeanza' : 'Work started');
      await _load();
    } else {
      _showSnack(res.message ?? (_isSwahili ? 'Imeshindwa' : 'Failed'));
    }
  }

  Future<void> _readyForPickup(GarageBooking b) async {
    final cost = await _showCostDialog(b);
    if (cost == null) return;
    final res = await GarageBookingService.readyForPickup(
      id: b.id,
      userId: widget.userId,
      finalCostTzs: cost,
    );
    if (!mounted) return;
    if (res.success) {
      _showSnack(_isSwahili
          ? 'Tayari kuchukuliwa'
          : 'Ready for pickup');
      await _load();
    } else {
      _showSnack(res.message ?? (_isSwahili ? 'Imeshindwa' : 'Failed'));
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _showReasonDialog({
    required String title,
    required String hint,
  }) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hint),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(_isSwahili ? 'Thibitisha' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  Future<(String, int)?> _showDiagnoseDialog(GarageBooking b) async {
    final diagCtrl = TextEditingController(text: b.diagnosis ?? '');
    final costCtrl = TextEditingController(
      text: b.revisedCostTzs != null ? b.revisedCostTzs.toString() : '',
    );
    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Tathmini' : 'Diagnose'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: diagCtrl,
                decoration: InputDecoration(
                  labelText: _isSwahili ? 'Tatizo' : 'Diagnosis',
                  hintText: _isSwahili
                      ? 'Eleza tatizo na suluhisho'
                      : 'Describe the fault and fix',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                decoration: InputDecoration(
                  labelText: _isSwahili ? 'Gharama' : 'Revised cost (TSh)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final cost = int.tryParse(costCtrl.text.trim());
              if (diagCtrl.text.trim().isEmpty || cost == null || cost < 0) {
                return;
              }
              Navigator.pop(ctx, (diagCtrl.text.trim(), cost));
            },
            child: Text(_isSwahili ? 'Wasiliana' : 'Submit'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<int?> _showCostDialog(GarageBooking b) async {
    final ctrl = TextEditingController(
      text: b.finalCostTzs != null ? b.finalCostTzs.toString() : '',
    );
    return showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Gharama ya Mwisho' : 'Final cost'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: _isSwahili ? 'Gharama (TSh)' : 'Cost (TSh)',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v == null || v < 0) return;
              Navigator.pop(ctx, v);
            },
            child: Text(_isSwahili ? 'Thibitisha' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {Color? color, bool selected = false}) {
    final bg = color ?? _kPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? bg : bg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bg.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : bg,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final statuses = <GarageBookingStatus?>[
      null,
      GarageBookingStatus.pending,
      GarageBookingStatus.confirmed,
      GarageBookingStatus.droppedOff,
      GarageBookingStatus.diagnosed,
      GarageBookingStatus.approved,
      GarageBookingStatus.inProgress,
      GarageBookingStatus.readyForPickup,
      GarageBookingStatus.completed,
    ];
    final labels = <String>[
      _isSwahili ? 'Zote' : 'All',
      _statusLabel(GarageBookingStatus.pending),
      _statusLabel(GarageBookingStatus.confirmed),
      _statusLabel(GarageBookingStatus.droppedOff),
      _statusLabel(GarageBookingStatus.diagnosed),
      _statusLabel(GarageBookingStatus.approved),
      _statusLabel(GarageBookingStatus.inProgress),
      _statusLabel(GarageBookingStatus.readyForPickup),
      _statusLabel(GarageBookingStatus.completed),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(statuses.length, (i) {
          final s = statuses[i];
          final selected = _filter == s;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[i]),
              selected: selected,
              onSelected: (_) => setState(() {
                _filter = s;
                _load();
              }),
              selectedColor: _kPrimary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : _kPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: _kBorder),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBookingCard(GarageBooking b) {
    final photos = b.photos.where((u) => u.isNotEmpty).toList();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name + status + time
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: b.customerPhotoUrl != null
                      ? NetworkImage(
                          '${ApiConfig.storageUrl}/${b.customerPhotoUrl}')
                      : null,
                  child: b.customerPhotoUrl == null
                      ? const Icon(Icons.person, size: 20, color: _kMuted)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.customerName ??
                            (_isSwahili ? 'Mteja' : 'Customer'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _chip(_statusLabel(b.status),
                              color: _statusColor(b.status), selected: true),
                          const SizedBox(width: 6),
                          Text(
                            _timeAgo(b.confirmedAt ?? b.droppedOffAt),
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Vehicle row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car,
                          size: 16, color: _kPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '${b.vehicleMake} ${b.vehicleModel}${b.vehicleYear != null ? ' (${b.vehicleYear})' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _chip(
                  b.vehiclePlate,
                  color: const Color(0xFF1565C0),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Skill chip
            _chip(
              _isSwahili ? b.skill.labelSwahili : b.skill.label,
              color: const Color(0xFF6A1B9A),
            ),
            const SizedBox(height: 10),
            // Fault summary
            Text(
              b.faultSummary,
              style: const TextStyle(fontSize: 13, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Photos
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${ApiConfig.storageUrl}/${photos[i]}',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        color: _kBorder,
                        child: const Icon(Icons.broken_image,
                            color: _kMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            // Cost caps / diagnosis preview
            if (b.costCapTzs != null || b.revisedCostTzs != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  if (b.costCapTzs != null)
                    _chip('${_isSwahili ? "Kikomo" : "Cap"}: ${_formatTzs(b.costCapTzs)}',
                        color: _kInfo),
                  if (b.revisedCostTzs != null)
                    _chip('${_isSwahili ? "Gharama" : "Cost"}: ${_formatTzs(b.revisedCostTzs)}',
                        color: _kSuccess),
                ],
              ),
            ],
            if (b.diagnosis != null && b.diagnosis!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  b.diagnosis!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSuccess,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Actions
            _buildActions(b),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(GarageBooking b) {
    switch (b.status) {
      case GarageBookingStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reject(b),
                icon: const Icon(Icons.close, size: 18),
                label: Text(_isSwahili ? 'Kataa' : 'Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kError,
                  side: const BorderSide(color: _kError),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _accept(b),
                icon: const Icon(Icons.check, size: 18),
                label: Text(_isSwahili ? 'Kubali' : 'Accept'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kSuccess,
                ),
              ),
            ),
          ],
        );
      case GarageBookingStatus.droppedOff:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _diagnose(b),
            icon: const Icon(Icons.search, size: 18),
            label: Text(_isSwahili ? 'Tathmini' : 'Diagnose'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
          ),
        );
      case GarageBookingStatus.approved:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _startWork(b),
            icon: const Icon(Icons.build, size: 18),
            label: Text(_isSwahili ? 'Anza Kazi' : 'Start work'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
          ),
        );
      case GarageBookingStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _readyForPickup(b),
            icon: const Icon(Icons.done_all, size: 18),
            label: Text(_isSwahili ? 'Tayari Kuchukuliwa' : 'Ready for pickup'),
            style: FilledButton.styleFrom(backgroundColor: _kSuccess),
          ),
        );
      case GarageBookingStatus.confirmed:
      case GarageBookingStatus.diagnosed:
      case GarageBookingStatus.readyForPickup:
      case GarageBookingStatus.completed:
      case GarageBookingStatus.cancelled:
      case GarageBookingStatus.rejected:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSwahili
        ? 'Booking za Gereji'
        : 'Garage Bookings';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kCard,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterBar(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: _kError)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: Text(_isSwahili ? 'Jaribu tena' : 'Retry'),
                      ),
                    ],
                  ),
                )
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _isSwahili
                            ? 'Hakuna booking'
                            : 'No bookings',
                        style: const TextStyle(color: _kMuted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 32),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildBookingCard(_filtered[i]),
                      ),
                    ),
    );
  }
}
