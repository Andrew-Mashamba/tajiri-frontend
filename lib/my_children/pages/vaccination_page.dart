// lib/my_children/pages/vaccination_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../services/my_children_service.dart';
import '../services/children_notification_helper.dart';
import '../widgets/vaccination_card.dart';
import '../../doctor/doctor_module.dart';
import '../../pharmacy/pharmacy_module.dart';
import '../../insurance/insurance_module.dart';
import '../../calendar/services/calendar_service.dart';
import '../../calendar/models/calendar_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

/// Tanzania EPI vaccination schedule — local fallback when API returns empty.
const List<Map<String, dynamic>> _tanzaniaEPI = [
  {'name_en': 'BCG', 'name_sw': 'BCG', 'age_label': 'Birth', 'due_age_days': 0},
  {'name_en': 'OPV-0', 'name_sw': 'OPV-0', 'age_label': 'Birth', 'due_age_days': 0},
  {'name_en': 'DPT-HepB-Hib-1', 'name_sw': 'Penta-1', 'age_label': '6 weeks', 'due_age_days': 42},
  {'name_en': 'OPV-1', 'name_sw': 'OPV-1', 'age_label': '6 weeks', 'due_age_days': 42},
  {'name_en': 'PCV13-1', 'name_sw': 'PCV-1', 'age_label': '6 weeks', 'due_age_days': 42},
  {'name_en': 'Rotavirus-1', 'name_sw': 'Rota-1', 'age_label': '6 weeks', 'due_age_days': 42},
  {'name_en': 'DPT-HepB-Hib-2', 'name_sw': 'Penta-2', 'age_label': '10 weeks', 'due_age_days': 70},
  {'name_en': 'OPV-2', 'name_sw': 'OPV-2', 'age_label': '10 weeks', 'due_age_days': 70},
  {'name_en': 'PCV13-2', 'name_sw': 'PCV-2', 'age_label': '10 weeks', 'due_age_days': 70},
  {'name_en': 'Rotavirus-2', 'name_sw': 'Rota-2', 'age_label': '10 weeks', 'due_age_days': 70},
  {'name_en': 'DPT-HepB-Hib-3', 'name_sw': 'Penta-3', 'age_label': '14 weeks', 'due_age_days': 98},
  {'name_en': 'OPV-3', 'name_sw': 'OPV-3', 'age_label': '14 weeks', 'due_age_days': 98},
  {'name_en': 'PCV13-3', 'name_sw': 'PCV-3', 'age_label': '14 weeks', 'due_age_days': 98},
  {'name_en': 'IPV', 'name_sw': 'IPV', 'age_label': '14 weeks', 'due_age_days': 98},
  {'name_en': 'Vitamin A (1st)', 'name_sw': 'Vitamini A (1)', 'age_label': '6 months', 'due_age_days': 183},
  {'name_en': 'Measles-Rubella-1', 'name_sw': 'Surua-Rubela-1', 'age_label': '9 months', 'due_age_days': 274},
  {'name_en': 'OPV-4', 'name_sw': 'OPV-4', 'age_label': '9 months', 'due_age_days': 274},
  {'name_en': 'Vitamin A (2nd)', 'name_sw': 'Vitamini A (2)', 'age_label': '12 months', 'due_age_days': 365},
  {'name_en': 'Measles-Rubella-2', 'name_sw': 'Surua-Rubela-2', 'age_label': '15 months', 'due_age_days': 457},
  {'name_en': 'Vitamin A (3rd)', 'name_sw': 'Vitamini A (3)', 'age_label': '18 months', 'due_age_days': 548},
  {'name_en': 'DPT-HepB-Hib Booster', 'name_sw': 'Penta Booster', 'age_label': '18 months', 'due_age_days': 548},
  {'name_en': 'Td (Tetanus-Diphtheria)', 'name_sw': 'Td', 'age_label': '7 years', 'due_age_days': 2555},
  {'name_en': 'HPV Dose 1 (Girls)', 'name_sw': 'HPV Dozi 1 (Wasichana)', 'age_label': '14 years', 'due_age_days': 5110},
  {'name_en': 'HPV Dose 2 (Girls)', 'name_sw': 'HPV Dozi 2 (Wasichana)', 'age_label': '14.5 years', 'due_age_days': 5293},
  {'name_en': 'Td Booster', 'name_sw': 'Td Booster', 'age_label': '15 years', 'due_age_days': 5475},
];

