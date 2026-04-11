// lib/katiba/pages/quiz_page.dart
import 'package:flutter/material.dart';
import '../models/katiba_models.dart';
import '../services/katiba_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<QuizQuestion> _questions = [];
  bool _loading = true;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _score = 0;
  final _service = KatibaService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getQuiz();
    if (mounted) {
      setState(() {
        _questions = result.items;
        _loading = false;
      });
    }
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) _score++;
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Matokeo', style: TextStyle(color: _kPrimary)),
        content: Text('Umepata $_score kati ya ${_questions.length}',
            style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Maliza', style: TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text('Mtihani wa Katiba',
            style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _questions.isEmpty
              ? const Center(child: Text('Hakuna maswali', style: TextStyle(color: _kSecondary)))
              : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_currentIndex];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Text('Swali ${_currentIndex + 1}/${_questions.length}',
              style: const TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 24),

          // Question
          Text(q.questionSw.isNotEmpty ? q.questionSw : q.questionEn,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 20),

          // Options
          ...List.generate(q.options.length, (i) {
            final isCorrect = i == q.correctIndex;
            final isSelected = i == _selectedOption;
            Color bg = Colors.white;
            if (_answered) {
              if (isCorrect) bg = const Color(0xFFE8F5E9);
              if (isSelected && !isCorrect) bg = const Color(0xFFFFEBEE);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _selectOption(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _kPrimary : const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: Text(q.options[i],
                      style: const TextStyle(fontSize: 14, color: _kPrimary)),
                ),
              ),
            );
          }),

          // Explanation
          if (_answered && q.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(q.explanation,
                  style: const TextStyle(fontSize: 13, color: _kSecondary)),
            ),
          ],

          const Spacer(),

          // Next button
          if (_answered)
            SizedBox(
              width: double.infinity, height: 48,
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentIndex < _questions.length - 1 ? 'Swali Linalofuata' : 'Maliza',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
