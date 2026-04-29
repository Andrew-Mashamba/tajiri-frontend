// lib/my_parents/pages/medication_manager_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import '../services/parents_notification_helper.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFEF5350);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kWarning = Color(0xFFFFA726);

class MedicationManagerPage extends StatefulWidget {
  final Parent parent;

  const MedicationManagerPage({super.key, required this.parent});

  @override
  State<MedicationManagerPage> createState() => _MedicationManagerPageState();
}

class _MedicationManagerPageState extends State<MedicationManagerPage> {
  final MyParentsService _service = MyParentsService();
  String? _token;
  bool _isLoading = true;
  List<ParentMedication> _medications = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.getMedications(_token!, widget.parent.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _medications = result.items;
          _scheduleRefillAndMissedDoseAlerts();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Imeshindikana kupakia dawa'
            : 'Failed to load medications')),
      );
    }
  }

  /// Fire-and-forget: check refill thresholds and schedule missed dose alerts.
  void _scheduleRefillAndMissedDoseAlerts() {
    final sw = _sw;
    final parentId = widget.parent.id;
    final parentName = widget.parent.name;

    for (final med in _medications.where((m) => m.isActive)) {
      // Refill alert if pills running low
      try {
        if (med.pillsRemaining != null &&
            med.refillThreshold != null &&
            med.pillsRemaining! <= med.refillThreshold!) {
          ParentsNotificationHelper.scheduleRefillAlert(
            parentId,
            parentName,
            med.name,
            med.pillsRemaining!,
            sw,
          );
        }
      } catch (_) {}

      // Schedule missed dose alerts (30 min after each dose time)
      try {
        for (final slot in med.timeSlots) {
          final parts = slot.split(':');
          if (parts.length == 2) {
            final h = int.tryParse(parts[0]) ?? 8;
            final m = int.tryParse(parts[1]) ?? 0;
            final now = DateTime.now();
            var doseTime = DateTime(now.year, now.month, now.day, h, m);
            if (doseTime.isAfter(now)) {
              // Schedule missed dose alert 30 min after dose time
              ParentsNotificationHelper.scheduleMissedDoseAlert(
                parentId,
                parentName,
                med.name,
                sw,
                doseTime: doseTime,
              );
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _logDose(ParentMedication med) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    try {
      final newPills = (med.pillsRemaining != null && med.pillsPerDose != null)
          ? (med.pillsRemaining! - med.pillsPerDose!).clamp(0, 999999)
          : null;
      final result = await _service.updateMedication(
        token: _token!,
        medicationId: med.id,
        pillsRemaining: newPills,
      );
      if (!mounted) return;
      if (result.success) {
        // Record adherence date in SharedPreferences
        _recordAdherenceDate(med.id);
        messenger.showSnackBar(
          SnackBar(content: Text(sw
              ? 'Dozi imerekodiwa'
              : 'Dose logged successfully')),
        );
        _loadMedications();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ??
              (sw ? 'Imeshindwa' : 'Failed'))),
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

  Future<void> _deleteMedication(ParentMedication med) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa dawa?' : 'Delete medication?'),
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
      final result = await _service.deleteMedication(token: _token!, medicationId: med.id);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Dawa imefutwa' : 'Medication deleted')),
        );
        _loadMedications();
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

  void _showMedicationOptions(ParentMedication med) {
    final sw = _sw;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              med.name,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: _kPrimary),
              title: Text(sw ? 'Hariri' : 'Edit',
                  style: const TextStyle(fontSize: 14, color: _kPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddMedicationSheet(existing: med);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: _kDanger),
              title: Text(sw ? 'Futa' : 'Delete',
                  style: const TextStyle(fontSize: 14, color: _kDanger)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMedication(med);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showAddMedicationSheet({ParentMedication? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '');
    final doctorCtrl = TextEditingController(text: existing?.prescribingDoctor ?? '');
    final pillsRemainingCtrl = TextEditingController(
        text: existing?.pillsRemaining?.toString() ?? '');
    final pillsPerDoseCtrl = TextEditingController(
        text: existing?.pillsPerDose?.toString() ?? '');
    final refillCtrl = TextEditingController(
        text: existing?.refillThreshold?.toString() ?? '');
    String frequency = existing?.frequency ?? 'daily';
    List<String> timeSlots = existing?.timeSlots.isNotEmpty == true
        ? List<String>.from(existing!.timeSlots)
        : ['08:00'];
    DateTime startDate = existing?.startDate ?? DateTime.now();
    final sw = _sw;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
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
                    isEdit
                        ? (sw ? 'Hariri Dawa' : 'Edit Medication')
                        : (sw ? 'Ongeza Dawa' : 'Add Medication'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  const SizedBox(height: 16),
                  _SheetTextField(
                    controller: nameCtrl,
                    label: sw ? 'Jina la dawa' : 'Medication name',
                  ),
                  const SizedBox(height: 12),
                  _SheetTextField(
                    controller: dosageCtrl,
                    label: sw ? 'Kipimo (mfano: 500mg)' : 'Dosage (e.g. 500mg)',
                  ),
                  const SizedBox(height: 12),
                  Text(sw ? 'Marudio' : 'Frequency',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: frequency,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: 'daily', child: Text(sw ? 'Kila siku' : 'Daily')),
                          DropdownMenuItem(value: 'twice_daily', child: Text(sw ? 'Mara 2 kwa siku' : 'Twice daily')),
                          DropdownMenuItem(value: 'thrice_daily', child: Text(sw ? 'Mara 3 kwa siku' : 'Three times daily')),
                          DropdownMenuItem(value: 'weekly', child: Text(sw ? 'Kila wiki' : 'Weekly')),
                        ],
                        onChanged: (v) {
                          if (v != null) setSheetState(() => frequency = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time slots
                  Text(sw ? 'Nyakati za kumeza' : 'Time slots',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...timeSlots.asMap().entries.map((entry) => Chip(
                            label: Text(entry.value,
                                style: const TextStyle(fontSize: 12, color: _kPrimary)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 16),
                            onDeleted: timeSlots.length > 1
                                ? () => setSheetState(() => timeSlots.removeAt(entry.key))
                                : null,
                            backgroundColor: _kPrimary.withValues(alpha: 0.06),
                            side: BorderSide.none,
                          )),
                      ActionChip(
                        label: Text(sw ? '+ Ongeza' : '+ Add',
                            style: const TextStyle(fontSize: 12, color: _kPrimary)),
                        backgroundColor: _kPrimary.withValues(alpha: 0.04),
                        side: BorderSide.none,
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            final formatted =
                                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            setSheetState(() => timeSlots.add(formatted));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SheetTextField(
                          controller: pillsRemainingCtrl,
                          label: sw ? 'Vidonge vilivyobaki' : 'Pills remaining',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SheetTextField(
                          controller: pillsPerDoseCtrl,
                          label: sw ? 'Vidonge kwa dozi' : 'Pills per dose',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SheetTextField(
                    controller: refillCtrl,
                    label: sw ? 'Kiwango cha onyo (vidonge)' : 'Refill threshold (pills)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _SheetTextField(
                    controller: doctorCtrl,
                    label: sw ? 'Daktari aliyeandika' : 'Prescribing doctor',
                  ),
                  const SizedBox(height: 12),
                  // Start date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setSheetState(() => startDate = picked);
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
                            '${sw ? 'Tarehe ya kuanza: ' : 'Start date: '}'
                            '${startDate.day}/${startDate.month}/${startDate.year}',
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
                        if (isEdit) {
                          _updateExistingMedication(
                            ctx,
                            medicationId: existing.id,
                            name: nameCtrl.text.trim(),
                            dosage: dosageCtrl.text.trim(),
                            frequency: frequency,
                            timeSlots: timeSlots,
                            startDate: startDate,
                            prescribingDoctor: doctorCtrl.text.trim(),
                            pillsRemaining: int.tryParse(pillsRemainingCtrl.text.trim()),
                            pillsPerDose: int.tryParse(pillsPerDoseCtrl.text.trim()),
                            refillThreshold: int.tryParse(refillCtrl.text.trim()),
                          );
                        } else {
                          _saveMedication(
                            ctx,
                            name: nameCtrl.text.trim(),
                            dosage: dosageCtrl.text.trim(),
                            frequency: frequency,
                            timeSlots: timeSlots,
                            startDate: startDate,
                            prescribingDoctor: doctorCtrl.text.trim(),
                            pillsRemaining: int.tryParse(pillsRemainingCtrl.text.trim()),
                            pillsPerDose: int.tryParse(pillsPerDoseCtrl.text.trim()),
                            refillThreshold: int.tryParse(refillCtrl.text.trim()),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                          isEdit
                              ? (sw ? 'Sasisha' : 'Update')
                              : (sw ? 'Hifadhi' : 'Save'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      nameCtrl.dispose();
      dosageCtrl.dispose();
      doctorCtrl.dispose();
      pillsRemainingCtrl.dispose();
      pillsPerDoseCtrl.dispose();
      refillCtrl.dispose();
    });
  }

  Future<void> _saveMedication(
    BuildContext sheetContext, {
    required String name,
    required String dosage,
    required String frequency,
    required List<String> timeSlots,
    required DateTime startDate,
    String? prescribingDoctor,
    int? pillsRemaining,
    int? pillsPerDose,
    int? refillThreshold,
  }) async {
    if (name.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Jina na kipimo vinahitajika'
            : 'Name and dosage are required')),
      );
      return;
    }
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    Navigator.pop(sheetContext);

    try {
      final result = await _service.addMedication(
        token: _token!,
        parentId: widget.parent.id,
        name: name,
        dosage: dosage,
        frequency: frequency,
        timeSlots: timeSlots,
        startDate: startDate,
        prescribingDoctor: prescribingDoctor?.isNotEmpty == true ? prescribingDoctor : null,
        pillsRemaining: pillsRemaining,
        pillsPerDose: pillsPerDose,
        refillThreshold: refillThreshold,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Dawa imeongezwa' : 'Medication added')),
        );
        // Schedule medication dose reminders for each time slot
        if (timeSlots.isNotEmpty) {
          for (final slot in timeSlots) {
            final parts = slot.split(':');
            if (parts.length == 2) {
              final h = int.tryParse(parts[0]) ?? 8;
              final m = int.tryParse(parts[1]) ?? 0;
              final now = DateTime.now();
              var doseTime = DateTime(now.year, now.month, now.day, h, m);
              if (doseTime.isBefore(now)) doseTime = doseTime.add(const Duration(days: 1));
              ParentsNotificationHelper.scheduleMedicationDoseReminder(
                widget.parent.id,
                widget.parent.name,
                name,
                dosage,
                doseTime,
                sw,
              );
            }
          }
        }
        _loadMedications();
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

  Future<void> _updateExistingMedication(
    BuildContext sheetContext, {
    required int medicationId,
    required String name,
    required String dosage,
    required String frequency,
    required List<String> timeSlots,
    required DateTime startDate,
    String? prescribingDoctor,
    int? pillsRemaining,
    int? pillsPerDose,
    int? refillThreshold,
  }) async {
    if (name.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text(_sw
            ? 'Jina na kipimo vinahitajika'
            : 'Name and dosage are required')),
      );
      return;
    }
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    Navigator.pop(sheetContext);

    try {
      final result = await _service.updateMedication(
        token: _token!,
        medicationId: medicationId,
        name: name,
        dosage: dosage,
        frequency: frequency,
        timeSlots: timeSlots,
        prescribingDoctor: prescribingDoctor?.isNotEmpty == true ? prescribingDoctor : null,
        pillsRemaining: pillsRemaining,
        pillsPerDose: pillsPerDose,
        refillThreshold: refillThreshold,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Dawa imesasishwa' : 'Medication updated')),
        );
        _loadMedications();
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

  // ─── Adherence Tracking ─────────────────────────────────────────
  static const _adherencePrefix = 'med_adherence_';

  Future<Set<String>> _getAdherenceDates(int medId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dates = prefs.getStringList('$_adherencePrefix$medId') ?? [];
      return dates.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _recordAdherenceDate(int medId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_adherencePrefix$medId';
      final dates = prefs.getStringList(key) ?? [];
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (!dates.contains(todayStr)) {
        dates.add(todayStr);
        await prefs.setStringList(key, dates);
      }
    } catch (_) {}
  }

  // ─── Side Effects Tracking ───────────────────────────────────────
  static const _sideEffectPrefix = 'med_side_effect_';

  Future<List<String>> _getSideEffects(int medId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('$_sideEffectPrefix$medId') ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSideEffect(int medId, String effect) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_sideEffectPrefix$medId';
      final effects = prefs.getStringList(key) ?? [];
      final timestamp = DateTime.now();
      final entry = '${timestamp.day}/${timestamp.month} - $effect';
      effects.insert(0, entry);
      await prefs.setStringList(key, effects);
    } catch (_) {}
  }

  void _showAddSideEffectSheet(ParentMedication med) {
    final ctrl = TextEditingController();
    final sw = _sw;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
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
              sw ? 'Rekodi Madhara ya ${med.name}' : 'Log Side Effect for ${med.name}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            _SheetTextField(
              controller: ctrl,
              label: sw ? 'Eleza madhara (mfano: kichefuchefu, kizunguzungu)' : 'Describe side effect (e.g. nausea, dizziness)',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(sw
                          ? 'Tafadhali eleza madhara'
                          : 'Please describe the side effect')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _saveSideEffect(med.id, text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw
                        ? 'Madhara yamerekodiwa'
                        : 'Side effect recorded')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                    sw ? 'Hifadhi' : 'Save',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => ctrl.dispose());
  }

  void _showMedicationDetail(ParentMedication med) {
    final sw = _sw;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      med.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildAdherenceBadge(med, sw),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${med.dosage} - ${_frequencyLabel(med.frequency, sw)}',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // Adherence calendar placeholder (last 30 days)
              Text(sw ? 'Utiifu (Siku 30 zilizopita)' : 'Adherence (Last 30 days)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
              const SizedBox(height: 10),
              _buildAdherenceCalendarAsync(med.id),
              const SizedBox(height: 20),

              // Side effects log
              Row(
                children: [
                  Expanded(
                    child: Text(sw ? 'Madhara' : 'Side Effects Log',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddSideEffectSheet(med);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sw ? '+ Ongeza' : '+ Add',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<String>>(
                future: _getSideEffects(med.id),
                builder: (context, snapshot) {
                  final effects = snapshot.data ?? [];
                  if (effects.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sw ? 'Hakuna madhara yaliyorekodiwa' : 'No side effects recorded',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Column(
                    children: effects.map((e) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kWarning.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kWarning.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: _kWarning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(e,
                                style: const TextStyle(fontSize: 12, color: _kPrimary),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Details
              if (med.prescribingDoctor != null && med.prescribingDoctor!.isNotEmpty) ...[
                _DetailRow(label: sw ? 'Daktari' : 'Doctor', value: med.prescribingDoctor!),
                const SizedBox(height: 8),
              ],
              if (med.pillsRemaining != null)
                _DetailRow(
                    label: sw ? 'Vidonge vilivyobaki' : 'Pills remaining',
                    value: '${med.pillsRemaining}'),
              if (med.startDate != null) ...[
                const SizedBox(height: 8),
                _DetailRow(
                    label: sw ? 'Tarehe ya kuanza' : 'Start date',
                    value: '${med.startDate!.day}/${med.startDate!.month}/${med.startDate!.year}'),
              ],
              if (med.timeSlots.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DetailRow(
                    label: sw ? 'Nyakati' : 'Times',
                    value: med.timeSlots.join(', ')),
              ],
              const SizedBox(height: 24),

              // Cross-module links
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Navigate to doctor module for side effects
                        try {
                          Navigator.pushNamed(context, '/doctor');
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.medical_services_rounded, size: 16),
                      label: Text(sw ? 'Daktari' : 'Doctor',
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Navigate to Shangazi AI (via chat) for medication questions
                        try {
                          Navigator.pushNamed(context, '/chat/0');
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.smart_toy_rounded, size: 16),
                      label: Text('Shangazi AI',
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdherenceCalendarAsync(int medId) {
    return FutureBuilder<Set<String>>(
      future: _getAdherenceDates(medId),
      builder: (context, snapshot) {
        final adherenceDates = snapshot.data ?? {};
        final now = DateTime.now();
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(30, (i) {
            final day = now.subtract(Duration(days: 29 - i));
            final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final isFuture = day.isAfter(now);
            final taken = adherenceDates.contains(dayStr);
            return Tooltip(
              message: '${day.day}/${day.month}${taken ? ' \u2713' : ''}',
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isFuture
                      ? _kPrimary.withValues(alpha: 0.02)
                      : taken
                          ? _kSuccess.withValues(alpha: 0.15)
                          : _kPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isFuture
                        ? _kSecondary.withValues(alpha: 0.3)
                        : taken
                            ? _kSuccess
                            : _kSecondary,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAdherenceBadge(ParentMedication med, bool sw) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        sw ? 'Inaendelea' : 'Active',
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: _kSuccess),
      ),
    );
  }

  String _frequencyLabel(String frequency, bool sw) {
    switch (frequency) {
      case 'daily':
        return sw ? 'Kila siku' : 'Daily';
      case 'twice_daily':
        return sw ? 'Mara 2/siku' : 'Twice daily';
      case 'thrice_daily':
        return sw ? 'Mara 3/siku' : 'Three times daily';
      case 'weekly':
        return sw ? 'Kila wiki' : 'Weekly';
      default:
        return frequency;
    }
  }

  bool _needsRefill(ParentMedication med) {
    if (med.pillsRemaining == null || med.refillThreshold == null) return false;
    return med.pillsRemaining! <= med.refillThreshold!;
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final activeMeds = _medications.where((m) => m.isActive).toList();

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
          '${widget.parent.name} - ${sw ? 'Dawa' : 'Medications'}',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationSheet,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadMedications,
              color: _kPrimary,
              child: activeMeds.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Icon(Icons.medication_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          sw ? 'Hakuna dawa zilizorekodiwa' : 'No medications recorded',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sw ? 'Bonyeza + kuongeza dawa' : 'Tap + to add a medication',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: activeMeds.length,
                      itemBuilder: (ctx, i) => _buildMedicationCard(activeMeds[i], sw),
                    ),
            ),
    );
  }

  Widget _buildMedicationCard(ParentMedication med, bool sw) {
    final refill = _needsRefill(med);
    return GestureDetector(
      onTap: () => _showMedicationDetail(med),
      onLongPress: () => _showMedicationOptions(med),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: refill
              ? Border.all(color: _kWarning.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication_rounded, size: 20, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${med.dosage} - ${_frequencyLabel(med.frequency, sw)}',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildAdherenceBadge(med, sw),
              ],
            ),
            if (med.timeSlots.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${sw ? 'Dozi ijayo: ' : 'Next dose: '}${med.timeSlots.first}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (refill) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, size: 14, color: _kWarning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sw
                            ? 'Vidonge ${med.pillsRemaining} vimebaki - Jaza dawa!'
                            : '${med.pillsRemaining} pills remaining - Refill needed!',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: _kWarning),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        try {
                          Navigator.pushNamed(context, '/shop');
                        } catch (_) {}
                      },
                      child: Text(
                        sw ? 'Duka la Dawa' : 'Pharmacy',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _logDose(med),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text(
                  sw ? 'Rekodi dozi' : 'Log dose taken',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kSuccess,
                  side: BorderSide(color: _kSuccess.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _SheetTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
