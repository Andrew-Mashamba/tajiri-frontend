// lib/my_children/pages/toddler_dashboard_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/live_update_service.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../../doctor/doctor_module.dart';
import '../../pharmacy/pharmacy_module.dart';
import '../services/my_children_service.dart';
import 'potty_tracker_page.dart';
import 'speech_tracker_page.dart';
import 'behavior_chart_page.dart';
import 'learning_activities_page.dart';
import 'dental_record_page.dart';
import 'growth_charts_page.dart';
import 'health_log_page.dart';
import 'vaccination_page.dart';
import 'milestones_page.dart';
import 'photo_journal_page.dart';
import 'emergency_card_page.dart';
import 'rch_card_page.dart';
import 'preschool_page.dart';
import 'toddler_nutrition_page.dart';
import 'safety_awareness_page.dart';
import 'caregiver_sharing_page.dart';
import 'doctor_sharing_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ToddlerDashboardPage extends StatefulWidget {
  final Child child;
  final int userId;

  const ToddlerDashboardPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<ToddlerDashboardPage> createState() => _ToddlerDashboardPageState();
}

class _ToddlerDashboardPageState extends State<ToddlerDashboardPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  List<BabyMilestone> _milestones = [];
  List<Map<String, dynamic>> _pottyHistory = [];
  List<Map<String, dynamic>> _speechHistory = [];
  String? _token;

  StreamSubscription<LiveUpdateEvent>? _liveUpdateSub;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();

    _liveUpdateSub = LiveUpdateService.instance.stream.listen((event) {
      if (event is BabyUpdateEvent) {
        if (event.babyId == null || event.babyId == widget.child.id) {
          _loadData();
        }
      }
    });
  }

  @override
  void dispose() {
    _liveUpdateSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getMilestones(_token!, widget.child.id),
        _service.getDailySummary(_token!, widget.child.id),
        _service.getPottyHistory(widget.child.id, token: _token),
        _service.getSpeechHistory(widget.child.id, token: _token),
      ]);

      if (mounted) {
        final mileResult = results[0] as MyBabyListResult<BabyMilestone>;
        // results[1] is daily summary (unused on toddler dashboard)
        final pottyResult =
            results[2] as MyChildrenListResult<Map<String, dynamic>>;
        final speechResult =
            results[3] as MyChildrenListResult<Map<String, dynamic>>;

        setState(() {
          _isLoading = false;
          if (mileResult.success) _milestones = mileResult.items;
          if (pottyResult.success) _pottyHistory = pottyResult.items;
          if (speechResult.success) _speechHistory = speechResult.items;
        });
      }
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

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) {
      if (mounted) _loadData();
    });
  }

  // ─── Stats helpers ──────────────────────────────────────────

  int get _todayPottySuccesses {
    final today = DateTime.now();
    return _pottyHistory.where((p) {
      final d = DateTime.tryParse(p['logged_at']?.toString() ?? '');
      return d != null &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day &&
          p['type'] == 'success';
    }).length;
  }

  int get _todayPottyAccidents {
    final today = DateTime.now();
    return _pottyHistory.where((p) {
      final d = DateTime.tryParse(p['logged_at']?.toString() ?? '');
      return d != null &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day &&
          p['type'] == 'accident';
    }).length;
  }

  int get _totalWords => _speechHistory.length;

  BabyMilestone? get _nextMilestone {
    final upcoming =
        _milestones.where((m) => !m.isDone).toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.ageMonths.compareTo(b.ageMonths));
    return upcoming.first;
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final child = widget.child;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          child.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // ─── Child Info Card ──────────────────────
                    _buildChildInfoCard(sw),
                    const SizedBox(height: 12),

                    // Incomplete profile prompt
                    _buildIncompleteProfilePrompt(sw),
                    const SizedBox(height: 4),

                    // ─── Quick Actions ────────────────────────
                    _buildSectionTitle(sw ? 'Vitendo vya Haraka' : 'Quick Actions'),
                    const SizedBox(height: 8),
                    _buildQuickActions(sw),
                    const SizedBox(height: 16),

                    // ─── Daily Summary ────────────────────────
                    _buildSectionTitle(sw ? 'Muhtasari wa Leo' : "Today's Summary"),
                    const SizedBox(height: 8),
                    _buildDailySummary(sw),
                    const SizedBox(height: 16),

                    // ─── Next Milestone ───────────────────────
                    if (_nextMilestone != null) ...[
                      _buildSectionTitle(
                          sw ? 'Hatua Inayofuata' : 'Next Milestone'),
                      const SizedBox(height: 8),
                      _buildNextMilestoneCard(sw),
                      const SizedBox(height: 16),
                    ],

                    // ─── Health Integrations ─────────────────
                    _buildHealthIntegrationRow(sw),
                    const SizedBox(height: 12),
                    _buildShopCard(sw),
                    const SizedBox(height: 16),

                    // ─── More Features ────────────────────────
                    _buildSectionTitle(sw ? 'Zaidi' : 'More'),
                    const SizedBox(height: 8),
                    _buildMoreFeatures(sw),
                    const SizedBox(height: 32),
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

  // ─── Child Info Card ──────────────────────────────────────────

  Widget _buildChildInfoCard(bool sw) {
    final child = widget.child;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: child.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      child.photoUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => const Icon(
                          Icons.child_care_rounded,
                          size: 28,
                          color: _kPrimary),
                    ),
                  )
                : Icon(
                    child.gender == 'male'
                        ? Icons.boy_rounded
                        : child.gender == 'female'
                            ? Icons.girl_rounded
                            : Icons.child_care_rounded,
                    size: 28,
                    color: _kPrimary,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  child.ageLabelLocalized(isSwahili: sw),
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              child.stageLabel(isSwahili: sw),
              style: const TextStyle(
                fontSize: 11,
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

  // ─── Quick Actions ──────────────────────────────────────────

  Widget _buildQuickActions(bool sw) {
    final actions = [
      _QuickAction(
        icon: Icons.wc_rounded,
        label: sw ? 'Choo' : 'Potty',
        onTap: () => _nav(PottyTrackerPage(
            child: widget.child, userId: widget.userId)),
      ),
      _QuickAction(
        icon: Icons.record_voice_over_rounded,
        label: sw ? 'Lugha' : 'Speech',
        onTap: () => _nav(SpeechTrackerPage(
            child: widget.child, userId: widget.userId)),
      ),
      _QuickAction(
        icon: Icons.star_rounded,
        label: sw ? 'Tabia' : 'Behavior',
        onTap: () => _nav(BehaviorChartPage(
            child: widget.child, userId: widget.userId)),
      ),
      _QuickAction(
        icon: Icons.school_rounded,
        label: sw ? 'Kujifunza' : 'Learning',
        onTap: () => _nav(LearningActivitiesPage(
            child: widget.child, userId: widget.userId)),
      ),
      _QuickAction(
        icon: Icons.apartment_rounded,
        label: sw ? 'Shule' : 'Preschool',
        onTap: () => _nav(PreschoolPage(child: widget.child)),
      ),
    ];

    return Row(
      children: actions
          .map((a) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: a.onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(a.icon, size: 26, color: _kPrimary),
                            const SizedBox(height: 6),
                            Text(
                              a.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ─── Daily Summary ──────────────────────────────────────────

  Widget _buildDailySummary(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.check_circle_rounded,
                  label: sw ? 'Choo Mafanikio' : 'Potty Successes',
                  value: '$_todayPottySuccesses',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.cancel_rounded,
                  label: sw ? 'Ajali' : 'Accidents',
                  value: '$_todayPottyAccidents',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  icon: Icons.chat_bubble_rounded,
                  label: sw ? 'Maneno' : 'Words Logged',
                  value: '$_totalWords',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  icon: Icons.emoji_events_rounded,
                  label: sw ? 'Hatua' : 'Milestones',
                  value: '${_milestones.where((m) => m.isDone).length}/${_milestones.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Next Milestone ──────────────────────────────────────────

  Widget _buildNextMilestoneCard(bool sw) {
    final m = _nextMilestone!;
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _nav(MilestonesPage(baby: widget.child)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded,
                    size: 20, color: _kPrimary),
              ),
              const SizedBox(width: 12),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (m.description != null)
                      Text(
                        m.description!,
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _kSecondary),
            ],
          ),
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
            Text(sw ? 'Nunua Bidhaa za Mtoto' : 'Shop Baby Products', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sw ? 'Tafuta bidhaa za ${widget.child.name}' : 'Find products for ${widget.child.name}', style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const Icon(Icons.chevron_right_rounded, color: _kSecondary),
        ]),
      ),
    );
  }

  // ─── More Features ──────────────────────────────────────────

  Widget _buildMoreFeatures(bool sw) {
    final features = [
      _FeatureItem(
        icon: Icons.show_chart_rounded,
        label: sw ? 'Chati ya Ukuaji' : 'Growth Charts',
        onTap: () => _nav(GrowthChartsPage(baby: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.health_and_safety_rounded,
        label: sw ? 'Kumbukumbu za Afya' : 'Health Log',
        onTap: () => _nav(HealthLogPage(baby: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.mood_rounded,
        label: sw ? 'Rekodi za Meno' : 'Dental Records',
        onTap: () => _nav(DentalRecordPage(child: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.vaccines_rounded,
        label: sw ? 'Chanjo' : 'Vaccinations',
        onTap: () => _nav(VaccinationPage(baby: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.emoji_events_rounded,
        label: sw ? 'Hatua za Maendeleo' : 'Milestones',
        onTap: () => _nav(MilestonesPage(baby: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.photo_library_rounded,
        label: sw ? 'Picha' : 'Photo Journal',
        onTap: () => _nav(PhotoJournalPage(
            baby: widget.child, userId: widget.userId)),
      ),
      _FeatureItem(
        icon: Icons.emergency_rounded,
        label: sw ? 'Kadi ya Dharura' : 'Emergency Card',
        onTap: () => _nav(EmergencyCardPage(child: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.badge_rounded,
        label: sw ? 'Kadi ya RCH' : 'Digital RCH Card',
        onTap: () => _nav(RchCardPage(child: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.restaurant_menu_rounded,
        label: sw ? 'Lishe' : 'Nutrition',
        onTap: () => _nav(ToddlerNutritionPage(child: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.shield_rounded,
        label: sw ? 'Usalama' : 'Safety',
        onTap: () => _nav(SafetyAwarenessPage(child: widget.child)),
      ),
      _FeatureItem(
        icon: Icons.medical_services_rounded,
        label: sw ? 'Shiriki na Daktari' : 'Share with Doctor',
        onTap: () => _nav(DoctorSharingPage(
            child: widget.child, userId: widget.userId)),
      ),
      _FeatureItem(
        icon: Icons.people_rounded,
        label: sw ? 'Walezi' : 'Caregivers',
        onTap: () => _nav(CaregiverSharingPage(
            baby: widget.child, userId: widget.userId)),
      ),
    ];

    return Column(
      children: features
          .map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: f.onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(f.icon, size: 22, color: _kPrimary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              f.label,
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
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _kPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ─── Helper classes ──────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kPrimary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _kSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FeatureItem(
      {required this.icon, required this.label, required this.onTap});
}
