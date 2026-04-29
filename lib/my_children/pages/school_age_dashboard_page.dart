// lib/my_children/pages/school_age_dashboard_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../calendar/services/calendar_service.dart';
import '../../calendar/models/calendar_models.dart';
import '../../doctor/doctor_module.dart';
import '../../pharmacy/pharmacy_module.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';
import '../services/my_children_service.dart';
import 'academic_tracker_page.dart';
import 'homework_tracker_page.dart';
import 'chore_chart_page.dart';
import 'allowance_page.dart';
import 'activity_manager_page.dart';
import 'reading_log_page.dart';
import 'dental_record_page.dart';
import 'growth_charts_page.dart';
import 'health_log_page.dart';
import 'milestones_page.dart';
import 'emergency_card_page.dart';
import 'rch_card_page.dart';
import 'health_checkups_page.dart';
import 'safety_awareness_page.dart';
import 'emotional_wellbeing_page.dart';
import 'caregiver_sharing_page.dart';
import 'doctor_sharing_page.dart';
import 'photo_journal_page.dart';
import 'school_sharing_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SchoolAgeDashboardPage extends StatefulWidget {
  final Child child;
  final int userId;
  const SchoolAgeDashboardPage({super.key, required this.child, required this.userId});
  @override
  State<SchoolAgeDashboardPage> createState() => _SchoolAgeDashboardPageState();
}

