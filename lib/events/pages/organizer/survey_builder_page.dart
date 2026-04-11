// lib/events/pages/organizer/survey_builder_page.dart
import 'package:flutter/material.dart';
import '../../models/event_analytics.dart';
import '../../models/event_strings.dart';
import '../../services/event_organizer_service.dart';
import '../../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class SurveyBuilderPage extends StatefulWidget {
  final int eventId;

  const SurveyBuilderPage({super.key, required this.eventId});

  @override
  State<SurveyBuilderPage> createState() => _SurveyBuilderPageState();
}

class _SurveyBuilderPageState extends State<SurveyBuilderPage> {
  final _service = EventOrganizerService();
  late EventStrings _strings;
  final List<_QuestionDraft> _questions = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
  }

  @override
  void dispose() {
    for (final q in _questions) { q.controller.dispose(); q.optionsCtrl.dispose(); }
    super.dispose();
  }

  void _addQuestion() => setState(() => _questions.add(_QuestionDraft()));

  void _removeQuestion(int index) => setState(() => _questions.removeAt(index));

  Future<void> _submit() async {
    final validQuestions = _questions.where((q) => q.controller.text.trim().isNotEmpty).toList();
    if (validQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one question.')));
      return;
    }

    setState(() => _submitting = true);
    final questions = validQuestions.map((q) => SurveyQuestion(
      question: q.controller.text.trim(),
      type: q.type,
      options: q.type == 'multiple_choice' && q.optionsCtrl.text.trim().isNotEmpty
          ? q.optionsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : null,
    )).toList();

    final result = await _service.createSurvey(eventId: widget.eventId, questions: questions);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Survey created successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to create survey')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Text(_strings.surveyBuilder, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2))
                : Text(_strings.submit, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _questions.isEmpty
                ? _EmptyState(onAdd: _addQuestion, label: _strings.addQuestion)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _questions.length,
                    itemBuilder: (_, i) => _QuestionCard(
                      index: i,
                      draft: _questions[i],
                      onRemove: () => _removeQuestion(i),
                      onTypeChanged: (t) => setState(() => _questions[i].type = t),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_rounded, color: _kPrimary),
                label: Text(_strings.addQuestion, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final _QuestionDraft draft;
  final VoidCallback onRemove;
  final ValueChanged<String> onTypeChanged;

  const _QuestionCard({required this.index, required this.draft, required this.onRemove, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: draft.type,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('Text Answer')),
                    DropdownMenuItem(value: 'rating', child: Text('Rating (1-5)')),
                    DropdownMenuItem(value: 'multiple_choice', child: Text('Multiple Choice')),
                    DropdownMenuItem(value: 'yes_no', child: Text('Yes / No')),
                  ],
                  onChanged: (v) { if (v != null) onTypeChanged(v); },
                ),
              ),
              IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: _kSecondary), onPressed: onRemove),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: draft.controller,
            style: const TextStyle(color: _kPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your question…',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          if (draft.type == 'multiple_choice') ...[
            const SizedBox(height: 8),
            TextField(
              controller: draft.optionsCtrl,
              style: const TextStyle(color: _kPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Options (comma-separated)',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final String label;

  const _EmptyState({required this.onAdd, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.quiz_rounded, size: 60, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 12),
          const Text('No questions yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 6),
          Text('Tap "$label" to get started', style: const TextStyle(fontSize: 13, color: _kSecondary)),
        ],
      ),
    );
  }
}

class _QuestionDraft {
  final TextEditingController controller = TextEditingController();
  final TextEditingController optionsCtrl = TextEditingController();
  String type = 'text';
}
