// lib/my_pregnancy/pages/mood_tracker_page.dart
import 'package:flutter/material.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ─── Mood Options ──────────────────────────────────────────────

class _MoodOption {
  final String key;
  final String emoji;
  final String en;
  final String sw;

  const _MoodOption(this.key, this.emoji, this.en, this.sw);
}

const List<_MoodOption> _moods = [
  _MoodOption('happy', '\u{1F60A}', 'Happy', 'Furaha'),
  _MoodOption('calm', '\u{1F60C}', 'Calm', 'Utulivu'),
  _MoodOption('sad', '\u{1F622}', 'Sad', 'Huzuni'),
  _MoodOption('anxious', '\u{1F630}', 'Anxious', 'Wasiwasi'),
  _MoodOption('irritable', '\u{1F624}', 'Irritable', 'Hasira'),
  _MoodOption('energetic', '\u{1F4AA}', 'Energetic', 'Nguvu'),
];

// ─── Affirmations ──────────────────────────────────────────────

class _Affirmation {
  final String en;
  final String sw;
  const _Affirmation(this.en, this.sw);
}

const List<_Affirmation> _affirmations = [
  _Affirmation(
    'Your body is doing amazing work. Trust the process.',
    'Mwili wako unafanya kazi ya ajabu. Amini mchakato.',
  ),
  _Affirmation(
    'You are stronger than you think.',
    'Wewe una nguvu zaidi ya unavyofikiri.',
  ),
  _Affirmation(
    'Every day brings you closer to meeting your baby.',
    'Kila siku inakusogelea kukutana na mtoto wako.',
  ),
  _Affirmation(
    'You are creating a miracle. Be patient with yourself.',
    'Unaunda muujiza. Jistahamilie.',
  ),
  _Affirmation(
    'Rest is not laziness. Your body needs it.',
    'Kupumzika si uvivu. Mwili wako unahitaji.',
  ),
  _Affirmation(
    'You are the perfect mother for your baby.',
    'Wewe ni mama bora kwa mtoto wako.',
  ),
  _Affirmation(
    'Trust your instincts. They are guiding you well.',
    'Amini silika yako. Inakuongoza vizuri.',
  ),
  _Affirmation(
    'It is okay to feel whatever you are feeling today.',
    'Ni sawa kujisikia hisia yoyote leo.',
  ),
  _Affirmation(
    'Your baby already loves the sound of your voice.',
    'Mtoto wako tayari anapenda sauti yako.',
  ),
  _Affirmation(
    'Every kick is a reminder of the love growing inside you.',
    'Kila teke ni ukumbusho wa upendo unaokua ndani yako.',
  ),
  _Affirmation(
    'You are doing something incredible right now.',
    'Unafanya jambo la ajabu sasa hivi.',
  ),
  _Affirmation(
    'Take it one day at a time. You are doing great.',
    'Chukua siku moja kwa wakati. Unafanya vizuri.',
  ),
  _Affirmation(
    'Your strength is preparing you for the journey ahead.',
    'Nguvu yako inakuandaa kwa safari ijayo.',
  ),
  _Affirmation(
    'Breathe deeply. Everything will be alright.',
    'Pumua kwa undani. Kila kitu kitakuwa sawa.',
  ),
  _Affirmation(
    'You are surrounded by love and support.',
    'Umezungukwa na upendo na msaada.',
  ),
  _Affirmation(
    'Your body knows what to do. Trust it.',
    'Mwili wako unajua cha kufanya. Uamini.',
  ),
  _Affirmation(
    'Today is a beautiful day to be pregnant.',
    'Leo ni siku nzuri kuwa mjamzito.',
  ),
  _Affirmation(
    'You are growing a human being. That is amazing.',
    'Unakuza binadamu. Hiyo ni ya ajabu.',
  ),
  _Affirmation(
    'Your baby can feel your calm. Stay peaceful.',
    'Mtoto wako anahisi utulivu wako. Kaa na amani.',
  ),
  _Affirmation(
    'Nourish your body. It is working hard for two.',
    'Lishe mwili wako. Unafanya kazi kwa wawili.',
  ),
  _Affirmation(
    'You are not alone in this journey.',
    'Hujapwekeka katika safari hii.',
  ),
  _Affirmation(
    'Celebrate every milestone, big or small.',
    'Sherehekea kila hatua, kubwa au ndogo.',
  ),
  _Affirmation(
    'Your love is already shaping your baby.',
    'Upendo wako tayari unamuunda mtoto wako.',
  ),
  _Affirmation(
    'Be gentle with yourself. You deserve kindness.',
    'Jitendee upole. Unastahili huruma.',
  ),
  _Affirmation(
    'Your baby is safe and growing beautifully.',
    'Mtoto wako yuko salama na anakua vizuri.',
  ),
  _Affirmation(
    'Every change in your body is a sign of progress.',
    'Kila mabadiliko ya mwili ni dalili ya maendeleo.',
  ),
  _Affirmation(
    'You will be an amazing mother.',
    'Utakuwa mama wa ajabu.',
  ),
  _Affirmation(
    'Slow down and enjoy this special time.',
    'Punguza kasi na furahia wakati huu maalum.',
  ),
  _Affirmation(
    'Your heartbeat is your baby\'s favorite song.',
    'Mapigo ya moyo wako ni wimbo unaoupenda mtoto wako.',
  ),
  _Affirmation(
    'You are building a beautiful future.',
    'Unajenga mustakabali mzuri.',
  ),
];

