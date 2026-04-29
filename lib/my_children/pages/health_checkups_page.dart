// lib/my_children/pages/health_checkups_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../l10n/app_strings_scope.dart';
import '../../doctor/doctor_module.dart';
import '../../insurance/insurance_module.dart';
import '../../calendar/services/calendar_service.dart';
import '../../calendar/models/calendar_models.dart';
import '../models/my_children_models.dart';
import 'dental_record_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ─── Checkup type definitions ─────────────────────────────────────

/// Recommended vision screening ages (years).
const List<int> _visionScreeningAges = [3, 5, 8, 12, 15];

/// Recommended hearing screening ages (years).
const List<int> _hearingScreeningAges = [0, 4, 8, 12];

/// Vision result options.
const List<String> _visionResults = ['normal', 'needs_glasses', 'follow_up'];

/// Hearing result options.
const List<String> _hearingResults = [
  'normal',
  'mild_loss',
  'moderate_loss',
  'follow_up'
];

String _visionResultLabel(String key, bool sw) {
  switch (key) {
    case 'normal':
      return sw ? 'Kawaida' : 'Normal';
    case 'needs_glasses':
      return sw ? 'Anahitaji miwani' : 'Needs glasses';
    case 'follow_up':
      return sw ? 'Ufuatiliaji' : 'Follow-up needed';
    default:
      return key;
  }
}

String _hearingResultLabel(String key, bool sw) {
  switch (key) {
    case 'normal':
      return sw ? 'Kawaida' : 'Normal';
    case 'mild_loss':
      return sw ? 'Upungufu mdogo' : 'Mild loss';
    case 'moderate_loss':
      return sw ? 'Upungufu wa wastani' : 'Moderate loss';
    case 'follow_up':
      return sw ? 'Ufuatiliaji' : 'Follow-up needed';
    default:
      return key;
  }
}

// ─── Data model for stored checkups ───────────────────────────────

class _CheckupRecord {
  final String type; // 'annual', 'vision', 'hearing'
  final DateTime date;
  final String? result;
  final String? notes;

