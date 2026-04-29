// lib/my_children/pages/teen_dashboard_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../models/school_age_models.dart';
import '../../doctor/doctor_module.dart';
import '../../pharmacy/pharmacy_module.dart';
import '../services/my_children_service.dart';
import 'academic_tracker_page.dart';
import 'dental_record_page.dart';
import 'growth_charts_page.dart';
import 'health_log_page.dart';
import 'vaccination_page.dart';
import 'photo_journal_page.dart';
import 'career_guidance_page.dart';
import 'financial_literacy_page.dart';
import 'life_skills_page.dart';
import 'emergency_card_page.dart';
import 'rch_card_page.dart';
import 'health_checkups_page.dart';
import 'digital_safety_page.dart';
import 'puberty_health_page.dart';
import 'university_prep_page.dart';
import 'caregiver_sharing_page.dart';
import 'doctor_sharing_page.dart';
import 'school_sharing_page.dart';
import 'allowance_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class TeenDashboardPage extends StatefulWidget {
  final Child child;
  final int userId;

  const TeenDashboardPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<TeenDashboardPage> createState() => _TeenDashboardPageState();
}

class _TeenDashboardPageState extends State<TeenDashboardPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  String? _token;
  String? _profilePhotoUrl;

  // Academic data
  List<AcademicRecord> _recentGrades = [];
  // Allowance data
  double _totalEarnings = 0;
  double _totalSavings = 0;
  double _totalSpent = 0;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Load profile photo
      final photoResult = await _service.getPhotos(
        _token!,
        widget.child.id,
        type: 'profile',
      );
      if (!mounted) return;
      if (photoResult.success && photoResult.items.isNotEmpty) {
        _profilePhotoUrl = photoResult.items.first.displayUrl;
      }

      // Load academic records from backend
      final academicResult = await _service.getAcademicRecords(
        _token!,
        widget.child.id,
        year: DateTime.now().year,
      );
      if (academicResult.success) {
        _recentGrades = academicResult.items;
      }

      // Load allowance balance
      try {
        final balanceResult =
            await _service.getAllowanceBalance(_token!, widget.child.id);
        if (balanceResult.success && balanceResult.data != null) {
          _totalEarnings = balanceResult.data!.totalEarned;
          _totalSavings = balanceResult.data!.totalSaved;
          _totalSpent = balanceResult.data!.totalSpent;
        }
      } catch (_) {
        _totalEarnings = 0;
        _totalSavings = 0;
        _totalSpent = 0;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sw
                ? 'Imeshindikana kupakia data'
                : 'Failed to load data'),
          ),
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
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          widget.child.name,
          style: const TextStyle(
            color: _kPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: sw ? 'Onyesha upya' : 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildChildInfoCard(sw),
                    const SizedBox(height: 12),
                    _buildIncompleteProfilePrompt(sw),
                    const SizedBox(height: 4),
                    _buildAcademicSummary(sw),
                    const SizedBox(height: 16),
                    _buildQuickActions(sw),
                    const SizedBox(height: 16),
                    _buildUpcomingMilestones(sw),
                    const SizedBox(height: 16),
                    _buildLifeProgressCard(sw),
                    const SizedBox(height: 16),
                    _buildAllowanceSummary(sw),
                    const SizedBox(height: 16),
                    _buildBudgetLink(sw),
                    const SizedBox(height: 16),
                    _buildHealthIntegrationRow(sw),
                    const SizedBox(height: 12),
                    _buildShopCard(sw),
                    const SizedBox(height: 16),
                    _buildMoreLinks(sw),
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

  // ─── Child Info Card ─────────────────────────────────────────

  Widget _buildChildInfoCard(bool sw) {
    final age = widget.child.ageInYears;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Photo
          CircleAvatar(
            radius: 32,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            backgroundImage: _profilePhotoUrl != null
                ? NetworkImage(_profilePhotoUrl!)
                : null,
            child: _profilePhotoUrl == null
                ? const Icon(Icons.person_rounded, color: _kPrimary, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.child.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sw ? 'Miaka $age' : '$age years old',
                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.child.schoolName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.child.schoolName!,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (widget.child.grade != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sw
                        ? 'Darasa: ${widget.child.grade}'
                        : 'Grade: ${widget.child.grade}',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Stage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.child.stageLabel(isSwahili: sw),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
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

  // ─── Academic Summary ────────────────────────────────────────

  Widget _buildAcademicSummary(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded,
                    color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw ? 'Muhtasari wa Masomo' : 'Academic Summary',
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
          const SizedBox(height: 12),
          if (_recentGrades.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _kSecondary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Bado hakuna matokeo ya masomo yaliyoingizwa'
                          : 'No academic records entered yet',
                      style:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_recentGrades.take(3).map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.subject,
                          style: const TextStyle(
                              fontSize: 14, color: _kPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        g.grade ?? g.score?.toStringAsFixed(0) ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ))),
        ],
      ),
    );
  }

  // ─── Quick Actions ───────────────────────────────────────────

  Widget _buildQuickActions(bool sw) {
    final actions = [
      _QuickAction(
        icon: Icons.school_rounded,
        label: sw ? 'Masomo' : 'Academics',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AcademicTrackerPage(
                child: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.work_rounded,
        label: sw ? 'Kazi' : 'Career',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CareerGuidancePage(
                child: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.account_balance_wallet_rounded,
        label: sw ? 'Fedha' : 'Financial',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FinancialLiteracyPage(
                child: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.psychology_rounded,
        label: sw ? 'Ujuzi' : 'Life Skills',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LifeSkillsPage(
                child: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Vitendo vya Haraka' : 'Quick Actions',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          children: actions
              .map((a) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildActionCard(a, sw),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(_QuickAction action, bool sw) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: _kPrimary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Upcoming Milestones ─────────────────────────────────────

  Widget _buildUpcomingMilestones(bool sw) {
    final age = widget.child.ageInYears;
    final milestones = <_MilestoneItem>[];

    // NECTA exams
    if (age >= 12 && age <= 14) {
      milestones.add(_MilestoneItem(
        icon: Icons.assignment_rounded,
        title: sw ? 'Mtihani wa NECTA (Darasa 7)' : 'NECTA Exams (Std 7)',
        subtitle: sw
            ? 'Mtihani wa kumaliza elimu ya msingi'
            : 'Primary school leaving exam',
        ageTarget: 14,
      ));
    }
    if (age >= 14 && age <= 16) {
      milestones.add(_MilestoneItem(
        icon: Icons.assignment_rounded,
        title: sw ? 'Mtihani wa NECTA (Kidato 4)' : 'NECTA Exams (Form 4)',
        subtitle: sw
            ? 'Mtihani wa kidato cha nne'
            : 'O-Level national exam',
        ageTarget: 16,
      ));
    }
    if (age >= 16 && age <= 18) {
      milestones.add(_MilestoneItem(
        icon: Icons.assignment_rounded,
        title: sw ? 'Mtihani wa NECTA (Kidato 6)' : 'NECTA Exams (Form 6)',
        subtitle: sw
            ? 'Mtihani wa kidato cha sita'
            : 'A-Level national exam',
        ageTarget: 18,
      ));
    }

    // HESLB / University Prep — shown as tappable milestone
    if (age >= 16) {
      milestones.add(_MilestoneItem(
        icon: Icons.account_balance_rounded,
        title: sw ? 'Maandalizi ya Chuo' : 'University Prep',
        subtitle: sw
            ? 'Mkopo wa HESLB na maombi ya chuo'
            : 'HESLB loan & university applications',
        ageTarget: 18,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UniversityPrepPage(
                child: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ));
    }

    // NIDA at 18
    if (age >= 16) {
      milestones.add(_MilestoneItem(
        icon: Icons.badge_rounded,
        title: sw ? 'Usajili wa NIDA' : 'NIDA Registration',
        subtitle: sw
            ? 'Kitambulisho cha taifa akitimiza miaka 18'
            : 'National ID when turning 18',
        ageTarget: 18,
      ));
    }

    // Driving licence at 18
    if (age >= 16) {
      milestones.add(_MilestoneItem(
        icon: Icons.directions_car_rounded,
        title: sw ? 'Leseni ya Udereva' : 'Driving Licence',
        subtitle: sw
            ? 'Anastahili leseni akitimiza miaka 18'
            : 'Eligible at age 18',
        ageTarget: 18,
      ));
    }

    if (milestones.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw ? 'Malengo Yajayo' : 'Upcoming Milestones',
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
          const SizedBox(height: 12),
          ...milestones.map((m) => _buildMilestoneRow(m, sw)),
        ],
      ),
    );
  }

  Widget _buildMilestoneRow(_MilestoneItem m, bool sw) {
    final yearsLeft = m.ageTarget - widget.child.ageInYears;
    final timeLabel = yearsLeft <= 0
        ? (sw ? 'Sasa hivi' : 'Now')
        : (sw
            ? 'Miaka $yearsLeft iliyobaki'
            : '$yearsLeft year${yearsLeft > 1 ? 's' : ''} away');

    final row = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(m.icon, color: _kPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  m.subtitle,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (m.onTap != null)
            const Icon(Icons.chevron_right_rounded,
                color: _kSecondary, size: 18),
          if (m.onTap == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeLabel,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );

    if (m.onTap != null) {
      return InkWell(
        onTap: m.onTap,
        borderRadius: BorderRadius.circular(8),
        child: row,
      );
    }
    return row;
  }

  // ─── Allowance Summary ───────────────────────────────────────

  // ─── Life Progress Card ──────────────────────────────────────

  Widget _buildLifeProgressCard(bool sw) {
    final age = widget.child.ageInYears;

    // Calculate savings rate from loaded data
    final savingsRate = _totalEarnings > 0
        ? (_totalSavings / _totalEarnings * 100).round()
        : 0;

    // Career assessment status (from grades data — if any career-related entries)
    final hasCareerData = _recentGrades.isNotEmpty;

    // Academic progress items
    final scored = _recentGrades.where((g) => g.score != null).toList();
    final avgScore = scored.isNotEmpty
        ? scored.map((g) => g.score!).reduce((a, b) => a + b) / scored.length
        : 0.0;

    final items = <_ProgressItem>[
      _ProgressItem(
        icon: Icons.school_rounded,
        label: sw ? 'Masomo' : 'Academics',
        value: scored.isNotEmpty
            ? '${avgScore.toStringAsFixed(0)}%'
            : (sw ? 'Hakuna data' : 'No data'),
        progress: scored.isNotEmpty ? (avgScore / 100).clamp(0, 1) : 0,
        color: _kPrimary,
      ),
      _ProgressItem(
        icon: Icons.work_rounded,
        label: sw ? 'Mwongozo wa Kazi' : 'Career Guidance',
        value: hasCareerData
            ? (sw ? 'Imeanza' : 'Started')
            : (sw ? 'Haijaanza' : 'Not started'),
        progress: hasCareerData ? 0.3 : 0,
        color: _kPrimary,
      ),
      _ProgressItem(
        icon: Icons.savings_rounded,
        label: sw ? 'Ujuzi wa Fedha' : 'Financial Literacy',
        value: _totalEarnings > 0
            ? '${sw ? "Akiba" : "Savings"} $savingsRate%'
            : (sw ? 'Hakuna data' : 'No data'),
        progress: _totalEarnings > 0
            ? (savingsRate / 100).clamp(0, 1).toDouble()
            : 0,
        color: _kPrimary,
      ),
    ];

    // University prep (if age 16+)
    if (age >= 16) {
      items.add(_ProgressItem(
        icon: Icons.account_balance_rounded,
        label: sw ? 'Maandalizi ya Chuo' : 'University Prep',
        value: sw ? 'Inaendelea' : 'In progress',
        progress: 0.2,
        color: _kPrimary,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw ? 'Maendeleo ya Maisha' : 'Life Progress',
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
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(item.icon, size: 20, color: _kSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _kSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              backgroundColor: Colors.grey.shade200,
                              color: item.progress > 0.7
                                  ? const Color(0xFF2E7D32)
                                  : item.progress > 0.3
                                      ? Colors.orange
                                      : _kPrimary,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAllowanceSummary(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.savings_rounded,
                    color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sw ? 'Muhtasari wa Fedha' : 'Allowance Summary',
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
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatBox(
                sw ? 'Mapato' : 'Earned',
                'TZS ${_totalEarnings.toStringAsFixed(0)}',
                Icons.trending_up_rounded,
              ),
              const SizedBox(width: 10),
              _buildStatBox(
                sw ? 'Akiba' : 'Saved',
                'TZS ${_totalSavings.toStringAsFixed(0)}',
                Icons.savings_rounded,
              ),
              const SizedBox(width: 10),
              _buildStatBox(
                sw ? 'Matumizi' : 'Spent',
                'TZS ${_totalSpent.toStringAsFixed(0)}',
                Icons.shopping_cart_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllowancePage(
                      child: widget.child,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                sw ? 'Angalia Zaidi' : 'View Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: _kPrimary, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Budget Link ─────────────────────────────────────────────

  Widget _buildBudgetLink(bool sw) {
    return GestureDetector(
      onTap: () {
        // Navigate to Budget module
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(sw
                ? 'Moduli ya Bajeti inakuja hivi karibuni'
                : 'Budget module coming soon'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: _kPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw
                        ? 'Matumizi ya Mtoto kwenye Bajeti'
                        : 'View Child Expenses in Budget',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sw
                        ? 'Fuatilia matumizi yote ya ${widget.child.name}'
                        : 'Track all expenses for ${widget.child.name}',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
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

  // ─── Health Integrations: Doctor & Pharmacy ─────────────────

  Widget _buildHealthIntegrationRow(bool sw) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorModule(userId: widget.userId))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kPrimary.withValues(alpha: 0.08))),
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
          decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kPrimary.withValues(alpha: 0.08))),
          child: Row(children: [
            const Icon(Icons.local_pharmacy_rounded, size: 22, color: _kPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(sw ? 'Agiza Dawa' : 'Order Medicine', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildShopCard(bool sw) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/home?tab=shop'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kPrimary.withValues(alpha: 0.08))),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.shopping_bag_rounded, color: _kPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sw ? 'Nunua kwa Kijana' : 'Shop for Teen', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sw ? 'Tafuta bidhaa kwa ${widget.child.name}' : 'Find products for ${widget.child.name}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        ]),
      ),
    );
  }

  // ─── More Links ──────────────────────────────────────────────

  Widget _buildMoreLinks(bool sw) {
    final links = [
      _LinkItem(
        icon: Icons.show_chart_rounded,
        label: sw ? 'Chati za Ukuaji' : 'Growth Charts',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GrowthChartsPage(
                baby: widget.child,
              ),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.medical_services_rounded,
        label: sw ? 'Rekodi za Afya' : 'Health Log',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HealthLogPage(
                baby: widget.child,
              ),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.mood_rounded,
        label: sw ? 'Rekodi za Meno' : 'Dental Records',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DentalRecordPage(
                child: widget.child,
              ),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.medical_information_rounded,
        label: sw ? 'Uchunguzi wa Afya' : 'Health Checkups',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HealthCheckupsPage(
                child: widget.child,
              ),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.vaccines_rounded,
        label: sw ? 'Chanjo' : 'Vaccinations',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VaccinationPage(
                baby: widget.child,
              ),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.photo_library_rounded,
        label: sw ? 'Picha' : 'Photos',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoJournalPage(
                baby: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.security_rounded,
        label: sw ? 'Usalama wa Mtandao' : 'Digital Safety',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DigitalSafetyPage(child: widget.child),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.favorite_rounded,
        label: sw ? 'Afya na Ukuaji' : 'Health & Growth',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PubertyHealthPage(child: widget.child),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.emergency_rounded,
        label: sw ? 'Kadi ya Dharura' : 'Emergency Card',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmergencyCardPage(child: widget.child),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.badge_rounded,
        label: sw ? 'Kadi ya RCH' : 'Digital RCH Card',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RchCardPage(child: widget.child),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.medical_services_rounded,
        label: sw ? 'Shiriki na Daktari' : 'Share with Doctor',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorSharingPage(
                child: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.school_rounded,
        label: sw ? 'Shiriki na Shule' : 'Share with School',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SchoolSharingPage(
                child: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
      _LinkItem(
        icon: Icons.people_rounded,
        label: sw ? 'Walezi' : 'Caregivers',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CaregiverSharingPage(
                baby: widget.child,
                userId: widget.userId,
              ),
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Zaidi' : 'More',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: links.asMap().entries.map((entry) {
              final idx = entry.key;
              final link = entry.value;
              return Column(
                children: [
                  InkWell(
                    onTap: link.onTap,
                    borderRadius: idx == 0
                        ? const BorderRadius.vertical(
                            top: Radius.circular(12))
                        : idx == links.length - 1
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(12))
                            : BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(link.icon, color: _kPrimary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              link.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _kPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: _kSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (idx < links.length - 1)
                    Divider(
                        height: 1,
                        indent: 16,
                        color: _kPrimary.withValues(alpha: 0.06)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Helper Classes ──────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
}

class _MilestoneItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final int ageTarget;
  final VoidCallback? onTap;
  const _MilestoneItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ageTarget,
    this.onTap,
  });
}

class _LinkItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkItem(
      {required this.icon, required this.label, required this.onTap});
}

class _ProgressItem {
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  final Color color;
  const _ProgressItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });
}
