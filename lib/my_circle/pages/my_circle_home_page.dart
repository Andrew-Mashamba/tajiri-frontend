// lib/my_circle/pages/my_circle_home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_circle_models.dart';
import '../services/my_circle_service.dart';
import '../../services/event_service.dart';
import '../widgets/cycle_status_card.dart';
import '../../my_pregnancy/services/my_pregnancy_service.dart';
import '../../my_pregnancy/my_pregnancy_module.dart';
import '../../screens/groups/groups_screen.dart';
import 'cycle_calendar_page.dart';
import 'log_day_page.dart';
import 'insights_page.dart';
import 'contraception_page.dart';
import 'partner_sharing_page.dart';
import '../../insurance/insurance_module.dart';
import '../../doctor/doctor_module.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class MyCircleHomePage extends StatefulWidget {
  final int userId;
  const MyCircleHomePage({super.key, required this.userId});
  @override
  State<MyCircleHomePage> createState() => _MyCircleHomePageState();
}

class _MyCircleHomePageState extends State<MyCircleHomePage> {
  final MyCircleService _service = MyCircleService();

  CyclePrediction? _prediction;
  List<CycleDay> _recentDays = [];
  List<ContraceptionReminder> _reminders = [];
  Map<String, dynamic>? _partnerData;
  bool _isLoading = true;