class _SchoolAgeDashboardPageState extends State<SchoolAgeDashboardPage> {
  final MyChildrenService _service = MyChildrenService();
  bool _isLoading = true;
  List<AcademicRecord> _recentGrades = [];
  List<ChoreAssignment> _todayChores = [];
  AllowanceBalance? _allowanceBalance;
  String? _token;
  List<Map<String, dynamic>> _schoolEvents = [];
  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_token == null) { if (mounted) setState(() => _isLoading = false); return; }
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getAcademicRecords(_token!, widget.child.id, year: DateTime.now().year),
        _service.getChores(_token!, widget.child.id),
        _service.getAllowanceBalance(_token!, widget.child.id),
      ]);
      if (!mounted) return;
      final gradeResult = results[0] as MyBabyListResult<AcademicRecord>;
      final choreResult = results[1] as MyBabyListResult<ChoreAssignment>;
      final balanceResult = results[2] as MyBabyResult<AllowanceBalance>;
      try {
        final prefs = await SharedPreferences.getInstance();
        final evJson = prefs.getString('school_events_${widget.child.id}');
        if (evJson != null) {
          final decoded = jsonDecode(evJson);
          if (decoded is List) _schoolEvents = decoded.cast<Map<String, dynamic>>();
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (gradeResult.success) _recentGrades = gradeResult.items;
        if (choreResult.success) _todayChores = choreResult.items;
        if (balanceResult.success) _allowanceBalance = balanceResult.data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_sw ? 'Imeshindikana kupakia data' : 'Failed to load data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final child = widget.child;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg, foregroundColor: _kPrimary, elevation: 0,
        title: Text(child.name, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary, onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildChildInfoCard(sw, child),
                    const SizedBox(height: 12),
                    _buildIncompleteProfilePrompt(sw),
                    const SizedBox(height: 4),
                    if (child.schoolName == null) ...[_buildLinkSchoolCard(sw), const SizedBox(height: 16)],
                    _buildAcademicSummary(sw),
                    const SizedBox(height: 16),
                    _buildAcademicProgressCard(sw),
                    const SizedBox(height: 16),
                    _buildQuickActions(sw),
                    const SizedBox(height: 16),
                    _buildChoreProgress(sw),
                    const SizedBox(height: 16),
                    _buildAllowanceCard(sw),
                    const SizedBox(height: 16),
                    _buildSchoolFeeReminder(sw),
                    const SizedBox(height: 16),
                    _buildSchoolEventsSection(sw),
                    const SizedBox(height: 16),
                    if (child.schoolName != null) ...[_buildEducationLinks(sw), const SizedBox(height: 16)],
                    _buildHealthIntegrationCards(sw),
                    const SizedBox(height: 16),
                    _buildShopCard(sw),
                    const SizedBox(height: 16),
                    _buildSuppliesChecklist(sw),
                    const SizedBox(height: 16),
                    _buildHistoryLinks(sw),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildIncompleteProfilePrompt(bool sw) {
    final missing = <String>[];
    if (widget.child.allergies.isEmpty) missing.add(sw ? 'mzio' : 'allergies');
    if (widget.child.emergencyContacts.isEmpty) missing.add(sw ? 'mawasiliano ya dharura' : 'emergency contacts');
    if (widget.child.bloodType == null || widget.child.bloodType!.isEmpty) missing.add(sw ? 'kundi la damu' : 'blood type');
    if (missing.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(
          sw ? 'Kamilisha wasifu wa ${widget.child.name} — ongeza ${missing.join(", ")}'
             : 'Complete ${widget.child.name}\'s profile — add ${missing.join(", ")}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }

  Widget _buildChildInfoCard(bool sw, Child child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        CircleAvatar(radius: 32, backgroundColor: Colors.grey.shade200,
          backgroundImage: child.photoUrl != null ? NetworkImage(child.photoUrl!) : null,
          child: child.photoUrl == null ? const Icon(Icons.person_rounded, size: 32, color: _kSecondary) : null),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(child.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${child.ageLabelLocalized(isSwahili: sw)} ${child.stageLabel(isSwahili: sw)}', style: const TextStyle(fontSize: 14, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (child.grade != null || child.schoolName != null) ...[
            const SizedBox(height: 4),
            Text([if (child.grade != null) '${sw ? "Darasa" : "Grade"} ${child.grade}', if (child.schoolName != null) child.schoolName].join(' - '),
              style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ])),
      ]),
    );
  }

  Widget _buildAcademicSummary(bool sw) {
    if (_recentGrades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sw ? 'Matokeo ya Shule' : 'Academic Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Text(sw ? 'Hakuna matokeo bado. Ongeza matokeo.' : 'No results yet. Add results.', style: const TextStyle(fontSize: 14, color: _kSecondary)),
        ]),
      );
    }
    final scored = _recentGrades.where((g) => g.score != null).toList();
    final avg = scored.isNotEmpty ? scored.map((g) => g.score!).reduce((a, b) => a + b) / scored.length : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(sw ? 'Matokeo ya Shule' : 'Academic Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary))),
          Text('${sw ? "Wastani" : "Average"}: ${avg.toStringAsFixed(1)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _recentGrades.take(4).map((g) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: _kBackground, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Text(g.subject, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(g.grade ?? g.score?.toStringAsFixed(0) ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            ]),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildAcademicProgressCard(bool sw) {
    final scored = _recentGrades.where((g) => g.score != null).toList();
    if (scored.isEmpty) return const SizedBox.shrink();

    final avg = scored.map((g) => g.score!).reduce((a, b) => a + b) / scored.length;

    // Find best and worst subjects
    final sortedByScore = List<AcademicRecord>.from(scored)
      ..sort((a, b) => b.score!.compareTo(a.score!));
    final best = sortedByScore.first;
    final worst = sortedByScore.last;

    // Subjects needing attention (score < average - 10)
    final needsAttention = scored
        .where((g) => g.score! < (avg - 10))
        .toList()
      ..sort((a, b) => a.score!.compareTo(b.score!));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insights_rounded,
                    size: 18, color: _kPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw ? 'Maendeleo ya Masomo' : 'Academic Progress',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Average score
          Row(
            children: [
              Text(
                sw ? 'Wastani wa alama:' : 'Average score:',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Best subject
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sw
                        ? 'Bora zaidi: ${best.subject} (${best.score?.toStringAsFixed(0)})'
                        : 'Best: ${best.subject} (${best.score?.toStringAsFixed(0)})',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF2E7D32)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Worst subject
          if (scored.length > 1)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_down_rounded,
                      size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Dhaifu zaidi: ${worst.subject} (${worst.score?.toStringAsFixed(0)})'
                          : 'Weakest: ${worst.subject} (${worst.score?.toStringAsFixed(0)})',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.red),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Needs attention
          if (needsAttention.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...needsAttention.take(2).map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sw
                              ? 'Inahitaji umakini: ${g.subject} (${g.score?.toStringAsFixed(0)})'
                              : 'Needs attention: ${g.subject} (${g.score?.toStringAsFixed(0)})',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool sw) {
    final actions = [
      _QuickAction(icon: Icons.school_rounded, label: sw ? 'Matokeo' : 'Grades', onTap: () => _push(AcademicTrackerPage(child: widget.child, userId: widget.userId))),
      _QuickAction(icon: Icons.assignment_rounded, label: sw ? 'Kazi' : 'Homework', onTap: () => _push(HomeworkTrackerPage(child: widget.child, userId: widget.userId))),
      _QuickAction(icon: Icons.checklist_rounded, label: sw ? 'Majukumu' : 'Chores', onTap: () => _push(ChoreChartPage(child: widget.child, userId: widget.userId))),
      _QuickAction(icon: Icons.savings_rounded, label: sw ? 'Posho' : 'Allowance', onTap: () => _push(AllowancePage(child: widget.child, userId: widget.userId))),
      _QuickAction(icon: Icons.sports_soccer_rounded, label: sw ? 'Shughuli' : 'Activities', onTap: () => _push(ActivityManagerPage(child: widget.child, userId: widget.userId))),
      _QuickAction(icon: Icons.menu_book_rounded, label: sw ? 'Kusoma' : 'Reading', onTap: () => _push(ReadingLogPage(child: widget.child, userId: widget.userId))),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(sw ? 'Vitendo vya Haraka' : 'Quick Actions', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
      const SizedBox(height: 12),
      GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
        children: actions.map((a) => GestureDetector(onTap: a.onTap, child: Container(
          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(a.icon, size: 28, color: _kPrimary), const SizedBox(height: 8),
            Text(a.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ]),
        ))).toList()),
    ]);
  }

  Widget _buildChoreProgress(bool sw) {
    final done = _todayChores.where((c) => c.isCompleted).length;
    final total = _todayChores.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(sw ? 'Majukumu ya Leo' : "Today's Chores", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: total > 0 ? done / total : 0, backgroundColor: Colors.grey.shade200, color: _kPrimary, minHeight: 8))),
          const SizedBox(width: 12),
          Text('$done / $total', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        ]),
        if (total == 0) ...[const SizedBox(height: 8), Text(sw ? 'Hakuna majukumu bado' : 'No chores yet', style: const TextStyle(fontSize: 13, color: _kSecondary))],
      ]),
    );
  }

  Widget _buildAllowanceCard(bool sw) {
    final bal = _allowanceBalance;
    return GestureDetector(
      onTap: () => _push(AllowancePage(child: widget.child, userId: widget.userId)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.savings_rounded, size: 32, color: _kPrimary), const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Posho' : 'Allowance Balance', style: const TextStyle(fontSize: 14, color: _kSecondary)),
            const SizedBox(height: 4),
            Text('TZS ${_formatMoney(bal?.balance ?? 0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        ]),
      ),
    );
  }

  Widget _buildSchoolFeeReminder(bool sw) {
    return GestureDetector(
      onTap: () => _showFeeTrackingSheet(sw),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.payment_rounded, size: 28, color: _kPrimary), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Ada ya Shule' : 'School Fees', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sw ? 'Bonyeza kufuatilia malipo ya muhula' : 'Tap to track term fee payments', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        ]),
      ),
    );
  }

  void _showFeeTrackingSheet(bool sw) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _FeeTrackingSheet(childId: widget.child.id, childName: widget.child.name, token: _token ?? '', isSwahili: sw));
  }

  Widget _buildLinkSchoolCard(bool sw) {
    return GestureDetector(
      onTap: () => _showLinkSchoolDialog(sw),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.school_rounded, size: 28, color: _kPrimary), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Unganisha Shule' : 'Link School', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 2),
            Text(sw ? 'Ongeza jina la shule na darasa' : 'Add school name and grade', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.add_rounded, color: _kPrimary),
        ]),
      ),
    );
  }

  void _confirmDeleteSchoolEvent(int index, bool sw) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _kCardBg,
          title: Text(
            sw ? 'Futa Tukio' : 'Delete Event',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          content: Text(
            sw ? 'Una uhakika unataka kufuta tukio hili?' : 'Are you sure you want to delete this event?',
            style: const TextStyle(fontSize: 14, color: _kSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _schoolEvents.removeAt(index));
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('school_events_${widget.child.id}', jsonEncode(_schoolEvents));
                } catch (_) {}
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Tukio limefutwa' : 'Event deleted')),
                  );
                }
              },
              child: Text(sw ? 'Futa' : 'Delete', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showEditSchoolEventDialog(int index) {
    final sw = _sw;
    final ev = _schoolEvents[index];
    final titleCtrl = TextEditingController(text: ev['title'] as String? ?? '');
    DateTime eventDate;
    try {
      eventDate = DateTime.parse(ev['date'] as String? ?? '');
    } catch (_) {
      eventDate = DateTime.now().add(const Duration(days: 7));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(sw ? 'Hariri Tukio la Shule' : 'Edit School Event', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: sw ? 'Jina la tukio' : 'Event name',
                  labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: eventDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setSheetState(() => eventDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                    const SizedBox(width: 10),
                    Text('${eventDate.day}/${eventDate.month}/${eventDate.year}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final updated = {'title': titleCtrl.text.trim(), 'date': eventDate.toIso8601String()};
                    Navigator.pop(ctx);
                    setState(() => _schoolEvents[index] = updated);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('school_events_${widget.child.id}', jsonEncode(_schoolEvents));
                    } catch (_) {}
                  },
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(sw ? 'Hifadhi' : 'Save', style: const TextStyle(fontSize: 15)),
                ),
              ),
            ]),
          );
        });
      },
    ).then((_) => titleCtrl.dispose());
  }

  Future<void> _showLinkSchoolDialog(bool sw) async {
    final schoolCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(context: context, builder: (ctx) {
      return AlertDialog(
        backgroundColor: _kCardBg,
        title: Text(sw ? 'Unganisha Shule' : 'Link School', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: schoolCtrl, decoration: InputDecoration(labelText: sw ? 'Jina la Shule' : 'School Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 12),
          TextField(controller: gradeCtrl, decoration: InputDecoration(labelText: sw ? 'Darasa' : 'Grade/Class', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(sw ? 'Hifadhi' : 'Save', style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))),
        ],
      );
    });
    if (result == true && mounted) {
      final school = schoolCtrl.text.trim();
      final grade = gradeCtrl.text.trim();
      if (school.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(sw ? 'Tafadhali ingiza jina la shule' : 'Please enter school name')));
      } else if (_token != null) {
        try {
          await _service.updateBaby(token: _token!, babyId: widget.child.id, schoolName: school, grade: grade.isNotEmpty ? grade : null);
          if (mounted) { messenger.showSnackBar(SnackBar(content: Text(sw ? 'Shule imeunganishwa' : 'School linked'))); _loadData(); }
        } catch (e) {
          if (mounted) messenger.showSnackBar(SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')));
        }
      }
    }
    schoolCtrl.dispose();
    gradeCtrl.dispose();
  }

  Widget _buildSchoolEventsSection(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(sw ? 'Matukio ya Shule' : 'School Events', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary))),
          if (_schoolEvents.isNotEmpty)
            GestureDetector(
              onTap: _syncSchoolEventsToCalendar,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.sync_rounded, size: 16, color: _kSecondary),
                const SizedBox(width: 4),
                Text(sw ? 'Sawazisha' : 'Sync', style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ]),
            ),
        ]),
        const SizedBox(height: 8),
        if (_schoolEvents.isEmpty)
          GestureDetector(
            onTap: _showAddSchoolEventDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_rounded, size: 18, color: _kSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(sw ? 'Ongeza matukio ya shule (mitihani, mikutano)' : 'Add school events (exams, parent meetings)',
                  style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
        if (_schoolEvents.isNotEmpty) ...[
          ..._schoolEvents.asMap().entries.take(3).map((entry) {
            final idx = entry.key;
            final ev = entry.value;
            final title = ev['title'] as String? ?? '';
            final dateStr = ev['date'] as String?;
            String dateLabel = '';
            if (dateStr != null) {
              try {
                final d = DateTime.parse(dateStr);
                dateLabel = '${d.day}/${d.month}/${d.year}';
              } catch (_) {}
            }
            return GestureDetector(
              onTap: () => _showEditSchoolEventDialog(idx),
              onLongPress: () => _confirmDeleteSchoolEvent(idx, sw),
              child: Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
                const Icon(Icons.event_rounded, size: 18, color: _kSecondary), const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 13, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(dateLabel, style: const TextStyle(fontSize: 11, color: _kSecondary)),
                ],
              ])),
            );
          }),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _showAddSchoolEventDialog,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add_rounded, size: 16, color: _kPrimary),
              const SizedBox(width: 4),
              Text(sw ? 'Ongeza' : 'Add Event', style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w500)),
            ]),
          ),
        ],
      ]),
    );
  }

  void _showAddSchoolEventDialog() {
    final sw = _sw;
    final titleCtrl = TextEditingController();
    DateTime eventDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(sw ? 'Ongeza Tukio la Shule' : 'Add School Event', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: sw ? 'Jina la tukio' : 'Event name',
                  hintText: sw ? 'Mfano: Mtihani wa Mwisho' : 'e.g. Final Exam',
                  labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: eventDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (picked != null) setSheetState(() => eventDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: _kSecondary),
                    const SizedBox(width: 10),
                    Text('${eventDate.day}/${eventDate.month}/${eventDate.year}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final ev = {'title': titleCtrl.text.trim(), 'date': eventDate.toIso8601String()};
                    Navigator.pop(ctx);
                    setState(() => _schoolEvents.add(ev));
                    // Save to SharedPreferences
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('school_events_${widget.child.id}', jsonEncode(_schoolEvents));
                    } catch (_) {}
                    // Fire-and-forget: sync to calendar
                    try {
                      final calService = CalendarService();
                      await calService.createEvent(CalendarEvent(
                        id: 0,
                        userId: widget.userId,
                        title: '${widget.child.name}: ${titleCtrl.text.trim()}',
                        date: eventDate,
                        isAllDay: true,
                        source: EventSource.family,
                      ));
                    } catch (_) {}
                  },
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(sw ? 'Hifadhi' : 'Save', style: const TextStyle(fontSize: 15)),
                ),
              ),
            ]),
          );
        });
      },
    ).then((_) => titleCtrl.dispose());
  }

  /// Fire-and-forget: sync school events to TAJIRI Calendar
  void _syncSchoolEventsToCalendar() {
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    messenger.showSnackBar(SnackBar(content: Text(sw ? 'Inasawazisha...' : 'Syncing to calendar...'), duration: const Duration(seconds: 1)));

    final calendarService = CalendarService();
    for (final ev in _schoolEvents) {
      final title = ev['title'] as String? ?? '';
      final dateStr = ev['date'] as String?;
      if (title.isEmpty) continue;
      DateTime eventDate;
      try {
        eventDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
      } catch (_) {
        eventDate = DateTime.now();
      }
      calendarService.createEvent(CalendarEvent(
        id: 0,
        userId: widget.userId,
        title: '${widget.child.name}: $title',
        date: eventDate,
        isAllDay: true,
        source: EventSource.family,
        notes: '${sw ? "Tukio la shule la" : "School event for"} ${widget.child.name}',
      )).catchError((_) => null as dynamic);
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(sw ? 'Matukio yamesawazishwa' : 'Events synced to calendar'), duration: const Duration(seconds: 2)));
    });
  }

  /// Feature 1: Education links after school is linked
  Widget _buildEducationLinks(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.school_rounded, size: 20, color: _kPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(sw ? 'Kiunganishi cha Elimu' : 'Education Links', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildEduCard(
            icon: Icons.schedule_rounded,
            label: sw ? 'Ratiba' : 'View Timetable',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sw ? 'Ratiba ya shule itakuja na moduli ya Elimu' : 'School timetable coming with Education module')));
            },
          )),
          const SizedBox(width: 8),
          Expanded(child: _buildEduCard(
            icon: Icons.payment_rounded,
            label: sw ? 'Ada' : 'Fee Status',
            onTap: () => _showFeeTrackingSheet(sw),
          )),
          const SizedBox(width: 8),
          Expanded(child: _buildEduCard(
            icon: Icons.assignment_rounded,
            label: sw ? 'Kazi' : 'Assignments',
            onTap: () => _push(HomeworkTrackerPage(child: widget.child, userId: widget.userId)),
          )),
        ]),
      ]),
    );
  }

  Widget _buildEduCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: _kBackground, borderRadius: BorderRadius.circular(10)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 24, color: _kPrimary),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  /// Feature 6: Doctor/Pharmacy integration
  Widget _buildHealthIntegrationCards(bool sw) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorModule(userId: widget.userId))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.local_hospital_rounded, size: 22, color: _kPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(sw ? 'Pata Daktari' : 'Book Doctor', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      )),
      const SizedBox(width: 8),
      Expanded(child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PharmacyModule(userId: widget.userId))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.local_pharmacy_rounded, size: 22, color: _kPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(sw ? 'Agiza Dawa' : 'Order Medicine', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      )),
    ]);
  }

  /// Feature 7: Shop integration
  Widget _buildShopCard(bool sw) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/home?tab=shop'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shopping_bag_rounded, color: _kPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Nunua Vifaa vya Shule' : 'Shop School Supplies', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sw ? 'Tafuta vifaa vya shule kwa ${widget.child.name}' : 'Find school supplies for ${widget.child.name}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        ]),
      ),
    );
  }

  Widget _buildSuppliesChecklist(bool sw) {
    return GestureDetector(
      onTap: () => _showSuppliesSheet(sw),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.checklist_rounded, size: 28, color: _kPrimary), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Orodha ya Vifaa vya Shule' : 'Supplies Checklist', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sw ? 'Fuatilia vifaa vya shule' : 'Track school supply purchases', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        ]),
      ),
    );
  }

  void _showSuppliesSheet(bool sw) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _SuppliesChecklistSheet(childId: widget.child.id, childName: widget.child.name, token: _token ?? '', isSwahili: sw));
  }

  Widget _buildHistoryLinks(bool sw) {
    final links = [
      _HistoryLink(icon: Icons.show_chart_rounded, label: sw ? 'Ukuaji' : 'Growth', onTap: () => _push(GrowthChartsPage(baby: widget.child))),
      _HistoryLink(icon: Icons.health_and_safety_rounded, label: sw ? 'Afya' : 'Health', onTap: () => _push(HealthLogPage(baby: widget.child))),
      _HistoryLink(icon: Icons.medical_information_rounded, label: sw ? 'Uchunguzi wa Afya' : 'Health Checkups', onTap: () => _push(HealthCheckupsPage(child: widget.child))),
      _HistoryLink(icon: Icons.mood_rounded, label: sw ? 'Rekodi za Meno' : 'Dental Records', onTap: () => _push(DentalRecordPage(child: widget.child))),
      _HistoryLink(icon: Icons.flag_rounded, label: sw ? 'Malengo' : 'Milestones', onTap: () => _push(MilestonesPage(baby: widget.child))),
      _HistoryLink(icon: Icons.shield_rounded, label: sw ? 'Usalama' : 'Safety', onTap: () => _push(SafetyAwarenessPage(child: widget.child))),
      _HistoryLink(icon: Icons.favorite_rounded, label: sw ? 'Ustawi' : 'Well-being', onTap: () => _push(EmotionalWellbeingPage(child: widget.child))),
      _HistoryLink(icon: Icons.emergency_rounded, label: sw ? 'Kadi ya Dharura' : 'Emergency Card', onTap: () => _push(EmergencyCardPage(child: widget.child))),
      _HistoryLink(icon: Icons.badge_rounded, label: sw ? 'Kadi ya RCH' : 'Digital RCH Card', onTap: () => _push(RchCardPage(child: widget.child))),
      _HistoryLink(icon: Icons.medical_services_rounded, label: sw ? 'Shiriki na Daktari' : 'Share with Doctor', onTap: () => _push(DoctorSharingPage(child: widget.child, userId: widget.userId))),
      _HistoryLink(icon: Icons.school_rounded, label: sw ? 'Shiriki na Shule' : 'Share with School', onTap: () => _push(SchoolSharingPage(child: widget.child, userId: widget.userId))),
      _HistoryLink(icon: Icons.people_rounded, label: sw ? 'Walezi' : 'Caregivers', onTap: () => _push(CaregiverSharingPage(baby: widget.child, userId: widget.userId))),
      _HistoryLink(icon: Icons.photo_library_rounded, label: sw ? 'Picha' : 'Photo Journal', onTap: () => _push(PhotoJournalPage(baby: widget.child, userId: widget.userId))),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(sw ? 'Historia' : 'History', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
      const SizedBox(height: 8),
      ...links.map((l) => Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(onTap: l.onTap, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(l.icon, size: 22, color: _kPrimary), const SizedBox(width: 12),
          Expanded(child: Text(l.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary, size: 20),
        ]),
      )))),
    ]);
  }

  void _push(Widget page) { Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)); }

  String _formatMoney(double amount) {
    final s = amount.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) { if (i > 0 && (s.length - i) % 3 == 0) buf.write(','); buf.write(s[i]); }
    return buf.toString();
  }
}