class VaccinationPage extends StatefulWidget {
  final Baby baby;

  const VaccinationPage({super.key, required this.baby});

  @override
  State<VaccinationPage> createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage> {
  final MyChildrenService _service = MyChildrenService();
  final ImagePicker _picker = ImagePicker();
  String? _token;
  int? _currentUserId;

  bool _isLoading = true;
  List<Vaccination> _vaccinations = [];
  bool _justMarkedDone = false; // Show post-vaccination tip

  // RCH card photo
  BabyPhoto? _rchCardPhoto;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _currentUserId = LocalStorageService.instanceSync?.getUser()?.userId;
    _loadVaccinations();
    _loadRchCardPhoto();
  }

  Future<void> _loadVaccinations() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getVaccinationSchedule(_token!, widget.baby.id);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _vaccinations = result.items;
            // Fix 6: If API returns empty, generate from local Tanzania EPI schedule
            if (_vaccinations.isEmpty) {
              _vaccinations = _generateFromEPI(widget.baby);
            }
          } else {
            // Also fall back to EPI on failure
            _vaccinations = _generateFromEPI(widget.baby);
          }
        });
        _scheduleVaccinationReminders();
        _checkOverdueVaccines();
        _syncVaccineDueDatesToCalendar();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _vaccinations = _generateFromEPI(widget.baby);
        });
      }
    }
  }

  /// Fire-and-forget: sync all pending vaccine due dates to calendar.
  void _syncVaccineDueDatesToCalendar() {
    try {
      final calService = CalendarService();
      for (final v in _vaccinations) {
        if (v.isDone) continue;
        final dueDate = v.effectiveDueDate(widget.baby.dateOfBirth);
        if (dueDate == null) continue;
        calService.createEvent(CalendarEvent(
          id: 0,
          userId: widget.baby.userId,
          title: '${v.name} - ${widget.baby.name}',
          date: dueDate,
          isAllDay: true,
          source: EventSource.vaccination,
        ));
      }
    } catch (_) {}
  }

  /// Generate vaccination objects from the hardcoded Tanzania EPI schedule.
  List<Vaccination> _generateFromEPI(Baby baby) {
    return _tanzaniaEPI.asMap().entries.map((entry) {
      final i = entry.key;
      final epi = entry.value;
      final dueAgeDays = epi['due_age_days'] as int;
      final dueDate = baby.dateOfBirth.add(Duration(days: dueAgeDays));
      return Vaccination(
        id: -(i + 1), // Negative IDs for local-only entries
        babyId: baby.id,
        name: epi['name_en'] as String,
        swahiliName: epi['name_sw'] as String,
        dueDate: dueDate,
        isDone: false,
        ageLabel: epi['age_label'] as String,
        dueAgeDays: dueAgeDays,
      );
    }).toList();
  }

  /// Schedule local push notifications for upcoming vaccinations (within 30 days).
  /// Schedules at 7 days before, 1 day before, and on due date.
  Future<void> _scheduleVaccinationReminders() async {
    try {
      tz_data.initializeTimeZones();
      final flnp = FlutterLocalNotificationsPlugin();
      final now = DateTime.now();
      final childName = widget.baby.name;

      for (final v in _vaccinations) {
        if (v.isDone) continue;
        final dueDate = v.effectiveDueDate(widget.baby.dateOfBirth);
        if (dueDate == null) continue;

        final daysUntil = dueDate.difference(now).inDays;
        if (daysUntil < 0 || daysUntil > 30) continue;

        final vaccineName = v.name;
        // Unique base ID from vaccine ID + child ID
        final baseId = (v.id.abs() * 1000 + widget.baby.id) & 0x7FFFFFFF;

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
        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // 7 days before due date
        final sevenDaysBefore = dueDate.subtract(const Duration(days: 7));
        if (sevenDaysBefore.isAfter(now)) {
          await flnp.zonedSchedule(
            baseId,
            _sw ? 'Kikumbusho cha Chanjo' : 'Vaccination Reminder',
            _sw
                ? 'Chanjo ya $vaccineName inatarajiwa baada ya siku 7 kwa $childName'
                : 'Vaccination reminder: $vaccineName is due in 7 days for $childName',
            tz.TZDateTime.from(sevenDaysBefore, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }

        // 1 day before due date
        final oneDayBefore = dueDate.subtract(const Duration(days: 1));
        if (oneDayBefore.isAfter(now)) {
          await flnp.zonedSchedule(
            baseId + 1,
            _sw ? 'Chanjo Kesho' : 'Vaccination Tomorrow',
            _sw
                ? 'Kesho: Chanjo ya $vaccineName kwa $childName'
                : 'Tomorrow: $vaccineName for $childName',
            tz.TZDateTime.from(oneDayBefore, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }

        // On due date
        if (dueDate.isAfter(now)) {
          await flnp.zonedSchedule(
            baseId + 2,
            _sw ? 'Chanjo Leo' : 'Vaccination Due Today',
            _sw
                ? 'Chanjo ya $vaccineName inapaswa kutolewa leo kwa $childName'
                : '$vaccineName is due today for $childName',
            tz.TZDateTime.from(dueDate, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }

      // Also fire backend reminder for upcoming vaccines (existing behavior)
      for (final v in _vaccinations) {
        if (!v.isDone && v.effectiveDueDate(widget.baby.dateOfBirth) != null) {
          final dueDate = v.effectiveDueDate(widget.baby.dateOfBirth)!;
          final daysUntil = dueDate.difference(now).inDays;
          if (daysUntil >= 0 && daysUntil <= 7) {
            http.post(
              Uri.parse('${ApiConfig.baseUrl}/my-baby/reminders/vaccination'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'child_id': widget.baby.id,
                'vaccine_name': v.name,
                'due_date': dueDate.toIso8601String(),
              }),
            ).catchError((_) => http.Response('', 500));
          }
        }
      }
    } catch (_) {
      // Notifications are best-effort — don't break the page
    }
  }

  /// Fire-and-forget: check for overdue vaccines and send alerts.
  void _checkOverdueVaccines() {
    try {
      final now = DateTime.now();
      for (final v in _vaccinations) {
        if (v.isDone) continue;
        final dueDate = v.effectiveDueDate(widget.baby.dateOfBirth);
        if (dueDate == null) continue;
        final daysOverdue = now.difference(dueDate).inDays;
        if (daysOverdue > 0) {
          ChildrenNotificationHelper.scheduleVaccineOverdueAlert(
            widget.baby.id,
            widget.baby.name,
            _sw ? v.swahiliName : v.name,
            daysOverdue,
            isSwahili: _sw,
          ).catchError((_) {});
        }
      }
    } catch (_) {}
  }

  Future<void> _loadRchCardPhoto() async {
    if (_token == null) return;
    try {
      final result = await _service.getPhotos(_token!, widget.baby.id);
      if (!mounted) return;
      if (result.success) {
        final rchPhotos = result.items.where((p) => p.type == 'rch_card').toList();
        if (rchPhotos.isNotEmpty) {
          setState(() => _rchCardPhoto = rchPhotos.first);
        }
      }
    } catch (_) {
      // Silently fail — RCH card is optional
    }
  }

  Future<void> _snapRchCard() async {
    if (_token == null) return;
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final result = await _service.uploadPhoto(
        token: _token!,
        babyId: widget.baby.id,
        filePath: picked.path,
        type: 'rch_card',
      );

      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() => _rchCardPhoto = result.data);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Kadi ya RCH imehifadhiwa!' : 'RCH card saved!')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
      );
    }
  }

  Future<void> _shareVaccinationRecord() async {
    final sw = _sw;
    final buffer = StringBuffer();
    buffer.writeln(sw
        ? 'REKODI YA CHANJO -- ${widget.baby.name}'
        : 'VACCINATION RECORD -- ${widget.baby.name}');
    buffer.writeln(sw
        ? 'Tarehe ya Kuzaliwa: ${_formatDate(widget.baby.dateOfBirth, sw)}'
        : 'Date of Birth: ${_formatDate(widget.baby.dateOfBirth, sw)}');
    buffer.writeln('');
    for (final v in _vaccinations) {
      final effectiveDate = v.effectiveDueDate(widget.baby.dateOfBirth);
      final String status;
      if (v.isDone) {
        status = '\u2705'; // check mark
      } else if (v.isOverdueWithDob(widget.baby.dateOfBirth)) {
        status = sw ? '\u26A0\uFE0F IMECHELEWA' : '\u26A0\uFE0F OVERDUE';
      } else {
        status = '\u23F3'; // hourglass
      }
      final dateInfo = v.isDone && v.givenDate != null
          ? (sw ? 'Imetolewa: ${_formatDate(v.givenDate!, sw)}' : 'Given: ${_formatDate(v.givenDate!, sw)}')
          : effectiveDate != null
              ? (sw ? 'Inatarajiwa: ${_formatDate(effectiveDate, sw)}' : 'Due: ${_formatDate(effectiveDate, sw)}')
              : '';
      final name = sw
          ? (v.swahiliName.isNotEmpty ? v.swahiliName : v.name)
          : v.name;
      buffer.writeln('$status $name -- $dateInfo');
    }
    buffer.writeln('');
    buffer.writeln(sw ? 'Kutoka TAJIRI' : 'Sent from TAJIRI');

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Future<void> _markDone(Vaccination vacc) async {
    if (_token == null) return;
    // Local-only vaccinations (negative IDs) can't be marked done via API
    if (vacc.id < 0) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Chanjo hii ni ya ndani — sajili mtoto kwenye seva kwanza'
            : 'This is a local schedule — register baby on server first')),
      );
      return;
    }
    final now = DateTime.now();
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _service.markVaccinationDone(_token!, vacc.id, now);
      if (!mounted) return;
      if (result.success) {
        setState(() => _justMarkedDone = true);
        messenger.showSnackBar(
          SnackBar(
              content: Text(sw
                  ? '${vacc.swahiliName.isNotEmpty ? vacc.swahiliName : vacc.name} imekamilika'
                  : '${vacc.name} completed')),
        );
        _loadVaccinations();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa kukamilisha chanjo' : 'Failed to complete vaccination'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(sw ? 'Kosa: $e' : 'Error: $e')),
      );
    }
  }

  Future<void> _undoVaccination(Vaccination vacc) async {
    if (_token == null) return;
    if (vacc.id < 0) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Chanjo hii ni ya ndani — haiwezi kubatilishwa'
            : 'This is a local schedule entry — cannot undo')),
      );
      return;
    }
    final sw = _sw;
    final messenger = ScaffoldMessenger.of(context);
    final vaccineName = sw
        ? (vacc.swahiliName.isNotEmpty ? vacc.swahiliName : vacc.name)
        : vacc.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text(
          sw ? 'Batilisha Chanjo?' : 'Unmark Vaccination?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        content: Text(
          sw
              ? 'Una uhakika unataka kubatilisha "$vaccineName" kuwa haijatolewa?'
              : 'Are you sure you want to unmark "$vaccineName" as not given?',
          style: const TextStyle(fontSize: 14, color: _kSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Batilisha' : 'Undo', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final result = await _service.undoVaccination(_token!, vacc.id);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? '$vaccineName imebatilishwa' : '$vaccineName unmarked')),
        );
        _loadVaccinations();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? (sw ? 'Imeshindwa kubatilisha' : 'Failed to undo'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(sw ? 'Kosa: $e' : 'Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final doneCount = _vaccinations.where((v) => v.isDone).length;
    final overdueCount =
        _vaccinations.where((v) => v.isOverdueWithDob(widget.baby.dateOfBirth)).length;
    final totalCount = _vaccinations.length;

    // Group vaccinations by age label
    // Fix 10: Use effectiveDueDate for display
    final grouped = <String, List<Vaccination>>{};
    for (final v in _vaccinations) {
      grouped.putIfAbsent(v.ageLabel, () => []).add(v);
    }

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
          sw ? 'Ratiba ya Chanjo' : 'Vaccination Schedule',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
        actions: [
          // RCH card camera button
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: _kPrimary),
            tooltip: sw ? 'Piga picha ya Kadi ya RCH' : 'Snap RCH Card',
            onPressed: _snapRchCard,
          ),
          // Share vaccination record button
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            tooltip: sw ? 'Shiriki rekodi' : 'Share record',
            onPressed: _vaccinations.isNotEmpty ? _shareVaccinationRecord : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadVaccinations,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                children: [
                  // RCH card photo (if available)
                  if (_rchCardPhoto != null) ...[
                    _buildRchCardPreview(sw),
                    const SizedBox(height: 12),
                  ],

                  // Booking link — show when any vaccine is overdue or due within 7 days
                  if (_hasUrgentVaccines && _currentUserId != null) ...[
                    _buildCrossModuleLink(
                      icon: Icons.calendar_today_rounded,
                      label: sw
                          ? 'Weka miadi ya chanjo'
                          : 'Book vaccination appointment',
                      iconColor: overdueCount > 0 ? Colors.red.shade600 : _kPrimary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DoctorModule(userId: _currentUserId!))),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Post-vaccination tip card
                  if (_justMarkedDone && _currentUserId != null) ...[
                    _buildPostVaccinationTip(sw),
                    const SizedBox(height: 12),
                  ],

                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SummaryItem(
                              value: '$doneCount',
                              label: sw ? 'Zilizotolewa' : 'Given',
                              color: const Color(0xFF4CAF50),
                            ),
                            _SummaryItem(
                              value: '${totalCount - doneCount}',
                              label: sw ? 'Zilizobaki' : 'Remaining',
                              color: Colors.white,
                            ),
                            if (overdueCount > 0)
                              _SummaryItem(
                                value: '$overdueCount',
                                label: sw ? 'Zilizochelewa' : 'Overdue',
                                color: Colors.red.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalCount > 0
                                ? doneCount / totalCount
                                : 0,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: _kSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sw
                                ? 'Ratiba ya Chanjo ya Tanzania (EPI) - Hakikisha mtoto anapata chanjo zote kwa wakati.'
                                : 'Tanzania EPI Vaccination Schedule - Make sure your baby gets all vaccines on time.',
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_vaccinations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          sw
                              ? 'Ratiba ya chanjo itaonekana hapa baada ya kusajili mtoto.'
                              : 'The vaccination schedule will appear here after registering the baby.',
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  // Grouped vaccination list
                  ...grouped.entries.map((entry) {
                    // Fix 10: Compute effective due date for the group header
                    final firstVacc = entry.value.first;
                    final effectiveGroupDate = firstVacc.effectiveDueDate(widget.baby.dateOfBirth);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8, top: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      _kPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _kPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (effectiveGroupDate != null)
                                Text(
                                  _formatDate(effectiveGroupDate, sw),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _kSecondary),
                                ),
                            ],
                          ),
                        ),
                        ...entry.value.map((vacc) => VaccinationCard(
                              vaccination: vacc,
                              isSwahili: sw,
                              onMarkDone: vacc.isDone
                                  ? null
                                  : () => _markDone(vacc),
                              onUndoVaccination: vacc.isDone
                                  ? () => _undoVaccination(vacc)
                                  : null,
                              babyDob: widget.baby.dateOfBirth,
                            )),
                      ],
                    );
                  }),

                  // ─── Cross-module links ──────────────────
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
                  if (_currentUserId != null)
                    _buildCrossModuleLink(
                      icon: Icons.verified_user_rounded,
                      label: sw
                          ? 'Angalia kama chanjo inalipiwa na bima'
                          : 'Check if vaccination is covered by insurance',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => InsuranceModule(userId: _currentUserId!))),
                    ),
                  _buildCrossModuleLink(
                    icon: Icons.chat_rounded,
                    label: sw
                        ? 'Uliza Shangazi kuhusu madhara ya chanjo'
                        : 'Ask Shangazi about vaccine side effects',
                    onTap: () => Navigator.pushNamed(context, '/chat/0'),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  bool get _hasUrgentVaccines {
    final now = DateTime.now();
    return _vaccinations.any((v) {
      if (v.isDone) return false;
      if (v.isOverdueWithDob(widget.baby.dateOfBirth)) return true;
      final dueDate = v.effectiveDueDate(widget.baby.dateOfBirth);
      if (dueDate == null) return false;
      return dueDate.difference(now).inDays <= 7;
    });
  }

  Widget _buildPostVaccinationTip(bool sw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw
                      ? 'Mtoto anaweza kupata homa ndogo. Paracetamol ya watoto inapatikana dukani.'
                      : 'Baby may have mild fever. Infant paracetamol available at pharmacy.',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PharmacyModule(userId: _currentUserId!))),
            child: Text(
              sw ? 'Nenda duka la dawa >' : 'Go to pharmacy >',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
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
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? const Color(0xFF666666)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildRchCardPreview(bool sw) {
    return GestureDetector(
      onTap: _snapRchCard,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _rchCardPhoto!.displayUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade100,
                child: Icon(Icons.broken_image_rounded,
                    size: 32, color: Colors.grey.shade300),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: _kPrimary.withValues(alpha: 0.7),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      sw ? 'Kadi ya RCH' : 'RCH Card',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      sw ? 'Bonyeza kubadilisha' : 'Tap to update',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, bool sw) {
    const monthsSw = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final months = sw ? monthsSw : monthsEn;
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
