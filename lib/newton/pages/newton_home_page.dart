// lib/newton/pages/newton_home_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/newton_models.dart';
import '../services/newton_service.dart';
import '../widgets/newton_bubble.dart';
import '../widgets/subject_chip.dart';
import '../widgets/difficulty_selector.dart';
import '../widgets/usage_counter.dart';
import 'conversation_history_page.dart';
import 'saved_conversations_page.dart';
import 'formula_sheet_page.dart';
import 'periodic_table_page.dart';
import 'physics_tools_page.dart';
import 'photo_capture_page.dart';
import 'practice_mode_page.dart';
import 'settings_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class NewtonHomePage extends StatefulWidget {
  final int userId;
  final String? prefillText;
  const NewtonHomePage({super.key, required this.userId, this.prefillText});
  @override
  State<NewtonHomePage> createState() => _NewtonHomePageState();
}

class _NewtonHomePageState extends State<NewtonHomePage> {
  final NewtonService _service = NewtonService();
  final _inputC = TextEditingController();
  final _scrollC = ScrollController();
  final _imagePicker = ImagePicker();

  final List<NewtonMessage> _messages = [];
  SubjectMode _subject = SubjectMode.general;
  DifficultyLevel _difficulty = DifficultyLevel.form1_4;
  bool _socraticMode = false;
  bool _isSending = false;
  bool _isSwahili = false;
  int? _conversationId;
  UsageStats _usage = UsageStats();
  List<TopicSuggestion> _suggestions = [];

  bool _hasPrefill = false;

  @override
  void initState() {
    super.initState();
    _loadUsage();
    _loadSuggestions();
    if (widget.prefillText != null && widget.prefillText!.isNotEmpty) {
      _inputC.text = widget.prefillText!;
      _hasPrefill = true;
    }
  }

