import 'dart:convert';

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

/// F8 #26 — Minimal engagement questionnaire builder + renderer.
///
/// When [isBuilder] is true, the partner can create a questionnaire.
/// When false, the customer fills and submits it.
///
/// The questionnaire JSON is stored in [initialJson]; on submit it is returned
/// via [onSubmit].
class EngagementQuestionnairePage extends StatefulWidget {
  final bool isBuilder;
  final String? initialJson;
  final ValueChanged<String>? onSubmit;

  const EngagementQuestionnairePage({
    super.key,
    this.isBuilder = false,
    this.initialJson,
    this.onSubmit,
  });

  @override
  State<EngagementQuestionnairePage> createState() => _EngagementQuestionnairePageState();
}

class _Question {
  String text;
  String type; // 'text' | 'choice'
  List<String> options;
  _Question({required this.text, required this.type, this.options = const []});

  Map<String, dynamic> toJson() => {
        'text': text,
        'type': type,
        'options': options,
      };

  factory _Question.fromJson(Map<String, dynamic> json) => _Question(
        text: json['text']?.toString() ?? '',
        type: json['type']?.toString() ?? 'text',
        options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class _EngagementQuestionnairePageState extends State<EngagementQuestionnairePage> {
  final List<_Question> _questions = [];
  final Map<int, TextEditingController> _answerCtrls = {};
  final Map<int, int?> _choiceSelections = {};
  bool _readOnly = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.initialJson != null && widget.initialJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(widget.initialJson!) as List<dynamic>;
        _questions.addAll(decoded.map((q) => _Question.fromJson(q as Map<String, dynamic>)));
        _readOnly = !widget.isBuilder;
        for (var i = 0; i < _questions.length; i++) {
          _answerCtrls[i] = TextEditingController();
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    for (final c in _answerCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addQuestion(String type) {
    setState(() {
      _questions.add(_Question(text: '', type: type, options: type == 'choice' ? [''] : []));
      _answerCtrls[_questions.length - 1] = TextEditingController();
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _answerCtrls[index]?.dispose();
      _answerCtrls.remove(index);
      _questions.removeAt(index);
      // Rebuild indices
      final newCtrls = <int, TextEditingController>{};
      for (var i = 0; i < _questions.length; i++) {
        newCtrls[i] = _answerCtrls.entries.firstWhere((e) => e.key >= i, orElse: () => MapEntry(i, TextEditingController())).value;
      }
      _answerCtrls
        ..clear()
        ..addAll(newCtrls);
    });
  }

  void _submit() {
    if (widget.isBuilder) {
      // Validate
      for (final q in _questions) {
        if (q.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isSwahili ? 'Weka swali zote' : 'Please fill in all questions'),
            ),
          );
          return;
        }
      }
      final jsonStr = jsonEncode(_questions.map((q) => q.toJson()).toList());
      widget.onSubmit?.call(jsonStr);
      Navigator.of(context).pop(jsonStr);
    } else {
      // Customer submitting answers
      final answers = <Map<String, dynamic>>[];
      for (var i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final answer = q.type == 'choice'
            ? (_choiceSelections[i] != null && _choiceSelections[i]! < q.options.length
                ? q.options[_choiceSelections[i]!]
                : '')
            : (_answerCtrls[i]?.text ?? '');
        answers.add({
          'question': q.text,
          'type': q.type,
          'answer': answer,
        });
      }
      final jsonStr = jsonEncode(answers);
      widget.onSubmit?.call(jsonStr);
      Navigator.of(context).pop(jsonStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          widget.isBuilder
              ? (isSw ? 'Unda Maswali' : 'Build Questionnaire')
              : (isSw ? 'Jaza Maswali' : 'Fill Questionnaire'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _questions.isEmpty
                  ? Center(
                      child: Text(
                        isSw ? 'Hakuna maswali bado' : 'No questions yet',
                        style: const TextStyle(color: _kSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final q = _questions[index];
                        return _buildQuestionCard(index, q, isSw);
                      },
                    ),
            ),
            if (widget.isBuilder && !_readOnly)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addQuestion('text'),
                        icon: const Icon(Icons.short_text_rounded, size: 18),
                        label: Text(isSw ? 'Swali la Maandishi' : 'Text Question'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addQuestion('choice'),
                        icon: const Icon(Icons.check_box_rounded, size: 18),
                        label: Text(isSw ? 'Swali la Chaguo' : 'Multiple Choice'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _questions.isEmpty ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.isBuilder
                        ? (isSw ? 'Hifadhi Maswali' : 'Save Questionnaire')
                        : (isSw ? 'Wasilisha Majibu' : 'Submit Answers'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, _Question q, bool isSw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  q.type == 'choice' ? (isSw ? 'Chaguo' : 'Multiple Choice') : (isSw ? 'Maandishi' : 'Text'),
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ),
              if (widget.isBuilder && !_readOnly)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF44336)),
                  onPressed: () => _removeQuestion(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.isBuilder && !_readOnly)
            TextField(
              onChanged: (v) => q.text = v,
              decoration: InputDecoration(
                hintText: isSw ? 'Andika swali hapa...' : 'Type your question here...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            )
          else
            Text(
              q.text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          const SizedBox(height: 10),
          if (q.type == 'text')
            TextField(
              controller: _answerCtrls[index],
              enabled: !widget.isBuilder,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isSw ? 'Jibu hapa...' : 'Answer here...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            )
          else if (q.type == 'choice')
            ...q.options.asMap().entries.map((entry) {
              final optIndex = entry.key;
              final opt = entry.value;
              return widget.isBuilder && !_readOnly
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) {
                                setState(() {
                                  q.options[optIndex] = v;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: isSw ? 'Chaguo ${optIndex + 1}' : 'Option ${optIndex + 1}',
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Color(0xFFF44336)),
                            onPressed: () {
                              setState(() {
                                q.options.removeAt(optIndex);
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  : GestureDetector(
                    onTap: () => setState(() => _choiceSelections[index] = optIndex),
                    child: Row(
                      children: [
                        Icon(
                          _choiceSelections[index] == optIndex
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 20,
                          color: _choiceSelections[index] == optIndex ? _kPrimary : _kSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              color: _kPrimary,
                              fontWeight: _choiceSelections[index] == optIndex
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
            }),
          if (widget.isBuilder && !_readOnly && q.type == 'choice')
            TextButton.icon(
              onPressed: () => setState(() => q.options.add('')),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(isSw ? 'Ongeza Chaguo' : 'Add Option'),
              style: TextButton.styleFrom(foregroundColor: _kPrimary),
            ),
        ],
      ),
    );
  }
}
