import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../customer_orders/models/customer_order.dart';
import '../../customer_orders/widgets/rate_partner_cta.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF2E7D32);
const Color _kDanger = Color(0xFFB71C1C);
const Color _kMuted = Color(0xFF9E9E9E);

class AppointmentStatusPage extends StatefulWidget {
  final int userId;
  final int appointmentId;

  const AppointmentStatusPage({
    super.key,
    required this.userId,
    required this.appointmentId,
  });

  @override
  State<AppointmentStatusPage> createState() => _AppointmentStatusPageState();
}

class _AppointmentStatusPageState extends State<AppointmentStatusPage> {
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

  Future<void> _cancel() async {
    if (_busy || _appt == null) return;
    final reason = await _askReason(
      title: _isSwahili ? 'Sababu ya kughairi' : 'Cancellation reason',
    );
    if (reason == null) return;
    setState(() => _busy = true);
    final res = await AppointmentService.cancel(
      id: _appt!.id,
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

  Future<void> _reschedule() async {
    if (_busy || _appt == null) return;
    final initial = _appt!.startsAt.add(const Duration(days: 1));
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now.add(const Duration(hours: 5)) : initial,
      firstDate: now.add(const Duration(hours: 5)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _appt!.startsAt.hour, minute: 0),
    );
    if (time == null || !mounted) return;
    final newStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _busy = true);
    final res = await AppointmentService.reschedule(
      id: _appt!.id,
      userId: widget.userId,
      startsAt: newStart,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(res.success
        ? (_isSwahili ? 'Imebadilishwa' : 'Rescheduled')
        : (res.message ?? 'Error'));
    if (res.success) await _load();
  }

  Future<String?> _askReason({required String title}) async {
    final ctrl = TextEditingController();
    final isSw = _isSwahili;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 240,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: isSw ? 'Eleza kwa kifupi' : 'Brief reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSw ? 'Funga' : 'Close'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kDanger),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(isSw ? 'Thibitisha' : 'Confirm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        title: Text(isSw ? 'Hali ya Miadi' : 'Appointment Status',
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
                            _serviceCard(_appt!, isSw),
                            const SizedBox(height: 12),
                            _scheduleCard(_appt!, isSw),
                            const SizedBox(height: 12),
                            _partnerCard(_appt!, isSw),
                            const SizedBox(height: 12),
                            _timelineCard(_appt!, isSw),
                            if (_appt!.status == AppointmentStatus.completed) ...[
                              const SizedBox(height: 12),
                              RatePartnerCta(
                                reviewerUserId: widget.userId,
                                source: CustomerOrderSource.appointment,
                                sourceId: _appt!.id,
                                partnerName: _appt!.partnerName,
                                itemTitle: _appt!.serviceTitle,
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (_appt!.isReschedulableByCustomer)
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _reschedule,
                                icon: const Icon(Icons.schedule_rounded),
                                label: Text(isSw ? 'Badili Muda' : 'Reschedule'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kPrimary,
                                  side: const BorderSide(color: _kPrimary),
                                ),
                              ),
                            if (_appt!.isCancellableByCustomer) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _cancel,
                                icon: const Icon(Icons.cancel_outlined),
                                label: Text(isSw ? 'Ghairi' : 'Cancel'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kDanger,
                                  side: const BorderSide(color: _kDanger),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
      ),
    );
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
              const SizedBox(height: 2),
              Text(_statusBlurb(a, isSw),
                  style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  String _statusBlurb(Appointment a, bool isSw) {
    switch (a.status) {
      case AppointmentStatus.pending:
        return isSw ? 'Subiri fundi athibitishe.' : 'Awaiting partner confirmation.';
      case AppointmentStatus.confirmed:
        return isSw
            ? 'Fundi amethibitisha. Fika kwa muda uliopanga.'
            : 'Partner confirmed. Be on time.';
      case AppointmentStatus.checkedIn:
        return isSw ? 'Umewasili. Inafanyiwa maandalizi.' : 'You\'ve arrived. Prepping.';
      case AppointmentStatus.inProgress:
        return isSw ? 'Inaendelea sasa.' : 'In progress now.';
      case AppointmentStatus.completed:
        return isSw ? 'Imekamilika. Asante!' : 'Completed. Thank you!';
      case AppointmentStatus.noShow:
        return a.noShowFeeTzs != null
            ? (isSw
                ? 'Hukufika. Tozo: ${_fmtTzs(a.noShowFeeTzs!)} TZS'
                : 'Marked no-show. Fee: ${_fmtTzs(a.noShowFeeTzs!)} TZS')
            : (isSw ? 'Hukufika.' : 'Marked no-show.');
      case AppointmentStatus.cancelled:
        return a.cancellationReason ?? (isSw ? 'Imeghairiwa.' : 'Cancelled.');
      case AppointmentStatus.rejected:
        return a.rejectionReason ?? (isSw ? 'Imekataliwa na fundi.' : 'Declined by partner.');
    }
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

  Widget _serviceCard(Appointment a, bool isSw) => _card(
        title: isSw ? 'Huduma' : 'Service',
        children: [
          _kvRow(isSw ? 'Aina:' : 'Type', isSw ? a.vertical.labelSwahili : a.vertical.label),
          _kvRow(isSw ? 'Huduma:' : 'Service', a.serviceTitle),
          _kvRow(isSw ? 'Bei:' : 'Price', '${_fmtTzs(a.servicePriceTzs)} TZS'),
          _kvRow(isSw ? 'Muda:' : 'Duration', '${a.durationMin} min'),
          _kvRow(isSw ? 'Mahali:' : 'Location', isSw ? a.locationKind.labelSwahili : a.locationKind.label),
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
        ],
      );

  Widget _partnerCard(Appointment a, bool isSw) {
    final photo = a.partnerPhotoUrl != null ? ApiConfig.sanitizeUrl(a.partnerPhotoUrl!) : null;
    return _card(
      title: isSw ? 'Fundi' : 'Partner',
      children: [
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _kBorder,
            backgroundImage: (photo ?? a.partnerPhotoUrl) != null
                ? NetworkImage((photo ?? a.partnerPhotoUrl)!)
                : null,
            child: (photo ?? a.partnerPhotoUrl) == null
                ? const Icon(Icons.person_rounded, color: _kMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.partnerName ?? '—',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(isSw ? a.vertical.labelSwahili : a.vertical.label,
                    style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  Widget _timelineCard(Appointment a, bool isSw) {
    final events = _buildTimeline(a, isSw);
    return _card(
      title: isSw ? 'Ratiba' : 'Timeline',
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineRow(
            event: events[i],
            isLast: i == events.length - 1,
          ),
      ],
    );
  }

  List<_TimelineEvent> _buildTimeline(Appointment a, bool isSw) {
    final events = <_TimelineEvent>[];
    events.add(_TimelineEvent(
      label: isSw ? 'Ombi limetumwa' : 'Booked',
      ts: a.createdAt,
      done: true,
    ));
    if (a.status == AppointmentStatus.rejected) {
      events.add(_TimelineEvent(
        label: isSw ? 'Imekataliwa' : 'Rejected',
        ts: a.rejectedAt,
        done: true,
        danger: true,
      ));
      return events;
    }
    events.add(_TimelineEvent(
      label: isSw ? 'Imethibitishwa' : 'Confirmed',
      ts: a.confirmedAt,
      done: a.confirmedAt != null,
    ));
    events.add(_TimelineEvent(
      label: isSw ? 'Amefika' : 'Checked in',
      ts: a.checkedInAt,
      done: a.checkedInAt != null,
    ));
    events.add(_TimelineEvent(
      label: isSw ? 'Inaendelea' : 'In progress',
      ts: a.startedAt,
      done: a.startedAt != null,
    ));
    events.add(_TimelineEvent(
      label: isSw ? 'Imekamilika' : 'Completed',
      ts: a.completedAt,
      done: a.completedAt != null,
    ));
    if (a.status == AppointmentStatus.noShow) {
      events.add(_TimelineEvent(
        label: isSw ? 'Hakufika' : 'No-show',
        ts: a.noShowAt,
        done: true,
        danger: true,
      ));
    }
    if (a.status == AppointmentStatus.cancelled) {
      events.add(_TimelineEvent(
        label: isSw ? 'Imeghairiwa' : 'Cancelled',
        ts: a.cancelledAt,
        done: true,
        danger: true,
      ));
    }
    return events;
  }

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
            width: 96,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: _kSecondary, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: _kPrimary)),
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

class _TimelineEvent {
  final String label;
  final DateTime? ts;
  final bool done;
  final bool danger;
  _TimelineEvent({
    required this.label,
    required this.ts,
    required this.done,
    this.danger = false,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;
  const _TimelineRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = event.danger
        ? _kDanger
        : event.done
            ? _kAccent
            : _kMuted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: event.done ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _kBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: event.done ? FontWeight.w600 : FontWeight.w400,
                          color: event.done ? _kPrimary : _kMuted)),
                  if (event.ts != null)
                    Text(DateFormat('dd MMM • HH:mm').format(event.ts!.toLocal()),
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
