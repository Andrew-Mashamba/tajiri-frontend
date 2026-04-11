// lib/exam_prep/pages/flashcard_study_page.dart
import 'package:flutter/material.dart';
import '../models/exam_prep_models.dart';
import '../services/exam_prep_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FlashcardStudyPage extends StatefulWidget {
  final FlashcardDeck deck;
  const FlashcardStudyPage({super.key, required this.deck});
  @override
  State<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends State<FlashcardStudyPage> {
  final ExamPrepService _service = ExamPrepService();
  List<Flashcard> _cards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final result = await _service.getCards(widget.deck.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _cards = result.items;
      });
    }
  }

  void _next(int confidence) {
    if (_currentIndex < _cards.length) {
      _service.updateCardConfidence(cardId: _cards[_currentIndex].id, confidence: confidence);
    }
    setState(() {
      _showAnswer = false;
      if (_currentIndex < _cards.length - 1) {
        _currentIndex++;
      } else {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Umekamilisha!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Text('Kadi ${_cards.length} zimekamilika.\n${_cards.length} cards completed.', style: const TextStyle(fontSize: 14)),
      actions: [
        FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: _kPrimary), child: const Text('Maliza')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        title: Text(widget.deck.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [if (_cards.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${_currentIndex + 1}/${_cards.length}', style: const TextStyle(fontSize: 14, color: _kSecondary))))],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _cards.isEmpty
                ? const Center(child: Text('Hakuna kadi / No cards', style: TextStyle(color: _kSecondary)))
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(children: [
                      // Progress bar
                      LinearProgressIndicator(value: (_currentIndex + 1) / _cards.length, backgroundColor: Colors.grey.shade200, color: _kPrimary, minHeight: 4),
                      const SizedBox(height: 32),
                      // Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showAnswer = !_showAnswer),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: _showAnswer ? _kPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _showAnswer ? _kPrimary : Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(_showAnswer ? 'JIBU' : 'SWALI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _showAnswer ? Colors.white54 : _kSecondary, letterSpacing: 2)),
                              const SizedBox(height: 16),
                              Text(
                                _showAnswer ? _cards[_currentIndex].back : _cards[_currentIndex].front,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: _showAnswer ? Colors.white : _kPrimary, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (!_showAnswer) Text('Bonyeza kuona jibu', style: TextStyle(fontSize: 12, color: _kSecondary)),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      if (_showAnswer) Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => _next(0), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size(0, 48)), child: const Text('Sijui'))),
                        const SizedBox(width: 12),
                        Expanded(child: OutlinedButton(onPressed: () => _next(1), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)), child: const Text('Kidogo'))),
                        const SizedBox(width: 12),
                        Expanded(child: FilledButton(onPressed: () => _next(2), style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size(0, 48)), child: const Text('Najua'))),
                      ]),
                    ]),
                  ),
      ),
    );
  }
}