  _CheckupRecord({
    required this.type,
    required this.date,
    this.result,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'date': date.toIso8601String(),
        if (result != null) 'result': result,
        if (notes != null) 'notes': notes,
      };

  factory _CheckupRecord.fromJson(Map<String, dynamic> json) {
    return _CheckupRecord(
      type: json['type'] as String? ?? 'annual',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      result: json['result'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

// ─── Page ─────────────────────────────────────────────────────────

class HealthCheckupsPage extends StatefulWidget {
  final Child child;

  const HealthCheckupsPage({super.key, required this.child});

  @override
  State<HealthCheckupsPage> createState() => _HealthCheckupsPageState();
}

class _HealthCheckupsPageState extends State<HealthCheckupsPage> {
  bool _isLoading = true;
  List<_CheckupRecord> _records = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  String get _prefKey => 'health_checkups_${widget.child.id}';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List;
        _records = decoded
            .map((e) => _CheckupRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        _records.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
      _scheduleCheckupReminders();
    }
  }

  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefKey, jsonEncode(_records.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  /// Schedule local notifications for annual checkup reminders.
  Future<void> _scheduleCheckupReminders() async {
    try {
      tz_data.initializeTimeZones();
      final flnp = FlutterLocalNotificationsPlugin();
      final now = DateTime.now();
      final childName = widget.child.name;
      final ageYears = widget.child.ageInYears;
      final sw = _sw;

      // Determine next annual checkup date
      final annualRecords =
          _records.where((r) => r.type == 'annual').toList();
      DateTime nextAnnual;
      if (annualRecords.isNotEmpty) {
        annualRecords.sort((a, b) => b.date.compareTo(a.date));
        nextAnnual = annualRecords.first.date.add(const Duration(days: 365));
      } else {
        // No record — recommend now
        nextAnnual = now;
      }

      final baseId = (widget.child.id * 10000 + 9000) & 0x7FFFFFFF;

      const androidDetails = AndroidNotificationDetails(
        'baby',
        'Mtoto Wangu',
        channelDescription: 'Arifa za chanjo, kulisha, na maendeleo ya mtoto',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );
      const details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      // 1 month before annual checkup
      final oneMonthBefore = nextAnnual.subtract(const Duration(days: 30));
      if (oneMonthBefore.isAfter(now)) {
        await flnp.zonedSchedule(
          baseId,
          sw ? 'Uchunguzi wa Kila Mwaka' : 'Annual Checkup Reminder',
          sw
              ? 'Uchunguzi wa kila mwaka wa $childName unakaribia (mwezi 1)'
              : 'Annual checkup for $childName is coming up in 1 month',
          tz.TZDateTime.from(oneMonthBefore, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // 1 week before annual checkup
      final oneWeekBefore = nextAnnual.subtract(const Duration(days: 7));
      if (oneWeekBefore.isAfter(now)) {
        await flnp.zonedSchedule(
          baseId + 1,
          sw ? 'Uchunguzi wa Kila Mwaka' : 'Annual Checkup Reminder',
          sw
              ? 'Uchunguzi wa kila mwaka wa $childName wiki 1 ijayo'
              : 'Annual checkup for $childName in 1 week',
          tz.TZDateTime.from(oneWeekBefore, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // Vision screening reminder if age matches
      if (_visionScreeningAges.contains(ageYears)) {
        final hasVisionThisYear = _records.any((r) =>
            r.type == 'vision' &&
            r.date.year == now.year);
        if (!hasVisionThisYear) {
          // Schedule for next month (gives parent time)
          final visionReminder = now.add(const Duration(days: 30));
          await flnp.zonedSchedule(
            baseId + 2,
            sw ? 'Uchunguzi wa Macho' : 'Vision Screening Reminder',
            sw
                ? '$childName anahitaji uchunguzi wa macho mwaka huu'
                : '$childName is due for a vision screening this year',
            tz.TZDateTime.from(visionReminder, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }

      // Hearing screening reminder if age matches
      if (_hearingScreeningAges.contains(ageYears)) {
        final hasHearingThisYear = _records.any((r) =>
            r.type == 'hearing' &&
            r.date.year == now.year);
        if (!hasHearingThisYear) {
          final hearingReminder = now.add(const Duration(days: 30));
          await flnp.zonedSchedule(
            baseId + 3,
            sw ? 'Uchunguzi wa Kusikia' : 'Hearing Screening Reminder',
            sw
                ? '$childName anahitaji uchunguzi wa kusikia mwaka huu'
                : '$childName is due for a hearing screening this year',
            tz.TZDateTime.from(hearingReminder, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (_) {
      // Best-effort
    }
  }

  // ─── Next checkup date helpers ──────────────────────────────────

  DateTime _nextAnnualCheckup() {
    final annuals =
        _records.where((r) => r.type == 'annual').toList();
    if (annuals.isEmpty) return DateTime.now();
    annuals.sort((a, b) => b.date.compareTo(a.date));
    return annuals.first.date.add(const Duration(days: 365));
  }

  bool _isVisionDue() {
    final age = widget.child.ageInYears;
    if (!_visionScreeningAges.contains(age)) return false;
    return !_records.any(
        (r) => r.type == 'vision' && r.date.year == DateTime.now().year);
  }

  bool _isHearingDue() {
    final age = widget.child.ageInYears;
    if (!_hearingScreeningAges.contains(age)) return false;
    return !_records.any(
        (r) => r.type == 'hearing' && r.date.year == DateTime.now().year);
  }

  // ─── Add checkup dialog ─────────────────────────────────────────

  void _showAddCheckup(String type) {
    final sw = _sw;
    DateTime selectedDate = DateTime.now();
    String? selectedResult;
    final notesController = TextEditingController();

    final resultOptions = type == 'vision'
        ? _visionResults
        : type == 'hearing'
            ? _hearingResults
            : <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            margin: const EdgeInsets.only(top: 100),
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: const BoxDecoration(
              color: _kBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    type == 'annual'
                        ? (sw ? 'Uchunguzi wa Kila Mwaka' : 'Annual Checkup')
                        : type == 'vision'
                            ? (sw ? 'Uchunguzi wa Macho' : 'Vision Screening')
                            : (sw
                                ? 'Uchunguzi wa Kusikia'
                                : 'Hearing Screening'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: widget.child.dateOfBirth,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: _kSecondary),
                          const SizedBox(width: 10),
                          Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style:
                                const TextStyle(fontSize: 14, color: _kPrimary),
                          ),
                          const Spacer(),
                          Text(
                            sw ? 'Badilisha tarehe' : 'Change date',
                            style:
                                const TextStyle(fontSize: 12, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Result selection (for vision / hearing)
                  if (resultOptions.isNotEmpty) ...[
                    Text(
                      sw ? 'Matokeo' : 'Result',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: resultOptions.map((r) {
                        final isSelected = selectedResult == r;
                        final label = type == 'vision'
                            ? _visionResultLabel(r, sw)
                            : _hearingResultLabel(r, sw);
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedResult = r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? _kPrimary : _kCardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? _kPrimary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : _kPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: sw ? 'Maelezo (hiari)' : 'Notes (optional)',
                      hintStyle:
                          const TextStyle(fontSize: 14, color: _kSecondary),
                      filled: true,
                      fillColor: _kCardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final record = _CheckupRecord(
                          type: type,
                          date: selectedDate,
                          result: selectedResult,
                          notes: notesController.text.trim().isNotEmpty
                              ? notesController.text.trim()
                              : null,
                        );
                        setState(() {
                          _records.insert(0, record);
                        });
                        _saveRecords();
                        _scheduleCheckupReminders();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                sw ? 'Imehifadhiwa!' : 'Saved!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final ageYears = widget.child.ageInYears;

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
          sw ? 'Uchunguzi wa Afya' : 'Health Checkups',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadRecords,
                color: _kPrimary,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // ── Annual Checkup Section ──
                    _buildSectionHeader(
                      icon: Icons.health_and_safety_rounded,
                      title: sw
                          ? 'Uchunguzi wa Kila Mwaka'
                          : 'Annual Checkup',
                      sw: sw,
                    ),
                    _buildAnnualCheckupCard(sw),
                    const SizedBox(height: 20),

                    // ── Vision Screening Section ──
                    _buildSectionHeader(
                      icon: Icons.visibility_rounded,
                      title: sw ? 'Uchunguzi wa Macho' : 'Vision Screening',
                      sw: sw,
                    ),
                    _buildScreeningInfo(
                      sw: sw,
                      recommendedAges: _visionScreeningAges,
                      currentAge: ageYears,
                      type: 'vision',
                      isDue: _isVisionDue(),
                    ),
                    ..._buildRecordList('vision', sw),
                    const SizedBox(height: 20),

                    // ── Hearing Screening Section ──
                    _buildSectionHeader(
                      icon: Icons.hearing_rounded,
                      title:
                          sw ? 'Uchunguzi wa Kusikia' : 'Hearing Screening',
                      sw: sw,
                    ),
                    _buildScreeningInfo(
                      sw: sw,
                      recommendedAges: _hearingScreeningAges,
                      currentAge: ageYears,
                      type: 'hearing',
                      isDue: _isHearingDue(),
                    ),
                    ..._buildRecordList('hearing', sw),
                    const SizedBox(height: 20),

                    // ── Dental Checkups Link ──
                    _buildSectionHeader(
                      icon: Icons.mood_rounded,
                      title: sw ? 'Uchunguzi wa Meno' : 'Dental Checkups',
                      sw: sw,
                    ),
                    _buildDentalLink(sw),

                    // ─── Cross-module links ──────────────
                    const SizedBox(height: 20),
                    Text(
                      sw ? 'Viunganishi' : 'Related',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCrossModuleLink(
                      icon: Icons.local_hospital_rounded,
                      label: sw
                          ? 'Weka miadi na daktari'
                          : 'Book a checkup with doctor',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DoctorModule(userId: widget.child.userId))),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.verified_user_rounded,
                      label: sw
                          ? 'Angalia bima ya afya'
                          : 'Check insurance coverage',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => InsuranceModule(userId: widget.child.userId))),
                    ),
                    _buildCrossModuleLink(
                      icon: Icons.calendar_month_rounded,
                      label: sw
                          ? 'Weka tarehe za uchunguzi kwenye kalenda'
                          : 'Sync checkup dates to calendar',
                      onTap: () => _syncCheckupsToCalendar(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Widgets ────────────────────────────────────────────────────

  void _syncCheckupsToCalendar() {
    try {
      final calService = CalendarService();
      final now = DateTime.now();

      // Sync next annual checkup
      final nextAnnual = _nextAnnualCheckup();
      calService.createEvent(CalendarEvent(
        id: 0,
        userId: widget.child.userId,
        title: '${widget.child.name} - Annual Checkup',
        date: nextAnnual,
        isAllDay: true,
        source: EventSource.doctor,
      ));

      // Sync next vision screening if due
      for (final age in _visionScreeningAges) {
        final dueDate = DateTime(widget.child.dateOfBirth.year + age, widget.child.dateOfBirth.month, widget.child.dateOfBirth.day);
        if (dueDate.isAfter(now)) {
          calService.createEvent(CalendarEvent(
            id: 0,
            userId: widget.child.userId,
            title: '${widget.child.name} - Vision Screening',
            date: dueDate,
            isAllDay: true,
            source: EventSource.doctor,
          ));
          break;
        }
      }

      if (mounted) {
        final sw = _sw;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Imewekwa kwenye kalenda' : 'Synced to calendar')),
        );
      }
    } catch (_) {}
  }

  Widget _buildCrossModuleLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF999999)),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool sw,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualCheckupCard(bool sw) {
    final nextDate = _nextAnnualCheckup();
    final isOverdue = nextDate.isBefore(DateTime.now());
    final annualRecords =
        _records.where((r) => r.type == 'annual').toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFFFFF3E0) : _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: const Color(0xFFFF9800), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOverdue
                          ? (sw
                              ? 'Uchunguzi umechelewa!'
                              : 'Checkup overdue!')
                          : (sw
                              ? 'Uchunguzi ujao'
                              : 'Next checkup'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isOverdue
                            ? const Color(0xFFE65100)
                            : _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      annualRecords.isEmpty
                          ? (sw
                              ? 'Hakuna uchunguzi uliorekodi'
                              : 'No checkup recorded yet')
                          : '${nextDate.day}/${nextDate.month}/${nextDate.year}',
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddCheckup('annual'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    sw ? 'Ongeza' : 'Add',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
            ],
          ),
          if (annualRecords.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              sw ? 'Historia' : 'History',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary),
            ),
            const SizedBox(height: 6),
            ...annualRecords.take(3).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 8),
                      Text(
                        '${r.date.day}/${r.date.month}/${r.date.year}',
                        style:
                            const TextStyle(fontSize: 13, color: _kPrimary),
                      ),
                      if (r.notes != null && r.notes!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.notes!,
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildScreeningInfo({
    required bool sw,
    required List<int> recommendedAges,
    required int currentAge,
    required String type,
    required bool isDue,
  }) {
    final agesStr = recommendedAges
        .map((a) => a == 0 ? (sw ? 'kuzaliwa' : 'birth') : '$a')
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDue ? const Color(0xFFFFF3E0) : _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: isDue
            ? Border.all(color: const Color(0xFFFF9800), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw
                      ? 'Inapendekezwa umri wa: $agesStr ${sw ? "miaka" : "years"}'
                      : 'Recommended at ages: $agesStr years',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isDue) ...[
                  const SizedBox(height: 4),
                  Text(
                    sw
                        ? 'Uchunguzi unapendekezwa mwaka huu!'
                        : 'Screening recommended this year!',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => _showAddCheckup(type),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                sw ? 'Ongeza' : 'Add',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecordList(String type, bool sw) {
    final filtered = _records.where((r) => r.type == type).toList();
    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            sw ? 'Hakuna rekodi bado' : 'No records yet',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
        ),
      ];
    }

    return filtered.take(5).map((r) {
      final resultLabel = type == 'vision'
          ? _visionResultLabel(r.result ?? 'normal', sw)
          : _hearingResultLabel(r.result ?? 'normal', sw);
      final isNormal = r.result == 'normal' || r.result == null;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isNormal
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              size: 20,
              color: isNormal
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${r.date.day}/${r.date.month}/${r.date.year}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isNormal
                              ? const Color(0xFF4CAF50)
                                  .withValues(alpha: 0.1)
                              : const Color(0xFFFF9800)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          resultLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isNormal
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (r.notes != null && r.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.notes!,
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDentalLink(bool sw) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DentalRecordPage(child: widget.child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.mood_rounded, size: 22, color: _kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Rekodi za Meno' : 'Dental Records',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sw
                        ? 'Bonyeza kufungua rekodi za meno'
                        : 'Tap to open dental records',
                    style:
                        const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _kSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
