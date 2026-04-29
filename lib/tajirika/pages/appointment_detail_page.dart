import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../appointments/models/appointment.dart';
import '../../appointments/services/appointment_service.dart';
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF2E7D32);
const Color _kDanger = Color(0xFFB71C1C);
const Color _kMuted = Color(0xFF9E9E9E);

class AppointmentDetailPage extends StatefulWidget {
  final int userId;
  final int appointmentId;

  const AppointmentDetailPage({
    super.key,
    required this.userId,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Appointment? _appt;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await AppointmentService.get(
      id: widget.appointmentId,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.appointment != null) {
        _appt = res.appointment;
        _error = null;
      } else {
        _error = res.message ?? (_isSwahili ? 'Imeshindikana kupakia' : 'Failed to load');
      }
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _accept() async {
    if (_busy || _appt == null) return;
    setState(() => _busy = true);
    final res = await AppointmentService.accept(id: _appt!.id, userId: widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imekubaliwa' : 'Accepted') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _reject() async {
    if (_busy || _appt == null) return;
    final reason = await _askReason(
      title: _isSwahili ? 'Sababu ya kukataa' : 'Reason for rejecting',
      hint: _isSwahili ? 'Hiari' : 'Optional',
      required: false,
    );
    if (!mounted) return;
    setState(() => _busy = true);
    final res = await AppointmentService.reject(
      id: _appt!.id,
      userId: widget.userId,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imekataliwa' : 'Rejected') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _checkIn() async {
    if (_busy || _appt == null) return;
    setState(() => _busy = true);
    final res = await AppointmentService.checkIn(id: _appt!.id, userId: widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Amefika' : 'Checked in') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _start() async {
    if (_busy || _appt == null) return;
    setState(() => _busy = true);
    final res = await AppointmentService.start(id: _appt!.id, userId: widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imeanza' : 'Started') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _complete() async {
    if (_busy || _appt == null) return;
    setState(() => _busy = true);
    final res = await AppointmentService.complete(id: _appt!.id, userId: widget.userId);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success ? (_isSwahili ? 'Imekamilika' : 'Completed') : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<void> _noShow() async {
    if (_busy || _appt == null) return;
    final fee = await _askFee();
    if (fee == null) return;
    setState(() => _busy = true);
    final res = await AppointmentService.noShow(
      id: _appt!.id,
      userId: widget.userId,
      feeTzs: fee == 0 ? null : fee,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success
        ? (_isSwahili ? 'Imewekwa hakufika' : 'Marked no-show')
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
          maxLines: 3,
          maxLength: 240,
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

  Future<int?> _askFee() async {
    final ctrl = TextEditingController(text: '0');
    final result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Tozo ya kutokufika (TZS)' : 'No-show fee (TZS)'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'TZS',
            helperText: _isSwahili ? '0 = hakuna tozo' : '0 = no fee',
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
              final v = int.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.of(ctx).pop(v);
            },
            child: Text(_isSwahili ? 'Tuma' : 'Submit'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _callCustomer() async {
    final phone = _appt?.customerPhone?.trim();
    if (phone == null || phone.isEmpty) {
      _toast(_isSwahili ? 'Simu haipatikani' : 'Phone unavailable');
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast(_isSwahili ? 'Imeshindikana kupiga' : 'Cannot dial');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        title: Text(isSw ? 'Maelezo ya Miadi' : 'Appointment',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _error != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ))
                : _appt == null
                    ? const SizedBox.shrink()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _statusBanner(_appt!, isSw),
                            const SizedBox(height: 12),
                            _customerCard(_appt!, isSw),
                            const SizedBox(height: 12),
                            _serviceCard(_appt!, isSw),
                            const SizedBox(height: 12),
                            _scheduleCard(_appt!, isSw),
                          ],
                        ),
                      ),
      ),
      bottomNavigationBar: _appt == null || _loading ? null : _actionBar(_appt!, isSw),
    );
  }

  Widget? _actionBar(Appointment a, bool isSw) {
    final actions = _actionsFor(a, isSw);
    if (actions.isEmpty) return null;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: actions
              .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
              .toList()
            ..removeLast(),
        ),
      ),
    );
  }

  List<Widget> _actionsFor(Appointment a, bool isSw) {
    switch (a.status) {
      case AppointmentStatus.pending:
        return [
          OutlinedButton.icon(
            onPressed: _busy ? null : _reject,
            icon: const Icon(Icons.close_rounded),
            label: Text(isSw ? 'Kataa' : 'Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kDanger,
              side: const BorderSide(color: _kDanger),
            ),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _accept,
            icon: const Icon(Icons.check_rounded),
            label: Text(isSw ? 'Kubali' : 'Accept'),
            style: FilledButton.styleFrom(backgroundColor: _kAccent),
          ),
        ];
      case AppointmentStatus.confirmed:
        return [
          OutlinedButton.icon(
            onPressed: _busy ? null : _noShow,
            icon: const Icon(Icons.no_accounts_rounded),
            label: Text(isSw ? 'Hakufika' : 'No-show'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kDanger,
              side: const BorderSide(color: _kDanger),
            ),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _checkIn,
            icon: const Icon(Icons.login_rounded),
            label: Text(isSw ? 'Amefika' : 'Check in'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
          ),
        ];
      case AppointmentStatus.checkedIn:
        return [
          OutlinedButton.icon(
            onPressed: _busy ? null : _noShow,
            icon: const Icon(Icons.no_accounts_rounded),
            label: Text(isSw ? 'Hakufika' : 'No-show'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kDanger,
              side: const BorderSide(color: _kDanger),
            ),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(isSw ? 'Anza' : 'Start'),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
          ),
        ];
      case AppointmentStatus.inProgress:
        return [
          FilledButton.icon(
            onPressed: _busy ? null : _complete,
            icon: const Icon(Icons.task_alt_rounded),
            label: Text(isSw ? 'Maliza' : 'Complete'),
            style: FilledButton.styleFrom(backgroundColor: _kAccent),
          ),
        ];
      default:
        return [];
    }
  }

  Widget _statusBanner(Appointment a, bool isSw) {
    final (bg, fg, icon) = _statusColors(a.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: fg, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isSw ? a.status.labelSwahili : a.status.label,
                  style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700)),
              if (a.rejectionReason != null && a.status == AppointmentStatus.rejected)
                Text(a.rejectionReason!,
                    style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12)),
              if (a.cancellationReason != null && a.status == AppointmentStatus.cancelled)
                Text(a.cancellationReason!,
                    style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  (Color, Color, IconData) _statusColors(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.pending:
        return (const Color(0xFFFFF3E0), const Color(0xFFE65100), Icons.schedule_rounded);
      case AppointmentStatus.confirmed:
        return (const Color(0xFFE8F5E9), _kAccent, Icons.check_circle_rounded);
      case AppointmentStatus.checkedIn:
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.login_rounded);
      case AppointmentStatus.inProgress:
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0), Icons.autorenew_rounded);
      case AppointmentStatus.completed:
        return (const Color(0xFFE8F5E9), _kAccent, Icons.task_alt_rounded);
      case AppointmentStatus.noShow:
        return (const Color(0xFFFCE4EC), _kDanger, Icons.no_accounts_rounded);
      case AppointmentStatus.cancelled:
        return (const Color(0xFFFFEBEE), _kDanger, Icons.cancel_rounded);
      case AppointmentStatus.rejected:
        return (const Color(0xFFFFEBEE), _kDanger, Icons.block_rounded);
    }
  }

  Widget _customerCard(Appointment a, bool isSw) {
    final photo = a.customerPhotoUrl != null ? ApiConfig.sanitizeUrl(a.customerPhotoUrl!) : null;
    return _card(
      title: isSw ? 'Mteja' : 'Customer',
      children: [
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _kBorder,
            backgroundImage: (photo ?? a.customerPhotoUrl) != null
                ? NetworkImage((photo ?? a.customerPhotoUrl)!)
                : null,
            child: (photo ?? a.customerPhotoUrl) == null
                ? const Icon(Icons.person_rounded, color: _kMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.customerName ?? '—',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (a.customerPhone != null)
                  Text(a.customerPhone!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
          if (a.customerPhone != null)
            IconButton(
              icon: const Icon(Icons.call_rounded, color: _kAccent),
              onPressed: _callCustomer,
            ),
        ]),
      ],
    );
  }

  Widget _serviceCard(Appointment a, bool isSw) => _card(
        title: isSw ? 'Huduma' : 'Service',
        children: [
          _kvRow(isSw ? 'Aina:' : 'Vertical', isSw ? a.vertical.labelSwahili : a.vertical.label),
          _kvRow(isSw ? 'Huduma:' : 'Service', a.serviceTitle),
          _kvRow(isSw ? 'Bei:' : 'Price', '${_fmtTzs(a.servicePriceTzs)} TZS'),
          _kvRow(isSw ? 'Muda:' : 'Duration', '${a.durationMin} min'),
          _kvRow(isSw ? 'Mahali:' : 'Location',
              isSw ? a.locationKind.labelSwahili : a.locationKind.label),
          if (a.locationKind == LocationKind.home && a.customerAddress != null)
            _kvRow(isSw ? 'Anwani:' : 'Address', a.customerAddress!),
          if (a.notes != null && a.notes!.isNotEmpty)
            _kvRow(isSw ? 'Maelezo:' : 'Notes', a.notes!),
        ],
      );

  Widget _scheduleCard(Appointment a, bool isSw) => _card(
        title: isSw ? 'Muda' : 'Schedule',
        children: [
          _kvRow(isSw ? 'Anza:' : 'Starts',
              DateFormat('EEE, dd MMM yyyy • HH:mm').format(a.startsAt.toLocal())),
          _kvRow(isSw ? 'Mwisho:' : 'Ends',
              DateFormat('HH:mm').format(a.endsAt.toLocal())),
          if (a.rescheduleCount > 0)
            _kvRow(isSw ? 'Imebadilishwa:' : 'Rescheduled', '${a.rescheduleCount}x'),
          if (a.isRecurring && a.recurringPattern != null) ...[
            _kvRow(
                isSw ? 'Rudia:' : 'Repeats',
                (a.recurringPattern!.weekdays.toList()
                      ..sort((x, y) => (x == 0 ? 7 : x).compareTo(y == 0 ? 7 : y)))
                    .map(_weekdayShort)
                    .join(', ')),
            if (a.recurringPattern!.until != null)
              _kvRow(isSw ? 'Hadi:' : 'Until',
                  DateFormat('dd MMM yyyy').format(a.recurringPattern!.until!.toLocal())),
          ],
          if (a.confirmedAt != null)
            _kvRow(isSw ? 'Imethibitishwa:' : 'Confirmed',
                DateFormat('dd MMM • HH:mm').format(a.confirmedAt!.toLocal())),
          if (a.checkedInAt != null)
            _kvRow(isSw ? 'Amefika:' : 'Checked in',
                DateFormat('dd MMM • HH:mm').format(a.checkedInAt!.toLocal())),
          if (a.startedAt != null)
            _kvRow(isSw ? 'Ilianza:' : 'Started',
                DateFormat('dd MMM • HH:mm').format(a.startedAt!.toLocal())),
          if (a.completedAt != null)
            _kvRow(isSw ? 'Ilikamilika:' : 'Completed',
                DateFormat('dd MMM • HH:mm').format(a.completedAt!.toLocal())),
          if (a.noShowFeeTzs != null)
            _kvRow(isSw ? 'Tozo:' : 'No-show fee', '${_fmtTzs(a.noShowFeeTzs!)} TZS'),
        ],
      );

  Widget _card({required String title, required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _kvRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: _kSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: _kPrimary)),
          ),
        ]),
      );

  String _fmtTzs(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _weekdayShort(int wd) {
    // Carbon convention: 0=Sun..6=Sat.
    const en = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (wd < 0 || wd > 6) return '?';
    return en[wd];
  }
}
