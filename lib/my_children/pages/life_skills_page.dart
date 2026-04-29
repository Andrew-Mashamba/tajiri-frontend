// lib/my_children/pages/life_skills_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class LifeSkillsPage extends StatefulWidget {
  final Child child;
  final int userId;

  const LifeSkillsPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<LifeSkillsPage> createState() => _LifeSkillsPageState();
}

class _LifeSkillsPageState extends State<LifeSkillsPage> {
  bool _isLoading = true;

  // Set of completed skill keys (persisted in SharedPreferences)
  final Set<String> _completedSkills = {};
  // Date when each skill was marked complete
  final Map<String, DateTime> _completionDates = {};

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _loadSavedSkills();
  }

  Future<void> _loadSavedSkills() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'life_skills_${widget.child.id}';
      final savedKeys = prefs.getStringList('${key}_completed') ?? [];
      _completedSkills.addAll(savedKeys);

      for (final sk in savedKeys) {
        final dateStr = prefs.getString('${key}_date_$sk');
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null) _completionDates[sk] = dt;
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSkill(String skillKey, bool completed) async {
    setState(() {
      if (completed) {
        _completedSkills.add(skillKey);
        _completionDates[skillKey] = DateTime.now();
      } else {
        _completedSkills.remove(skillKey);
        _completionDates.remove(skillKey);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'life_skills_${widget.child.id}';
      await prefs.setStringList(
          '${key}_completed', _completedSkills.toList());
      if (completed) {
        await prefs.setString(
            '${key}_date_$skillKey', DateTime.now().toIso8601String());
      } else {
        await prefs.remove('${key}_date_$skillKey');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final age = widget.child.ageInYears;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Ujuzi wa Maisha' : 'Life Skills',
          style: const TextStyle(
            color: _kPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Progress header
                  _buildProgressHeader(sw),
                  const SizedBox(height: 16),

                  // Home skills
                  _buildSkillGroup(
                    sw ? 'Ujuzi wa Nyumbani' : 'Home Skills',
                    Icons.home_rounded,
                    _homeSkills(sw),
                    sw,
                  ),
                  const SizedBox(height: 16),

                  // Academic skills
                  _buildSkillGroup(
                    sw ? 'Ujuzi wa Masomo' : 'Academic Skills',
                    Icons.school_rounded,
                    _academicSkills(sw),
                    sw,
                  ),
                  const SizedBox(height: 16),

                  // Social skills
                  _buildSkillGroup(
                    sw ? 'Ujuzi wa Jamii' : 'Social Skills',
                    Icons.groups_rounded,
                    _socialSkills(sw),
                    sw,
                  ),
                  const SizedBox(height: 16),

                  // Independence milestones
                  _buildIndependenceMilestones(age, sw),
                  const SizedBox(height: 16),

                  // Driving licence preparation (17+)
                  if (age >= 17) _buildDrivingPrepCard(sw),

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
                    icon: Icons.chat_rounded,
                    label: sw
                        ? 'Uliza Shangazi kuhusu kufundisha ujuzi wa maisha'
                        : 'Ask Shangazi about teaching life skills',
                    onTap: () => Navigator.pushNamed(context, '/chat/0'),
                  ),
                  const SizedBox(height: 24),
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

  // ─── Progress Header ─────────────────────────────────────────

  Widget _buildProgressHeader(bool sw) {
    final allSkills = [
      ..._homeSkills(sw),
      ..._academicSkills(sw),
      ..._socialSkills(sw),
    ];
    final total = allSkills.length;
    final completed =
        allSkills.where((s) => _completedSkills.contains(s.key)).length;
    final progress = total > 0 ? completed / total : 0.0;

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: _kPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw ? 'Maendeleo' : 'Progress',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$completed / $total ${sw ? 'ujuzi umejifunzwa' : 'skills learned'}',
                      style:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _kPrimary.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Skill Group ─────────────────────────────────────────────

  Widget _buildSkillGroup(
      String title, IconData icon, List<_LifeSkill> skills, bool sw) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: _kPrimary, size: 20),
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
          ),
          ...skills.map((skill) {
            final isCompleted = _completedSkills.contains(skill.key);
            final completedDate = _completionDates[skill.key];
            return _buildSkillTile(skill, isCompleted, completedDate, sw);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSkillTile(
      _LifeSkill skill, bool isCompleted, DateTime? completedDate, bool sw) {
    return CheckboxListTile(
      value: isCompleted,
      onChanged: (val) => _toggleSkill(skill.key, val ?? false),
      activeColor: _kPrimary,
      checkColor: Colors.white,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      dense: true,
      title: Text(
        skill.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isCompleted ? _kSecondary : _kPrimary,
          decoration: isCompleted ? TextDecoration.lineThrough : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: completedDate != null
          ? Text(
              '${sw ? 'Tarehe' : 'Date'}: '
              '${completedDate.day}/${completedDate.month}/${completedDate.year}',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }

  // ─── Independence Milestones ─────────────────────────────────

  Widget _buildIndependenceMilestones(int age, bool sw) {
    final milestones = _independenceMilestones(sw);

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.lock_open_rounded,
                    color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sw ? 'Hatua za Uhuru' : 'Independence Milestones',
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
          ),
          ...milestones.map((m) {
            final unlocked = age >= m.unlockAge;
            final isCompleted = _completedSkills.contains(m.key);
            final completedDate = _completionDates[m.key];

            return Opacity(
              opacity: unlocked ? 1.0 : 0.5,
              child: CheckboxListTile(
                value: isCompleted,
                onChanged: unlocked
                    ? (val) => _toggleSkill(m.key, val ?? false)
                    : null,
                activeColor: _kPrimary,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? _kPrimary.withValues(alpha: 0.08)
                            : _kPrimary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${m.unlockAge}+',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: unlocked ? _kPrimary : _kSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isCompleted ? _kSecondary : _kPrimary,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!unlocked)
                      Padding(
                        padding: const EdgeInsets.only(left: 38),
                        child: Text(
                          sw
                              ? 'Itafunguliwa akitimiza miaka ${m.unlockAge}'
                              : 'Unlocks at age ${m.unlockAge}',
                          style:
                              const TextStyle(fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (completedDate != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 38),
                        child: Text(
                          '${sw ? 'Tarehe' : 'Date'}: '
                          '${completedDate.day}/${completedDate.month}/${completedDate.year}',
                          style:
                              const TextStyle(fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Driving Licence Prep Card ────────────────────────────────

  Widget _buildDrivingPrepCard(bool sw) {
    final requirements = sw
        ? [
            'Umri wa miaka 18+',
            'Kitambulisho halali cha NIDA',
            'Cheti cha afya (medical certificate)',
            'Cheti cha shule ya udereva',
          ]
        : [
            'Age 18+',
            'Valid NIDA ID',
            'Medical certificate',
            'Driving school certificate',
          ];

    final steps = sw
        ? [
            'Pata kitambulisho cha NIDA',
            'Jiandikishe shule ya udereva',
            'Fanya mtihani wa maandishi',
            'Fanya mtihani wa vitendo',
          ]
        : [
            'Get NIDA ID',
            'Enroll in driving school',
            'Pass written test',
            'Pass practical test',
          ];

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.directions_car_rounded,
                    color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sw
                        ? 'Maandalizi ya Leseni ya Udereva'
                        : 'Driving Licence Preparation',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              sw ? 'Mahitaji:' : 'Requirements:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...requirements.map((r) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: _kSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r,
                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              sw ? 'Hatua:' : 'Steps:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...steps.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(sw
                          ? 'Moduli ya Leseni ya Udereva inakuja hivi karibuni'
                          : 'Driving Licence module coming soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(
                  sw
                      ? 'Fungua Moduli ya Leseni'
                      : 'Open Driving Licence Module',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Skill Data ──────────────────────────────────────────────

  List<_LifeSkill> _homeSkills(bool sw) => [
        _LifeSkill(
          key: 'cook_basic',
          title: sw ? 'Kupika chakula rahisi' : 'Cook a basic meal',
        ),
        _LifeSkill(
          key: 'laundry',
          title: sw ? 'Kufua nguo' : 'Do laundry',
        ),
        _LifeSkill(
          key: 'clean_room',
          title: sw ? 'Kusafisha chumba' : 'Clean your room',
        ),
        _LifeSkill(
          key: 'iron_clothes',
          title: sw ? 'Kupiga pasi' : 'Iron clothes',
        ),
      ];

  List<_LifeSkill> _academicSkills(bool sw) => [
        _LifeSkill(
          key: 'homework_schedule',
          title: sw
              ? 'Kupanga ratiba ya kazi za nyumbani'
              : 'Manage homework schedule',
        ),
        _LifeSkill(
          key: 'study_effectively',
          title: sw ? 'Kusoma kwa ufanisi' : 'Study effectively',
        ),
        _LifeSkill(
          key: 'take_notes',
          title: sw ? 'Kuandika maelezo' : 'Take notes',
        ),
        _LifeSkill(
          key: 'exam_prep',
          title: sw ? 'Kujiandaa kwa mitihani' : 'Prepare for exams',
        ),
      ];

  List<_LifeSkill> _socialSkills(bool sw) => [
        _LifeSkill(
          key: 'resolve_conflicts',
          title: sw
              ? 'Kutatua migogoro kwa amani'
              : 'Resolve conflicts peacefully',
        ),
        _LifeSkill(
          key: 'communicate_respect',
          title: sw
              ? 'Kuwasiliana kwa heshima'
              : 'Communicate respectfully',
        ),
        _LifeSkill(
          key: 'teamwork',
          title: sw ? 'Kufanya kazi katika timu' : 'Work in a team',
        ),
      ];

  List<_IndependenceMilestone> _independenceMilestones(bool sw) => [
        _IndependenceMilestone(
          key: 'first_phone',
          unlockAge: 13,
          title: sw
              ? 'Uwajibikaji wa simu ya kwanza'
              : 'First phone responsibility',
        ),
        _IndependenceMilestone(
          key: 'public_transport',
          unlockAge: 14,
          title: sw
              ? 'Kutumia usafiri wa umma peke yake'
              : 'Public transport alone',
        ),
        _IndependenceMilestone(
          key: 'part_time_work',
          unlockAge: 16,
          title: sw
              ? 'Kustahili kazi ya muda mfupi'
              : 'Part-time work eligibility',
        ),
        _IndependenceMilestone(
          key: 'nida_registration',
          unlockAge: 18,
          title: sw ? 'Usajili wa NIDA' : 'NIDA registration',
        ),
        _IndependenceMilestone(
          key: 'driving_licence',
          unlockAge: 18,
          title: sw
              ? 'Kustahili leseni ya udereva'
              : 'Driving licence eligibility',
        ),
        _IndependenceMilestone(
          key: 'bank_account',
          unlockAge: 18,
          title: sw
              ? 'Kufungua akaunti ya benki'
              : 'Bank account opening',
        ),
      ];
}

// ─── Helper Classes ──────────────────────────────────────────────

class _LifeSkill {
  final String key;
  final String title;
  const _LifeSkill({required this.key, required this.title});
}

class _IndependenceMilestone {
  final String key;
  final int unlockAge;
  final String title;
  const _IndependenceMilestone({
    required this.key,
    required this.unlockAge,
    required this.title,
  });
}
