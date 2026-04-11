// lib/exam_prep/pages/exam_prep_home_page.dart
import 'package:flutter/material.dart';
import '../models/exam_prep_models.dart';
import '../services/exam_prep_service.dart';
import 'flashcard_study_page.dart';
import 'quiz_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ExamPrepHomePage extends StatefulWidget {
  final int userId;
  const ExamPrepHomePage({super.key, required this.userId});
  @override
  State<ExamPrepHomePage> createState() => _ExamPrepHomePageState();
}

class _ExamPrepHomePageState extends State<ExamPrepHomePage> {
  final ExamPrepService _service = ExamPrepService();
  List<FlashcardDeck> _decks = [];
  List<ExamCountdown> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([_service.getDecks(), _service.getExamCountdowns()]);
    if (mounted) {
      setState(() {
        _isLoading = false;
        final dRes = results[0] as PrepListResult<FlashcardDeck>;
        final eRes = results[1] as PrepListResult<ExamCountdown>;
        if (dRes.success) _decks = dRes.items;
        if (eRes.success) _exams = eRes.items..sort((a, b) => a.examDate.compareTo(b.examDate));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: _kPrimary,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text('Mitihani', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      ]),
                      SizedBox(height: 6),
                      Text('Exam Prep — flashcards, quizzes & study tools', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Quick actions
                  Row(children: [
                    _actionCard(Icons.quiz_rounded, 'Jaribio', 'Quick Quiz', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizPage(subject: 'general')))),
                    const SizedBox(width: 12),
                    _actionCard(Icons.timer_rounded, 'Pomodoro', 'Study Timer', () => _showPomodoroDialog()),
                  ]),
                  const SizedBox(height: 20),

                  // Exam Countdown
                  if (_exams.isNotEmpty) ...[
                    const Text('Mitihani Ijayo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                    const SizedBox(height: 4),
                    const Text('Upcoming Exams', style: TextStyle(fontSize: 12, color: _kSecondary)),
                    const SizedBox(height: 10),
                    ..._exams.where((e) => !e.isPast).take(3).map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: e.daysRemaining <= 3 ? Colors.red.shade200 : Colors.grey.shade200)),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: e.daysRemaining <= 3 ? Colors.red.shade50 : _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text('${e.daysRemaining}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: e.daysRemaining <= 3 ? Colors.red : _kPrimary))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${e.examDate.day}/${e.examDate.month}/${e.examDate.year}${e.venue != null ? ' · ${e.venue}' : ''}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                        ])),
                        Text('siku', style: const TextStyle(fontSize: 11, color: _kSecondary)),
                      ]),
                    )),
                    const SizedBox(height: 16),
                  ],

                  // Flashcard Decks
                  const Text('Kadi za Kusoma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 4),
                  const Text('Flashcard Decks', style: TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(height: 10),
                  if (_decks.isEmpty)
                    Container(padding: const EdgeInsets.all(32), alignment: Alignment.center, child: const Text('Hakuna kadi bado / No cards yet', style: TextStyle(color: _kSecondary)))
                  else
                    ..._decks.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        leading: CircleAvatar(backgroundColor: _kPrimary.withValues(alpha: 0.08), child: const Icon(Icons.style_rounded, color: _kPrimary, size: 20)),
                        title: Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${d.subject} · ${d.cardCount} kadi', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                        trailing: Text('${(d.progressPercent * 100).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardStudyPage(deck: d))),
                      ),
                    )),
                ]),
              ),
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 24, color: _kPrimary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ]),
        ),
      ),
    );
  }

  void _showPomodoroDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Pomodoro Timer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: const Text('25 dakika za kusoma, 5 dakika pumziko.\n\n25 minutes focus, 5 minutes break.', style: TextStyle(fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
        FilledButton(onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(backgroundColor: _kPrimary), child: const Text('Anza')),
      ],
    ));
  }
}
