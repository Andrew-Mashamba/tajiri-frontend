// lib/my_children/pages/speech_tracker_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../doctor/doctor_module.dart';
import '../models/my_children_models.dart';
import '../services/my_children_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class SpeechTrackerPage extends StatefulWidget {
  final Child child;
  final int userId;

  const SpeechTrackerPage({
    super.key,
    required this.child,
    required this.userId,
  });

  @override
  State<SpeechTrackerPage> createState() => _SpeechTrackerPageState();
}

class _SpeechTrackerPageState extends State<SpeechTrackerPage> {
  final MyChildrenService _service = MyChildrenService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _words = [];
  String? _token;

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
      final result = await _service.getSpeechHistory(
        widget.child.id,
        token: _token,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _words = result.items;
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

  void _showLogWordDialog() {
    final wordController = TextEditingController();
    String selectedType = 'new_word';
    String selectedLanguage = 'both';
    final sw = _sw;

    final types = [
      {'value': 'first_word', 'en': 'First Word', 'sw': 'Neno la Kwanza'},
      {'value': 'new_word', 'en': 'New Word', 'sw': 'Neno Jipya'},
      {
        'value': 'first_sentence',
        'en': 'First Sentence',
        'sw': 'Sentensi ya Kwanza'
      },
      {
        'value': 'conversation',
        'en': 'Conversation',
        'sw': 'Mazungumzo'
      },
    ];

    final languages = [
      {'value': 'swahili', 'label': 'Kiswahili'},
      {'value': 'english', 'label': 'English'},
      {'value': 'both', 'en': 'Both', 'sw': 'Zote'},
    ];

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
                    sw ? 'Rekodi Neno Jipya' : 'Log New Word',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: wordController,
                    decoration: InputDecoration(
                      labelText: sw ? 'Neno / Sentensi' : 'Word / Sentence',
                      labelStyle:
                          const TextStyle(fontSize: 13, color: _kSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    sw ? 'Aina:' : 'Type:',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: types.map((t) {
                      final isSelected = selectedType == t['value'];
                      return ChoiceChip(
                        label: Text(sw
                            ? (t['sw'] ?? t['en'] ?? '')
                            : (t['en'] ?? '')),
                        selected: isSelected,
                        onSelected: (v) {
                          if (v) {
                            setSheetState(
                                () => selectedType = t['value'] ?? 'new_word');
                          }
                        },
                        selectedColor: _kPrimary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected ? _kPrimary : _kSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    sw ? 'Lugha:' : 'Language:',
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: languages.map((l) {
                      final isSelected = selectedLanguage == l['value'];
                      return ChoiceChip(
                        label: Text(sw
                            ? (l['sw'] ?? l['label'] ?? '')
                            : (l['en'] ?? l['label'] ?? '')),
                        selected: isSelected,
                        onSelected: (v) {
                          if (v) {
                            setSheetState(() =>
                                selectedLanguage = l['value'] ?? 'both');
                          }
                        },
                        selectedColor: _kPrimary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected ? _kPrimary : _kSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (wordController.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        await _saveWord(
                          wordController.text.trim(),
                          selectedType,
                          selectedLanguage,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        sw ? 'Hifadhi' : 'Save',
                        style: const TextStyle(fontSize: 15),
                      ),
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

  Future<void> _saveWord(String content, String type, String language) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _service.logSpeech(
        widget.child.id,
        type,
        content,
        language,
        token: _token,
      );
      if (mounted) {
        if (result.success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(_sw ? 'Neno limehifadhiwa' : 'Word saved'),
            ),
          );
          _loadData();
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(result.message ??
                  (_sw ? 'Imeshindwa kuhifadhi' : 'Failed to save')),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_sw ? 'Hitilafu imetokea' : 'An error occurred'),
          ),
        );
      }
    }
  }

  // ─── Milestones checklist ──────────────────────────────────

  List<_SpeechMilestone> _getMilestones(bool sw) {
    final ageYears = widget.child.ageInYears;
    return [
      _SpeechMilestone(
        ageLabel: sw ? 'Miaka 2' : '2 years',
        items: [
          _MilestoneItem(
            en: '50+ words',
            sw: 'Maneno 50+',
            met: _words.length >= 50,
          ),
          _MilestoneItem(
            en: '2-word phrases',
            sw: 'Vifungu vya maneno 2',
            met: _words.any((w) => w['type'] == 'first_sentence'),
          ),
        ],
        active: ageYears >= 2,
      ),
      _SpeechMilestone(
        ageLabel: sw ? 'Miaka 3' : '3 years',
        items: [
          _MilestoneItem(
            en: '200+ words',
            sw: 'Maneno 200+',
            met: _words.length >= 200,
          ),
          _MilestoneItem(
            en: '3-word sentences',
            sw: 'Sentensi za maneno 3',
            met: false,
          ),
          _MilestoneItem(
            en: 'Asks "why?"',
            sw: 'Anauliza "kwa nini?"',
            met: false,
          ),
        ],
        active: ageYears >= 3,
      ),
      _SpeechMilestone(
        ageLabel: sw ? 'Miaka 4' : '4 years',
        items: [
          _MilestoneItem(
            en: 'Tells stories',
            sw: 'Anasimulia hadithi',
            met: false,
          ),
          _MilestoneItem(
            en: 'Uses past tense',
            sw: 'Anatumia wakati uliopita',
            met: false,
          ),
        ],
        active: ageYears >= 4,
      ),
      _SpeechMilestone(
        ageLabel: sw ? 'Miaka 5' : '5 years',
        items: [
          _MilestoneItem(
            en: 'Speaks clearly',
            sw: 'Anazungumza wazi',
            met: false,
          ),
          _MilestoneItem(
            en: 'Complex sentences',
            sw: 'Sentensi ngumu',
            met: false,
          ),
        ],
        active: ageYears >= 5,
      ),
    ];
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
          sw ? 'Maendeleo ya Lugha' : 'Speech Development',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogWordDialog,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  children: [
                    // ─── Word Count Card ──────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.chat_bubble_rounded,
                              size: 32, color: _kPrimary),
                          const SizedBox(height: 8),
                          Text(
                            '${_words.length}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                          Text(
                            sw ? 'Jumla ya Maneno' : 'Total Words',
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Recent Words ─────────────────────
                    _buildSectionTitle(
                        sw ? 'Maneno ya Hivi Karibuni' : 'Recent Words'),
                    const SizedBox(height: 8),
                    if (_words.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          sw
                              ? 'Bonyeza + kurekodi neno la kwanza'
                              : 'Tap + to log the first word',
                          style: const TextStyle(
                              fontSize: 13, color: _kSecondary),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      ..._words.take(15).map((w) => GestureDetector(
                          onLongPress: () => _confirmDeleteSpeech(w),
                          child: _buildWordItem(w, sw),
                        )),
                    const SizedBox(height: 16),

                    // ─── Vocabulary Growth Insights ───────
                    _buildVocabularyGrowth(sw),
                    const SizedBox(height: 16),

                    // ─── Speech Milestones ────────────────
                    _buildSectionTitle(
                        sw ? 'Hatua za Lugha' : 'Speech Milestones'),
                    const SizedBox(height: 8),
                    ..._getMilestones(sw)
                        .map((m) => _buildMilestoneGroup(m, sw)),
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
                          ? 'Nunua vitabu na flashcards'
                          : 'Shop books & flashcards',
                      onTap: () => Navigator.pushNamed(context, '/home', arguments: {'tab': 'shop'}),
                    ),
                    if (_words.length < 50 && widget.child.ageInYears >= 2)
                      _buildCrossModuleLink(
                        icon: Icons.local_hospital_rounded,
                        label: sw
                            ? 'Zungumza na daktari kuhusu maendeleo ya lugha'
                            : 'Talk to a doctor about speech development',
                        iconColor: Colors.amber.shade800,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => DoctorModule(userId: widget.userId))),
                      ),
                    _buildCrossModuleLink(
                      icon: Icons.chat_rounded,
                      label: sw
                          ? 'Uliza Shangazi kuhusu shughuli za lugha'
                          : 'Ask Shangazi about speech activities',
                      onTap: () => Navigator.pushNamed(context, '/chat/0'),
                    ),
                    const SizedBox(height: 80), // FAB clearance
                  ],
                ),
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

  Widget _buildVocabularyGrowth(bool sw) {
    if (_words.isEmpty) return const SizedBox.shrink();

    final totalWords = _words.length;

    // New words this week vs last week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));

    final thisWeekWords = _words.where((w) {
      final d = DateTime.tryParse(w['logged_at']?.toString() ?? '');
      return d != null && d.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).length;

    final lastWeekWords = _words.where((w) {
      final d = DateTime.tryParse(w['logged_at']?.toString() ?? '');
      return d != null &&
          d.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
          d.isBefore(weekStart);
    }).length;

    final weekDiff = thisWeekWords - lastWeekWords;

    // Language balance
    final swahiliCount =
        _words.where((w) => w['language'] == 'swahili').length;
    final englishCount =
        _words.where((w) => w['language'] == 'english').length;
    final bothCount = _words.where((w) => w['language'] == 'both').length;
    final totalLang = swahiliCount + englishCount + bothCount;

    // Expected vocabulary for age
    final ageYears = widget.child.ageInYears;
    int expectedWords;
    String ageLabel;
    if (ageYears <= 1) {
      expectedWords = 10;
      ageLabel = sw ? 'mwaka 1' : '1 year';
    } else if (ageYears == 2) {
      expectedWords = 50;
      ageLabel = sw ? 'miaka 2' : '2 years';
    } else if (ageYears == 3) {
      expectedWords = 200;
      ageLabel = sw ? 'miaka 3' : '3 years';
    } else if (ageYears == 4) {
      expectedWords = 500;
      ageLabel = sw ? 'miaka 4' : '4 years';
    } else {
      expectedWords = 1000;
      ageLabel = sw ? 'miaka $ageYears' : '$ageYears years';
    }

    final vocabPct =
        expectedWords > 0 ? (totalWords / expectedWords * 100).round() : 0;

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
                  sw ? 'Ukuaji wa Msamiati' : 'Vocabulary Growth',
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

          // Total and new this week
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw ? 'Jumla ya Maneno' : 'Total Words',
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalWords',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sw ? 'Wiki Hii' : 'This Week',
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '+$thisWeekWords',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (lastWeekWords > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: weekDiff >= 0
                                  ? const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              weekDiff > 0
                                  ? '\u2191$weekDiff'
                                  : weekDiff < 0
                                      ? '\u2193${-weekDiff}'
                                      : '\u2192',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: weekDiff > 0
                                    ? const Color(0xFF2E7D32)
                                    : weekDiff < 0
                                        ? Colors.red
                                        : _kSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Language balance
          if (totalLang > 0) ...[
            Text(
              sw ? 'Uwiano wa Lugha:' : 'Language Balance:',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (swahiliCount > 0)
                  _buildLangChip(
                    'Kiswahili',
                    '${(swahiliCount / totalLang * 100).round()}%',
                    _kPrimary,
                  ),
                if (swahiliCount > 0 && englishCount > 0)
                  const SizedBox(width: 8),
                if (englishCount > 0)
                  _buildLangChip(
                    'English',
                    '${(englishCount / totalLang * 100).round()}%',
                    _kSecondary,
                  ),
                if ((swahiliCount > 0 || englishCount > 0) &&
                    bothCount > 0)
                  const SizedBox(width: 8),
                if (bothCount > 0)
                  _buildLangChip(
                    sw ? 'Zote' : 'Both',
                    '${(bothCount / totalLang * 100).round()}%',
                    const Color(0xFF999999),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Expected vocabulary comparison
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: vocabPct >= 80
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.06)
                  : vocabPct >= 50
                      ? Colors.orange.withValues(alpha: 0.06)
                      : _kPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw
                      ? 'Msamiati unaotarajiwa kwa $ageLabel: $expectedWords maneno'
                      : 'Expected vocabulary for $ageLabel: $expectedWords words',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (totalWords / expectedWords).clamp(0, 1),
                    backgroundColor: Colors.grey.shade200,
                    color: vocabPct >= 80
                        ? const Color(0xFF2E7D32)
                        : vocabPct >= 50
                            ? Colors.orange
                            : _kPrimary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$vocabPct% ${sw ? "ya lengo" : "of target"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: vocabPct >= 80
                        ? const Color(0xFF2E7D32)
                        : vocabPct >= 50
                            ? Colors.orange
                            : _kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label, String pct, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $pct',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _confirmDeleteSpeech(Map<String, dynamic> word) {
    final sw = _sw;
    final content = word['content']?.toString() ?? '';
    final id = word['id'];
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Futa?' : 'Delete?'),
        content: Text(sw ? 'Futa "$content"?' : 'Delete "$content"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteSpeech(_token!, id is int ? id : int.parse(id.toString()));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imefutwa' : 'Deleted')),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sw ? 'Imeshindikana kufuta' : 'Failed to delete')),
                  );
                }
              }
            },
            child: Text(sw ? 'Futa' : 'Delete',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildWordItem(Map<String, dynamic> word, bool sw) {
    final content = word['content']?.toString() ?? '';
    final type = word['type']?.toString() ?? '';
    final language = word['language']?.toString() ?? '';
    final date = DateTime.tryParse(word['logged_at']?.toString() ?? '');

    String typeLabel;
    switch (type) {
      case 'first_word':
        typeLabel = sw ? 'Neno la Kwanza' : 'First Word';
      case 'first_sentence':
        typeLabel = sw ? 'Sentensi ya Kwanza' : 'First Sentence';
      case 'conversation':
        typeLabel = sw ? 'Mazungumzo' : 'Conversation';
      default:
        typeLabel = sw ? 'Neno Jipya' : 'New Word';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_rounded,
                  size: 16, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$typeLabel  ·  $language',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (date != null)
              Text(
                '${date.day}/${date.month}',
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneGroup(_SpeechMilestone milestone, bool sw) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: milestone.active
              ? Border.all(color: _kPrimary.withValues(alpha: 0.2))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              milestone.ageLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: milestone.active ? _kPrimary : _kSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ...milestone.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        item.met
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: item.met
                            ? const Color(0xFF2E7D32)
                            : _kSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sw ? item.sw : item.en,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                item.met ? _kPrimary : _kSecondary,
                            decoration: item.met
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
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
}

class _SpeechMilestone {
  final String ageLabel;
  final List<_MilestoneItem> items;
  final bool active;
  const _SpeechMilestone({
    required this.ageLabel,
    required this.items,
    required this.active,
  });
}

class _MilestoneItem {
  final String en;
  final String sw;
  final bool met;
  const _MilestoneItem({
    required this.en,
    required this.sw,
    required this.met,
  });
}
