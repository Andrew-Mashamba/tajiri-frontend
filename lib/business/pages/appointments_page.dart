// lib/business/pages/appointments_page.dart
// Appointment Booking (Miadi ya Wateja / Customer Appointments).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AppointmentsPage extends StatefulWidget {
  final int businessId;
  const AppointmentsPage({super.key, required this.businessId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _token;
  bool _loading = true;
  String? _error;
  List<BusinessAppointment> _appointments = [];
  DateTime _selectedDate = DateTime.now();

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await BusinessService.getAppointments(
          _token!, widget.businessId,
          date: _tabCtrl.index == 0 ? dateStr : null);
      if (mounted) {
        setState(() {
          _loading = false;
          if (res.success) {
            _appointments = res.data;
          } else {
            _error = res.message ??
                (_isSwahili ? 'Imeshindikana kupata miadi' : 'Failed to load appointments');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _isSwahili ? 'Tatizo la mtandao' : 'Network error';
        });
      }
    }
  }

  Future<void> _updateStatus(BusinessAppointment apt, String status) async {
    if (_token == null || apt.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await BusinessService.updateAppointmentStatus(
        _token!, apt.id!, status);
    if (mounted) {
      messenger.showSnackBar(SnackBar(
          content: Text(res.success
              ? (_isSwahili ? 'Imesasishwa' : 'Updated')
              : (res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'))),
          backgroundColor: res.success ? null : Colors.red));
      if (res.success) _load();
    }
  }

  Future<void> _cancelAppointment(BusinessAppointment apt) async {
    if (_token == null || apt.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Futa Miadi?' : 'Cancel Appointment?'),
        content: Text(_isSwahili
            ? 'Miadi hii itafutwa.'
            : 'This appointment will be cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isSwahili ? 'Hapana' : 'No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_isSwahili ? 'Ndio, Futa' : 'Yes, Cancel',
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final res = await BusinessService.cancelAppointment(_token!, apt.id!);
    if (mounted) {
      messenger.showSnackBar(SnackBar(
          content: Text(res.success
              ? (_isSwahili ? 'Miadi imefutwa' : 'Appointment cancelled')
              : (res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed'))),
          backgroundColor: res.success ? null : Colors.red));
      if (res.success) _load();
    }
  }

  void _shareAppointment(BusinessAppointment apt) {
    final text = _isSwahili
        ? 'Miadi: ${apt.serviceName ?? "Huduma"}\n'
            'Tarehe: ${apt.date != null ? DateFormat('dd/MM/yyyy').format(apt.date!) : "-"}\n'
            'Muda: ${apt.startTime ?? "?"} - ${apt.endTime ?? "?"}\n'
            'Mteja: ${apt.customerName ?? "Mteja"}\n\n'
            'Imeandikishwa kupitia TAJIRI'
        : 'Appointment: ${apt.serviceName ?? "Service"}\n'
            'Date: ${apt.date != null ? DateFormat('dd/MM/yyyy').format(apt.date!) : "-"}\n'
            'Time: ${apt.startTime ?? "?"} - ${apt.endTime ?? "?"}\n'
            'Customer: ${apt.customerName ?? "Customer"}\n\n'
            'Booked via TAJIRI';
    SharePlus.instance.share(ShareParams(text: text));
  }

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  String _statusLabel(AppointmentStatus s) {
    if (_isSwahili) return appointmentStatusLabel(s);
    switch (s) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No-Show';
    }
  }

  void _showCreateSheet() {
    final customerNameCtrl = TextEditingController();
    final customerPhoneCtrl = TextEditingController();
    final serviceCtrl = TextEditingController();
    final depositCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime aptDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    int duration = 60;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final endTime = TimeOfDay(
            hour: (startTime.hour + duration ~/ 60) % 24,
            minute: (startTime.minute + duration % 60) % 60,
          );
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_isSwahili ? 'Miadi Mpya' : 'New Appointment',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary)),
                  const SizedBox(height: 14),
                  _sheetField(customerNameCtrl,
                      _isSwahili ? 'Jina la Mteja *' : 'Customer Name *'),
                  const SizedBox(height: 10),
                  _sheetField(customerPhoneCtrl,
                      _isSwahili ? 'Simu ya Mteja' : 'Customer Phone',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  _sheetField(serviceCtrl,
                      _isSwahili ? 'Huduma *' : 'Service *'),
                  const SizedBox(height: 10),
                  // Date
                  GestureDetector(
                    onTap: () async {
                      final dt = await showDatePicker(
                        context: ctx,
                        initialDate: aptDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (dt != null) setSheetState(() => aptDate = dt);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _isSwahili ? 'Tarehe' : 'Date',
                        filled: true,
                        fillColor: _kBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(Icons.calendar_today_rounded,
                            size: 16, color: _kSecondary),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(aptDate)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Time
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: startTime,
                            );
                            if (t != null) setSheetState(() => startTime = t);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: _isSwahili
                                  ? 'Muda wa Kuanza'
                                  : 'Start Time',
                              filled: true,
                              fillColor: _kBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            child: Text(startTime.format(ctx)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: _isSwahili
                                ? 'Muda wa Kumaliza'
                                : 'End Time',
                            filled: true,
                            fillColor: _kBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          child: Text(endTime.format(ctx)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Duration
                  Text(
                      _isSwahili ? 'Muda (dakika)' : 'Duration (minutes)',
                      style: const TextStyle(
                          fontSize: 12, color: _kSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60, 90, 120].map((d) {
                      final sel = duration == d;
                      return ChoiceChip(
                        label: Text(
                            _isSwahili ? '${d}dk' : '${d}m',
                            style: TextStyle(
                                fontSize: 12,
                                color: sel ? Colors.white : _kPrimary)),
                        selected: sel,
                        onSelected: (_) =>
                            setSheetState(() => duration = d),
                        selectedColor: _kPrimary,
                        backgroundColor: _kCardBg,
                        side: BorderSide(
                            color: sel ? _kPrimary : Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  _sheetField(depositCtrl,
                      _isSwahili ? 'Amana (TZS)' : 'Deposit (TZS)',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  _sheetField(notesCtrl,
                      _isSwahili ? 'Maelezo' : 'Notes'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final name = customerNameCtrl.text.trim();
                              final service = serviceCtrl.text.trim();
                              if (name.isEmpty || service.isEmpty) return;
                              setSheetState(() => submitting = true);
                              try {
                                final body = {
                                  'business_id': widget.businessId,
                                  'customer_name': name,
                                  'customer_phone':
                                      customerPhoneCtrl.text.trim(),
                                  'service_name': service,
                                  'date': aptDate.toIso8601String(),
                                  'start_time':
                                      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                  'end_time':
                                      '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                  'duration_minutes': duration,
                                  'deposit_amount': double.tryParse(
                                          depositCtrl.text
                                              .replaceAll(',', '')) ??
                                      0,
                                  'notes': notesCtrl.text.trim(),
                                };
                                final res =
                                    await BusinessService.createAppointment(
                                        _token!, widget.businessId, body);
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(res.message ??
                                            (_isSwahili
                                                ? 'Miadi imeundwa'
                                                : 'Appointment created'))),
                                  );
                                  _load();
                                }
                              } catch (e) {
                                setSheetState(() => submitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(_isSwahili
                                          ? 'Imeshindikana. Jaribu tena.'
                                          : 'Failed. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isSwahili ? 'Unda Miadi' : 'Create Appointment',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _kBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'en');
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Material(
            color: _kCardBg,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: _kPrimary,
              unselectedLabelColor: _kSecondary,
              indicatorColor: _kPrimary,
              onTap: (_) => _load(),
              tabs: [
                Tab(text: _isSwahili ? 'Leo' : 'Today'),
                Tab(text: _isSwahili ? 'Zijazo' : 'Upcoming'),
              ],
            ),
          ),
          Expanded(
            child: Column(
        children: [
          // Date selector for "Today" tab
          if (_tabCtrl.index == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: _kPrimary),
                    onPressed: () {
                      setState(() => _selectedDate =
                          _selectedDate.subtract(const Duration(days: 1)));
                      _load();
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (dt != null) {
                          setState(() => _selectedDate = dt);
                          _load();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Text(
                            df.format(_selectedDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: _kPrimary),
                    onPressed: () {
                      setState(() => _selectedDate =
                          _selectedDate.add(const Duration(days: 1)));
                      _load();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14)),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _load,
                              style: FilledButton.styleFrom(
                                  backgroundColor: _kPrimary),
                              child: Text(
                                  _isSwahili ? 'Jaribu Tena' : 'Retry'),
                            ),
                          ],
                        ),
                      )
                    : _appointments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                    _isSwahili
                                        ? 'Hakuna miadi'
                                        : 'No appointments',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                    _isSwahili
                                        ? 'Bonyeza + kuunda miadi mpya'
                                        : 'Tap + to create a new appointment',
                                    style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: _kPrimary,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _appointments.length,
                              itemBuilder: (_, i) =>
                                  _buildAppointmentCard(
                                      _appointments[i], nf),
                            ),
                          ),
          ),
        ],
      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BusinessAppointment apt, NumberFormat nf) {
    final color = _statusColor(apt.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Timeline indicator + card content
          IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Time
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kPrimary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${apt.startTime ?? "?"} - ${apt.endTime ?? "?"}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _statusLabel(apt.status),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            apt.customerName ??
                                (_isSwahili ? 'Mteja' : 'Customer'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (apt.serviceName != null)
                          Text(apt.serviceName!,
                              style: const TextStyle(
                                  fontSize: 13, color: _kSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        if (apt.depositAmount > 0)
                          Text(
                              '${_isSwahili ? "Amana" : "Deposit"}: TZS ${nf.format(apt.depositAmount)}',
                              style: const TextStyle(
                                  fontSize: 11, color: _kSecondary)),
                        if (apt.customerPhone != null &&
                            apt.customerPhone!.isNotEmpty)
                          Text(apt.customerPhone!,
                              style: const TextStyle(
                                  fontSize: 11, color: _kSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          if (apt.status == AppointmentStatus.pending ||
              apt.status == AppointmentStatus.confirmed)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Row(
                children: [
                  if (apt.status == AppointmentStatus.pending)
                    _actionBtn(
                        _isSwahili ? 'Thibitisha' : 'Confirm',
                        Icons.check_rounded,
                        () => _updateStatus(apt, 'confirmed')),
                  if (apt.status == AppointmentStatus.confirmed)
                    _actionBtn(
                        _isSwahili ? 'Kamilisha' : 'Complete',
                        Icons.done_all_rounded,
                        () => _updateStatus(apt, 'completed')),
                  if (apt.status == AppointmentStatus.confirmed)
                    _actionBtn(
                        _isSwahili ? 'Hakuja' : 'No-Show',
                        Icons.person_off_rounded,
                        () => _updateStatus(apt, 'no_show')),
                  _actionBtn(
                      _isSwahili ? 'Shiriki' : 'Share',
                      Icons.share_rounded,
                      () => _shareAppointment(apt)),
                  _actionBtn(
                      _isSwahili ? 'Futa' : 'Cancel',
                      Icons.cancel_rounded,
                      () => _cancelAppointment(apt)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: SizedBox(
        height: 32,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 12),
          label: Text(label, style: const TextStyle(fontSize: 10)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimary,
            side: const BorderSide(color: _kPrimary, width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    );
  }
}