  @override
  void dispose() {
    _inputC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    final result = await _service.getUsageStats();
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() => _usage = result.data!);
    }
  }

  Future<void> _loadSuggestions() async {
    final result = await _service.getTopicSuggestions(_subject);
    if (!mounted) return;
    if (result.success) {
      setState(() => _suggestions = result.items);
    }
  }

  Future<void> _send() async {
    final text = _inputC.text.trim();
    if (text.isEmpty) return;
    if (_usage.isLimitReached) {
      _showLimitDialog();
      return;
    }
    _inputC.clear();
    setState(() {
      _messages.add(NewtonMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        content: text,
        isUser: true,
        subject: _subject,
        createdAt: DateTime.now(),
      ));
      _isSending = true;
    });
    _scrollToBottom();

    final result = await _service.askQuestion(
      question: text,
      subject: _subject,
      difficulty: _difficulty,
      conversationId: _conversationId,
      socraticMode: _socraticMode,
      isSwahili: _isSwahili,
    );
    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (result.success && result.data != null) {
        _messages.add(result.data!);
      } else {
        _messages.add(NewtonMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          content: result.message ??
              (_isSwahili
                  ? 'Samahani, nimeshindwa kujibu. Jaribu tena.'
                  : 'Sorry, I could not respond. Please try again.'),
          isUser: false,
          createdAt: DateTime.now(),
        ));
      }
      _usage = UsageStats(
        questionsToday: _usage.questionsToday + 1,
        dailyLimit: _usage.dailyLimit,
        questionsTotal: _usage.questionsTotal + 1,
      );
    });
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    try {
      final picked =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (picked == null || !mounted) return;
      if (_usage.isLimitReached) {
        _showLimitDialog();
        return;
      }
      setState(() {
        _messages.add(NewtonMessage(
          id: DateTime.now().millisecondsSinceEpoch,
          content: _isSwahili
              ? 'Picha imetumwa...'
              : 'Photo sent...',
          isUser: true,
          imageUrl: picked.path,
          subject: _subject,
          createdAt: DateTime.now(),
        ));
        _isSending = true;
      });
      _scrollToBottom();

      final result = await _service.askWithImage(
        imagePath: picked.path,
        question: _inputC.text.trim().isEmpty ? null : _inputC.text.trim(),
        subject: _subject,
        difficulty: _difficulty,
        isSwahili: _isSwahili,
      );
      _inputC.clear();
      if (!mounted) return;
      setState(() {
        _isSending = false;
        if (result.success && result.data != null) {
          _messages.add(result.data!);
        } else {
          _messages.add(NewtonMessage(
            id: DateTime.now().millisecondsSinceEpoch,
            content: result.message ??
                (_isSwahili
                    ? 'Imeshindwa kusoma picha.'
                    : 'Failed to read the image.'),
            isUser: false,
            createdAt: DateTime.now(),
          ));
        }
        _usage = UsageStats(
          questionsToday: _usage.questionsToday + 1,
          dailyLimit: _usage.dailyLimit,
          questionsTotal: _usage.questionsTotal + 1,
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_isSwahili
                ? 'Imeshindwa kufungua kamera'
                : 'Failed to open camera')),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          _scrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _isSwahili ? 'Kikomo kimefikiwa' : 'Daily limit reached',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          _isSwahili
              ? 'Umefika kikomo cha maswali ${_usage.dailyLimit} kwa leo. Jaribu tena kesho.'
              : 'You have reached your daily limit of ${_usage.dailyLimit} questions. Try again tomorrow.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Sawa' : 'OK',
                style: const TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark(int index) {
    setState(() {
      final msg = _messages[index];
      _messages[index] = msg.copyWith(isBookmarked: !msg.isBookmarked);
    });
  }

  void _flagMessage(int index) {
    final msg = _messages[index];
    if (msg.isFlagged) return;
    _service.flagMessage(msg.id, reason: 'Incorrect answer');
    setState(() {
      _messages[index] = msg.copyWith(isFlagged: true);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSwahili
            ? 'Jibu limeripotiwa. Asante!'
            : 'Response reported. Thank you!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onSuggestionTap(TopicSuggestion suggestion) {
    _inputC.text =
        _isSwahili ? suggestion.questionHintSw : suggestion.questionHint;
    _send();
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _conversationId = null;
    });
  }

  void _generateExamQuestions() {
    _showTopicInputDialog(
      title: _isSwahili ? 'Maswali ya mtihani' : 'Exam questions',
      hint: _isSwahili
          ? 'Mada (k.m. Algebra, Mechanics)'
          : 'Topic (e.g. Algebra, Mechanics)',
      onSubmit: (topic) async {
        setState(() {
          _messages.add(NewtonMessage(
            id: DateTime.now().millisecondsSinceEpoch,
            content: _isSwahili
                ? 'Tengeneza maswali ya mtihani wa NECTA kuhusu "$topic"'
                : 'Generate NECTA exam questions on "$topic"',
            isUser: true,
            createdAt: DateTime.now(),
          ));
          _isSending = true;
        });
        _scrollToBottom();
        final result = await _service.generateExamQuestions(
          subject: _subject,
          topic: topic,
          difficulty: _difficulty,
          isSwahili: _isSwahili,
        );
        if (!mounted) return;
        setState(() {
          _isSending = false;
          if (result.success && result.data != null) {
            _messages.add(result.data!);
          }
        });
        _scrollToBottom();
      },
    );
  }

  void _generatePractice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeModePage(
          userId: widget.userId,
          subject: _subject,
          difficulty: _difficulty,
          isSwahili: _isSwahili,
        ),
      ),
    );
  }

  void _showTopicInputDialog({
    required String title,
    required String hint,
    required ValueChanged<String> onSubmit,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isSwahili ? 'Ghairi' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                onSubmit(text);
              }
            },
            child: Text(_isSwahili ? 'Tuma' : 'Submit',
                style: const TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    // NO AppBar (profile tab)
    return Container(
      color: _kBg,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Top bar: usage + actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  UsageCounter(stats: _usage, isSwahili: _isSwahili),
                  const Spacer(),
                  // Language toggle
                  IconButton(
                    icon: Icon(
                      Icons.translate_rounded,
                      size: 20,
                      color: _isSwahili ? _kPrimary : _kSecondary,
                    ),
                    tooltip:
                        _isSwahili ? 'English' : 'Kiswahili',
                    onPressed: () =>
                        setState(() => _isSwahili = !_isSwahili),
                  ),
                  // Socratic toggle
                  IconButton(
                    icon: Icon(
                      Icons.psychology_rounded,
                      size: 20,
                      color: _socraticMode
                          ? Colors.amber.shade700
                          : _kSecondary,
                    ),
                    tooltip: _isSwahili
                        ? 'Njia ya Socratic'
                        : 'Socratic mode',
                    onPressed: () {
                      setState(() => _socraticMode = !_socraticMode);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_socraticMode
                              ? (_isSwahili
                                  ? 'Njia ya Socratic imewashwa'
                                  : 'Socratic mode enabled')
                              : (_isSwahili
                                  ? 'Njia ya Socratic imezimwa'
                                  : 'Socratic mode disabled')),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  // More menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 20, color: _kSecondary),
                    onSelected: _onMenuAction,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'new_chat',
                        child: _menuItem(Icons.add_rounded,
                            _isSwahili ? 'Mazungumzo mapya' : 'New chat'),
                      ),
                      PopupMenuItem(
                        value: 'history',
                        child: _menuItem(Icons.history_rounded,
                            _isSwahili ? 'Historia' : 'History'),
                      ),
                      PopupMenuItem(
                        value: 'saved',
                        child: _menuItem(Icons.bookmark_rounded,
                            _isSwahili ? 'Zilizohifadhiwa' : 'Saved'),
                      ),
                      PopupMenuItem(
                        value: 'formulas',
                        child: _menuItem(Icons.functions_rounded,
                            _isSwahili ? 'Fomula' : 'Formula sheet'),
                      ),
                      PopupMenuItem(
                        value: 'periodic',
                        child: _menuItem(Icons.grid_on_rounded,
                            _isSwahili ? 'Jedwali la elementi' : 'Periodic table'),
                      ),
                      PopupMenuItem(
                        value: 'photo_mode',
                        child: _menuItem(Icons.camera_alt_rounded,
                            _isSwahili ? 'Hali ya picha' : 'Photo mode'),
                      ),
                      PopupMenuItem(
                        value: 'physics_tools',
                        child: _menuItem(Icons.science_rounded,
                            _isSwahili ? 'Zana za Fizikia' : 'Physics tools'),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: _menuItem(Icons.settings_rounded,
                            _isSwahili ? 'Mipangilio' : 'Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Subject selector ──
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: SubjectMode.values.map((s) {
                  return SubjectChip(
                    subject: s,
                    selected: _subject == s,
                    isSwahili: _isSwahili,
                    onSelected: (v) {
                      setState(() => _subject = v);
                      _loadSuggestions();
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 4),

            // ── Difficulty selector ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  DifficultySelector(
                    selected: _difficulty,
                    onChanged: (v) =>
                        setState(() => _difficulty = v),
                    isSwahili: _isSwahili,
                  ),
                  const Spacer(),
                  if (_socraticMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology_rounded,
                              size: 12, color: Colors.amber.shade700),
                          const SizedBox(width: 4),
                          Text(
                            _isSwahili ? 'Socratic' : 'Socratic',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Prefill banner ──
            if (_hasPrefill)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note_rounded, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isSwahili
                            ? 'Kuelezea maelezo yako'
                            : 'Explaining your notes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _hasPrefill = false),
                      child: Icon(Icons.close_rounded,
                          size: 14, color: Colors.amber.shade700),
                    ),
                  ],
                ),
              ),

            // ── Messages / empty state ──
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollC,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length && _isSending) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _kPrimary),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isSwahili
                                        ? 'Newton anafikiria...'
                                        : 'Newton is thinking...',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _kSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final msg = _messages[i];
                        return NewtonBubble(
                          message: msg,
                          isSwahili: _isSwahili,
                          onBookmark: msg.isUser
                              ? null
                              : () => _toggleBookmark(i),
                          onFlag: msg.isUser
                              ? null
                              : () => _flagMessage(i),
                        );
                      },
                    ),
            ),

            // ── Quick actions ──
            if (_messages.isNotEmpty)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _quickAction(
                      Icons.quiz_rounded,
                      _isSwahili ? 'Mtihani' : 'Exam Qs',
                      _generateExamQuestions,
                    ),
                    _quickAction(
                      Icons.fitness_center_rounded,
                      _isSwahili ? 'Mazoezi' : 'Practice',
                      _generatePractice,
                    ),
                    _quickAction(
                      Icons.functions_rounded,
                      _isSwahili ? 'Fomula' : 'Formulas',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FormulaSheetPage(
                                isSwahili: _isSwahili)),
                      ),
                    ),
                    _quickAction(
                      Icons.grid_on_rounded,
                      _isSwahili ? 'Elementi' : 'Elements',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PeriodicTablePage(
                                isSwahili: _isSwahili)),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Input bar ──
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Camera button
                    IconButton(
                      icon: const Icon(Icons.camera_alt_rounded,
                          color: _kSecondary, size: 22),
                      tooltip: _isSwahili
                          ? 'Piga picha ya swali'
                          : 'Take photo of question',
                      onPressed: _isSending ? null : _sendImage,
                    ),
                    // Mic button (voice input coming soon)
                    IconButton(
                      icon: const Icon(Icons.mic_rounded,
                          color: _kSecondary, size: 22),
                      tooltip: _isSwahili
                          ? 'Ingizo la sauti linakuja hivi karibuni'
                          : 'Voice input coming soon',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isSwahili
                                  ? 'Ingizo la sauti linakuja hivi karibuni'
                                  : 'Voice input coming soon',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _inputC,
                        decoration: InputDecoration(
                          hintText: _isSwahili
                              ? 'Uliza swali...'
                              : 'Ask a question...',
                          hintStyle: const TextStyle(
                              fontSize: 14, color: _kSecondary),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        maxLines: null,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    // Send button
                    IconButton(
                      icon: Icon(
                        _isSending
                            ? Icons.hourglass_empty_rounded
                            : Icons.send_rounded,
                        color: _kPrimary,
                        size: 22,
                      ),
                      onPressed: _isSending ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.auto_awesome_rounded,
              size: 56, color: _kSecondary),
          const SizedBox(height: 16),
          Text(
            _isSwahili
                ? 'Habari! Mimi ni Newton.'
                : 'Hello! I am Newton.',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _kPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _isSwahili
                ? 'Niulize swali lolote la masomo - Hisabati, Fizikia, Kemia, na mengine.'
                : 'Ask me any academic question - Math, Physics, Chemistry, and more.',
            style: const TextStyle(fontSize: 14, color: _kSecondary),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            _isSwahili
                ? 'Ninaendana na mtaala wa NECTA.'
                : 'Aligned with NECTA curriculum.',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Topic suggestions
          if (_suggestions.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _isSwahili
                    ? 'Mada zinazopendekezwa'
                    : 'Suggested topics',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            ...(_suggestions.map((s) => _suggestionCard(s))),
          ],

          const SizedBox(height: 20),

          // Quick actions grid
          Text(
            _isSwahili ? 'Vitendo vya haraka' : 'Quick actions',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _quickActionCard(
                Icons.camera_alt_rounded,
                _isSwahili ? 'Piga picha' : 'Photo solve',
                _isSwahili
                    ? 'Piga picha ya swali'
                    : 'Take a photo of your question',
                _sendImage,
              ),
              const SizedBox(width: 10),
              _quickActionCard(
                Icons.quiz_rounded,
                _isSwahili ? 'Mtihani' : 'Exam Qs',
                _isSwahili
                    ? 'Maswali ya mtihani'
                    : 'Generate exam questions',
                _generateExamQuestions,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _quickActionCard(
                Icons.fitness_center_rounded,
                _isSwahili ? 'Mazoezi' : 'Practice',
                _isSwahili
                    ? 'Zoezi la maswali'
                    : 'Practice problem session',
                _generatePractice,
              ),
              const SizedBox(width: 10),
              _quickActionCard(
                Icons.functions_rounded,
                _isSwahili ? 'Fomula' : 'Formulas',
                _isSwahili
                    ? 'Orodha ya fomula'
                    : 'Reference formula sheets',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          FormulaSheetPage(isSwahili: _isSwahili)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionCard(TopicSuggestion suggestion) {
    final hint = _isSwahili
        ? suggestion.questionHintSw
        : suggestion.questionHint;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onSuggestionTap(suggestion),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(subjectIcon(suggestion.subject),
                    size: 20, color: _kSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.topic,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hint,
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: _kSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 24, color: _kPrimary),
                const SizedBox(height: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 10, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: _kPrimary),
        label: Text(label,
            style: const TextStyle(fontSize: 11, color: _kPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.grey.shade100,
        side: BorderSide.none,
        onPressed: onTap,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _menuItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _kPrimary),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'new_chat':
        _startNewChat();
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ConversationHistoryPage(
                  userId: widget.userId, isSwahili: _isSwahili)),
        );
        break;
      case 'saved':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SavedConversationsPage(
                  userId: widget.userId, isSwahili: _isSwahili)),
        );
        break;
      case 'formulas':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FormulaSheetPage(isSwahili: _isSwahili)),
        );
        break;
      case 'periodic':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  PeriodicTablePage(isSwahili: _isSwahili)),
        );
        break;
      case 'photo_mode':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoCapturePage(
              subject: _subject,
              difficulty: _difficulty,
              isSwahili: _isSwahili,
            ),
          ),
        );
        break;
      case 'physics_tools':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhysicsToolsPage(isSwahili: _isSwahili),
          ),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => NewtonSettingsPage(
                  userId: widget.userId, isSwahili: _isSwahili)),
        );
        break;
    }
  }
}
