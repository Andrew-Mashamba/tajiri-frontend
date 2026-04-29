// lib/my_children/pages/emotional_wellbeing_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_children_models.dart';
import '../../doctor/doctor_module.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmotionalWellbeingPage extends StatefulWidget {
  final Child child;

  const EmotionalWellbeingPage({super.key, required this.child});

  @override
  State<EmotionalWellbeingPage> createState() => _EmotionalWellbeingPageState();
}

class _EmotionalWellbeingPageState extends State<EmotionalWellbeingPage> {
  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;
  int? _currentUserId;

  // Mood data: key = 'yyyy-MM-dd', value = 0-4 (very sad to very happy)
  Map<String, int> _moods = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = LocalStorageService.instanceSync?.getUser()?.userId;
    _loadMoods();
  }

  String get _prefKey => 'wellbeing_${widget.child.id}';

  Future<void> _loadMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && mounted) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        setState(() {
          _moods = data.map((k, v) => MapEntry(k, v as int));
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw ? 'Hitilafu kupakia data' : 'Failed to load data')),
        );
      }
    }
  }

  Future<void> _saveMoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(_moods));
    } catch (_) {}
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
          sw ? 'Ustawi wa Kihisia' : 'Well-being',
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
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Daily mood check-in
                  _buildSectionTitle(sw ? 'Hali ya Leo' : 'Today\'s Mood'),
                  const SizedBox(height: 8),
                  _buildMoodCheckIn(sw),
                  const SizedBox(height: 24),

                  // Weekly mood chart
                  _buildSectionTitle(sw ? 'Hali ya Wiki Hii' : 'This Week\'s Mood'),
                  const SizedBox(height: 8),
                  _buildWeeklyChart(sw),
                  const SizedBox(height: 8),
                  _buildMoodSummary(sw),
                  const SizedBox(height: 24),

                  // Self-esteem activities
                  _buildSectionTitle(sw ? 'Shughuli za Kujiamini' : 'Self-Esteem Activities'),
                  const SizedBox(height: 8),
                  ..._selfEsteemActivities.map((a) => _buildActivityCard(a, sw)),
                  const SizedBox(height: 24),

                  // Bullying awareness
                  _buildSectionTitle(sw ? 'Ufahamu wa Unyanyasaji' : 'Bullying Awareness'),
                  const SizedBox(height: 8),
                  _buildBullyingSection(sw),
                  const SizedBox(height: 24),

                  // Talk to counselor
                  _buildCounselorCard(sw),
                  const SizedBox(height: 24),

                  // ─── Cross-module links ──────────────────
                  _buildSectionTitle(sw ? 'Viunganishi' : 'Related'),
                  const SizedBox(height: 8),
                  if (_hasLowMoodStreak && _currentUserId != null)
                    _buildCrossModuleLink(
                      icon: Icons.local_hospital_rounded,
                      label: sw
                          ? 'Fikiria kuzungumza na mshauri nasaha'
                          : 'Consider speaking with a counselor',
                      iconColor: Colors.amber.shade700,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => DoctorModule(userId: _currentUserId!))),
                    ),
                  _buildCrossModuleLink(
                    icon: Icons.chat_rounded,
                    label: sw
                        ? 'Uliza Shangazi kuhusu kusaidia ustawi wa kihisia wa ${widget.child.name}'
                        : 'Ask Shangazi about supporting ${widget.child.name}\'s emotional health',
                    onTap: () => Navigator.pushNamed(context, '/chat/0'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
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

  // ─── Mood Check-in ──────────────────────────────────────────

  Widget _buildMoodCheckIn(bool sw) {
    final todayMood = _moods[_todayKey()];
    final moods = [
      _MoodOption(0, '😢', sw ? 'Huzuni sana' : 'Very Sad'),
      _MoodOption(1, '😟', sw ? 'Huzuni' : 'Sad'),
      _MoodOption(2, '😐', sw ? 'Kawaida' : 'Okay'),
      _MoodOption(3, '🙂', sw ? 'Furaha' : 'Happy'),
      _MoodOption(4, '😄', sw ? 'Furaha sana' : 'Very Happy'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            sw ? 'Mtoto wako anahisije leo?' : 'How is your child feeling today?',
            style: const TextStyle(fontSize: 14, color: _kSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: moods.map((m) {
              final isSelected = todayMood == m.value;
              return GestureDetector(
                onTap: () {
                  setState(() => _moods[_todayKey()] = m.value);
                  _saveMoods();
                },
                child: Column(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _kPrimary.withValues(alpha: 0.12) : Colors.transparent,
                        border: isSelected
                            ? Border.all(color: _kPrimary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(m.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? _kPrimary : _kSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Weekly Chart ──────────────────────────────────────────

  Widget _buildWeeklyChart(bool sw) {
    final today = DateTime.now();
    final dayLabels = sw
        ? ['Jpt', 'Jtt', 'Jnn', 'Alh', 'Ijm', 'Jms', 'Jpli']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Get Monday of current week
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weekDays.asMap().entries.map((entry) {
          final idx = entry.key;
          final day = entry.value;
          final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          final mood = _moods[key];
          final barHeight = mood != null ? (mood + 1) * 16.0 : 4.0;
          final isToday = day.day == today.day && day.month == today.month;

          return Expanded(
            child: Column(
              children: [
                if (mood != null)
                  Text(
                    ['😢', '😟', '😐', '🙂', '😄'][mood],
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: mood != null ? _kPrimary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dayLabels[idx],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                    color: isToday ? _kPrimary : _kSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Mood Summary ──────────────────────────────────────────

  Widget _buildMoodSummary(bool sw) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    // This week's moods
    final thisWeekMoods = <int>[];
    for (final day in weekDays) {
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final mood = _moods[key];
      if (mood != null) thisWeekMoods.add(mood);
    }

    if (thisWeekMoods.isEmpty) return const SizedBox.shrink();

    final avgMood = thisWeekMoods.reduce((a, b) => a + b) / thisWeekMoods.length;
    final avgEmoji = ['😢', '😟', '😐', '🙂', '😄'][avgMood.round().clamp(0, 4)];
    final avgLabel = sw
        ? ['Huzuni sana', 'Huzuni', 'Kawaida', 'Furaha', 'Furaha sana'][avgMood.round().clamp(0, 4)]
        : ['Very Sad', 'Sad', 'Okay', 'Happy', 'Very Happy'][avgMood.round().clamp(0, 4)];

    // Last week comparison
    final lastMonday = monday.subtract(const Duration(days: 7));
    final lastWeekDays = List.generate(7, (i) => lastMonday.add(Duration(days: i)));
    final lastWeekMoods = <int>[];
    for (final day in lastWeekDays) {
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final mood = _moods[key];
      if (mood != null) lastWeekMoods.add(mood);
    }

    String? comparisonText;
    if (lastWeekMoods.isNotEmpty) {
      final lastAvg = lastWeekMoods.reduce((a, b) => a + b) / lastWeekMoods.length;
      final diff = avgMood - lastAvg;
      if (diff > 0.3) {
        comparisonText = sw ? 'Kuboresha kutoka wiki iliyopita \u2191' : 'Improving from last week \u2191';
      } else if (diff < -0.3) {
        comparisonText = sw ? 'Imeshuka kutoka wiki iliyopita \u2193' : 'Declining from last week \u2193';
      } else {
        comparisonText = sw ? 'Sawa na wiki iliyopita \u2192' : 'Same as last week \u2192';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(avgEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Wastani wa wiki: $avgLabel' : 'Week average: $avgLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                if (comparisonText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    comparisonText,
                    style: TextStyle(
                      fontSize: 12,
                      color: comparisonText.contains('\u2191')
                          ? const Color(0xFF4CAF50)
                          : comparisonText.contains('\u2193')
                              ? Colors.red
                              : _kSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Self-Esteem Activities ──────────────────────────────────

  Widget _buildActivityCard(_SelfEsteemActivity activity, bool sw) {
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
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${activity.index}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sw ? activity.sw : activity.en,
              style: const TextStyle(fontSize: 13, color: _kPrimary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bullying Section ──────────────────────────────────────

  Widget _buildBullyingSection(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signs to watch
          Text(
            sw ? 'Dalili za Kuangalia' : 'Signs to Watch For',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._bullySigns.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_rounded, size: 16, color: _kSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sw ? s.sw : s.en,
                        style: const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),

          // What to do
          Text(
            sw ? 'Nini cha Kufanya' : 'What to Do',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ..._bullyActions.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: _kPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sw ? a.sw : a.en,
                        style: const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ─── Counselor Card ──────────────────────────────────────────

  Widget _buildCounselorCard(bool sw) {
    return Material(
      color: _kPrimary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(sw ? 'Moduli ya Mshauri inakuja hivi karibuni' : 'Counselor module coming soon')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.support_agent_rounded, size: 28, color: _kPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw ? 'Zungumza na Mshauri' : 'Talk to a Counselor',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sw
                          ? 'Pata msaada wa kitaalamu kwa ustawi wa kihisia wa mtoto wako'
                          : 'Get professional help for your child\'s emotional well-being',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 2,
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

  /// Returns true if 3+ low mood days (0 or 1) in the last 7 days
  bool get _hasLowMoodStreak {
    final today = DateTime.now();
    int lowDays = 0;
    for (int i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final mood = _moods[key];
      if (mood != null && mood <= 1) lowDays++;
    }
    return lowDays >= 3;
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

class _MoodOption {
  final int value;
  final String emoji;
  final String label;
  const _MoodOption(this.value, this.emoji, this.label);
}

class _SelfEsteemActivity {
  final int index;
  final String en;
  final String sw;
  const _SelfEsteemActivity(this.index, this.en, this.sw);
}

const _selfEsteemActivities = [
  _SelfEsteemActivity(1, 'Tell your child 3 things you love about them',
      'Mwambie mtoto wako mambo 3 unayoyapenda kwake'),
  _SelfEsteemActivity(2, 'Let them choose an activity for the family',
      'Mruhusu achague shughuli ya familia'),
  _SelfEsteemActivity(3, 'Create a "strengths jar" - write what they are good at',
      'Tengeneza "jar ya nguvu" - andika anachofanya vizuri'),
  _SelfEsteemActivity(4, 'Practice positive affirmations together each morning',
      'Fanyeni mazoezi ya maneno mazuri pamoja kila asubuhi'),
  _SelfEsteemActivity(5, 'Celebrate small achievements, not just big ones',
      'Sherehekea mafanikio madogo, si makubwa tu'),
  _SelfEsteemActivity(6, 'Read stories about overcoming challenges',
      'Soma hadithi kuhusu kushinda changamoto'),
  _SelfEsteemActivity(7, 'Draw or paint feelings together',
      'Chora au paka rangi hisia pamoja'),
  _SelfEsteemActivity(8, 'Teach problem-solving instead of solving for them',
      'Fundisha kutatua matatizo badala ya kutatua kwa niaba yao'),
  _SelfEsteemActivity(9, 'Have a "gratitude moment" before bed',
      'Kuwa na "wakati wa shukrani" kabla ya kulala'),
  _SelfEsteemActivity(10, 'Encourage trying new things without fear of failure',
      'Himiza kujaribu mambo mapya bila hofu ya kushindwa'),
];

class _BilingualText {
  final String en;
  final String sw;
  const _BilingualText(this.en, this.sw);
}

const _bullySigns = [
  _BilingualText('Sudden loss of friends or avoidance of social situations',
      'Kupoteza marafiki ghafla au kuepuka mazingira ya kijamii'),
  _BilingualText('Unexplained injuries or damaged belongings',
      'Majeraha yasiyoelezeka au vitu vilivyoharibiwa'),
  _BilingualText('Changes in eating or sleeping habits',
      'Mabadiliko ya tabia za kula au kulala'),
  _BilingualText('Declining grades or loss of interest in school',
      'Alama zinazoshuka au kupoteza nia ya shule'),
  _BilingualText('Frequent headaches or stomachaches',
      'Maumivu ya kichwa au tumbo ya mara kwa mara'),
];

const _bullyActions = [
  _BilingualText('Listen without judgment - let them talk',
      'Sikiliza bila kuhukumu - waache waongee'),
  _BilingualText('Document incidents with dates and details',
      'Andika matukio na tarehe na maelezo'),
  _BilingualText('Contact the school or teacher immediately',
      'Wasiliana na shule au mwalimu mara moja'),
  _BilingualText('Teach assertiveness, not aggression',
      'Fundisha ujasiri, si ukali'),
  _BilingualText('Seek professional help if needed',
      'Tafuta msaada wa kitaalamu ikihitajika'),
];
