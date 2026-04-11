// lib/newton/pages/practice_mode_page.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';
import '../services/newton_service.dart';
import '../widgets/subject_chip.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PracticeModePage extends StatefulWidget {
  final int userId;
  final SubjectMode subject;
  final DifficultyLevel difficulty;
  final bool isSwahili;

  const PracticeModePage({
    super.key,
    required this.userId,
    this.subject = SubjectMode.mathematics,
    this.difficulty = DifficultyLevel.form1_4,
    this.isSwahili = false,
  });

  @override
  State<PracticeModePage> createState() => _PracticeModePageState();
}

class _PracticeModePageState extends State<PracticeModePage> {
  final NewtonService _service = NewtonService();
  final _answerC = TextEditingController();
  final _topicC = TextEditingController();
  final _scrollC = ScrollController();

  late SubjectMode _subject;
  late DifficultyLevel _difficulty;
  String? _currentQuestion;
  String? _feedback;
  bool _isGenerating = false;
  bool _isEvaluating = false;
  bool _showTopicInput = true;
  int _score = 0;
  int _attempted = 0;

  @override
  void initState() {
    super.initState();
    _subject = widget.subject;
    _difficulty = widget.difficulty;
  }

  @override
  void dispose() {
    _answerC.dispose();
    _topicC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _generateQuestion() async {
    final topic = _topicC.text.trim();
    if (topic.isEmpty) return;
    setState(() {
      _isGenerating = true;
      _currentQuestion = null;
      _feedback = null;
      _showTopicInput = false;
    });

    final result = await _service.generatePracticeProblems(
      subject: _subject,
      topic: topic,
      difficulty: _difficulty,
      isSwahili: widget.isSwahili,
    );

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      if (result.success && result.data != null) {
        _currentQuestion = result.data!.content;
      } else {
        _currentQuestion = widget.isSwahili
            ? 'Imeshindwa kutengeneza swali. Jaribu tena.'
            : 'Failed to generate question. Try again.';
      }
    });
  }

  Future<void> _submitAnswer() async {
    final answer = _answerC.text.trim();
    if (answer.isEmpty || _currentQuestion == null) return;
    setState(() => _isEvaluating = true);

    final result = await _service.askQuestion(
      question: widget.isSwahili
          ? 'Swali: $_currentQuestion\n\nJibu la mwanafunzi: $answer\n\n'
              'Tathmini jibu hili. Sema kama ni sahihi au sio, na toa maelezo mafupi. '
              'Kama jibu si sahihi, toa jibu sahihi.'
          : 'Question: $_currentQuestion\n\nStudent answer: $answer\n\n'
              'Evaluate this answer. State if it is correct or incorrect, and provide a brief explanation. '
              'If incorrect, provide the correct answer.',
      subject: _subject,
      difficulty: _difficulty,
      isSwahili: widget.isSwahili,
    );

    if (!mounted) return;
    setState(() {
      _isEvaluating = false;
      _attempted++;
      if (result.success && result.data != null) {
        _feedback = result.data!.content;
        final lower = _feedback!.toLowerCase();
        if (lower.contains('correct') ||
            lower.contains('sahihi') ||
            lower.contains('right')) {
          _score++;
        }
      } else {
        _feedback = widget.isSwahili
            ? 'Imeshindwa kutathmini. Jaribu tena.'
            : 'Failed to evaluate. Try again.';
      }
    });
    _answerC.clear();
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion = null;
      _feedback = null;
    });
    _generateQuestion();
  }

  void _resetSession() {
    setState(() {
      _showTopicInput = true;
      _currentQuestion = null;
      _feedback = null;
      _score = 0;
      _attempted = 0;
      _topicC.clear();
      _answerC.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(
          sw ? 'Mazoezi' : 'Practice mode',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_attempted > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_score/$_attempted',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollC,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic input section
              if (_showTopicInput) ...[
                Text(
                  sw ? 'Chagua somo na mada' : 'Select subject and topic',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Subject selector
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: SubjectMode.values
                        .where((s) => s != SubjectMode.general)
                        .map((s) => SubjectChip(
                              subject: s,
                              selected: _subject == s,
                              isSwahili: sw,
                              onSelected: (v) =>
                                  setState(() => _subject = v),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Topic text field
                TextField(
                  controller: _topicC,
                  decoration: InputDecoration(
                    hintText: sw
                        ? 'Andika mada (k.m. Algebra, Mwendo)'
                        : 'Enter topic (e.g. Algebra, Mechanics)',
                    hintStyle:
                        const TextStyle(fontSize: 14, color: _kSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _generateQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      sw ? 'Anza mazoezi' : 'Start practice',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],

              // Loading
              if (_isGenerating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary),
                  ),
                ),

              // Question display
              if (_currentQuestion != null && !_isGenerating) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.quiz_rounded,
                              size: 18, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Text(
                            sw ? 'Swali' : 'Question',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        _currentQuestion!,
                        style: const TextStyle(
                            fontSize: 14, color: _kPrimary, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Answer input
                if (_feedback == null) ...[
                  TextField(
                    controller: _answerC,
                    decoration: InputDecoration(
                      hintText: sw
                          ? 'Andika jibu lako hapa...'
                          : 'Type your answer here...',
                      hintStyle:
                          const TextStyle(fontSize: 14, color: _kSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 5,
                    minLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isEvaluating ? null : _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isEvaluating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(sw ? 'Wasilisha' : 'Submit',
                              style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],

                // Feedback
                if (_feedback != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 16, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Text(
                              sw ? 'Tathmini ya Newton' : 'Newton\'s feedback',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          _feedback!,
                          style: const TextStyle(
                              fontSize: 14,
                              color: _kPrimary,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _nextQuestion,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: Text(sw
                                ? 'Swali linalofuata'
                                : 'Next question'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _resetSession,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: _kPrimary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(sw ? 'Anza upya' : 'Reset'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
