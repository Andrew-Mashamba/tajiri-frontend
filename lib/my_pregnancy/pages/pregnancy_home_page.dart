// lib/my_pregnancy/pages/pregnancy_home_page.dart
import 'package:flutter/material.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';
import '../widgets/week_progress_card.dart';
import '../../my_baby/my_baby_module.dart';
import '../../my_baby/services/my_baby_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/event_service.dart';
import 'pregnancy_week_page.dart';
import 'kick_counter_page.dart';
import 'anc_schedule_page.dart';
import 'danger_signs_page.dart';
import 'contraction_timer_page.dart';
import 'weight_tracker_page.dart';
import 'nutrition_guide_page.dart';
import 'birth_plan_page.dart';
import 'mood_tracker_page.dart';
import 'pregnancy_journal_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class PregnancyHomePage extends StatefulWidget {
  final int userId;
  const PregnancyHomePage({super.key, required this.userId});
  @override
  State<PregnancyHomePage> createState() => _PregnancyHomePageState();
}

class _PregnancyHomePageState extends State<PregnancyHomePage> {
  final MyPregnancyService _service = MyPregnancyService();

  bool _isLoading = true;
  Pregnancy? _pregnancy;
  WeekInfo? _weekInfo;
  List<AncVisit> _ancVisits = [];

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  bool get _sw =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final pregnancyResult =
          await _service.getMyPregnancy(widget.userId, token: _token);

      Pregnancy? pregnancy;
      WeekInfo? weekInfo;
      List<AncVisit> ancVisits = [];

      if (pregnancyResult.success && pregnancyResult.data != null) {
        pregnancy = pregnancyResult.data;
        if (pregnancy!.isActive) {
          final weekResult =
              await _service.getWeekInfo(pregnancy.currentWeek, token: _token);
          if (weekResult.success) weekInfo = weekResult.data;

          final ancResult =
              await _service.getAncSchedule(pregnancy.id, token: _token);
          if (ancResult.success) ancVisits = ancResult.items;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _pregnancy = pregnancy;
          _weekInfo = weekInfo;
          _ancVisits = ancVisits;
        });

