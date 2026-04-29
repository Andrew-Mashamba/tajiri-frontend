// lib/my_children/pages/health_log_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../config/api_config.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/event_service.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../services/children_notification_helper.dart';
import '../services/my_children_service.dart';
import '../../doctor/doctor_module.dart';
import '../../pharmacy/pharmacy_module.dart';
import '../../insurance/insurance_module.dart';
import '../../calendar/services/calendar_service.dart';
import '../../calendar/models/calendar_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ─── Health log types ─────────────────────────────────────────────

class _LogType {
  final String key;
  final String labelEn;
  final String labelSw;
  final IconData icon;

  const _LogType({
    required this.key,
    required this.labelEn,
    required this.labelSw,
    required this.icon,
  });

  String label(bool sw) => sw ? labelSw : labelEn;
}

const List<_LogType> _logTypes = [
  _LogType(key: 'temperature', labelEn: 'Temperature', labelSw: 'Joto', icon: Icons.thermostat_rounded),
  _LogType(key: 'medication', labelEn: 'Medication', labelSw: 'Dawa', icon: Icons.medication_rounded),
  _LogType(key: 'illness', labelEn: 'Illness', labelSw: 'Ugonjwa', icon: Icons.sick_rounded),
  _LogType(key: 'allergy', labelEn: 'Allergy', labelSw: 'Mzio', icon: Icons.warning_amber_rounded),
  _LogType(key: 'doctor_visit', labelEn: 'Doctor Visit', labelSw: 'Kumtembelea Daktari', icon: Icons.local_hospital_rounded),
  _LogType(key: 'dental_visit', labelEn: 'Dental', labelSw: 'Meno', icon: Icons.mood_rounded),
];

// ─── Page ─────────────────────────────────────────────────────────

class HealthLogPage extends StatefulWidget {
  final Baby baby;

  const HealthLogPage({super.key, required this.baby});

  @override
  State<HealthLogPage> createState() => _HealthLogPageState();
}

