// lib/my_children/pages/career_guidance_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/my_children_models.dart';
import 'academic_tracker_page.dart';
import 'university_prep_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class CareerGuidancePage extends StatefulWidget {
  final Child child;
  final int userId;

  const CareerGuidancePage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<CareerGuidancePage> createState() => _CareerGuidancePageState();
}

class _CareerGuidancePageState extends State<CareerGuidancePage> {
  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  // Assessment answers: question index -> score (1-5)
  final Map<int, int> _answers = {};
  bool _showResults = false;
  bool _isLoading = false;

  // Career clusters
  static const _clusters = [
    'science_tech',
    'business',
    'arts_creative',
    'social',
    'trade_practical',
  ];

  // Question -> cluster mapping (2 questions per cluster)
  static const _questionClusterMap = [
    'science_tech', // Q0
    'science_tech', // Q1
    'business', // Q2
    'business', // Q3
    'arts_creative', // Q4
    'arts_creative', // Q5
    'social', // Q6
    'social', // Q7
    'trade_practical', // Q8
    'trade_practical', // Q9
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedAnswers();
  }

  Future<void> _loadSavedAnswers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'career_assessment_${widget.child.id}';
      for (int i = 0; i < 10; i++) {
        final v = prefs.getInt('${key}_q$i');
        if (v != null) _answers[i] = v;
      }
      if (_answers.length == 10) _showResults = true;
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAnswers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'career_assessment_${widget.child.id}';
      for (final entry in _answers.entries) {
        await prefs.setInt('${key}_q${entry.key}', entry.value);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sw
                ? 'Imeshindikana kuhifadhi majibu'
                : 'Failed to save answers'),
          ),
        );
      }
    }
  }

  List<_Question> _getQuestions(bool sw) {
    return [
      _Question(
        en: 'Do you enjoy solving math problems?',
        sw: 'Je, unapenda kutatua hesabu?',
      ),
      _Question(
        en: 'Are you curious about how technology works?',
        sw: 'Je, una hamu ya kujua teknolojia inavyofanya kazi?',
      ),
      _Question(
        en: 'Do you like managing money or planning budgets?',
        sw: 'Je, unapenda kusimamia pesa au kupanga bajeti?',
      ),
      _Question(
        en: 'Do you enjoy negotiating or convincing others?',
        sw: 'Je, unapenda kujadiliana au kushawishi wengine?',
      ),
      _Question(
        en: 'Do you enjoy drawing, painting, or creating art?',
        sw: 'Je, unapenda kuchora, kupaka rangi, au kutengeneza sanaa?',
      ),
      _Question(
        en: 'Do you like writing stories or making music?',
        sw: 'Je, unapenda kuandika hadithi au kutengeneza muziki?',
      ),
      _Question(
        en: 'Do you like helping others with their problems?',
        sw: 'Je, unapenda kusaidia wengine na matatizo yao?',
      ),
      _Question(
        en: 'Do you enjoy teaching or explaining things to others?',
        sw: 'Je, unapenda kufundisha au kuelezea mambo kwa wengine?',
      ),
      _Question(
        en: 'Do you enjoy fixing or building things with your hands?',
        sw: 'Je, unapenda kutengeneza au kujenga vitu kwa mikono yako?',
      ),
      _Question(
        en: 'Do you like working outdoors or with plants and animals?',
        sw: 'Je, unapenda kufanya kazi nje au na mimea na wanyama?',
      ),
    ];
  }

  List<String> _getScaleLabels(bool sw) {
    return sw
        ? [
            'Sikubaliani kabisa',
            'Sikubaliani',
            'Wastani',
            'Nakubaliana',
            'Nakubaliana sana',
          ]
        : [
            'Strongly disagree',
            'Disagree',
            'Neutral',
            'Agree',
            'Strongly agree',
          ];
  }

  // Calculate scores per cluster
  Map<String, int> _calculateScores() {
    final scores = <String, int>{};
    for (final c in _clusters) {
      scores[c] = 0;
    }
    for (final entry in _answers.entries) {
      final cluster = _questionClusterMap[entry.key];
      scores[cluster] = (scores[cluster] ?? 0) + entry.value;
    }
    return scores;
  }

  // Get top 3 clusters sorted by score
  List<MapEntry<String, int>> _topClusters() {
    final scores = _calculateScores();
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
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
          sw ? 'Mwongozo wa Kazi' : 'Career Guidance',
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
            : _showResults
                ? _buildResults(sw)
                : _buildAssessment(sw),
      ),
    );
  }

  // ─── Assessment View ─────────────────────────────────────────

  Widget _buildAssessment(bool sw) {
    final questions = _getQuestions(sw);
    final scaleLabels = _getScaleLabels(sw);
    final allAnswered = _answers.length == 10;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sw ? 'Tathmini ya Maslahi' : 'Interest Assessment',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                sw
                    ? 'Jibu maswali 10 hapa chini ili kugundua fani zinazokufaa.'
                    : 'Answer the 10 questions below to discover career paths that match your interests.',
                style: const TextStyle(fontSize: 14, color: _kSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Questions
        ...questions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          return _buildQuestionCard(idx, q, scaleLabels, sw);
        }),

        const SizedBox(height: 16),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: allAnswered
                ? () {
                    _saveAnswers();
                    setState(() => _showResults = true);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kPrimary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              sw ? 'Angalia Matokeo' : 'View Results',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuestionCard(
      int index, _Question q, List<String> scaleLabels, bool sw) {
    final selectedScore = _answers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${sw ? q.sw : q.en}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (score) {
            final actualScore = score + 1;
            final isSelected = selectedScore == actualScore;
            return InkWell(
              onTap: () {
                setState(() => _answers[index] = actualScore);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _kPrimary : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? _kPrimary
                              : _kPrimary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scaleLabels[score],
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? _kPrimary : _kSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Results View ────────────────────────────────────────────

  Widget _buildResults(bool sw) {
    final top3 = _topClusters();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Results header
        Container(
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
                    child: const Icon(Icons.stars_rounded,
                        color: _kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Matokeo ya ${widget.child.name}'
                          : '${widget.child.name}\'s Results',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                sw
                    ? 'Fani 3 bora zinazofanana na maslahi:'
                    : 'Top 3 career clusters matching interests:',
                style: const TextStyle(fontSize: 14, color: _kSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Top 3 clusters
        ...top3.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final cluster = entry.value;
          return _buildClusterCard(rank, cluster.key, cluster.value, sw);
        }),

        const SizedBox(height: 16),

        // Subject-career mapping
        _buildSubjectMapping(top3.first.key, sw),

        const SizedBox(height: 16),

        // Academic link
        _buildAcademicLink(top3.first.key, sw),

        const SizedBox(height: 16),

        // Tanzania context
        _buildTanzaniaContext(sw),

        const SizedBox(height: 16),

        // Retake button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _answers.clear();
                _showResults = false;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              sw ? 'Fanya Tathmini Tena' : 'Retake Assessment',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

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
              ? 'Uliza Shangazi kuhusu fani maarufu Tanzania'
              : 'Ask Shangazi about career paths in Tanzania',
          onTap: () => Navigator.pushNamed(context, '/chat/0'),
        ),
        _buildCrossModuleLink(
          icon: Icons.school_rounded,
          label: sw
              ? 'Angalia matokeo ya masomo'
              : 'View academic results',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AcademicTrackerPage(child: widget.child, userId: widget.userId))),
        ),
        _buildCrossModuleLink(
          icon: Icons.account_balance_rounded,
          label: sw
              ? 'Maandalizi ya Chuo Kikuu'
              : 'University Preparation',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => UniversityPrepPage(child: widget.child, userId: widget.userId))),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildClusterCard(int rank, String cluster, int score, bool sw) {
    final info = _clusterInfo(cluster, sw);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  info.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$score/10',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Linear progress
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 10,
              backgroundColor: _kPrimary.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sw ? 'Fani:' : 'Careers:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: info.careers.map((career) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  career,
                  style: const TextStyle(fontSize: 12, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectMapping(String topCluster, bool sw) {
    final mapping = _subjectMapping(topCluster, sw);
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
              const Icon(Icons.menu_book_rounded,
                  color: _kPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw ? 'Masomo ya Kuzingatia' : 'Focus Subjects',
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
          const SizedBox(height: 10),
          Text(
            mapping.description,
            style: const TextStyle(fontSize: 14, color: _kSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ...mapping.subjects.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: _kPrimary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style:
                            const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 1,
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

  Widget _buildAcademicLink(String topCluster, bool sw) {
    final info = _clusterInfo(topCluster, sw);
    final mapping = _subjectMapping(topCluster, sw);
    final focusSubjects = mapping.subjects.take(3).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw ? 'Unganisha na Masomo' : 'Link to Academics',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sw
                ? 'Fani bora ya ${widget.child.name} ni ${info.name}. Masomo ya kuzingatia: $focusSubjects.'
                : '${widget.child.name}\'s top career cluster is ${info.name}. Focus subjects: $focusSubjects.',
            style: const TextStyle(fontSize: 13, color: _kPrimary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to academic tracker
                Navigator.pop(context);
              },
              icon: const Icon(Icons.assessment_rounded, size: 18),
              label: Text(
                sw ? 'Angalia Matokeo ya Shule' : 'Check Academic Records',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTanzaniaContext(bool sw) {
    final professions = sw
        ? [
            'Uhandisi (TZS 800K - 3M/mwezi)',
            'Udaktari (TZS 1M - 5M/mwezi)',
            'Ualimu (TZS 400K - 1.5M/mwezi)',
            'Uhasibu (TZS 600K - 2.5M/mwezi)',
            'Kilimo cha kisasa (TZS 500K - 4M/mwezi)',
            'Teknolojia ya Habari (TZS 700K - 3M/mwezi)',
          ]
        : [
            'Engineering (TZS 800K - 3M/month)',
            'Medicine (TZS 1M - 5M/month)',
            'Teaching (TZS 400K - 1.5M/month)',
            'Accounting (TZS 600K - 2.5M/month)',
            'Modern Agriculture (TZS 500K - 4M/month)',
            'Information Technology (TZS 700K - 3M/month)',
          ];

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
              const Icon(Icons.location_on_rounded,
                  color: _kPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sw ? 'Fani Maarufu Tanzania' : 'Popular Professions in Tanzania',
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
          const SizedBox(height: 10),
          ...professions.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, color: _kPrimary, size: 6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p,
                        style:
                            const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Text(
            sw
                ? 'Njia ya elimu: Msingi -> Sekondari -> Chuo/Chuo Kikuu'
                : 'Education path: Primary -> Secondary -> College/University',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _kSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Data Helpers ────────────────────────────────────────────

  _ClusterInfo _clusterInfo(String cluster, bool sw) {
    switch (cluster) {
      case 'science_tech':
        return _ClusterInfo(
          name: sw ? 'Sayansi na Teknolojia' : 'Science & Technology',
          careers: sw
              ? ['Mhandisi', 'Daktari', 'Mprogramu', 'Mwanasayansi']
              : ['Engineer', 'Doctor', 'Programmer', 'Scientist'],
        );
      case 'business':
        return _ClusterInfo(
          name: sw ? 'Biashara' : 'Business',
          careers: sw
              ? ['Mhasibu', 'Mjasiriamali', 'Meneja', 'Mchumi']
              : ['Accountant', 'Entrepreneur', 'Manager', 'Economist'],
        );
      case 'arts_creative':
        return _ClusterInfo(
          name: sw ? 'Sanaa na Ubunifu' : 'Arts & Creative',
          careers: sw
              ? ['Mbuni', 'Mwandishi', 'Mwanamuziki', 'Msanii']
              : ['Designer', 'Writer', 'Musician', 'Artist'],
        );
      case 'social':
        return _ClusterInfo(
          name: sw ? 'Huduma za Jamii' : 'Social Services',
          careers: sw
              ? ['Mwalimu', 'Mshauri', 'Mfanyakazi wa Jamii', 'Mwanasheria']
              : ['Teacher', 'Counselor', 'Social Worker', 'Lawyer'],
        );
      case 'trade_practical':
        return _ClusterInfo(
          name: sw ? 'Ufundi na Vitendo' : 'Trade & Practical',
          careers: sw
              ? ['Fundi Mitambo', 'Fundi Umeme', 'Mkulima', 'Fundi Seremala']
              : ['Mechanic', 'Electrician', 'Farmer', 'Carpenter'],
        );
      default:
        return _ClusterInfo(name: cluster, careers: []);
    }
  }

  _SubjectMapping _subjectMapping(String cluster, bool sw) {
    switch (cluster) {
      case 'science_tech':
        return _SubjectMapping(
          description: sw
              ? 'Kwa fani za sayansi na teknolojia, zingatia masomo haya:'
              : 'For Science & Technology careers, focus on:',
          subjects: sw
              ? ['Fizikia', 'Hesabu', 'Kemia', 'Baiolojia', 'Kompyuta']
              : ['Physics', 'Mathematics', 'Chemistry', 'Biology', 'Computer Science'],
        );
      case 'business':
        return _SubjectMapping(
          description: sw
              ? 'Kwa fani za biashara, zingatia masomo haya:'
              : 'For Business careers, focus on:',
          subjects: sw
              ? ['Hesabu', 'Uhasibu', 'Biashara', 'Uchumi', 'Kiingereza']
              : ['Mathematics', 'Bookkeeping', 'Commerce', 'Economics', 'English'],
        );
      case 'arts_creative':
        return _SubjectMapping(
          description: sw
              ? 'Kwa fani za sanaa na ubunifu, zingatia masomo haya:'
              : 'For Arts & Creative careers, focus on:',
          subjects: sw
              ? ['Sanaa', 'Kiswahili', 'Kiingereza', 'Muziki', 'Historia']
              : ['Fine Art', 'Kiswahili', 'English', 'Music', 'History'],
        );
      case 'social':
        return _SubjectMapping(
          description: sw
              ? 'Kwa fani za huduma za jamii, zingatia masomo haya:'
              : 'For Social Services careers, focus on:',
          subjects: sw
              ? ['Kiswahili', 'Kiingereza', 'Historia', 'Uraia', 'Saikolojia']
              : ['Kiswahili', 'English', 'History', 'Civics', 'Psychology'],
        );
      case 'trade_practical':
        return _SubjectMapping(
          description: sw
              ? 'Kwa fani za ufundi na vitendo, zingatia masomo haya:'
              : 'For Trade & Practical careers, focus on:',
          subjects: sw
              ? ['Hesabu', 'Fizikia', 'Kilimo', 'Ufundi', 'Baiolojia']
              : ['Mathematics', 'Physics', 'Agriculture', 'Technical Drawing', 'Biology'],
        );
      default:
        return _SubjectMapping(description: '', subjects: []);
    }
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
}

// ─── Helper Classes ──────���───────────────────���───────────────────

class _Question {
  final String en;
  final String sw;
  const _Question({required this.en, required this.sw});
}

class _ClusterInfo {
  final String name;
  final List<String> careers;
  const _ClusterInfo({required this.name, required this.careers});
}

class _SubjectMapping {
  final String description;
  final List<String> subjects;
  const _SubjectMapping({required this.description, required this.subjects});
}
