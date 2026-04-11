// lib/driving_licence/pages/theory_prep_page.dart
import 'package:flutter/material.dart';
import '../models/driving_licence_models.dart';
import '../services/driving_licence_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TheoryPrepPage extends StatefulWidget {
  const TheoryPrepPage({super.key});
  @override
  State<TheoryPrepPage> createState() => _TheoryPrepPageState();
}

class _TheoryPrepPageState extends State<TheoryPrepPage> {
  List<TheoryQuestion> _questions = [];
  bool _loading = true;
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correct = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await DrivingLicenceService.getTheoryQuestions();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) _questions = result.items;
    });
  }

  void _answer(int idx) {
    if (_answered) return;
    setState(() {
      _selectedOption = idx;
      _answered = true;
      _total++;
      if (idx == _questions[_currentIndex].correctIndex) _correct++;
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() { _currentIndex++; _selectedOption = null; _answered = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Maandalizi ya Nadharia',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          Center(child: Padding(padding: const EdgeInsets.only(right: 16),
            child: Text('$_correct/$_total', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _questions.isEmpty
              ? const Center(child: Text('Hakuna maswali', style: TextStyle(color: _kSecondary)))
              : _buildQuizView(),
    );
  }

  Widget _buildQuizView() {
    final q = _questions[_currentIndex];
    return ListView(padding: const EdgeInsets.all(16), children: [
      LinearProgressIndicator(
        value: (_currentIndex + 1) / _questions.length,
        backgroundColor: const Color(0xFFE0E0E0), color: _kPrimary, minHeight: 4),
      const SizedBox(height: 4),
      Text('${_currentIndex + 1}/${_questions.length}',
          style: const TextStyle(fontSize: 11, color: _kSecondary)),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(q.questionSw, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          Text(q.questionEn, style: const TextStyle(fontSize: 13, color: _kSecondary)),
        ])),
      const SizedBox(height: 12),
      ...List.generate(q.options.length, (i) {
        final isCorrect = i == q.correctIndex;
        final isSelected = i == _selectedOption;
        Color bg = Colors.white;
        if (_answered && isCorrect) bg = const Color(0xFF4CAF50).withValues(alpha: 0.12);
        if (_answered && isSelected && !isCorrect) bg = Colors.red.withValues(alpha: 0.12);
        return Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Material(color: bg, borderRadius: BorderRadius.circular(12),
            child: InkWell(onTap: () => _answer(i), borderRadius: BorderRadius.circular(12),
              child: Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? _kPrimary : const Color(0xFFE0E0E0))),
                child: Row(children: [
                  Container(width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : const Color(0xFFE0E0E0),
                      shape: BoxShape.circle),
                    child: Center(child: Text(String.fromCharCode(65 + i),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : _kSecondary)))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(q.options[i],
                      style: const TextStyle(fontSize: 13, color: _kPrimary),
                      maxLines: 3, overflow: TextOverflow.ellipsis)),
                ])))));
      }),
      if (_answered && q.explanation != null) ...[
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12)),
          child: Text(q.explanation!, style: const TextStyle(fontSize: 12, color: _kSecondary))),
      ],
      if (_answered) ...[
        const SizedBox(height: 16),
        SizedBox(height: 48, width: double.infinity, child: ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text(_currentIndex < _questions.length - 1 ? 'Ifuatayo' : 'Mwisho',
              style: const TextStyle(color: Colors.white)))),
      ],
    ]);
  }
}
