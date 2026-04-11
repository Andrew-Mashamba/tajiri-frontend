// lib/newton/services/newton_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/newton_models.dart';

class NewtonService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── System prompt builder ──────────────────────────────────

  String _buildSystemPrompt({
    SubjectMode? subject,
    DifficultyLevel? difficulty,
    bool socraticMode = false,
    bool isSwahili = false,
  }) {
    final lang = isSwahili ? 'Swahili' : 'English';
    final subj = subject?.displayName ?? 'General';
    final diff = difficulty?.displayName ?? 'Form 1-4';
    final necta = 'Align with NECTA (National Examinations Council of Tanzania) syllabus.';
    final textbooks = 'Reference standard Tanzanian textbooks where applicable.';
    final guardrails = 'You are an educational tutor only. '
        'Refuse to write full essays, do homework assignments entirely, or provide non-educational content. '
        'Guide the student to learn, do not just give answers.';
    final socratic = socraticMode
        ? 'Use the Socratic method: instead of giving direct answers, ask guiding questions to help the student discover the answer themselves.'
        : 'Provide clear step-by-step explanations.';

    return 'You are Newton, an AI tutor for Tanzanian students. '
        'Subject: $subj. Level: $diff. '
        'Respond in $lang. $necta $textbooks $guardrails $socratic';
  }

  // ─── Ask question ──────────────────────────────────────────

  Future<NewtonResult<NewtonMessage>> askQuestion({
    required String question,
    SubjectMode? subject,
    DifficultyLevel? difficulty,
    int? conversationId,
    bool socraticMode = false,
    bool isSwahili = false,
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt(
        subject: subject,
        difficulty: difficulty,
        socraticMode: socraticMode,
        isSwahili: isSwahili,
      );
      final res = await _dio.post('/ai/ask', data: {
        'prompt': question,
        'system_prompt': systemPrompt,
        'context': 'newton_education',
        if (subject != null) 'subject': subject.name,
        if (difficulty != null) 'difficulty': difficulty.apiValue,
        if (conversationId != null) 'conversation_id': conversationId,
        'socratic_mode': socraticMode,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];
        return NewtonResult(
          success: true,
          data: NewtonMessage(
            id: _parseInt(data['id']),
            content: data['response']?.toString() ?? '',
            isUser: false,
            subject: subject,
            createdAt: DateTime.now(),
          ),
        );
      }
      return NewtonResult(
        success: false,
        message: isSwahili
            ? 'Newton hakujibu. Jaribu tena.'
            : 'Newton did not respond. Try again.',
      );
    } catch (e) {
      return NewtonResult(success: false, message: '$e');
    }
  }

  // ─── Ask with image ────────────────────────────────────────

  Future<NewtonResult<NewtonMessage>> askWithImage({
    required String imagePath,
    String? question,
    SubjectMode? subject,
    DifficultyLevel? difficulty,
    bool isSwahili = false,
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt(
        subject: subject,
        difficulty: difficulty,
        isSwahili: isSwahili,
      );
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        if (question != null && question.isNotEmpty) 'prompt': question,
        'system_prompt': systemPrompt,
        'context': 'newton_education',
        if (subject != null) 'subject': subject.name,
        if (difficulty != null) 'difficulty': difficulty.apiValue,
      });
      final res = await _dio.post('/ai/ask-image', data: formData);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];
        return NewtonResult(
          success: true,
          data: NewtonMessage(
            id: _parseInt(data['id']),
            content: data['response']?.toString() ?? '',
            isUser: false,
            subject: subject,
            createdAt: DateTime.now(),
          ),
        );
      }
      return NewtonResult(
        success: false,
        message: isSwahili
            ? 'Imeshindwa kusoma picha. Jaribu tena.'
            : 'Failed to read image. Try again.',
      );
    } catch (e) {
      return NewtonResult(success: false, message: '$e');
    }
  }

  // ─── Conversations ────────────────────────────────────────

  Future<NewtonListResult<NewtonConversation>> getConversations({
    SubjectMode? subject,
    bool? bookmarkedOnly,
  }) async {
    try {
      final params = <String, dynamic>{
        'context': 'newton_education',
      };
      if (subject != null) params['subject'] = subject.name;
      if (bookmarkedOnly == true) params['bookmarked'] = '1';

      final res = await _dio.get('/ai/conversations', queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) =>
                NewtonConversation.fromJson(j as Map<String, dynamic>))
            .toList();
        return NewtonListResult(success: true, items: items);
      }
      return NewtonListResult(success: false);
    } catch (e) {
      return NewtonListResult(success: false, message: '$e');
    }
  }

  // ─── Single conversation ──────────────────────────────────

  Future<NewtonResult<NewtonConversation>> getConversation(int id) async {
    try {
      final res = await _dio.get('/ai/conversations/$id');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return NewtonResult(
          success: true,
          data: NewtonConversation.fromJson(
              res.data['data'] as Map<String, dynamic>),
        );
      }
      return NewtonResult(success: false);
    } catch (e) {
      return NewtonResult(success: false, message: '$e');
    }
  }

  // ─── Messages in conversation ─────────────────────────────

  Future<NewtonListResult<NewtonMessage>> getMessages(
      int conversationId) async {
    try {
      final res =
          await _dio.get('/ai/conversations/$conversationId/messages');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => NewtonMessage.fromJson(j as Map<String, dynamic>))
            .toList();
        return NewtonListResult(success: true, items: items);
      }
      return NewtonListResult(success: false);
    } catch (e) {
      return NewtonListResult(success: false, message: '$e');
    }
  }

  // ─── Bookmark conversation ────────────────────────────────

  Future<NewtonResult<bool>> bookmarkConversation(int id,
      {bool bookmark = true}) async {
    try {
      final res = await _dio.post('/ai/conversations/$id/bookmark', data: {
        'bookmark': bookmark,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return NewtonResult(success: true, data: true);
      }
      return NewtonResult(success: false);
    } catch (e) {
      return NewtonResult(success: false, message: '$e');
    }
  }

  // ─── Delete conversation ──────────────────────────────────

  Future<NewtonResult<bool>> deleteConversation(int id) async {
    try {
      final res = await _dio.delete('/ai/conversations/$id');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return NewtonResult(success: true, data: true);
      }
      return NewtonResult(success: false);
    } catch (e) {
      return NewtonResult(success: false, message: '$e');
    }
  }

  // ─── Flag message ─────────────────────────────────────────

  Future<NewtonResult<bool>> flagMessage(int messageId,
      {String? reason}) async {
    try {
      final res = await _dio.post('/ai/messages/$messageId/flag', data: {
        if (reason != null) 'reason': reason,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return NewtonResult(success: true, data: true);
      }
      return NewtonResult(success: false);
    } catch (e) {
      return NewtonResult(success: false, message: '$e');
    }
  }

  // ─── Usage stats ──────────────────────────────────────────

  Future<NewtonResult<UsageStats>> getUsageStats() async {
    try {
      final res = await _dio.get('/ai/usage', queryParameters: {
        'context': 'newton_education',
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return NewtonResult(
          success: true,
          data: UsageStats.fromJson(
              res.data['data'] as Map<String, dynamic>),
        );
      }
      return NewtonResult(success: true, data: UsageStats());
    } catch (e) {
      return NewtonResult(success: true, data: UsageStats());
    }
  }

  // ─── Topic suggestions ────────────────────────────────────

  Future<NewtonListResult<TopicSuggestion>> getTopicSuggestions(
      SubjectMode subject) async {
    try {
      final res = await _dio.get('/ai/topics', queryParameters: {
        'context': 'newton_education',
        'subject': subject.name,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) =>
                TopicSuggestion.fromJson(j as Map<String, dynamic>))
            .toList();
        return NewtonListResult(success: true, items: items);
      }
      return NewtonListResult(success: true, items: _defaultTopics(subject));
    } catch (e) {
      return NewtonListResult(success: true, items: _defaultTopics(subject));
    }
  }

  // ─── Generate exam questions ──────────────────────────────

  Future<NewtonResult<NewtonMessage>> generateExamQuestions({
    required SubjectMode subject,
    required String topic,
    int count = 5,
    DifficultyLevel? difficulty,
    bool isSwahili = false,
  }) async {
    final lang = isSwahili ? 'Swahili' : 'English';
    final diff = difficulty?.displayName ?? 'Form 1-4';
    final prompt = 'Generate $count NECTA-style exam questions on "$topic" '
        'for $diff level ${subject.displayName}. '
        'Include a mix of multiple choice and structured questions. '
        'Respond in $lang. Align with Tanzanian curriculum.';
    return askQuestion(
      question: prompt,
      subject: subject,
      difficulty: difficulty,
      isSwahili: isSwahili,
    );
  }

  // ─── Generate practice problems ───────────────────────────

  Future<NewtonResult<NewtonMessage>> generatePracticeProblems({
    required SubjectMode subject,
    required String topic,
    DifficultyLevel? difficulty,
    bool isSwahili = false,
  }) async {
    final lang = isSwahili ? 'Swahili' : 'English';
    final diff = difficulty?.displayName ?? 'Form 1-4';
    final prompt = 'Give me 5 practice problems on "$topic" '
        'for $diff level ${subject.displayName}. '
        'Start with easier problems and increase difficulty. '
        'Include worked examples where appropriate. '
        'Respond in $lang. Align with NECTA curriculum.';
    return askQuestion(
      question: prompt,
      subject: subject,
      difficulty: difficulty,
      isSwahili: isSwahili,
    );
  }

  // ─── Default topic suggestions (offline fallback) ─────────

  static List<TopicSuggestion> _defaultTopics(SubjectMode subject) {
    switch (subject) {
      case SubjectMode.mathematics:
        return const [
          TopicSuggestion(subject: SubjectMode.mathematics, topic: 'Algebra', questionHint: 'Solve quadratic equations', questionHintSw: 'Tatua milinganyo ya quadratic'),
          TopicSuggestion(subject: SubjectMode.mathematics, topic: 'Trigonometry', questionHint: 'Sin, cos, tan relationships', questionHintSw: 'Uhusiano wa sin, cos, tan'),
          TopicSuggestion(subject: SubjectMode.mathematics, topic: 'Statistics', questionHint: 'Mean, median, mode', questionHintSw: 'Wastani, kati, msimbo'),
        ];
      case SubjectMode.physics:
        return const [
          TopicSuggestion(subject: SubjectMode.physics, topic: 'Mechanics', questionHint: 'Newton\'s laws of motion', questionHintSw: 'Sheria za Newton za mwendo'),
          TopicSuggestion(subject: SubjectMode.physics, topic: 'Electricity', questionHint: 'Ohm\'s law circuits', questionHintSw: 'Sheria ya Ohm katika saketi'),
          TopicSuggestion(subject: SubjectMode.physics, topic: 'Waves', questionHint: 'Properties of waves', questionHintSw: 'Sifa za mawimbi'),
        ];
      case SubjectMode.chemistry:
        return const [
          TopicSuggestion(subject: SubjectMode.chemistry, topic: 'Chemical bonding', questionHint: 'Ionic vs covalent bonds', questionHintSw: 'Vifungo vya ioniki dhidi ya kovalenti'),
          TopicSuggestion(subject: SubjectMode.chemistry, topic: 'Organic Chemistry', questionHint: 'Hydrocarbons and reactions', questionHintSw: 'Hidrokaboni na athari zake'),
          TopicSuggestion(subject: SubjectMode.chemistry, topic: 'Periodic Table', questionHint: 'Element properties and trends', questionHintSw: 'Sifa za elementi na mwenendo'),
        ];
      case SubjectMode.biology:
        return const [
          TopicSuggestion(subject: SubjectMode.biology, topic: 'Cell Biology', questionHint: 'Cell structure and functions', questionHintSw: 'Muundo na kazi za seli'),
          TopicSuggestion(subject: SubjectMode.biology, topic: 'Genetics', questionHint: 'Mendel\'s laws of inheritance', questionHintSw: 'Sheria za Mendel za urithi'),
          TopicSuggestion(subject: SubjectMode.biology, topic: 'Ecology', questionHint: 'Ecosystems and food chains', questionHintSw: 'Mifumo ya ikolojia na minyororo ya chakula'),
        ];
      default:
        return const [
          TopicSuggestion(subject: SubjectMode.general, topic: 'Study tips', questionHint: 'How to study effectively', questionHintSw: 'Jinsi ya kusoma kwa ufanisi'),
          TopicSuggestion(subject: SubjectMode.general, topic: 'Exam preparation', questionHint: 'How to prepare for NECTA', questionHintSw: 'Jinsi ya kujiandaa kwa NECTA'),
          TopicSuggestion(subject: SubjectMode.general, topic: 'Time management', questionHint: 'Managing study time', questionHintSw: 'Kusimamia muda wa masomo'),
        ];
    }
  }
}

// ─── Parse helpers ───────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