// ─── WHO-5 Questions ───────────────────────────────────────────

class _WellnessQuestion {
  final String en;
  final String sw;
  const _WellnessQuestion(this.en, this.sw);
}

const List<_WellnessQuestion> _who5Questions = [
  _WellnessQuestion(
    'I have felt cheerful and in good spirits',
    'Nimejisikia furaha na moyo mwema',
  ),
  _WellnessQuestion(
    'I have felt calm and relaxed',
    'Nimejisikia utulivu',
  ),
  _WellnessQuestion(
    'I have felt active and energetic',
    'Nimejisikia nguvu na bidii',
  ),
  _WellnessQuestion(
    'I woke up feeling fresh and rested',
    'Niliamka nikijisikia safi',
  ),
  _WellnessQuestion(
    'My daily life has been filled with things that interest me',
    'Maisha yangu yamejaa mambo yanayonivutia',
  ),
];

// Scale labels (5-point: 0-5 mapped to indices 0-4 visually)
const List<Map<String, String>> _scaleLabels = [
  {'en': 'All the time', 'sw': 'Wakati wote'},
  {'en': 'Most of the time', 'sw': 'Mara nyingi'},
  {'en': 'Sometimes', 'sw': 'Wakati mwingine'},
  {'en': 'Rarely', 'sw': 'Mara chache'},
  {'en': 'Never', 'sw': 'Kamwe'},
];

// ─── Page ──────────────────────────────────────────────────────

class MoodTrackerPage extends StatefulWidget {
  final Pregnancy pregnancy;

  const MoodTrackerPage({super.key, required this.pregnancy});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  final MyPregnancyService _service = MyPregnancyService();

  bool _isLoading = true;
  bool _isSavingMood = false;

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  // Today's mood
  String? _selectedMood;
  final TextEditingController _notesController = TextEditingController();

  // WHO-5 answers (index 0-4 for each question, null = unanswered)
  final List<int?> _wellnessAnswers = List.filled(5, null);

