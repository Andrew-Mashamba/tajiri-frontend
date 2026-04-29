// lib/my_children/pages/learning_activities_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class LearningActivitiesPage extends StatefulWidget {
  final Child child;
  final int userId;

  const LearningActivitiesPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<LearningActivitiesPage> createState() =>
      _LearningActivitiesPageState();
}

class _LearningActivitiesPageState extends State<LearningActivitiesPage> {
  bool _isLoading = true;
  Set<String> _completed = {};

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  String get _prefsKey => 'learning_${widget.child.id}';

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('${_prefsKey}_completed') ?? [];
      if (mounted) {
        setState(() {
          _isLoading = false;
          _completed = list.toSet();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActivity(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newSet = Set<String>.from(_completed);
      if (newSet.contains(id)) {
        newSet.remove(id);
      } else {
        newSet.add(id);
      }
      await prefs.setStringList(
          '${_prefsKey}_completed', newSet.toList());
      if (mounted) setState(() => _completed = newSet);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_sw ? 'Hitilafu imetokea' : 'An error occurred'),
          ),
        );
      }
    }
  }

  // ─── Activities data ──────────────────────────────────────

  List<_ActivityGroup> _getActivities(bool sw) {
    final ageYears = widget.child.ageInYears;

    return [
      _ActivityGroup(
        titleEn: 'Colors & Shapes',
        titleSw: 'Rangi na Maumbo',
        icon: Icons.palette_rounded,
        ageRange: '2-3',
        activities: [
          _Activity(
            id: 'cs1',
            en: 'Point to red objects around the house',
            sw: 'Onesha vitu vyekundu nyumbani',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 10,
          ),
          _Activity(
            id: 'cs2',
            en: 'Sort toys by color',
            sw: 'Panga vinyago kwa rangi',
            materialsEn: 'Colorful toys',
            materialsSw: 'Vinyago vya rangi',
            timeMin: 15,
          ),
          _Activity(
            id: 'cs3',
            en: 'Find circles, squares, and triangles at home',
            sw: 'Tafuta duara, mraba na pembetatu nyumbani',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 10,
          ),
          _Activity(
            id: 'cs4',
            en: 'Draw shapes with finger paint',
            sw: 'Chora maumbo kwa rangi ya vidole',
            materialsEn: 'Finger paint, paper',
            materialsSw: 'Rangi ya vidole, karatasi',
            timeMin: 20,
          ),
          _Activity(
            id: 'cs5',
            en: 'Color matching game with socks',
            sw: 'Mchezo wa kulinganisha rangi na soksi',
            materialsEn: 'Colorful socks',
            materialsSw: 'Soksi za rangi',
            timeMin: 10,
          ),
        ],
        isActive: ageYears >= 2 && ageYears < 4,
      ),
      _ActivityGroup(
        titleEn: 'Counting',
        titleSw: 'Kuhesabu',
        icon: Icons.looks_one_rounded,
        ageRange: '3-4',
        activities: [
          _Activity(
            id: 'ct1',
            en: 'Count your fingers in Swahili',
            sw: 'Hesabu vidole vyako kwa Kiswahili',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 5,
          ),
          _Activity(
            id: 'ct2',
            en: 'Count stairs as you walk up',
            sw: 'Hesabu ngazi unapopanda',
            materialsEn: 'Stairs',
            materialsSw: 'Ngazi',
            timeMin: 5,
          ),
          _Activity(
            id: 'ct3',
            en: 'Count fruits at the market',
            sw: 'Hesabu matunda sokoni',
            materialsEn: 'Fruits',
            materialsSw: 'Matunda',
            timeMin: 10,
          ),
          _Activity(
            id: 'ct4',
            en: 'Put 1-5 items in cups and count',
            sw: 'Weka vitu 1-5 kwenye vikombe na hesabu',
            materialsEn: 'Cups, small objects',
            materialsSw: 'Vikombe, vitu vidogo',
            timeMin: 15,
          ),
          _Activity(
            id: 'ct5',
            en: 'Sing a counting song',
            sw: 'Imba wimbo wa kuhesabu',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 5,
          ),
        ],
        isActive: ageYears >= 3 && ageYears < 5,
      ),
      _ActivityGroup(
        titleEn: 'Letters & Writing',
        titleSw: 'Herufi na Kuandika',
        icon: Icons.abc_rounded,
        ageRange: '4-5',
        activities: [
          _Activity(
            id: 'lw1',
            en: 'Practice writing your name',
            sw: 'Fanya mazoezi ya kuandika jina lako',
            materialsEn: 'Paper, pencil',
            materialsSw: 'Karatasi, penseli',
            timeMin: 15,
          ),
          _Activity(
            id: 'lw2',
            en: 'Trace letters A-E',
            sw: 'Fuatilia herufi A-E',
            materialsEn: 'Tracing paper',
            materialsSw: 'Karatasi ya kufuatilia',
            timeMin: 15,
          ),
          _Activity(
            id: 'lw3',
            en: 'Find letters on food packages',
            sw: 'Tafuta herufi kwenye vifungashio vya chakula',
            materialsEn: 'Food packages',
            materialsSw: 'Vifungashio vya chakula',
            timeMin: 10,
          ),
          _Activity(
            id: 'lw4',
            en: 'Write letters in sand or flour',
            sw: 'Andika herufi kwenye mchanga au unga',
            materialsEn: 'Sand or flour, tray',
            materialsSw: 'Mchanga au unga, sinia',
            timeMin: 15,
          ),
          _Activity(
            id: 'lw5',
            en: 'Match uppercase and lowercase letters',
            sw: 'Linganisha herufi kubwa na ndogo',
            materialsEn: 'Letter cards',
            materialsSw: 'Kadi za herufi',
            timeMin: 15,
          ),
        ],
        isActive: ageYears >= 4,
      ),
      _ActivityGroup(
        titleEn: 'Nature & Science',
        titleSw: 'Mazingira na Sayansi',
        icon: Icons.nature_rounded,
        ageRange: '2-5',
        activities: [
          _Activity(
            id: 'ns1',
            en: 'Name 5 animals you see outside',
            sw: 'Taja wanyama 5 unaowaona nje',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 10,
          ),
          _Activity(
            id: 'ns2',
            en: 'Plant a seed and watch it grow',
            sw: 'Panda mbegu na angalia inakua',
            materialsEn: 'Seed, soil, cup',
            materialsSw: 'Mbegu, udongo, kikombe',
            timeMin: 15,
          ),
          _Activity(
            id: 'ns3',
            en: 'Collect leaves and sort by size',
            sw: 'Kusanya majani na yapange kwa ukubwa',
            materialsEn: 'Leaves',
            materialsSw: 'Majani',
            timeMin: 15,
          ),
          _Activity(
            id: 'ns4',
            en: 'Look at clouds and describe shapes',
            sw: 'Angalia mawingu na eleza maumbo',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 10,
          ),
          _Activity(
            id: 'ns5',
            en: 'Listen to bird sounds and identify them',
            sw: 'Sikiliza sauti za ndege na watambue',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 10,
          ),
        ],
        isActive: true,
      ),
      _ActivityGroup(
        titleEn: 'Body & Movement',
        titleSw: 'Mwili na Harakati',
        icon: Icons.directions_run_rounded,
        ageRange: '2-5',
        activities: [
          _Activity(
            id: 'bm1',
            en: 'Name body parts while pointing',
            sw: 'Taja sehemu za mwili ukionyesha',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 5,
          ),
          _Activity(
            id: 'bm2',
            en: 'Simon says game',
            sw: "Mchezo wa 'Simoni anasema'",
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 10,
          ),
          _Activity(
            id: 'bm3',
            en: 'Dance to a Swahili song',
            sw: 'Cheza densi kwa wimbo wa Kiswahili',
            materialsEn: 'Music',
            materialsSw: 'Muziki',
            timeMin: 10,
          ),
          _Activity(
            id: 'bm4',
            en: 'Balance on one foot for 5 seconds',
            sw: 'Simama kwa mguu mmoja sekunde 5',
            materialsEn: 'None',
            materialsSw: 'Hakuna',
            timeMin: 5,
          ),
          _Activity(
            id: 'bm5',
            en: 'Jump over small objects',
            sw: 'Ruka juu ya vitu vidogo',
            materialsEn: 'Small objects',
            materialsSw: 'Vitu vidogo',
            timeMin: 10,
          ),
        ],
        isActive: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final groups = _getActivities(sw);
    final totalActivities =
        groups.fold<int>(0, (sum, g) => sum + g.activities.length);
    final completedCount = _completed.length;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Shughuli za Kujifunza' : 'Learning Activities',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                children: [
                  // ─── Progress Card ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                size: 22, color: _kPrimary),
                            const SizedBox(width: 8),
                            Text(
                              sw
                                  ? '$completedCount / $totalActivities zimekamilika'
                                  : '$completedCount / $totalActivities completed',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalActivities > 0
                                ? completedCount / totalActivities
                                : 0,
                            minHeight: 6,
                            backgroundColor:
                                _kPrimary.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                _kPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Activity Groups ────────────────────
                  ...groups.map((g) => _buildGroup(g, sw)),

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
                    icon: Icons.shopping_bag_rounded,
                    label: sw
                        ? 'Nunua vinyago vya kielimu'
                        : 'Shop educational toys',
                    onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
                  ),
                  _buildCrossModuleLink(
                    icon: Icons.chat_rounded,
                    label: sw
                        ? 'Uliza Shangazi kuhusu shughuli zaidi'
                        : 'Ask Shangazi for more activities',
                    onTap: () => Navigator.pushNamed(context, '/chat/0'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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

  Widget _buildGroup(_ActivityGroup group, bool sw) {
    final completedInGroup =
        group.activities.where((a) => _completed.contains(a.id)).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: group.isActive
              ? Border.all(color: _kPrimary.withValues(alpha: 0.15))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(group.icon, size: 20, color: _kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sw ? group.titleSw : group.titleEn,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          sw
                              ? 'Miaka ${group.ageRange} · $completedInGroup/${group.activities.length}'
                              : 'Ages ${group.ageRange} · $completedInGroup/${group.activities.length}',
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...group.activities
                .map((a) => _buildActivityTile(a, sw)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(_Activity activity, bool sw) {
    final isDone = _completed.contains(activity.id);
    return InkWell(
      onTap: () => _toggleActivity(activity.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isDone ? const Color(0xFF2E7D32) : _kSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? activity.sw : activity.en,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDone
                          ? _kSecondary
                          : _kPrimary,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sw
                        ? 'Vifaa: ${activity.materialsSw} · ${activity.timeMin} dk'
                        : 'Materials: ${activity.materialsEn} · ${activity.timeMin} min',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────

class _ActivityGroup {
  final String titleEn;
  final String titleSw;
  final IconData icon;
  final String ageRange;
  final List<_Activity> activities;
  final bool isActive;

  const _ActivityGroup({
    required this.titleEn,
    required this.titleSw,
    required this.icon,
    required this.ageRange,
    required this.activities,
    required this.isActive,
  });
}

class _Activity {
  final String id;
  final String en;
  final String sw;
  final String materialsEn;
  final String materialsSw;
  final int timeMin;

  const _Activity({
    required this.id,
    required this.en,
    required this.sw,
    required this.materialsEn,
    required this.materialsSw,
    required this.timeMin,
  });
}