        // Fire-and-forget notification check
        _service.checkPregnancyNotifications(widget.userId, token: _token);
        // Fire-and-forget calendar sync
        _syncToCalendar();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sw
                ? 'Imeshindwa kupakia data: $e'
                : 'Failed to load data: $e'),
          ),
        );
      }
    }
  }

  Future<void> _syncToCalendar() async {
    if (_pregnancy == null || !_pregnancy!.isActive) return;
    try {
      final eventService = EventService();
      final sw = _sw;

      // Sync due date
      if (_pregnancy!.dueDate != null &&
          _pregnancy!.dueDate!.isAfter(DateTime.now())) {
        await eventService.createEvent(
          creatorId: widget.userId,
          name: sw ? 'Tarehe ya Kujifungua' : 'Expected Due Date',
          startDate: _pregnancy!.dueDate!,
          description: sw
              ? 'Tarehe inayotarajiwa ya kujifungua'
              : 'Your expected delivery date',
          isAllDay: true,
          privacy: 'private',
          category: 'health',
        );
      }

      // Sync all upcoming ANC visits
      for (final visit in _ancVisits) {
        if (!visit.isDone &&
            visit.scheduledDate != null &&
            visit.scheduledDate!.isAfter(DateTime.now())) {
          await eventService.createEvent(
            creatorId: widget.userId,
            name: sw
                ? 'Kliniki ya ANC #${visit.visitNumber}'
                : 'ANC Visit #${visit.visitNumber}',
            startDate: visit.scheduledDate!,
            description: sw
                ? 'Ziara ya kliniki ya ujauzito'
                : 'Prenatal clinic visit',
            isAllDay: true,
            privacy: 'private',
            category: 'health',
          );
        }
      }
    } catch (_) {
      // Silent — calendar sync is non-critical
    }
  }

  void _startTracking() {
    _showCreatePregnancyDialog();
  }

  void _showCreatePregnancyDialog() {
    final sw = _sw;
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 30));
    final nameController = TextEditingController();
    final preWeightController = TextEditingController();
    String? gender;
    bool useDueDate = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw
                          ? 'Anza Kufuatilia Ujauzito'
                          : 'Start Tracking Pregnancy',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      useDueDate
                          ? (sw
                              ? 'Weka tarehe ya kujifungua ili tuweze kukokotoa wiki.'
                              : 'Enter your due date so we can calculate your weeks.')
                          : (sw
                              ? 'Weka tarehe ya hedhi yako ya mwisho ili tuweze kukokotoa wiki na tarehe ya kujifungua.'
                              : 'Enter your last period date so we can calculate your weeks and due date.'),
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                    const SizedBox(height: 16),
                    // Toggle: LMP vs Due Date
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(
                            sw ? 'Najua tarehe ya hedhi' : 'I know my LMP',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(
                            sw ? 'Najua tarehe ya kujifungua' : 'I know my due date',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      selected: {useDueDate},
                      onSelectionChanged: (v) {
                        setSheetState(() {
                          useDueDate = v.first;
                          // Reset date to a sensible default
                          if (useDueDate) {
                            selectedDate = DateTime.now().add(const Duration(days: 200));
                          } else {
                            selectedDate = DateTime.now().subtract(const Duration(days: 30));
                          }
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: _kPrimary.withValues(alpha: 0.12),
                        selectedForegroundColor: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: useDueDate
                              ? DateTime.now()
                              : DateTime.now().subtract(const Duration(days: 300)),
                          lastDate: useDueDate
                              ? DateTime.now().add(const Duration(days: 300))
                              : DateTime.now(),
                          helpText: useDueDate
                              ? (sw ? 'Chagua tarehe ya kujifungua' : 'Select due date')
                              : (sw ? 'Chagua tarehe ya hedhi ya mwisho' : 'Select last period date'),
                          cancelText: sw ? 'Ghairi' : 'Cancel',
                          confirmText: sw ? 'Chagua' : 'Select',
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: _kSecondary),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  useDueDate
                                      ? (sw ? 'Tarehe ya Kujifungua' : 'Due Date')
                                      : (sw ? 'Tarehe ya Hedhi ya Mwisho' : 'Last Period Date'),
                                  style: const TextStyle(
                                      fontSize: 11, color: _kSecondary),
                                ),
                                Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Baby name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: sw
                            ? 'Jina la Mtoto (si lazima)'
                            : 'Baby Name (optional)',
                        labelStyle:
                            const TextStyle(fontSize: 13, color: _kSecondary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Pre-pregnancy weight (optional)
                    TextField(
                      controller: preWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: sw
                            ? 'Uzito kabla ya ujauzito (kg) - si lazima'
                            : 'Pre-pregnancy weight (kg) - optional',
                        hintText: sw ? 'Mfano: 60' : 'e.g. 60',
                        labelStyle:
                            const TextStyle(fontSize: 13, color: _kSecondary),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Gender
                    Row(
                      children: [
                        Text(sw ? 'Jinsia:' : 'Gender:',
                            style: const TextStyle(
                                fontSize: 13, color: _kSecondary)),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: Text(sw ? 'Mvulana' : 'Boy'),
                          selected: gender == 'male',
                          onSelected: (v) =>
                              setSheetState(() => gender = v ? 'male' : null),
                          selectedColor: _kPrimary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: gender == 'male' ? _kPrimary : _kSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(sw ? 'Msichana' : 'Girl'),
                          selected: gender == 'female',
                          onSelected: (v) =>
                              setSheetState(() => gender = v ? 'female' : null),
                          selectedColor: _kPrimary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: gender == 'female' ? _kPrimary : _kSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          // Calculate LMP from due date if needed
                          DateTime lmpDate = selectedDate;
                          if (useDueDate) {
                            lmpDate = selectedDate.subtract(const Duration(days: 280));
                          }
                          final preWeight = double.tryParse(
                              preWeightController.text.trim());
                          Navigator.pop(ctx);
                          await _createPregnancy(
                            lmpDate,
                            nameController.text.trim().isEmpty
                                ? null
                                : nameController.text.trim(),
                            gender,
                            prePregnancyWeightKg: preWeight,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                            sw ? 'Anza Kufuatilia' : 'Start Tracking',
                            style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createPregnancy(
      DateTime lastPeriod, String? name, String? gender,
      {double? prePregnancyWeightKg}) async {
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    try {
      final result = await _service.createPregnancy(
        userId: widget.userId,
        lastPeriodDate: lastPeriod,
        babyName: name,
        babyGender: gender,
        prePregnancyWeightKg: prePregnancyWeightKg,
        token: _token,
      );
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(sw
                  ? 'Umefanikiwa kuanza kufuatilia ujauzito'
                  : 'Successfully started tracking pregnancy')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw
                      ? 'Imeshindwa kuanza kufuatilia'
                      : 'Failed to start tracking'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(sw ? 'Kosa: $e' : 'Error: $e')),
      );
    }
  }

  // ─── Baby is Born ─────────────────────────────────────────────

  void _showBabyIsBornDialog() {
    final sw = _sw;
    DateTime deliveryDate = DateTime.now();
    String deliveryType = 'normal';
    final weightController = TextEditingController();
    final nameController = TextEditingController(
      text: _pregnancy?.babyName ?? '',
    );
    String? gender = _pregnancy?.babyGender;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Mtoto Amezaliwa!' : 'Baby is Born!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sw
                        ? 'Hongera! Jaza taarifa za kuzaliwa kwa mtoto.'
                        : 'Congratulations! Fill in the birth details.',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Delivery date
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: deliveryDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                        helpText: sw ? 'Tarehe ya kuzaliwa' : 'Date of birth',
                        cancelText: sw ? 'Ghairi' : 'Cancel',
                        confirmText: sw ? 'Chagua' : 'Select',
                      );
                      if (picked != null) {
                        setSheetState(() => deliveryDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: _kSecondary),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sw
                                    ? 'Tarehe ya Kuzaliwa'
                                    : 'Date of Birth',
                                style: const TextStyle(
                                    fontSize: 11, color: _kSecondary),
                              ),
                              Text(
                                '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Delivery type
                  Text(sw ? 'Njia ya Kujifungua:' : 'Delivery Method:',
                      style:
                          const TextStyle(fontSize: 13, color: _kSecondary)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'normal',
                        label: Text(sw ? 'Kawaida' : 'Natural'),
                        icon: const Icon(Icons.favorite_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: 'caesarean',
                        label: Text(sw ? 'Upasuaji' : 'Caesarean'),
                        icon: const Icon(Icons.medical_services_rounded,
                            size: 16),
                      ),
                    ],
                    selected: {deliveryType},
                    onSelectionChanged: (v) =>
                        setSheetState(() => deliveryType = v.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor:
                          _kPrimary.withValues(alpha: 0.12),
                      selectedForegroundColor: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Baby name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: sw
                          ? 'Jina la Mtoto (si lazima)'
                          : 'Baby Name (optional)',
                      labelStyle:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Gender
                  Row(
                    children: [
                      Text(sw ? 'Jinsia:' : 'Gender:',
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: Text(sw ? 'Mvulana' : 'Boy'),
                        selected: gender == 'male',
                        onSelected: (v) =>
                            setSheetState(() => gender = v ? 'male' : null),
                        selectedColor: _kPrimary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: gender == 'male' ? _kPrimary : _kSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(sw ? 'Msichana' : 'Girl'),
                        selected: gender == 'female',
                        onSelected: (v) =>
                            setSheetState(() => gender = v ? 'female' : null),
                        selectedColor: _kPrimary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: gender == 'female' ? _kPrimary : _kSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Weight
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: sw
                          ? 'Uzito wa Kuzaliwa (gramu)'
                          : 'Birth Weight (grams)',
                      hintText: sw ? 'Mfano: 3200' : 'e.g. 3200',
                      labelStyle:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              // Pop sheet first before running the flow
                              Navigator.pop(ctx);
                              await _completeBabyIsBorn(
                                deliveryDate: deliveryDate,
                                deliveryType: deliveryType,
                                babyName: nameController.text.trim().isEmpty
                                    ? null
                                    : nameController.text.trim(),
                                babyGender: gender,
                                babyWeightGrams:
                                    int.tryParse(weightController.text.trim()),
                              );
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              sw ? 'Hifadhi na Endelea' : 'Save & Continue',
                              style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeBabyIsBorn({
    required DateTime deliveryDate,
    required String deliveryType,
    String? babyName,
    String? babyGender,
    int? babyWeightGrams,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sw = _sw;

    try {
      // 1. Update pregnancy status to 'delivered'
      if (_pregnancy != null) {
        await _service.updatePregnancy(
          pregnancyId: _pregnancy!.id,
          status: 'delivered',
          deliveryType: deliveryType,
          deliveryDate: deliveryDate,
          babyWeightGrams: babyWeightGrams,
          babyGender: babyGender,
          babyName: babyName,
          token: _token,
        );
      }

      // 2. Register baby in the postnatal module
      final babyService = MyBabyService();
      final babyResult = await babyService.registerBaby(
        token: _token ?? '',
        userId: widget.userId,
        name: babyName ?? (sw ? 'Mtoto' : 'Baby'),
        dateOfBirth: deliveryDate,
        gender: babyGender,
        birthWeightGrams: babyWeightGrams,
      );

      if (!mounted) return;

      if (babyResult.success) {
        // Fire-and-forget: transfer ANC history to baby health log
        if (babyResult.data != null) {
          final babyId = babyResult.data!.id;
          final token = _token ?? '';

          // Transfer completed ANC visits
          for (final visit in _ancVisits.where((v) => v.isDone)) {
            babyService.logHealth(
              token: token,
              babyId: babyId,
              type: 'doctor_visit',
              title: 'ANC Visit #${visit.visitNumber}',
              description:
                  'Facility: ${visit.facility ?? "N/A"}\nNotes: ${visit.notes ?? "N/A"}',
              loggedAt: visit.completedDate ?? visit.scheduledDate,
            ).catchError((_) => null as dynamic);
          }

          // Transfer birth weight as first growth measurement
          if (babyWeightGrams != null && babyWeightGrams > 0) {
            babyService.logGrowth(
              token: token,
              babyId: babyId,
              weightKg: babyWeightGrams / 1000.0,
              measuredAt: deliveryDate,
              notes: sw ? 'Uzito wa kuzaliwa' : 'Birth weight',
            ).catchError((_) => null as dynamic);
          }
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text(sw
                ? 'Hongera kwa kuzaliwa kwa mtoto wako! Karibu kwenye My Baby.'
                : 'Congratulations on the birth of your baby! Welcome to My Baby.'),
            backgroundColor: _kPrimary,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to baby module
        navigator.push(
          MaterialPageRoute(
            builder: (_) => MyBabyModule(userId: widget.userId),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(babyResult.message ??
                (sw
                    ? 'Imeshindwa kusajili mtoto. Jaribu tena.'
                    : 'Failed to register baby. Try again.')),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(sw ? 'Kosa: $e' : 'Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // If has active pregnancy
          if (_pregnancy != null && _pregnancy!.isActive) ...[
            WeekProgressCard(
              pregnancy: _pregnancy!,
              isSwahili: sw,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PregnancyWeekPage(
                    pregnancy: _pregnancy!,
                    weekInfo: _weekInfo,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick actions — 2 rows of 4
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.touch_app_rounded,
                    label: sw ? 'Hesabu Mateke' : 'Kick Counter',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            KickCounterPage(pregnancy: _pregnancy!),
                      ),
                    ).then((_) {
                      if (mounted) _loadData();
                    }),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.calendar_month_rounded,
                    label: sw ? 'Kliniki (ANC)' : 'ANC Clinic',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AncSchedulePage(
                          pregnancy: _pregnancy!,
                          visits: _ancVisits,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) _loadData();
                    }),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.warning_rounded,
                    label: sw ? 'Dalili za Hatari' : 'Danger Signs',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DangerSignsPage(),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.timer_rounded,
                    label: sw ? 'Uchungu' : 'Contractions',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ContractionTimerPage(pregnancy: _pregnancy!),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.monitor_weight_rounded,
                    label: sw ? 'Uzito' : 'Weight',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeightTrackerPage(
                          pregnancy: _pregnancy!,
                          prePregnancyWeightKg:
                              _pregnancy!.prePregnancyWeightKg,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.restaurant_rounded,
                    label: sw ? 'Lishe' : 'Nutrition',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NutritionGuidePage(),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.assignment_rounded,
                    label: sw ? 'Mpango Kuzaa' : 'Birth Plan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BirthPlanPage(pregnancy: _pregnancy!),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.mood_rounded,
                    label: sw ? 'Hali ya Hisia' : 'Mood',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MoodTrackerPage(pregnancy: _pregnancy!),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 62) / 4,
                  child: _QuickAction(
                    icon: Icons.book_rounded,
                    label: sw ? 'Daftari' : 'Journal',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PregnancyJournalPage(
                          pregnancy: _pregnancy!,
                          userId: widget.userId,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // "Baby is Born" button — visible when >= 36 weeks
            if (_pregnancy!.currentWeek >= 36) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _showBabyIsBornDialog,
                  icon: const Icon(Icons.child_friendly_rounded, size: 22),
                  label: Text(
                    sw ? 'Mtoto Amezaliwa!' : 'Baby is Born!',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kPrimary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Next ANC visit
            ..._buildNextAncReminder(sw),

            // Weekly tip
            if (_weekInfo != null && _weekInfo!.motherTips.isNotEmpty) ...[
              Text(
                sw ? 'Ushauri wa Wiki Hii' : "This Week's Tip",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 20, color: _kSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _weekInfo!.motherTips,
                        style:
                            const TextStyle(fontSize: 13, color: _kSecondary),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Emergency banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.emergency_rounded,
                      color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Dharura? Piga 112 au nenda hospitali ya karibu.'
                          : 'Emergency? Call 112 or go to the nearest hospital.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // "Baby is Born" — also visible as text link for < 36 weeks
            if (_pregnancy!.currentWeek < 36)
              Center(
                child: TextButton(
                  onPressed: _showBabyIsBornDialog,
                  child: Text(
                    sw
                        ? 'Mtoto amezaliwa mapema?'
                        : 'Baby born early?',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],

          // No pregnancy — empty state
          if (_pregnancy == null || !_pregnancy!.isActive) ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pregnant_woman_rounded,
                        size: 56, color: _kPrimary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    sw ? 'Ujauzito Wangu' : 'My Pregnancy',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      sw
                          ? 'Fuatilia ujauzito wako, hesabu mateke, kumbuka kliniki, na ujue dalili za hatari.'
                          : 'Track your pregnancy, count kicks, remember clinic visits, and learn danger signs.',
                      style:
                          const TextStyle(fontSize: 14, color: _kSecondary),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: FilledButton(
                      onPressed: _startTracking,
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        sw ? 'Anza Kufuatilia' : 'Start Tracking',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],

          // Related services
          if (_pregnancy != null && _pregnancy!.isActive) ...[
            Text(
              sw ? 'Huduma Zinazohusiana' : 'Related Services',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary),
            ),
            const SizedBox(height: 10),
            _CrossModuleLink(
              icon: Icons.medical_services_rounded,
              title: sw ? 'Daktari wa Uzazi' : 'Obstetrician',
              subtitle: sw
                  ? 'Pata ushauri wa daktari wa uzazi'
                  : 'Get advice from an obstetrician',
              onTap: () => _tryNavigate('/doctor'),
            ),
            _CrossModuleLink(
              icon: Icons.local_pharmacy_rounded,
              title: sw ? 'Duka la Dawa' : 'Pharmacy',
              subtitle: sw
                  ? 'Vitamini na dawa za ujauzito'
                  : 'Pregnancy vitamins and medications',
              onTap: () => _tryNavigate('/pharmacy'),
            ),
            _CrossModuleLink(
              icon: Icons.health_and_safety_rounded,
              title: sw ? 'Bima ya Afya (NHIF)' : 'Health Insurance (NHIF)',
              subtitle: sw
                  ? 'Bima ya uzazi na kujifungua'
                  : 'Maternity and delivery insurance',
              onTap: () => _tryNavigate('/insurance'),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildNextAncReminder(bool sw) {
    final nextVisit = _ancVisits
        .where((v) => !v.isDone)
        .toList()
      ..sort((a, b) {
        if (a.scheduledDate == null) return 1;
        if (b.scheduledDate == null) return -1;
        return a.scheduledDate!.compareTo(b.scheduledDate!);
      });

    if (nextVisit.isEmpty) return [];

    final visit = nextVisit.first;
    final isOverdue = visit.isOverdue;

    return [
      Text(
        sw ? 'Kliniki Ijayo' : 'Next Clinic Visit',
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AncSchedulePage(
              pregnancy: _pregnancy!,
              visits: _ancVisits,
            ),
          ),
        ).then((_) {
          if (mounted) _loadData();
        }),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isOverdue ? Colors.red.shade50 : _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: isOverdue
                ? Border.all(color: Colors.red.shade200)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? Colors.red.shade100
                      : _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: isOverdue ? Colors.red.shade700 : _kPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw
                          ? 'Kliniki ya ${visit.visitNumber}'
                          : 'Visit ${visit.visitNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    if (visit.scheduledDate != null)
                      Text(
                        isOverdue
                            ? '${sw ? "Imechelewa" : "Overdue"} - ${_formatDate(visit.scheduledDate!, sw)}'
                            : _formatDate(visit.scheduledDate!, sw),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isOverdue ? Colors.red.shade700 : _kSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isOverdue ? Colors.red.shade700 : _kSecondary,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  void _tryNavigate(String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (_) {
      final sw = _sw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sw
              ? 'Huduma hii itapatikana hivi karibuni'
              : 'This service will be available soon'),
        ),
      );
    }
  }

  String _formatDate(DateTime date, bool sw) {
    if (sw) {
      const months = [
        'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
        'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}

// ─── Quick Action Button ──────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cross-Module Link ────────────────────────────────────────

class _CrossModuleLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CrossModuleLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style:
                            const TextStyle(fontSize: 11, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: _kSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
