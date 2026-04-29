// lib/my_parents/pages/appointments_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../services/expenditure_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import '../services/parents_notification_helper.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFEF5350);
const Color _kSuccess = Color(0xFF4CAF50);

class AppointmentsPage extends StatefulWidget {
  final Parent parent;

  const AppointmentsPage({super.key, required this.parent});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final MyParentsService _service = MyParentsService();
  String? _token;
  bool _isLoading = true;
  List<ParentAppointment> _appointments = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getAppointments(_token!, widget.parent.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _appointments = result.items
            ..sort((a, b) => b.date.compareTo(a.date));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Imeshindikana kupakia miadi'
            : 'Failed to load appointments')),
      );
    }
  }

  List<ParentAppointment> get _upcoming => _appointments
      .where((a) => a.status == 'upcoming' && a.date.isAfter(DateTime.now().subtract(const Duration(days: 1))))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  List<ParentAppointment> get _past => _appointments
      .where((a) => a.status == 'completed' || a.date.isBefore(DateTime.now().subtract(const Duration(days: 1))))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  String _countdown(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    final sw = _sw;
    if (diff.isNegative) return sw ? 'Imepita' : 'Passed';
    if (diff.inDays == 0) return sw ? 'Leo' : 'Today';
    if (diff.inDays == 1) return sw ? 'Kesho' : 'Tomorrow';
    return sw ? 'Siku ${diff.inDays}' : 'in ${diff.inDays} days';
  }

  void _showAddAppointmentSheet() {
    final doctorCtrl = TextEditingController();
    final facilityCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  sw ? 'Ongeza Miadi' : 'Add Appointment',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 16),
                _Field(controller: doctorCtrl, label: sw ? 'Jina la daktari' : 'Doctor name'),
                const SizedBox(height: 12),
                _Field(controller: facilityCtrl, label: sw ? 'Kituo cha afya' : 'Health facility'),
                const SizedBox(height: 12),
                _Field(controller: reasonCtrl, label: sw ? 'Sababu' : 'Reason'),
                const SizedBox(height: 12),
                // Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Text(
                          '${sw ? 'Tarehe: ' : 'Date: '}'
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 13, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: timeCtrl,
                  label: sw ? 'Muda (mfano: 10:00)' : 'Time (e.g. 10:00)',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      final doctor = doctorCtrl.text.trim();
                      final facility = facilityCtrl.text.trim();
                      final reason = reasonCtrl.text.trim();
                      if (doctor.isEmpty && facility.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(sw
                              ? 'Tafadhali ingiza daktari au kituo'
                              : 'Please enter doctor or facility')),
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      _saveAppointment(
                        doctorName: doctor.isNotEmpty ? doctor : null,
                        facility: facility.isNotEmpty ? facility : null,
                        reason: reason.isNotEmpty ? reason : null,
                        date: selectedDate,
                        time: timeCtrl.text.trim().isNotEmpty ? timeCtrl.text.trim() : null,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                // Cross-module: Book via doctor module
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/doctor');
                    },
                    child: Text(
                      sw ? 'Panga kupitia TAJIRI Doctor' : 'Book via TAJIRI Doctor',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _kPrimary, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      doctorCtrl.dispose();
      facilityCtrl.dispose();
      reasonCtrl.dispose();
      timeCtrl.dispose();
    });
  }

  Future<void> _saveAppointment({
    String? doctorName,
    String? facility,
    String? reason,
    required DateTime date,
    String? time,
  }) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final result = await _service.addAppointment(
        token: _token!,
        parentId: widget.parent.id,
        doctorName: doctorName,
        facility: facility,
        reason: reason,
        date: date,
        time: time,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Miadi imeongezwa' : 'Appointment added')),
        );
        // Schedule reminder
        ParentsNotificationHelper.scheduleAppointmentReminder(
          widget.parent.id,
          widget.parent.name,
          doctorName ?? facility ?? '',
          date,
          _sw,
        );
        _loadAppointments();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  void _showAppointmentDetail(ParentAppointment apt) {
    final diagnosisCtrl = TextEditingController(text: apt.diagnosis ?? '');
    final prescriptionCtrl = TextEditingController(text: apt.prescription ?? '');
    final costCtrl = TextEditingController(
        text: apt.cost != null ? apt.cost!.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController(text: apt.notes ?? '');
    DateTime? followUpDate = apt.followUpDate;
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  sw ? 'Maelezo ya Miadi' : 'Appointment Details',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 16),
                if (apt.doctorName != null)
                  _InfoRow(label: sw ? 'Daktari' : 'Doctor', value: apt.doctorName!),
                if (apt.facility != null)
                  _InfoRow(label: sw ? 'Kituo' : 'Facility', value: apt.facility!),
                if (apt.reason != null)
                  _InfoRow(label: sw ? 'Sababu' : 'Reason', value: apt.reason!),
                _InfoRow(
                  label: sw ? 'Tarehe' : 'Date',
                  value: '${apt.date.day}/${apt.date.month}/${apt.date.year}'
                      '${apt.time != null ? ' ${apt.time}' : ''}',
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _Field(controller: diagnosisCtrl,
                    label: sw ? 'Uchunguzi' : 'Diagnosis'),
                const SizedBox(height: 12),
                _Field(controller: prescriptionCtrl,
                    label: sw ? 'Dawa zilizoandikwa' : 'Prescription'),
                const SizedBox(height: 12),
                _Field(controller: costCtrl,
                    label: sw ? 'Gharama (TSh)' : 'Cost (TSh)',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _Field(controller: notesCtrl,
                    label: sw ? 'Maelezo' : 'Notes', maxLines: 3),
                const SizedBox(height: 12),
                // Follow-up date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: followUpDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => followUpDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_repeat_rounded, size: 18, color: _kSecondary),
                        const SizedBox(width: 10),
                        Text(
                          followUpDate != null
                              ? '${sw ? 'Tarehe ya kurudi: ' : 'Follow-up: '}'
                                '${followUpDate!.day}/${followUpDate!.month}/${followUpDate!.year}'
                              : (sw ? 'Weka tarehe ya kurudi' : 'Set follow-up date'),
                          style: const TextStyle(fontSize: 13, color: _kPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateAppointment(
                        apt,
                        diagnosis: diagnosisCtrl.text.trim().isNotEmpty
                            ? diagnosisCtrl.text.trim()
                            : null,
                        prescription: prescriptionCtrl.text.trim().isNotEmpty
                            ? prescriptionCtrl.text.trim()
                            : null,
                        cost: double.tryParse(costCtrl.text.trim()),
                        notes: notesCtrl.text.trim().isNotEmpty
                            ? notesCtrl.text.trim()
                            : null,
                        followUpDate: followUpDate,
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(sw ? 'Sasisha' : 'Update',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
                // Cross-module links
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (apt.prescription != null && apt.prescription!.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, '/pharmacy');
                        },
                        child: Text(sw ? 'Duka la Dawa' : 'Pharmacy',
                            style: const TextStyle(fontSize: 12, color: _kPrimary,
                                decoration: TextDecoration.underline)),
                      ),
                    if (apt.cost != null && apt.cost! > 0)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, '/insurance');
                        },
                        child: Text(sw ? 'Bima' : 'Insurance',
                            style: const TextStyle(fontSize: 12, color: _kPrimary,
                                decoration: TextDecoration.underline)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      diagnosisCtrl.dispose();
      prescriptionCtrl.dispose();
      costCtrl.dispose();
      notesCtrl.dispose();
    });
  }

  Future<void> _updateAppointment(
    ParentAppointment apt, {
    String? diagnosis,
    String? prescription,
    double? cost,
    String? notes,
    DateTime? followUpDate,
  }) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final result = await _service.updateAppointment(
        token: _token!,
        appointmentId: apt.id,
        diagnosis: diagnosis,
        prescription: prescription,
        cost: cost,
        notes: notes,
        followUpDate: followUpDate,
        status: apt.date.isBefore(DateTime.now()) ? 'completed' : apt.status,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Miadi imesasishwa' : 'Appointment updated')),
        );

        // Fire-and-forget: record expenditure if cost added
        if (cost != null && cost > 0) {
          ExpenditureService.recordExpenditure(
            token: _token!,
            amount: cost,
            category: 'wazazi',
            description: '${sw ? 'Gharama ya daktari' : 'Doctor visit cost'}'
                ' - ${apt.doctorName ?? apt.facility ?? ''}',
            sourceModule: 'my_parents',
          );
        }

        // Schedule follow-up reminder if set
        if (followUpDate != null) {
          ParentsNotificationHelper.scheduleAppointmentReminder(
            widget.parent.id,
            widget.parent.name,
            apt.doctorName ?? apt.facility ?? '',
            followUpDate,
            _sw,
          );
        }

        _loadAppointments();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kusasisha' : 'Failed to update'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _deleteAppointment(ParentAppointment apt) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa miadi?' : 'Delete appointment?'),
        content: Text(sw
            ? 'Hatua hii haiwezi kutenduliwa.'
            : 'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: _kDanger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await _service.deleteAppointment(token: _token!, appointmentId: apt.id);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Miadi imefutwa' : 'Appointment deleted')),
        );
        _loadAppointments();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa kufuta' : 'Failed to delete'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Miadi' : 'Appointments',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAppointmentSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Cost summary
                  if (_appointments.any((a) => a.cost != null && a.cost! > 0))
                    _buildCostSummary(sw),
                  if (_appointments.any((a) => a.cost != null && a.cost! > 0))
                    const SizedBox(height: 16),
                  // Upcoming
                  if (_upcoming.isNotEmpty) ...[
                    Text(
                      sw ? 'Miadi Ijayo' : 'Upcoming',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    const SizedBox(height: 12),
                    ..._upcoming.map((a) => _buildAppointmentCard(a, sw, isUpcoming: true)),
                    const SizedBox(height: 24),
                  ],
                  // Past
                  if (_past.isNotEmpty) ...[
                    Text(
                      sw ? 'Miadi Iliyopita' : 'Past Appointments',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    const SizedBox(height: 12),
                    ..._past.map((a) => _buildAppointmentCard(a, sw, isUpcoming: false)),
                  ],
                  if (_upcoming.isEmpty && _past.isEmpty) ...[
                    const SizedBox(height: 100),
                    Icon(Icons.calendar_month_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      sw ? 'Hakuna miadi' : 'No appointments yet',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  // Cross-module: Calendar link
                  if (_appointments.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/calendar');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_month_rounded, size: 18, color: _kSecondary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            sw ? 'Tazama kwenye Kalenda' : 'View in Calendar',
                            style: const TextStyle(fontSize: 13, color: _kPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          )),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildAppointmentCard(ParentAppointment apt, bool sw, {required bool isUpcoming}) {
    return GestureDetector(
      onTap: () => _showAppointmentDetail(apt),
      onLongPress: () => _deleteAppointment(apt),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isUpcoming
                    ? _kPrimary.withValues(alpha: 0.06)
                    : _kSuccess.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${apt.date.day}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  Text(
                    _monthAbbr(apt.date.month),
                    style: const TextStyle(fontSize: 9, color: _kSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apt.doctorName ?? apt.facility ?? (sw ? 'Miadi' : 'Appointment'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (apt.reason != null && apt.reason!.isNotEmpty)
                    Text(apt.reason!,
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (apt.diagnosis != null && apt.diagnosis!.isNotEmpty)
                    Text(
                      '${sw ? 'Uchunguzi: ' : 'Diagnosis: '}${apt.diagnosis}',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isUpcoming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _countdown(apt.date),
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                  ),
                if (apt.time != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(apt.time!,
                        style: const TextStyle(fontSize: 11, color: _kSecondary)),
                  ),
                if (apt.cost != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'TSh ${apt.cost!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: _kSecondary),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostSummary(bool sw) {
    final now = DateTime.now();
    final monthTotal = _appointments
        .where((a) => a.cost != null && a.cost! > 0 &&
            a.date.year == now.year && a.date.month == now.month)
        .fold(0.0, (sum, a) => sum + a.cost!);
    final yearTotal = _appointments
        .where((a) => a.cost != null && a.cost! > 0 && a.date.year == now.year)
        .fold(0.0, (sum, a) => sum + a.cost!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(sw ? 'Gharama Mwezi Huu' : 'This Month',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 4),
                Text('TSh ${_formatAmount(monthTotal)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.15)),
          Expanded(
            child: Column(
              children: [
                Text(sw ? 'Jumla ya Mwaka' : 'This Year',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 4),
                Text('TSh ${_formatAmount(yearTotal)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _monthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month.clamp(1, 12) - 1];
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int? maxLines;

  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        filled: true,
        fillColor: _kPrimary.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: const TextStyle(fontSize: 14, color: _kPrimary),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
