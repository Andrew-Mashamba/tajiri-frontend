import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/travel_models.dart';
import '../widgets/mode_icon.dart';
import 'ticket_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kSuccess = Color(0xFF1B5E20);
const Color _kWarning = Color(0xFFE65100);

/// Customer-facing trip tracker page.
///
/// Rich interactive view of an active or upcoming transport booking
/// with live countdown, status timeline, and quick actions.
class MyTripPage extends StatefulWidget {
  final TransportBooking booking;
  const MyTripPage({super.key, required this.booking});

  @override
  State<MyTripPage> createState() => _MyTripPageState();
}

class _MyTripPageState extends State<MyTripPage> {
  Timer? _timer;
  late DateTime _now;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmtDate(DateTime dt) {
    final m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtCurrency(double v, String currency) {
    final s = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return '$currency ${buffer.toString()}';
  }

  String _countdownText(DateTime target) {
    final diff = target.difference(_now);
    if (diff.isNegative) {
      return _isSwahili ? 'Inaendelea' : 'In progress';
    }
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    if (d > 0) {
      return _isSwahili
          ? 'Siku $d, masaa $h'
          : '$d d, $h h to go';
    }
    if (h > 0) {
      return _isSwahili
          ? 'Masaa $h, dakika $m'
          : '$h h, $m min to go';
    }
    return _isSwahili
        ? 'Dakika $m'
        : '$m min to go';
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return _kWarning;
      case BookingStatus.confirmed:
        return _kSuccess;
      case BookingStatus.cancelled:
        return Colors.red.shade700;
      case BookingStatus.completed:
        return _kMuted;
    }
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return _isSwahili ? 'Inasubiri' : 'Pending';
      case BookingStatus.confirmed:
        return _isSwahili ? 'Imethibitishwa' : 'Confirmed';
      case BookingStatus.cancelled:
        return _isSwahili ? 'Imeghairiwa' : 'Cancelled';
      case BookingStatus.completed:
        return _isSwahili ? 'Imekamilika' : 'Completed';
    }
  }

  List<_TimelineItem> _buildTimeline() {
    final b = widget.booking;
    final now = _now;
    final dep = b.departure;
    final arr = b.arrival;
    final items = <_TimelineItem>[
      _TimelineItem(
        icon: Icons.check_circle,
        title: _isSwahili ? 'Booking imethibitishwa' : 'Booking confirmed',
        subtitle: _fmtDate(dep),
        isDone: true,
      ),
      _TimelineItem(
        icon: Icons.departure_board,
        title: _isSwahili ? 'Kufunguliwa kwa check-in' : 'Check-in opens',
        subtitle: _isSwahili
            ? 'Saa 1 kabla ya safari'
            : '1 hour before departure',
        isDone: now.isAfter(dep.subtract(const Duration(hours: 1))),
        isActive: now.isAfter(dep.subtract(const Duration(hours: 2))) &&
            now.isBefore(dep.subtract(const Duration(hours: 1))),
      ),
      _TimelineItem(
        icon: Icons.flight_takeoff,
        title: _isSwahili ? 'Kutoka ${b.originCity}' : 'Depart ${b.originCity}',
        subtitle: _fmtTime(dep),
        isDone: now.isAfter(dep),
        isActive: now.isAfter(dep.subtract(const Duration(hours: 1))) &&
            now.isBefore(dep),
      ),
      _TimelineItem(
        icon: Icons.flight_land,
        title: _isSwahili
            ? 'Kufika ${b.destinationCity}'
            : 'Arrive ${b.destinationCity}',
        subtitle: _fmtTime(arr),
        isDone: now.isAfter(arr),
        isActive: now.isAfter(dep) && now.isBefore(arr),
      ),
    ];
    return items;
  }

  void _openTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketPage(booking: widget.booking)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isUpcoming = b.departure.isAfter(_now);
    final isActive = _now.isAfter(b.departure) && _now.isBefore(b.arrival);
    final timeline = _buildTimeline();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          _isSwahili ? 'Safari Yangu' : 'My Trip',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Share trip details
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor(b.status).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _statusColor(b.status).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    b.status == BookingStatus.confirmed
                        ? Icons.check_circle
                        : Icons.info,
                    color: _statusColor(b.status),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusLabel(b.status),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _statusColor(b.status),
                            fontSize: 14,
                          ),
                        ),
                        if (isUpcoming)
                          Text(
                            _countdownText(b.departure),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kSecondary,
                            ),
                          ),
                        if (isActive)
                          Text(
                            _isSwahili
                                ? 'Safari inaendelea'
                                : 'Trip in progress',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Route card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ModeIcon(mode: b.mode, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.operator,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              b.mode.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          b.bookingReference,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fmtTime(b.departure),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _kPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.originCity,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kSecondary,
                              ),
                            ),
                            Text(
                              _fmtDate(b.departure),
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${b.durationMinutes ~/ 60}h ${b.durationMinutes % 60}m',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _kMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 1,
                                color: _kBorder,
                              ),
                              const Icon(Icons.arrow_forward,
                                  size: 14, color: _kMuted),
                              Container(
                                width: 40,
                                height: 1,
                                color: _kBorder,
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: _kMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _fmtTime(b.arrival),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _kPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b.destinationCity,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kSecondary,
                              ),
                            ),
                            Text(
                              _fmtDate(b.arrival),
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Timeline
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSwahili ? 'Hatua' : 'Timeline',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(timeline.length, (i) {
                    final item = timeline[i];
                    return _TimelineTile(
                      item: item,
                      isLast: i == timeline.length - 1,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Passengers
            if (b.passengers.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSwahili ? 'Abiria' : 'Passengers',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...b.passengers.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    _kPrimary.withValues(alpha: 0.06),
                                child: const Icon(Icons.person,
                                    size: 16, color: _kPrimary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (p.idNumber != null)
                                      Text(
                                        '${p.idType?.toUpperCase() ?? 'ID'}: ${p.idNumber}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _kMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (p.isLead)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _kSuccess.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _isSwahili ? 'Mkuu' : 'Lead',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _kSuccess,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            if (b.passengers.isNotEmpty) const SizedBox(height: 16),
            // Trip details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSwahili ? 'Maelezo' : 'Details',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    _isSwahili ? 'Aina' : 'Class',
                    b.transportClass ??
                        (_isSwahili ? 'Kawaida' : 'Standard'),
                  ),
                  _detailRow(
                    _isSwahili ? 'Abiria' : 'Passengers',
                    '${b.passengerCount}',
                  ),
                  _detailRow(
                    _isSwahili ? 'Bei' : 'Price',
                    _fmtCurrency(b.totalAmount, b.currency),
                  ),
                  if (b.paymentMethod != null)
                    _detailRow(
                      _isSwahili ? 'Malipo' : 'Payment',
                      b.paymentMethod!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openTicket,
                icon: const Icon(Icons.confirmation_num_outlined),
                label: Text(_isSwahili ? 'Tazama Tiketi' : 'View Ticket'),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (b.canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Cancel flow
                  },
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.red),
                  label: Text(
                    _isSwahili ? 'Ghairi Safari' : 'Cancel Trip',
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
        ],
      ),
    );
  }
}

// ─── Timeline helpers ─────────────────────────────────────────

class _TimelineItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDone = false,
    this.isActive = false,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineItem item;
  final bool isLast;

  const _TimelineTile({required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (item.isDone) {
      color = _kSuccess;
    } else if (item.isActive) {
      color = _kPrimary;
    } else {
      color = _kMuted;
    }

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
                  color: item.isDone || item.isActive
                      ? color.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: item.isDone || item.isActive ? 2 : 1,
                  ),
                ),
                child: Icon(
                  item.isDone ? Icons.check : item.icon,
                  size: 14,
                  color: color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: item.isDone ? color : _kBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: item.isActive ? _kPrimary : _kSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: item.isActive ? _kSecondary : _kMuted,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