class _HealthLogPageState extends State<HealthLogPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  List<HealthLog> _logs = [];
  String? _token;
  int? _currentUserId;
  String? _errorMessage;
  String? _filterType;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _currentUserId = LocalStorageService.instanceSync?.getUser()?.userId;
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.getHealthHistory(
        _token!,
        widget.baby.id,
        type: _filterType,
      );
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _logs = result.items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddForm(_LogType logType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HealthLogForm(
        logType: logType,
        baby: widget.baby,
        token: _token ?? '',
        service: _service,
        isSwahili: _sw,
        onSaved: () {
          Navigator.pop(ctx);
          _loadLogs();
        },
      ),
    );
  }

  void _confirmDeleteHealthLog(HealthLog log) {
    if (log.id == null) return;
    final sw = _sw;
    final label = log.title;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa?' : 'Delete?'),
        content: Text(sw ? 'Futa "$label"?' : 'Delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteHealthLog(_token!, log.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imefutwa' : 'Deleted')),
                  );
                  _loadLogs();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imeshindikana kufuta' : 'Failed to delete')),
                  );
                }
              }
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  _LogType _logTypeForKey(String key) {
    return _logTypes.firstWhere(
      (t) => t.key == key,
      orElse: () => _logTypes.first,
    );
  }

  Widget _buildRecommendedCheckups(bool sw) {
    final now = DateTime.now();
    final ageDays = now.difference(widget.baby.dateOfBirth).inDays;
    final ageYears = ageDays ~/ 365;

    // Determine recommended interval in days
    int intervalDays;
    String intervalLabel;
    if (ageYears < 5) {
      intervalDays = 180; // every 6 months
      intervalLabel = sw ? 'kila miezi 6' : 'every 6 months';
    } else if (ageYears < 12) {
      intervalDays = 365; // annual
      intervalLabel = sw ? 'kila mwaka' : 'annually';
    } else {
      intervalDays = 365; // annual
      intervalLabel = sw ? 'kila mwaka' : 'annually';
    }

    // Find last doctor visit
    final doctorVisits = _logs.where((l) => l.type == 'doctor_visit').toList();
    DateTime? lastVisit;
    if (doctorVisits.isNotEmpty) {
      doctorVisits.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      lastVisit = doctorVisits.first.loggedAt;
    }

    final nextRecommended = lastVisit != null
        ? lastVisit.add(Duration(days: intervalDays))
        : now;
    final isOverdue = nextRecommended.isBefore(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isOverdue
              ? const Color(0xFFFFF3E0) // amber tint
              : _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: isOverdue
              ? Border.all(color: const Color(0xFFFF9800), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isOverdue
                    ? const Color(0xFFFF9800).withValues(alpha: 0.15)
                    : _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOverdue
                    ? Icons.warning_amber_rounded
                    : Icons.health_and_safety_rounded,
                size: 20,
                color: isOverdue ? const Color(0xFFE65100) : _kPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Uchunguzi Unaoshauriwa' : 'Recommended Checkup',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOverdue
                        ? (sw
                            ? 'Uchunguzi umechelewa! ($intervalLabel)'
                            : 'Checkup overdue! ($intervalLabel)')
                        : (sw
                            ? 'Uchunguzi ujao: ${nextRecommended.day}/${nextRecommended.month}/${nextRecommended.year}'
                            : 'Next checkup: ${nextRecommended.day}/${nextRecommended.month}/${nextRecommended.year}'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue
                          ? const Color(0xFFE65100)
                          : _kSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ageYears >= 5 && ageYears <= 7) ...[
                    const SizedBox(height: 2),
                    Text(
                      sw
                          ? 'Pia: Uchunguzi wa macho'
                          : 'Also: Vision test recommended',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          sw ? 'Rekodi ya Afya' : 'Health Log',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick-add buttons
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: _logTypes.map((lt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 68,
                      child: _QuickAddButton(
                        icon: lt.icon,
                        label: lt.label(sw),
                        onTap: () => _showAddForm(lt),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: sw ? 'Zote' : 'All',
                    isSelected: _filterType == null,
                    onTap: () {
                      setState(() => _filterType = null);
                      _loadLogs();
                    },
                  ),
                  ..._logTypes.map((lt) => _FilterChip(
                        label: lt.label(sw),
                        isSelected: _filterType == lt.key,
                        onTap: () {
                          setState(() => _filterType = lt.key);
                          _loadLogs();
                        },
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Recommended checkups (Partial 19)
            _buildRecommendedCheckups(sw),

            // Cross-module contextual links
            _buildHealthCrossModuleLinks(sw),

            // History list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary))
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14, color: _kSecondary),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _loadLogs,
                                  child: Text(sw ? 'Jaribu tena' : 'Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _logs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.health_and_safety_rounded,
                                      size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    sw
                                        ? 'Bado hakuna rekodi za afya'
                                        : 'No health records yet',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadLogs,
                              color: _kPrimary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                itemCount: _logs.length,
                                itemBuilder: (_, i) {
                                  final log = _logs[i];
                                  final lt = _logTypeForKey(log.type);
                                  return GestureDetector(
                                    onLongPress: () => _confirmDeleteHealthLog(log),
                                    child: _HealthLogItem(
                                      log: log,
                                      logType: lt,
                                      isSwahili: sw,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Health cross-module links ────────────────────────────────

  bool get _hasMedicationEntries =>
      _logs.any((l) => l.type == 'medication');

  bool get _hasDoctorVisitEntries =>
      _logs.any((l) => l.type == 'doctor_visit');

  bool get _hasFeverEntries {
    for (final l in _logs) {
      if (l.type == 'temperature' && l.value != null) {
        final temp = double.tryParse(l.value!.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (temp != null && temp > 38.5) return true;
      }
    }
    return false;
  }

  Widget _buildHealthCrossModuleLinks(bool sw) {
    if (_currentUserId == null) return const SizedBox.shrink();
    final userId = _currentUserId!;

    final links = <Widget>[];

    if (_hasFeverEntries) {
      links.add(_buildCrossModuleLink(
        icon: Icons.local_hospital_rounded,
        label: sw
            ? 'Homa ikiendelea, tembeleana daktari'
            : 'If fever persists, see a doctor',
        iconColor: Colors.red.shade400,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DoctorModule(userId: userId))),
      ));
    }

    if (_hasMedicationEntries) {
      links.add(_buildCrossModuleLink(
        icon: Icons.medication_rounded,
        label: sw ? 'Jaza tena dawa duka la dawa' : 'Refill at pharmacy',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PharmacyModule(userId: userId))),
      ));
    }

    if (_hasDoctorVisitEntries) {
      links.add(_buildCrossModuleLink(
        icon: Icons.receipt_long_rounded,
        label: sw ? 'Daiwa kwenye bima' : 'Claim on insurance',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => InsuranceModule(userId: userId))),
      ));
    }

    links.add(_buildCrossModuleLink(
      icon: Icons.chat_rounded,
      label: sw
          ? 'Uliza Shangazi kuhusu dalili za mtoto'
          : 'Ask Shangazi about child\'s symptoms',
      onTap: () => Navigator.pushNamed(context, '/chat/0'),
    ));

    links.add(_buildCrossModuleLink(
      icon: Icons.calendar_month_rounded,
      label: sw
          ? 'Weka tarehe za ziara kwenye kalenda'
          : 'Sync doctor visits to calendar',
      onTap: () => _syncDoctorVisitsToCalendar(),
    ));

    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Viunganishi' : 'Related',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ...links,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _syncDoctorVisitsToCalendar() {
    try {
      final calService = CalendarService();
      for (final log in _logs) {
        if (log.type != 'doctor_visit') continue;
        calService.createEvent(CalendarEvent(
          id: 0,
          userId: widget.baby.userId,
          title: '${log.title} - ${widget.baby.name}',
          date: log.loggedAt,
          isAllDay: true,
          source: EventSource.doctor,
        ));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw ? 'Imewekwa kwenye kalenda' : 'Synced to calendar')),
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
}

// ─── Quick Add Button ─────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: _kPrimary),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? _kPrimary : _kCardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Health Log Item ──────────────────────────────────────────────

class _HealthLogItem extends StatelessWidget {
  final HealthLog log;
  final _LogType logType;
  final bool isSwahili;

  const _HealthLogItem({
    required this.log,
    required this.logType,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(log.icon, size: 18, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (log.value != null && log.value!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.value!,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (log.description != null &&
                    log.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.description!,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${log.loggedAt.day}/${log.loggedAt.month}/${log.loggedAt.year}  ${log.loggedAt.hour.toString().padLeft(2, '0')}:${log.loggedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              logType.label(isSwahili),
              style: const TextStyle(fontSize: 10, color: _kSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Health Log Form (Bottom Sheet) ───────────────────────────────

class _HealthLogForm extends StatefulWidget {
  final _LogType logType;
  final Baby baby;
  final String token;
  final MyChildrenService service;
  final bool isSwahili;
  final VoidCallback onSaved;

  const _HealthLogForm({
    required this.logType,
    required this.baby,
    required this.token,
    required this.service,
    required this.isSwahili,
    required this.onSaved,
  });

  @override
  State<_HealthLogForm> createState() => _HealthLogFormState();
}

class _HealthLogFormState extends State<_HealthLogForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Common fields
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  DateTime _logDate = DateTime.now();

  // Medication-specific fields
  String _medFrequency = 'once_daily';
  DateTime? _medStartDate;
  DateTime? _medEndDate;

  // Doctor visit follow-up date (Missing 45)
  DateTime? _followUpDate;

  bool get sw => widget.isSwahili;

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _logDate,
      firstDate: widget.baby.dateOfBirth,
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _logDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      String title = _titleController.text.trim();
      String? value = _valueController.text.trim();
      String? desc = _descriptionController.text.trim();

      // Build title from type-specific fields
      if (widget.logType.key == 'temperature') {
        title = '${sw ? 'Joto' : 'Temperature'}: ${value.isNotEmpty ? value : '-'}°C';
        value = '${value.isNotEmpty ? value : '0'}°C';
      }

      // Append medication metadata to description
      if (widget.logType.key == 'medication') {
        final freqLabels = {
          'once_daily': sw ? 'Mara moja kwa siku' : 'Once daily',
          'twice_daily': sw ? 'Mara mbili kwa siku' : 'Twice daily',
          'three_times': sw ? 'Mara tatu kwa siku' : 'Three times daily',
          'as_needed': sw ? 'Inapohitajika' : 'As needed',
        };
        final parts = <String>[];
        parts.add('${sw ? 'Mara' : 'Freq'}: ${freqLabels[_medFrequency] ?? _medFrequency}');
        if (_medStartDate != null) {
          parts.add('${sw ? 'Kuanza' : 'Start'}: ${_medStartDate!.day}/${_medStartDate!.month}/${_medStartDate!.year}');
        }
        if (_medEndDate != null) {
          parts.add('${sw ? 'Kumaliza' : 'End'}: ${_medEndDate!.day}/${_medEndDate!.month}/${_medEndDate!.year}');
        }
        final medMeta = parts.join(' | ');
        desc = desc.isNotEmpty ? '$medMeta\n$desc' : medMeta;
      }

      if (title.isEmpty) {
        title = widget.logType.label(sw);
      }

      final result = await widget.service.logHealth(
        token: widget.token,
        babyId: widget.baby.id,
        type: widget.logType.key,
        title: title,
        value: value.isNotEmpty ? value : null,
        description: desc.isNotEmpty ? desc : null,
        loggedAt: _logDate,
      );

      if (!mounted) return;

      if (result.success) {
        // Missing 50: Track medical expense
        final cost = double.tryParse(_costController.text.trim()) ?? 0;
        if (cost > 0 &&
            (widget.logType.key == 'doctor_visit' ||
                widget.logType.key == 'medication')) {
          ExpenditureService.recordExpenditure(
            token: widget.token,
            amount: cost,
            category: 'afya',
            description: '${widget.baby.name}: $title',
            referenceId:
                'child_health_${widget.baby.id}_${DateTime.now().millisecondsSinceEpoch}',
            sourceModule: 'my_children',
          ).then((_) {}).catchError((_) {});

          // Fire-and-forget: schedule medical expense notification
          ChildrenNotificationHelper.scheduleMedicalExpenseAlert(
            widget.baby.id,
            widget.baby.name,
            cost,
            isSwahili: sw,
          ).catchError((_) {});
        }

        // Missing 45: Schedule follow-up reminder + calendar event
        if (widget.logType.key == 'doctor_visit' && _followUpDate != null) {
          // Schedule reminder via backend
          http.post(
            Uri.parse('${ApiConfig.baseUrl}/my-baby/reminders/checkup'),
            headers: ApiConfig.authHeaders(widget.token),
            body: jsonEncode({
              'child_id': widget.baby.id,
              'remind_at': _followUpDate!.toIso8601String(),
            }),
          ).then((_) {}).catchError((_) {});

          // Sync to TAJIRI Calendar
          final userId = LocalStorageService.instanceSync?.getUser()?.userId;
          if (userId != null) {
            EventService().createEvent(
              creatorId: userId,
              name: sw
                  ? 'Ufuatiliaji wa daktari - ${widget.baby.name}'
                  : 'Doctor follow-up - ${widget.baby.name}',
              startDate: _followUpDate!,
              description: title,
              isAllDay: true,
              category: 'health',
            ).then((_) {}).catchError((_) {});
          }

          // Feature 45: Schedule local push notifications for doctor visit
          _scheduleDoctorVisitNotifications(
            childName: widget.baby.name,
            appointmentDate: _followUpDate!,
            childId: widget.baby.id,
            isSwahili: sw,
          );
        }

        // Also schedule notifications for any future-dated doctor visit log
        if (widget.logType.key == 'doctor_visit' &&
            _logDate.isAfter(DateTime.now())) {
          _scheduleDoctorVisitNotifications(
            childName: widget.baby.name,
            appointmentDate: _logDate,
            childId: widget.baby.id,
            isSwahili: sw,
          );
        }

        // Centralized follow-up reminder via helper
        if (widget.logType.key == 'doctor_visit' && _followUpDate != null) {
          ChildrenNotificationHelper.scheduleFollowUpReminder(
            widget.baby.id, widget.baby.name, _followUpDate!, sw,
          ).catchError((_) {});
        }

        // Schedule medication reminders via centralized helper
        if (widget.logType.key == 'medication' &&
            _medFrequency != 'as_needed') {
          final medName = _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : (sw ? 'Dawa' : 'Medication');
          final dosage = _valueController.text.trim().isNotEmpty
              ? _valueController.text.trim()
              : '';
          // Schedule next dose based on frequency
          final int intervalHours;
          switch (_medFrequency) {
            case 'three_times':
              intervalHours = 8;
              break;
            case 'twice_daily':
              intervalHours = 12;
              break;
            default:
              intervalHours = 24;
          }
          final nextDose =
              DateTime.now().add(Duration(hours: intervalHours));
          // Only schedule if within medication end date
          if (_medEndDate == null || nextDose.isBefore(_medEndDate!)) {
            ChildrenNotificationHelper.scheduleMedicationReminder(
              widget.baby.id, widget.baby.name, medName, dosage, nextDose, sw,
            ).catchError((_) {});
          }
        }

        messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Imehifadhiwa!' : 'Saved!'),
        ));
        widget.onSaved();
      } else {
        setState(() => _isSaving = false);
        messenger.showSnackBar(SnackBar(
          content: Text(result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save')),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred'),
      ));
    }
  }

  /// Schedule local notifications for a doctor appointment.
  /// 1 day before + 2 hours before (if appointment has time component).
  void _scheduleDoctorVisitNotifications({
    required String childName,
    required DateTime appointmentDate,
    required int childId,
    required bool isSwahili,
  }) {
    try {
      tz_data.initializeTimeZones();
      final flnp = FlutterLocalNotificationsPlugin();
      final now = DateTime.now();
      // Unique base ID from timestamp + child ID
      final baseId =
          (appointmentDate.millisecondsSinceEpoch ~/ 1000 + childId) &
              0x7FFFFFFF;

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

      // 1 day before
      final oneDayBefore =
          appointmentDate.subtract(const Duration(days: 1));
      if (oneDayBefore.isAfter(now)) {
        flnp
            .zonedSchedule(
              baseId,
              isSwahili
                  ? 'Kikumbusho cha Daktari'
                  : 'Doctor Appointment Reminder',
              isSwahili
                  ? 'Kikumbusho: Miadi ya daktari kwa $childName kesho'
                  : 'Reminder: Doctor appointment for $childName tomorrow',
              tz.TZDateTime.from(oneDayBefore, tz.local),
              details,
              androidScheduleMode:
                  AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            )
            .catchError((_) {});
      }

      // 2 hours before (only if appointment has a non-midnight time)
      final hasTime =
          appointmentDate.hour != 0 || appointmentDate.minute != 0;
      if (hasTime) {
        final twoHoursBefore =
            appointmentDate.subtract(const Duration(hours: 2));
        if (twoHoursBefore.isAfter(now)) {
          flnp
              .zonedSchedule(
                baseId + 1,
                isSwahili
                    ? 'Miadi ya Daktari'
                    : 'Doctor Appointment Soon',
                isSwahili
                    ? 'Miadi ya daktari kwa $childName baada ya saa 2'
                    : 'Doctor appointment for $childName in 2 hours',
                tz.TZDateTime.from(twoHoursBefore, tz.local),
                details,
                androidScheduleMode:
                    AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
              )
              .catchError((_) {});
        }
      }
    } catch (_) {
      // Best-effort notification scheduling
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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
              Row(
                children: [
                  Icon(widget.logType.icon, size: 22, color: _kPrimary),
                  const SizedBox(width: 10),
                  Text(
                    widget.logType.label(sw),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type-specific fields
              ..._buildFields(),

              const SizedBox(height: 16),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
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
                        '${_logDate.day}/${_logDate.month}/${_logDate.year}',
                        style: const TextStyle(
                            fontSize: 14, color: _kPrimary),
                      ),
                      const Spacer(),
                      Text(
                        sw ? 'Badilisha tarehe' : 'Change date',
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
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
      ),
    );
  }

  List<Widget> _buildFields() {
    switch (widget.logType.key) {
      case 'temperature':
        return [
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Joto (°C)' : 'Temperature (°C)',
            hint: sw ? 'Mfano: 37.5' : 'e.g. 37.5',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return sw ? 'Tafadhali ingiza joto' : 'Please enter temperature';
              }
              final num = double.tryParse(v);
              if (num == null || num < 30 || num > 45) {
                return sw ? 'Joto lisilo sahihi' : 'Invalid temperature';
              }
              return null;
            },
          ),
        ];

      case 'medication':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Jina la dawa' : 'Medication name',
            hint: sw ? 'Mfano: Paracetamol' : 'e.g. Paracetamol',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Kipimo' : 'Dosage',
            hint: sw ? 'Mfano: 5ml' : 'e.g. 5ml',
          ),
          const SizedBox(height: 12),
          // Frequency dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _medFrequency,
              decoration: InputDecoration(
                labelText: sw ? 'Mara ngapi' : 'Frequency',
                labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'once_daily',
                  child: Text(sw ? 'Mara moja kwa siku' : 'Once daily'),
                ),
                DropdownMenuItem(
                  value: 'twice_daily',
                  child: Text(sw ? 'Mara mbili kwa siku' : 'Twice daily'),
                ),
                DropdownMenuItem(
                  value: 'three_times',
                  child: Text(sw ? 'Mara tatu kwa siku' : 'Three times daily'),
                ),
                DropdownMenuItem(
                  value: 'as_needed',
                  child: Text(sw ? 'Inapohitajika' : 'As needed'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _medFrequency = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Start date
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _medStartDate ?? DateTime.now(),
                firstDate: widget.baby.dateOfBirth,
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: sw ? 'Tarehe ya kuanza' : 'Start date',
              );
              if (picked != null && mounted) {
                setState(() => _medStartDate = picked);
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
                      size: 16, color: _kSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _medStartDate != null
                        ? '${sw ? 'Kuanza' : 'Start'}: ${_medStartDate!.day}/${_medStartDate!.month}/${_medStartDate!.year}'
                        : (sw ? 'Tarehe ya kuanza (hiari)' : 'Start date (optional)'),
                    style: TextStyle(
                      fontSize: 13,
                      color: _medStartDate != null ? _kPrimary : _kSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // End date
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _medEndDate ?? (_medStartDate ?? DateTime.now()),
                firstDate: _medStartDate ?? widget.baby.dateOfBirth,
                lastDate: DateTime.now().add(const Duration(days: 365)),
                helpText: sw ? 'Tarehe ya kumaliza' : 'End date',
              );
              if (picked != null && mounted) {
                setState(() => _medEndDate = picked);
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
                  const Icon(Icons.event_rounded,
                      size: 16, color: _kSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _medEndDate != null
                        ? '${sw ? 'Kumaliza' : 'End'}: ${_medEndDate!.day}/${_medEndDate!.month}/${_medEndDate!.year}'
                        : (sw ? 'Tarehe ya kumaliza (hiari)' : 'End date (optional)'),
                    style: TextStyle(
                      fontSize: 13,
                      color: _medEndDate != null ? _kPrimary : _kSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Missing 50: Cost field for medication
          _buildTextField(
            controller: _costController,
            label: sw ? 'Gharama (TZS) - hiari' : 'Cost (TZS) - optional',
            hint: sw ? 'Mfano: 15000' : 'e.g. 15000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Maelezo' : 'Notes',
            hint: sw ? 'Maelezo ya ziada' : 'Additional notes',
            maxLines: 2,
          ),
        ];

      case 'illness':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Jina la ugonjwa' : 'Illness name',
            hint: sw ? 'Mfano: Homa' : 'e.g. Fever',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Dalili' : 'Symptoms',
            hint: sw ? 'Eleza dalili' : 'Describe symptoms',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Matibabu na matokeo' : 'Treatment & outcome',
            hint: sw ? 'Matibabu yaliyotolewa' : 'Treatment given',
            maxLines: 2,
          ),
        ];

      case 'allergy':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Kitu kinachosababisha mzio' : 'Allergen',
            hint: sw ? 'Mfano: Maziwa' : 'e.g. Milk',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Majibu ya mwili' : 'Reaction',
            hint: sw ? 'Eleza dalili za mzio' : 'Describe the reaction',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Ukali' : 'Severity',
            hint: sw ? 'Kidogo / Wastani / Kali' : 'Mild / Moderate / Severe',
          ),
        ];

      case 'doctor_visit':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Sababu ya ziara' : 'Visit reason',
            hint: sw ? 'Mfano: Uchunguzi wa kawaida' : 'e.g. Routine checkup',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Uchunguzi' : 'Diagnosis',
            hint: sw ? 'Matokeo ya daktari' : "Doctor's findings",
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Dawa na ufuatiliaji' : 'Prescription & follow-up',
            hint: sw ? 'Dawa zilizotolewa' : 'Medications prescribed',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          // Missing 50: Cost field
          _buildTextField(
            controller: _costController,
            label: sw ? 'Gharama (TZS) - hiari' : 'Cost (TZS) - optional',
            hint: sw ? 'Mfano: 50000' : 'e.g. 50000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          // Missing 45: Follow-up date picker
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
                helpText: sw ? 'Tarehe ya ufuatiliaji' : 'Follow-up date',
              );
              if (picked != null && mounted) {
                setState(() => _followUpDate = picked);
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
                  const Icon(Icons.event_repeat_rounded,
                      size: 16, color: _kSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _followUpDate != null
                          ? '${sw ? 'Ufuatiliaji' : 'Follow-up'}: ${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                          : (sw ? 'Tarehe ya ufuatiliaji (hiari)' : 'Follow-up date (optional)'),
                      style: TextStyle(
                        fontSize: 13,
                        color: _followUpDate != null ? _kPrimary : _kSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];

      case 'dental_visit':
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Aina ya ziara' : 'Visit Type',
            hint: sw
                ? 'Uchunguzi / Kusafisha / Kujaza / Braces / Kung\'oa'
                : 'Checkup / Cleaning / Filling / Braces / Extraction',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _valueController,
            label: sw ? 'Jina la daktari wa meno' : 'Dentist Name',
            hint: sw ? 'Mfano: Dk. Mwangi' : 'e.g. Dr. Mwangi',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Maelezo' : 'Notes',
            hint: sw ? 'Maelezo ya ziada' : 'Additional notes',
            maxLines: 2,
          ),
        ];

      default:
        return [
          _buildTextField(
            controller: _titleController,
            label: sw ? 'Kichwa' : 'Title',
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: sw ? 'Maelezo' : 'Description',
            maxLines: 3,
          ),
        ];
    }
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return sw ? 'Sehemu hii inahitajika' : 'This field is required';
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _kPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: _kCardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
      ),
    );
  }
}