  // Mood history
  List<Map<String, dynamic>> _moodHistory = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _isSw =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getMoods(widget.pregnancy.id, token: _token);
      if (mounted && result.success) {
        setState(() {
          _moodHistory = List<Map<String, dynamic>>.from(result.items);
        });
      }
    } catch (_) {
      // Ignore — empty history
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) return;
    setState(() => _isSavingMood = true);
    try {
      final result = await _service.saveMood(
        pregnancyId: widget.pregnancy.id,
        userId: widget.pregnancy.userId,
        mood: _selectedMood!,
        notes: _notesController.text.trim(),
        token: _token,
      );
      if (mounted) {
        final sw = _isSw;
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(sw
                    ? 'Hisia zimehifadhiwa'
                    : 'Mood saved')),
          );
          _notesController.clear();
          _loadData(); // Refresh history
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result.message ??
                    (sw
                        ? 'Imeshindwa kuhifadhi'
                        : 'Failed to save'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSw ? 'Kosa: $e' : 'Error: $e')),
        );
      }
    }
    if (mounted) setState(() => _isSavingMood = false);
  }

  _Affirmation get _todayAffirmation {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return _affirmations[dayOfYear % _affirmations.length];
  }

  // WHO-5 scoring: each answer 0-5 (index 0 = 5, index 4 = 0)
  // Raw score 0-25, percentage = raw * 4
  int? get _wellnessScore {
    if (_wellnessAnswers.any((a) => a == null)) return null;
    int raw = 0;
    for (final a in _wellnessAnswers) {
      raw += (4 - a!); // index 0 = 4 points (best), index 4 = 0 points
    }
    // Scale: max = 20, convert to percentage
    return ((raw / 20) * 100).round();
  }

  String _wellnessInterpretation(int score, bool sw) {
    if (score > 50) {
      return sw ? 'Hali nzuri' : 'Good';
    } else if (score >= 25) {
      return sw ? 'Wastani' : 'Moderate';
    } else {
      return sw ? 'Inahitaji msaada' : 'Needs attention';
    }
  }

  Color _wellnessColor(int score) {
    if (score > 50) return const Color(0xFF2E7D32);
    if (score >= 25) return const Color(0xFFF57F17);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final sw = _isSw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          sw ? 'Hisia na Ustawi' : 'Mood & Wellness',
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: _kPrimary),
        ),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTodayMood(sw),
                      const SizedBox(height: 24),
                      _buildAffirmation(sw),
                      const SizedBox(height: 24),
                      _buildWellnessCheck(sw),
                      const SizedBox(height: 24),
                      _buildProfessionalHelp(sw),
                      const SizedBox(height: 24),
                      _buildMoodHistory(sw),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Section 1: Today's Mood ──────────────────────────────────

  Widget _buildTodayMood(bool sw) {
    return _SectionCard(
      title: sw ? 'Hisia za Leo' : "Today's Mood",
      children: [
        // Mood row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _moods.map((mood) {
            final selected = _selectedMood == mood.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood.key),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sw ? mood.sw : mood.en,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? _kPrimary : _kSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Notes
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: sw ? 'Maelezo (hiari)' : 'Notes (optional)',
            hintText:
                sw ? 'Unahisije leo?' : 'How are you feeling today?',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          minLines: 1,
        ),
        const SizedBox(height: 12),

        // Save button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed:
                (_selectedMood != null && !_isSavingMood) ? _saveMood : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSavingMood
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(
                    sw ? 'Hifadhi Hisia' : 'Save Mood',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Section 2: Daily Affirmation ─────────────────────────────

  Widget _buildAffirmation(bool sw) {
    final affirmation = _todayAffirmation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                sw ? 'Ujumbe wa Leo' : 'Daily Affirmation',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sw ? affirmation.sw : affirmation.en,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 3: Wellness Check ────────────────────────────────

  Widget _buildWellnessCheck(bool sw) {
    final score = _wellnessScore;

    return _SectionCard(
      title: sw ? 'Uchunguzi wa Ustawi (WHO-5)' : 'Wellness Check (WHO-5)',
      children: [
        Text(
          sw
              ? 'Jibu kulingana na hali yako wiki hii.'
              : 'Answer based on how you felt this week.',
          style: const TextStyle(fontSize: 13, color: _kSecondary),
        ),
        const SizedBox(height: 12),

        // Scale legend
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: List.generate(5, (i) {
            return Text(
              '${i + 1}= ${sw ? _scaleLabels[i]['sw'] : _scaleLabels[i]['en']}',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            );
          }),
        ),
        const SizedBox(height: 16),

        // Questions
        ...List.generate(_who5Questions.length, (qi) {
          final q = _who5Questions[qi];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? q.sw : q.en,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (si) {
                    final selected = _wellnessAnswers[qi] == si;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                            () => _wellnessAnswers[qi] = si),
                        child: Container(
                          height: 48,
                          margin: EdgeInsets.only(
                              right: si < 4 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: selected
                                ? _kPrimary
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${si + 1}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  selected ? Colors.white : _kPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        }),

        // Score
        if (score != null) ...[
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                sw ? 'Alama: $score%' : 'Score: $score%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _wellnessColor(score).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _wellnessInterpretation(score, sw),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _wellnessColor(score),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Section 4: Professional Help ─────────────────────────────

  Widget _buildProfessionalHelp(bool sw) {
    return GestureDetector(
      onTap: () {
        try {
          Navigator.pushNamed(context, '/doctor');
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isSw
                  ? 'Huduma hii itapatikana hivi karibuni'
                  : 'This service will be available soon'),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: _kPrimary,
              radius: 22,
              child: Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Ongea na Mtaalamu' : 'Talk to a Counselor',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sw
                        ? 'Pata msaada wa kitaalamu kupitia Daktari'
                        : 'Get professional support via Doctor module',
                    style: const TextStyle(
                        fontSize: 13, color: _kSecondary),
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
    );
  }

  // ─── Section 5: Mood History ──────────────────────────────────

  Widget _buildMoodHistory(bool sw) {
    return _SectionCard(
      title: sw ? 'Historia ya Hisia' : 'Mood History',
      children: [
        if (_moodHistory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              sw
                  ? 'Hakuna hisia zilizohifadhiwa bado.'
                  : 'No moods recorded yet.',
              style: const TextStyle(fontSize: 14, color: _kSecondary),
            ),
          )
        else
          ...(_moodHistory.take(7).map((entry) {
            final mood = entry['mood'] as String? ?? '';
            final notes = entry['notes'] as String? ?? '';
            final dateStr = entry['created_at'] as String? ??
                entry['date'] as String? ??
                '';
            final date = DateTime.tryParse(dateStr);
            final moodOption = _moods.cast<_MoodOption?>().firstWhere(
                  (m) => m!.key == mood,
                  orElse: () => null,
                );

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                moodOption?.emoji ?? '\u{2753}',
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(
                moodOption != null
                    ? (sw ? moodOption.sw : moodOption.en)
                    : mood,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: notes.isNotEmpty
                  ? Text(
                      notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: _kSecondary),
                    )
                  : null,
              trailing: date != null
                  ? Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                          fontSize: 12, color: _kSecondary),
                    )
                  : null,
              dense: true,
            );
          })),
      ],
    );
  }
}

// ─── Section Card Widget ──────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