class _QuickAction { final IconData icon; final String label; final VoidCallback onTap; const _QuickAction({required this.icon, required this.label, required this.onTap}); }
class _HistoryLink { final IconData icon; final String label; final VoidCallback onTap; const _HistoryLink({required this.icon, required this.label, required this.onTap}); }

// ─── Fee Tracking Sheet (Partial 14) ────────────────────────────────

class _FeeTrackingSheet extends StatefulWidget {
  final int childId; final String childName; final String token; final bool isSwahili;
  const _FeeTrackingSheet({required this.childId, required this.childName, required this.token, required this.isSwahili});
  @override
  State<_FeeTrackingSheet> createState() => _FeeTrackingSheetState();
}

class _FeeTrackingSheetState extends State<_FeeTrackingSheet> {
  bool get sw => widget.isSwahili;
  bool _isLoading = true;
  final Map<int, _TermFee> _terms = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() { super.initState(); _loadFees(); }

  String get _prefKey => 'school_fees_${widget.childId}';

  Future<void> _loadFees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in data.entries) {
          _terms[int.parse(entry.key)] = _TermFee.fromMap(entry.value as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveFees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_terms.map((k, v) => MapEntry(k.toString(), v.toMap()))));
    } catch (_) {}
  }

  Future<String?> _pickReceiptPhoto(BuildContext dialogContext) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: dialogContext,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _kPrimary),
              title: Text(sw ? 'Piga picha' : 'Take Photo', style: const TextStyle(color: _kPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _kPrimary),
              title: Text(sw ? 'Chagua picha' : 'Choose from Gallery', style: const TextStyle(color: _kPrimary)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );
    if (source == null) return null;
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);
      return picked?.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _editTerm(int term) async {
    final existing = _terms[term];
    final amountCtrl = TextEditingController(text: existing?.amount != null && existing!.amount > 0 ? existing.amount.toStringAsFixed(0) : '');
    bool paid = existing?.paid ?? false;
    List<String> receiptPaths = List<String>.from(existing?.receiptPaths ?? []);
    final result = await showDialog<bool>(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          backgroundColor: _kCardBg,
          title: Text('${sw ? "Muhula" : "Term"} $term', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: sw ? 'Kiasi (TZS)' : 'Amount Due (TZS)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 12),
              SwitchListTile(title: Text(sw ? 'Imelipwa' : 'Paid', style: const TextStyle(fontSize: 14, color: _kPrimary)), value: paid, activeThumbColor: _kPrimary, onChanged: (v) => setDialogState(() => paid = v)),
              const SizedBox(height: 8),
              // Receipt photos section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(sw ? 'Risiti za malipo' : 'Payment Receipts', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
              ),
              const SizedBox(height: 8),
              if (receiptPaths.isNotEmpty) ...[
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: receiptPaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final path = receiptPaths[i];
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showReceiptFullScreen(path),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(path), width: 80, height: 80, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80, height: 80,
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.broken_image_rounded, color: _kSecondary),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2, right: 2,
                            child: GestureDetector(
                              onTap: () => setDialogState(() => receiptPaths.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final path = await _pickReceiptPhoto(ctx);
                    if (path != null) {
                      setDialogState(() => receiptPaths.add(path));
                    }
                  },
                  icon: const Icon(Icons.add_a_photo_rounded, size: 18, color: _kPrimary),
                  label: Text(sw ? 'Ongeza risiti' : 'Add Receipt Photo', style: const TextStyle(fontSize: 13, color: _kPrimary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(sw ? 'Ghairi' : 'Cancel', style: const TextStyle(color: _kSecondary))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(sw ? 'Hifadhi' : 'Save', style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600))),
          ],
        );
      });
    });
    if (result == true && mounted) {
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      setState(() { _terms[term] = _TermFee(amount: amount, paid: paid, datePaid: paid ? DateTime.now().toIso8601String() : null, receiptPaths: receiptPaths); });
      _saveFees();
      if (paid && amount > 0 && widget.token.isNotEmpty) {
        try { ExpenditureService.recordExpenditure(token: widget.token, amount: amount, category: 'ada_shule', description: 'School fee Term $term - ${widget.childName}', sourceModule: 'my_children').then((_) {}).catchError((_) {}); } catch (_) {}
      }
    }
    amountCtrl.dispose();
  }

  void _showReceiptFullScreen(String path) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(sw ? 'Risiti' : 'Receipt', style: const TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white, size: 64),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final termLabels = sw ? ['Muhula wa 1', 'Muhula wa 2', 'Muhula wa 3'] : ['Term 1', 'Term 2', 'Term 3'];
    return Container(
      margin: const EdgeInsets.only(top: 120),
      decoration: const BoxDecoration(color: _kBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          const Icon(Icons.payment_rounded, size: 22, color: _kPrimary), const SizedBox(width: 10),
          Expanded(child: Text(sw ? 'Ada ya Shule' : 'School Fees', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ])),
        const SizedBox(height: 16),
        if (_isLoading) const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        else Flexible(child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(horizontal: 20), children: List.generate(3, (i) {
          final term = i + 1;
          final fee = _terms[term];
          final isPaid = fee?.paid ?? false;
          final hasReceipts = fee != null && fee.receiptPaths.isNotEmpty;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(color: _kCardBg, borderRadius: BorderRadius.circular(10), child: InkWell(onTap: () => _editTerm(term), borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.all(14), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: isPaid ? _kPrimary.withValues(alpha: 0.08) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Icon(isPaid ? Icons.check_circle_rounded : Icons.payment_rounded, color: isPaid ? _kPrimary : _kSecondary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(termLabels[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (fee != null && fee.amount > 0) Text('TZS ${fee.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ])),
              Text(isPaid ? (sw ? 'Imelipwa' : 'Paid') : (sw ? 'Haijalipwa' : 'Unpaid'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPaid ? _kPrimary : _kSecondary)),
              const SizedBox(width: 8),
              const Icon(Icons.edit_rounded, size: 16, color: _kSecondary),
            ]),
            if (hasReceipts) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: fee.receiptPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, ri) {
                    return GestureDetector(
                      onTap: () => _showReceiptFullScreen(fee.receiptPaths[ri]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(File(fee.receiptPaths[ri]), width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.receipt_long_rounded, color: _kSecondary, size: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ])))));
        }))),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _TermFee {
  final double amount; final bool paid; final String? datePaid; final List<String> receiptPaths;
  const _TermFee({required this.amount, required this.paid, this.datePaid, this.receiptPaths = const []});
  factory _TermFee.fromMap(Map<String, dynamic> map) => _TermFee(
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    paid: map['paid'] == true,
    datePaid: map['datePaid'] as String?,
    receiptPaths: map['receiptPaths'] is List ? (map['receiptPaths'] as List).cast<String>() : const [],
  );
  Map<String, dynamic> toMap() => {'amount': amount, 'paid': paid, if (datePaid != null) 'datePaid': datePaid, 'receiptPaths': receiptPaths};
}

// ─── Supplies Checklist Sheet ───────────────────────────────────────

class _SupplyItem { final String key; final String labelEn; final String labelSw; final double estimatedCost;
  const _SupplyItem({required this.key, required this.labelEn, required this.labelSw, required this.estimatedCost});
  String label(bool sw) => sw ? labelSw : labelEn;
}

const List<_SupplyItem> _supplyItems = [
  _SupplyItem(key: 'uniform', labelEn: 'School uniform', labelSw: 'Sare ya shule', estimatedCost: 35000),
  _SupplyItem(key: 'shoes', labelEn: 'School shoes', labelSw: 'Viatu vya shule', estimatedCost: 25000),
  _SupplyItem(key: 'backpack', labelEn: 'Backpack', labelSw: 'Mkoba', estimatedCost: 15000),
  _SupplyItem(key: 'textbooks', labelEn: 'Textbooks', labelSw: 'Vitabu', estimatedCost: 30000),
  _SupplyItem(key: 'stationery', labelEn: 'Stationery', labelSw: 'Vifaa vya kuandikia', estimatedCost: 10000),
  _SupplyItem(key: 'pe_kit', labelEn: 'PE kit', labelSw: 'Vifaa vya michezo', estimatedCost: 20000),
];

class _SuppliesChecklistSheet extends StatefulWidget {
  final int childId; final String childName; final String token; final bool isSwahili;
  const _SuppliesChecklistSheet({required this.childId, required this.childName, required this.token, required this.isSwahili});
  @override
  State<_SuppliesChecklistSheet> createState() => _SuppliesChecklistSheetState();
}

class _SuppliesChecklistSheetState extends State<_SuppliesChecklistSheet> {
  final Map<String, bool> _checkedItems = {};
  bool _isLoading = true;
  bool get sw => widget.isSwahili;

  @override
  void initState() { super.initState(); _loadState(); }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'supplies_${widget.childId}_';
      for (final item in _supplyItems) { _checkedItems[item.key] = prefs.getBool('$prefix${item.key}') ?? false; }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleItem(_SupplyItem item) async {
    final wasChecked = _checkedItems[item.key] ?? false;
    final nowChecked = !wasChecked;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checkedItems[item.key] = nowChecked);
    try { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('supplies_${widget.childId}_${item.key}', nowChecked); } catch (_) {}
    if (nowChecked && widget.token.isNotEmpty) {
      try {
        ExpenditureService.recordExpenditure(token: widget.token, amount: item.estimatedCost, category: 'watoto', description: '${widget.childName}: ${item.label(sw)}', referenceId: 'child_supply_${widget.childId}_${item.key}', sourceModule: 'my_children').then((_) {}).catchError((_) {});
        if (mounted) messenger.showSnackBar(SnackBar(content: Text(sw ? 'Gharama imerekodiwa' : 'Expense recorded'), duration: const Duration(seconds: 1)));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = _supplyItems.fold<double>(0, (sum, item) => sum + ((_checkedItems[item.key] ?? false) ? item.estimatedCost : 0));
    final estimatedTotal = _supplyItems.fold<double>(0, (sum, item) => sum + item.estimatedCost);
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(color: _kBackground, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          const Icon(Icons.checklist_rounded, size: 22, color: _kPrimary), const SizedBox(width: 10),
          Expanded(child: Text(sw ? 'Orodha ya Vifaa vya Shule' : 'Supplies Checklist', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ])),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(sw ? 'Jumla ya gharama' : 'Total cost', style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('TZS ${totalCost.toStringAsFixed(0)} / ${estimatedTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]))),
        const SizedBox(height: 8),
        if (_isLoading) const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        else Flexible(child: ListView.builder(shrinkWrap: true, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), itemCount: _supplyItems.length, itemBuilder: (_, i) {
          final item = _supplyItems[i]; final checked = _checkedItems[item.key] ?? false;
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: Material(color: _kCardBg, borderRadius: BorderRadius.circular(10), child: InkWell(onTap: () => _toggleItem(item), borderRadius: BorderRadius.circular(10), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
            SizedBox(width: 24, height: 24, child: Checkbox(value: checked, onChanged: (_) => _toggleItem(item), activeColor: _kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
            const SizedBox(width: 12),
            Expanded(child: Text(item.label(sw), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary, decoration: checked ? TextDecoration.lineThrough : null), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('TZS ${item.estimatedCost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])))));
        })),
        const SizedBox(height: 20),
      ]),
    );
  }
}
