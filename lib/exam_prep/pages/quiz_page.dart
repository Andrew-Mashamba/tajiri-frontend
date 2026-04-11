// lib/exam_prep/pages/quiz_page.dart
import 'package:flutter/material.dart';
import '../models/exam_prep_models.dart';
import '../services/exam_prep_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class QuizPage extends StatefulWidget {
  final String subject;
  const QuizPage({super.key, required this.subject});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final ExamPrepService _service = ExamPrepService();
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    final result = await _service.generateQuiz(subject: widget.subject);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _questions = result.items;
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
      setState(() { _currentIndex++; _selectedOption = null; _answered = false; });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Text('Matokeo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Text('Umepata $_score kati ya ${_questions.length}\nScore: $_score / ${_questions.length}', style: const TextStyle(fontSize: 16)),
      actions: [
        FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: _kPrimary), child: const Text('Maliza')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0, title: const Text('Jaribio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _questions.isEmpty
                ? const Center(child: Text('Hakuna maswali / No questions', style: TextStyle(color: _kSecondary)))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      LinearProgressIndicator(value: (_currentIndex + 1) / _questions.length, backgroundColor: Colors.grey.shade200, color: _kPrimary, minHeight: 4),
                      const SizedBox(height: 8),
                      Text('Swali ${_currentIndex + 1} / ${_questions.length}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      const SizedBox(height: 20),
                      Text(_questions[_currentIndex].question, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _kPrimary, height: 1.4)),
                      const SizedBox(height: 20),
                      ...List.generate(_questions[_currentIndex].options.length, (i) {
                        final isCorrect = i == _questions[_currentIndex].correctIndex;
                        final isSelected = i == _selectedOption;
                        Color bgColor = Colors.white;
                        Color borderColor = Colors.grey.shade200;
                        if (_answered && isCorrect) { bgColor = Colors.green.shade50; borderColor = Colors.green; }
                        if (_answered && isSelected && !isCorrect) { bgColor = Colors.red.shade50; borderColor = Colors.red; }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => _selectOption(i),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                              child: Text(_questions[_currentIndex].options[i], style: const TextStyle(fontSize: 14, color: _kPrimary)),
                            ),
                          ),
                        );
                      }),
                      if (_answered && _questions[_currentIndex].explanation != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
                          child: Text(_questions[_currentIndex].explanation!, style: const TextStyle(fontSize: 13, color: _kSecondary, height: 1.4)),
                        ),
                      ],
                      const Spacer(),
                      if (_answered) FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
                        child: Text(_currentIndex < _questions.length - 1 ? 'Endelea' : 'Maliza'),
                      ),
                    ]),
                  ),
      ),
    );
  }
}