  // Tracking state
  bool _isTracking = true;
  String? _stopReason;
  String? _pregnancyStartDate;
  String? _estimatedDueDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final results = await Future.wait([
      _service.getPredictions(widget.userId),
      _service.getCycleDays(userId: widget.userId, month: now.month, year: now.year),
      _service.getContraceptionReminders(widget.userId),
      _service.viewPartnerCycle(widget.userId),
      _service.getSettings(widget.userId),
    ]);
    if (mounted) {
      final predResult = results[0] as CircleResult<CyclePrediction>;
      final daysResult = results[1] as CircleListResult<CycleDay>;
      final remindersResult = results[2] as CircleListResult<ContraceptionReminder>;
      final partnerView = results[3] as CircleResult<Map<String, dynamic>>;
      final settingsResult = results[4] as CircleResult<Map<String, dynamic>>;
      setState(() {
        _isLoading = false;
        _prediction = predResult.success ? predResult.data : CyclePrediction();
        if (daysResult.success) _recentDays = daysResult.items;
        if (remindersResult.success) _reminders = remindersResult.items;
        _partnerData = (partnerView.success && partnerView.data != null) ? partnerView.data : null;
        if (settingsResult.success && settingsResult.data != null) {
          _isTracking = settingsResult.data!['is_tracking'] ?? true;
          _stopReason = settingsResult.data!['stop_reason'] as String?;
          _pregnancyStartDate = settingsResult.data!['pregnancy_start_date'] as String?;
          _estimatedDueDate = settingsResult.data!['estimated_due_date'] as String?;
        }
      });
      // Fire-and-forget notification check
      _service.checkNotifications(widget.userId);
      // Fire-and-forget: sync cycle dates to TAJIRI calendar
      _syncToCalendar();
    }
  }

  Future<void> _syncToCalendar() async {
    if (_prediction == null || !_prediction!.hasData) return;
    try {
      final eventService = EventService();
      final pred = _prediction!;

      // Sync next period (if in the future)
      if (pred.nextPeriodDate != null && pred.nextPeriodDate!.isAfter(DateTime.now())) {
        await eventService.createEvent(
          creatorId: widget.userId,
          name: _isSwahili ? 'Hedhi Inatarajiwa' : 'Period Expected',
          startDate: pred.nextPeriodDate!,
          description: _isSwahili
              ? 'Duru yako ya hedhi inatarajiwa kuanza'
              : 'Your menstrual period is expected to start',
          isAllDay: true,
          privacy: 'private',
          category: 'health',
        );
      }

      // Sync ovulation day
      if (pred.ovulationDate != null && pred.ovulationDate!.isAfter(DateTime.now())) {
        await eventService.createEvent(
          creatorId: widget.userId,
          name: _isSwahili ? 'Siku ya Ovulesheni' : 'Ovulation Day',
          startDate: pred.ovulationDate!,
          description: _isSwahili
              ? 'Siku yako ya ovulesheni inatarajiwa'
              : 'Your ovulation day is expected',
          isAllDay: true,
          privacy: 'private',
          category: 'health',
        );
      }

      // Sync fertile window start
      if (pred.fertileWindowStart != null && pred.fertileWindowStart!.isAfter(DateTime.now())) {
        await eventService.createEvent(
          creatorId: widget.userId,
          name: _isSwahili ? 'Kipindi cha Rutuba Kinaanza' : 'Fertile Window Starts',
          startDate: pred.fertileWindowStart!,
          description: _isSwahili
              ? 'Kipindi chako cha rutuba kinaanza leo'
              : 'Your fertile window starts today',
          isAllDay: true,
          privacy: 'private',
          category: 'health',
        );
      }
    } catch (_) {
      // Silent — calendar sync is non-critical
    }
  }

  String _formatDate(DateTime dt) => DateFormat('d MMM yyyy').format(dt);

  Future<void> _shareWithDoctor() async {
    final pred = _prediction;
    if (pred == null) return;

    final summary = StringBuffer();
    summary.writeln('=== MY CYCLE REPORT / RIPOTI YA DURU YANGU ===');
    summary.writeln('');
    summary.writeln('Cycle length / Urefu wa duru: ${pred.cycleLength} days / siku');
    summary.writeln('Period length / Urefu wa hedhi: ${pred.periodLength} days / siku');
    if (pred.nextPeriodDate != null) {
      summary.writeln('Next period / Hedhi ijayo: ${_formatDate(pred.nextPeriodDate!)}');
    }
    if (pred.ovulationDate != null) {
      summary.writeln('Ovulation / Ovulesheni: ${_formatDate(pred.ovulationDate!)}');
    }
    if (pred.fertileWindowStart != null && pred.fertileWindowEnd != null) {
      summary.writeln('Fertile window / Dirisha la rutuba: ${_formatDate(pred.fertileWindowStart!)} - ${_formatDate(pred.fertileWindowEnd!)}');
    }

    // Recent symptoms
    if (_recentDays.any((d) => d.symptoms.isNotEmpty)) {
      summary.writeln('');
      summary.writeln('Recent symptoms / Dalili za hivi karibuni:');
      final frequency = <Symptom, int>{};
      for (final day in _recentDays) {
        for (final s in day.symptoms) {
          frequency[s] = (frequency[s] ?? 0) + 1;
        }
      }
      final sorted = frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted.take(5)) {
        summary.writeln('  - ${e.key.displayName()}: ${e.value}x');
      }
    }

    summary.writeln('');
    summary.writeln('Sent from TAJIRI / Imetumwa kutoka TAJIRI');

    await SharePlus.instance.share(ShareParams(text: summary.toString()));
  }

  int? get _currentCycleDay {
    if (_prediction?.nextPeriodDate == null) return null;
    final cycleLen = _prediction!.cycleLength;
    final daysUntil = _prediction!.daysUntilNextPeriod;
    if (daysUntil < 0) return null;
    return cycleLen - daysUntil;
  }

  void _nav(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadData();
  }

  Future<void> _handleSetup(int cycleLength, int periodLength, DateTime lastPeriod) async {
    final dateStr = '${lastPeriod.year}-${lastPeriod.month.toString().padLeft(2, '0')}-${lastPeriod.day.toString().padLeft(2, '0')}';
    final result = await _service.saveSettings(
      userId: widget.userId,
      cycleLength: cycleLength,
      periodLength: periodLength,
      lastPeriodDate: dateStr,
    );
    if (mounted) {
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? (AppStringsScope.maybeOf(context)?.isSwahili == true ? 'Imeshindwa kuhifadhi' : 'Failed to save settings'))),
        );
      }
      _loadData();
    }
  }

  void _showSettingsSheet() async {
    final settingsResult = await _service.getSettings(widget.userId);
    if (!mounted) return;
    final currentSettings = settingsResult.success && settingsResult.data != null
        ? settingsResult.data!
        : <String, dynamic>{'cycle_length': 28, 'period_length': 5, 'last_period_date': null};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CycleSettingsSheet(
        initialCycleLength: (currentSettings['cycle_length'] as num?)?.toInt() ?? 28,
        initialPeriodLength: (currentSettings['period_length'] as num?)?.toInt() ?? 5,
        onSave: (cycleLen, periodLen) async {
          Navigator.pop(ctx);
          final result = await _service.saveSettings(
            userId: widget.userId,
            cycleLength: cycleLen,
            periodLength: periodLen,
          );
          if (mounted) {
            if (result.success) {
              final sw2 = AppStringsScope.maybeOf(context)?.isSwahili ?? false;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(sw2 ? 'Mipangilio imehifadhiwa' : 'Settings saved')),
              );
            }
            _loadData();
          }
        },
      ),
    );
  }

  bool get _isSwahili => AppStringsScope.maybeOf(context)?.isSwahili ?? false;

  void _showStopTrackingDialog(bool isPregnancy) {
    final sw = _isSwahili;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isPregnancy
              ? (sw ? 'Hongera!' : 'Congratulations!')
              : (sw ? 'Simamisha Ufuatiliaji?' : 'Pause Tracking?'),
          style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        content: Text(
          isPregnancy
              ? (sw
                  ? 'Tutasimamisha ufuatiliaji wa duru na kuhamisha taarifa kwa Baby tab kuanza kufuatilia ujauzito wako.'
                  : 'We\'ll pause cycle tracking and transfer your info to the Baby tab to start tracking your pregnancy.')
              : (sw
                  ? 'Unaweza kuendelea kufuatilia wakati wowote.'
                  : 'You can resume tracking at any time.'),
          style: const TextStyle(color: _kSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _stopTracking(isPregnancy ? 'pregnant' : 'paused');
            },
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(isPregnancy ? (sw ? 'Endelea' : 'Continue') : (sw ? 'Simamisha' : 'Pause')),
          ),
        ],
      ),
    );
  }

  Future<void> _stopTracking(String reason) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.stopTracking(widget.userId, reason);
    if (!mounted) return;

    if (result.success) {
      if (reason == 'pregnant') {
        final sw = _isSwahili;
        messenger.showSnackBar(SnackBar(
          content: Text(sw
              ? 'Ufuatiliaji umesimamishwa. Hongera kwa ujauzito!'
              : 'Tracking paused. Congratulations on your pregnancy!'),
          backgroundColor: const Color(0xFF66BB6A),
        ));

        // Transfer pregnancy data to My Baby module
        final pregnancyStart = result.data?['pregnancy_start_date'] as String?;
        if (pregnancyStart != null) {
          final lastPeriod = DateTime.tryParse(pregnancyStart);
          if (lastPeriod != null) {
            // Fire-and-forget: don't block on My Pregnancy creation
            MyPregnancyService().createPregnancy(
              userId: widget.userId,
              lastPeriodDate: lastPeriod,
            ).ignore();
          }
        }
      }
      _loadData();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(result.message ?? 'Error'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _resumeTracking() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.resumeTracking(widget.userId);
    if (!mounted) return;

    if (result.success) {
      final sw = _isSwahili;
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Ufuatiliaji umeendelea' : 'Tracking resumed'),
      ));
      _loadData();
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(result.message ?? 'Error'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.maybeOf(context)?.isSwahili ?? false;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    final bool hasData = _prediction != null && _prediction!.hasData;

    return RefreshIndicator(
        onRefresh: _loadData,
        color: _kPrimary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Privacy notice
            _PrivacyBanner(isSwahili: sw),
            const SizedBox(height: 12),

            // Partner's cycle card (if user is someone's partner)
            if (_partnerData != null) ...[
              _PartnerCycleCard(
                data: _partnerData!,
                isSwahili: sw,
                onTap: () => _nav(PartnerSharingPage(userId: widget.userId, isSwahili: sw)),
              ),
              const SizedBox(height: 12),
            ],

            // Paused / Pregnant state
            if (!_isTracking && _stopReason == 'pregnant') ...[
              _PregnantCard(
                isSwahili: sw,
                pregnancyStartDate: _pregnancyStartDate,
                estimatedDueDate: _estimatedDueDate,
                onGoToBaby: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MyPregnancyModule(userId: widget.userId)),
                ),
                onResume: _resumeTracking,
              ),
              const SizedBox(height: 32),
            ] else if (!_isTracking && _stopReason == 'paused') ...[
              _PausedCard(isSwahili: sw, onResume: _resumeTracking),
              const SizedBox(height: 32),
            ] else ...[
              // Cycle status card or first-time onboarding
              if (!hasData)
                _SetupCard(onSetup: _handleSetup)
              else ...[
                // Settings gear row above the status card
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showSettingsSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.settings_rounded, size: 16, color: _kSecondary),
                            const SizedBox(width: 4),
                            Text(sw ? 'Mipangilio ya duru' : 'Cycle Settings', style: const TextStyle(fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CycleStatusCard(prediction: _prediction, currentCycleDay: _currentCycleDay, isSwahili: sw),
              ],
              const SizedBox(height: 16),

              // Quick log button
              _QuickLogButton(isSwahili: sw, onTap: () => _nav(LogDayPage(userId: widget.userId, isSwahili: sw))),
              const SizedBox(height: 16),

              // Quick actions row
              Row(
                children: [
                  Expanded(child: _QuickAction(icon: Icons.edit_calendar_rounded, label: sw ? 'Rekodi' : 'Log', onTap: () => _nav(LogDayPage(userId: widget.userId, isSwahili: sw)))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.calendar_month_rounded, label: sw ? 'Kalenda' : 'Calendar', onTap: () => _nav(CycleCalendarPage(userId: widget.userId, isSwahili: sw)))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.insights_rounded, label: sw ? 'Takwimu' : 'Insights', onTap: () => _nav(InsightsPage(userId: widget.userId, isSwahili: sw)))),
                  const SizedBox(width: 10),
                  Expanded(child: _QuickAction(icon: Icons.shield_rounded, label: sw ? 'Uzazi mpango' : 'Contraception', onTap: () => _nav(ContraceptionPage(userId: widget.userId, isSwahili: sw)))),
                ],
              ),
              const SizedBox(height: 20),

              // Predictions section
              if (_prediction != null) ...[
                Text(sw ? 'Utabiri' : 'Predictions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 10),
                _PredictionCards(prediction: _prediction!, isSwahili: sw),
                const SizedBox(height: 20),
              ],

              // Share section
              Text(sw ? 'Shiriki' : 'Share', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.medical_services_rounded,
                      label: sw ? 'Daktari' : 'Doctor',
                      onTap: _shareWithDoctor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.favorite_rounded,
                      label: sw ? 'Mpenzi' : 'Partner',
                      onTap: () => _nav(PartnerSharingPage(userId: widget.userId, isSwahili: sw)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.psychology_rounded,
                      label: sw ? 'Uliza Shangazi' : 'Ask Shangazi',
                      onTap: () => Navigator.pushNamed(context, '/tea'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contraception reminders
              if (_reminders.isNotEmpty) ...[
                Text(sw ? 'Vikumbusho vya uzazi mpango' : 'Contraception Reminders', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 10),
                ..._reminders.map((r) => _ReminderTile(reminder: r, isSwahili: sw)),
                const SizedBox(height: 20),
              ],

              // Recent symptoms
              if (_recentDays.any((d) => d.symptoms.isNotEmpty)) ...[
                Text(sw ? 'Dalili za hivi karibuni' : 'Recent Symptoms', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 10),
                _RecentSymptomsSummary(days: _recentDays, isSwahili: sw),
                const SizedBox(height: 20),
              ],

              // ── Health Services ──
              Text(sw ? 'Huduma za Afya' : 'Health Services',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 10),

              // Community card
              Material(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () async {
                    final nav = Navigator.of(context);
                    final group = await _service.getWomensHealthGroup(widget.userId);
                    if (!mounted) return;
                    if (group != null && group['conversation_id'] != null) {
                      nav.pushNamed('/chat/${group['conversation_id']}');
                    } else {
                      _nav(GroupsScreen(currentUserId: widget.userId));
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, color: _kPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sw ? 'Jumuiya ya Wanawake' : "Women's Health Community",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                              Text(sw ? 'Jiunge na vikundi vya afya ya wanawake' : 'Join women\'s health support groups',
                                style: const TextStyle(fontSize: 11, color: _kSecondary),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _kSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Find a Gynaecologist card
              Material(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _nav(DoctorModule(userId: widget.userId)),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: _kPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sw ? 'Tafuta Daktari wa Wanawake' : 'Find a Gynaecologist',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                              Text(sw ? 'Pata daktari bingwa wa afya ya uzazi' : 'Find a reproductive health specialist',
                                style: const TextStyle(fontSize: 11, color: _kSecondary),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _kSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Health Insurance card
              Material(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InsuranceModule(userId: widget.userId)),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.health_and_safety_rounded, color: _kPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sw ? 'Angalia Bima ya Afya' : 'Check Health Insurance',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                              Text(sw ? 'Je, bima yako inashughulikia huduma za afya ya uzazi?' : 'Does your insurance cover reproductive health?',
                                style: const TextStyle(fontSize: 11, color: _kSecondary),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: _kSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stop tracking section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(sw ? 'Simamisha Ufuatiliaji' : 'Stop Tracking',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showStopTrackingDialog(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kSecondary,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(0, 48),
                            ),
                            child: Text(sw ? 'Simamisha' : 'Pause'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showStopTrackingDialog(true),
                            icon: const Icon(Icons.child_care_rounded, size: 18),
                            label: Text(sw ? 'Nina mimba' : 'I\'m pregnant'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kPrimary,
                              side: const BorderSide(color: _kPrimary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      );
  }
}

// ─── Privacy Banner ────────────────────────────────────────────

class _PrivacyBanner extends StatelessWidget {
  final bool isSwahili;
  const _PrivacyBanner({this.isSwahili = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: _kSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSwahili
                  ? 'Data yako ni ya faragha. Hakuna mtu mwingine anayeweza kuiona.'
                  : 'Your data is private. No one else can see your period data.',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Log Button ──────────────────────────────────────────

class _QuickLogButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSwahili;
  const _QuickLogButton({required this.onTap, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.add_circle_rounded, color: _kPrimary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isSwahili ? 'Rekodi Leo' : 'Log Today', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                    Text(isSwahili ? 'Rekodi kiwango cha hedhi, dalili, na hisia' : 'Record flow level, symptoms, and mood', style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Action ──────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 22, color: _kPrimary),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Prediction Cards ──────────────────────────────────────────

class _PredictionCards extends StatelessWidget {
  final CyclePrediction prediction;
  final bool isSwahili;
  const _PredictionCards({required this.prediction, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _PredCard(
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFFEF5350),
              title: isSwahili ? 'Hedhi ijayo' : 'Next Period',
              value: prediction.nextPeriodDate != null
                  ? '${prediction.nextPeriodDate!.day}/${prediction.nextPeriodDate!.month}/${prediction.nextPeriodDate!.year}'
                  : '--',
              subtitle: prediction.daysUntilNextPeriod >= 0
                  ? (isSwahili ? 'Siku ${prediction.daysUntilNextPeriod} zimebaki' : '${prediction.daysUntilNextPeriod} days remaining')
                  : (isSwahili ? 'Haijahesabiwa' : 'Not estimated'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _PredCard(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFF66BB6A),
              title: isSwahili ? 'Dirisha la rutuba' : 'Fertile Window',
              value: prediction.fertileWindowStart != null && prediction.fertileWindowEnd != null
                  ? '${prediction.fertileWindowStart!.day}/${prediction.fertileWindowStart!.month} - ${prediction.fertileWindowEnd!.day}/${prediction.fertileWindowEnd!.month}'
                  : '--',
              subtitle: prediction.isFertileToday
                  ? (isSwahili ? 'Leo ni siku ya rutuba' : 'Today is a fertile day')
                  : (isSwahili ? 'Dirisha la rutuba lifuatalo' : 'Next fertile window'),
            )),
          ],
        ),
        const SizedBox(height: 10),
        _PredCard(
          icon: Icons.egg_rounded,
          iconColor: const Color(0xFF42A5F5),
          title: isSwahili ? 'Ovulesheni' : 'Ovulation',
          value: prediction.ovulationDate != null
              ? '${prediction.ovulationDate!.day}/${prediction.ovulationDate!.month}/${prediction.ovulationDate!.year}'
              : '--',
          subtitle: isSwahili ? 'Siku yenye uwezekano mkubwa wa kupata mimba' : 'Most likely day for conception',
        ),
      ],
    );
  }
}

class _PredCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  const _PredCard({required this.icon, required this.iconColor, required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reminder Tile ─────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  final ContraceptionReminder reminder;
  final bool isSwahili;
  const _ReminderTile({required this.reminder, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: reminder.isOverdue
                  ? const Color(0xFFEF5350).withValues(alpha: 0.1)
                  : _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              reminder.type.icon,
              size: 18,
              color: reminder.isOverdue ? const Color(0xFFEF5350) : _kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.type.displayName(isSwahili), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  reminder.isDueToday
                      ? (isSwahili ? 'Leo!' : 'Due today!')
                      : reminder.isOverdue
                          ? (isSwahili ? 'Imepitwa siku ${-reminder.daysUntilDue}' : 'Overdue — ${-reminder.daysUntilDue} days')
                          : (isSwahili ? 'Siku ${reminder.daysUntilDue} zimebaki' : '${reminder.daysUntilDue} days remaining'),
                  style: TextStyle(
                    fontSize: 11,
                    color: reminder.isOverdue ? const Color(0xFFEF5350) : _kSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Symptoms Summary ───────────────────────────────────

class _RecentSymptomsSummary extends StatelessWidget {
  final List<CycleDay> days;
  final bool isSwahili;
  const _RecentSymptomsSummary({required this.days, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final frequency = <Symptom, int>{};
    for (final day in days) {
      for (final s in day.symptoms) {
        frequency[s] = (frequency[s] ?? 0) + 1;
      }
    }
    final sorted = frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: top.map((entry) {
          final maxCount = sorted.first.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(entry.key.icon, size: 16, color: _kPrimary),
                const SizedBox(width: 8),
                Text(entry.key.displayName(isSwahili), style: const TextStyle(fontSize: 12, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: maxCount > 0 ? entry.value / maxCount : 0,
                    backgroundColor: _kPrimary.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${entry.value}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kSecondary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Paused Card ──────────────────────────────────────────────

class _PausedCard extends StatelessWidget {
  final bool isSwahili;
  final VoidCallback onResume;
  const _PausedCard({required this.isSwahili, required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pause_circle_rounded, size: 28, color: _kSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            isSwahili ? 'Ufuatiliaji Umesimamishwa' : 'Tracking Paused',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili
                ? 'Ufuatiliaji wa duru yako umesimamishwa. Unaweza kuendelea wakati wowote.'
                : 'Your cycle tracking is paused. You can resume at any time.',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(isSwahili ? 'Endelea Kufuatilia' : 'Resume Tracking'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pregnant Card ────────────────────────────────────────────

class _PregnantCard extends StatelessWidget {
  final bool isSwahili;
  final String? pregnancyStartDate;
  final String? estimatedDueDate;
  final VoidCallback onGoToBaby;
  final VoidCallback onResume;
  const _PregnantCard({
    required this.isSwahili,
    this.pregnancyStartDate,
    this.estimatedDueDate,
    required this.onGoToBaby,
    required this.onResume,
  });

  int get _weeksPregnant {
    if (pregnancyStartDate == null) return 0;
    final start = DateTime.tryParse(pregnancyStartDate!);
    if (start == null) return 0;
    return DateTime.now().difference(start).inDays ~/ 7;
  }

  String get _formattedDueDate {
    if (estimatedDueDate == null) return '--';
    final dt = DateTime.tryParse(estimatedDueDate!);
    if (dt == null) return '--';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final weeks = _weeksPregnant;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF66BB6A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded, size: 28, color: Color(0xFF66BB6A)),
          ),
          const SizedBox(height: 16),
          Text(
            isSwahili ? 'Hongera!' : 'Congratulations!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili ? 'Wiki $weeks za ujauzito' : '$weeks weeks pregnant',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Tarehe ya kujifungua: $_formattedDueDate'
                : 'Estimated due date: $_formattedDueDate',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onGoToBaby,
              icon: const Icon(Icons.child_friendly_rounded, size: 20),
              label: Text(isSwahili ? 'Nenda Baby' : 'Go to Baby tab'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onResume,
            child: Text(
              isSwahili ? 'Endelea kufuatilia duru' : 'Resume cycle tracking',
              style: const TextStyle(fontSize: 13, color: _kSecondary, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Partner Cycle Card (shown when user is a partner) ──────

class _PartnerCycleCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final bool isSwahili;
  const _PartnerCycleCard({required this.data, required this.onTap, this.isSwahili = false});

  @override
  Widget build(BuildContext context) {
    final name = data['owner_name'] ?? (isSwahili ? 'Mpenzi' : 'Partner');
    final photo = data['owner_photo'] as String?;
    final nextPeriod = data['next_period_date'] as String?;

    String subtitle = isSwahili ? 'Gusa kuona data iliyoshirikiwa' : 'Tap to view shared cycle data';
    if (nextPeriod != null) {
      final dt = DateTime.tryParse(nextPeriod);
      if (dt != null) {
        final days = dt.difference(DateTime.now()).inDays;
        if (days >= 0) {
          subtitle = isSwahili ? 'Siku $days hadi hedhi' : '$days days until period';
        }
      }
    }

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF66BB6A).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _kPrimary.withValues(alpha: 0.08),
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null ? const Icon(Icons.person_rounded, color: _kSecondary, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isSwahili ? 'Mzunguko wa $name' : "$name's Cycle", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF66BB6A)),
                    SizedBox(width: 4),
                    Text('Live', style: TextStyle(fontSize: 10, color: Color(0xFF66BB6A), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: _kSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Setup Card (First-time onboarding) ──────────────────────

class _SetupCard extends StatefulWidget {
  final Future<void> Function(int cycleLength, int periodLength, DateTime lastPeriod) onSetup;
  const _SetupCard({required this.onSetup});

  @override
  State<_SetupCard> createState() => _SetupCardState();
}

class _SetupCardState extends State<_SetupCard> {
  double _cycleLength = 28;
  double _periodLength = 5;
  DateTime? _lastPeriodDate;
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate ?? DateTime.now().subtract(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary, onSurface: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _lastPeriodDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStringsScope.maybeOf(context)?.isSwahili == true ? 'Tafadhali chagua tarehe hedhi yako ya mwisho ilianza' : 'Please select when your last period started')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSetup(_cycleLength.round(), _periodLength.round(), _lastPeriodDate!);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop_rounded, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set Up Your Cycle', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('Weka mzunguko wako', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cycle length slider
          const Text('How long is your cycle?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const Text('Duru yako ina siku ngapi?', style: TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: _cycleLength,
                    min: 21,
                    max: 45,
                    divisions: 24,
                    onChanged: (v) => setState(() => _cycleLength = v),
                  ),
                ),
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_cycleLength.round()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Period length slider
          const Text('How many days does your period last?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const Text('Hedhi yako inachukua siku ngapi?', style: TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: _periodLength,
                    min: 2,
                    max: 10,
                    divisions: 8,
                    onChanged: (v) => setState(() => _periodLength = v),
                  ),
                ),
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_periodLength.round()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Last period date picker
          const Text('When did your last period start?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const Text('Hedhi yako ya mwisho ilianza lini?', style: TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                _lastPeriodDate != null
                    ? DateFormat('d MMM yyyy').format(_lastPeriodDate!)
                    : 'Select date',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Start tracking button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kPrimary,
                disabledBackgroundColor: Colors.white54,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                  : Text(
                      AppStringsScope.maybeOf(context)?.isSwahili == true ? 'Anza Kufuatilia' : 'Start Tracking',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cycle Settings Bottom Sheet ──────────────────────────────

class _CycleSettingsSheet extends StatefulWidget {
  final int initialCycleLength;
  final int initialPeriodLength;
  final Future<void> Function(int cycleLength, int periodLength) onSave;

  const _CycleSettingsSheet({
    required this.initialCycleLength,
    required this.initialPeriodLength,
    required this.onSave,
  });

  @override
  State<_CycleSettingsSheet> createState() => _CycleSettingsSheetState();
}

class _CycleSettingsSheetState extends State<_CycleSettingsSheet> {
  late double _cycleLength;
  late double _periodLength;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.initialCycleLength.toDouble().clamp(21, 45);
    _periodLength = widget.initialPeriodLength.toDouble().clamp(2, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Cycle Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              const Text('Mipangilio ya mzunguko', style: TextStyle(fontSize: 12, color: _kSecondary)),
              const SizedBox(height: 20),

              // Cycle length
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cycle length (days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                    child: Text('${_cycleLength.round()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                  ),
                ],
              ),
              const Text('Urefu wa duru (siku)', style: TextStyle(fontSize: 11, color: _kSecondary)),
              Slider(
                value: _cycleLength,
                min: 21,
                max: 45,
                divisions: 24,
                activeColor: _kPrimary,
                inactiveColor: _kPrimary.withValues(alpha: 0.15),
                onChanged: (v) => setState(() => _cycleLength = v),
              ),
              const SizedBox(height: 12),

              // Period length
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Period length (days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                    child: Text('${_periodLength.round()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                  ),
                ],
              ),
              const Text('Urefu wa hedhi (siku)', style: TextStyle(fontSize: 11, color: _kSecondary)),
              Slider(
                value: _periodLength,
                min: 2,
                max: 10,
                divisions: 8,
                activeColor: _kPrimary,
                inactiveColor: _kPrimary.withValues(alpha: 0.15),
                onChanged: (v) => setState(() => _periodLength = v),
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            await widget.onSave(_cycleLength.round(), _periodLength.round());
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          AppStringsScope.maybeOf(context)?.isSwahili == true ? 'Hifadhi' : 'Save',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
