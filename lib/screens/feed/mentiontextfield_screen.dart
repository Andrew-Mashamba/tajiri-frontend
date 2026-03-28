import 'package:flutter/material.dart';
import '../../models/friend_models.dart';
import '../../widgets/mention_text_field.dart';

/// Result returned by [MentionTextFieldScreen] via Navigator.pop.
class MentionTextFieldResult {
  final String text;
  final List<int> mentionedUserIds;

  const MentionTextFieldResult({
    required this.text,
    required this.mentionedUserIds,
  });
}

/// Screen that provides @mentions and #hashtags in a post text field.
/// Navigation: Create Post (any type) -> @ and # in text field (Story 86).
/// Design: DOCS/DESIGN.md (SafeArea, 48dp touch targets, monochrome).
class MentionTextFieldScreen extends StatefulWidget {
  final int currentUserId;
  final String? initialText;
  final String? hintText;

  const MentionTextFieldScreen({
    super.key,
    required this.currentUserId,
    this.initialText,
    this.hintText,
  });

  /// Push this screen and await the composed text + mentioned user IDs.
  /// Returns null if the user pops without confirming.
  ///
  /// Example:
  /// ```dart
  /// final result = await MentionTextFieldScreen.navigate(
  ///   context,
  ///   currentUserId: userId,
  ///   initialText: existingCaption,
  /// );
  /// if (result != null) {
  ///   print(result.text);
  ///   print(result.mentionedUserIds);
  /// }
  /// ```
  static Future<MentionTextFieldResult?> navigate(
    BuildContext context, {
    required int currentUserId,
    String? initialText,
    String? hintText,
  }) {
    return Navigator.push<MentionTextFieldResult?>(
      context,
      MaterialPageRoute<MentionTextFieldResult?>(
        builder: (_) => MentionTextFieldScreen(
          currentUserId: currentUserId,
          initialText: initialText,
          hintText: hintText,
        ),
      ),
    );
  }

  @override
  State<MentionTextFieldScreen> createState() => _MentionTextFieldScreenState();
}

class _MentionTextFieldScreenState extends State<MentionTextFieldScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final List<int> _mentionedUserIds = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onMentionSelected(UserProfile user) {
    if (!_mentionedUserIds.contains(user.id)) {
      setState(() {
        _mentionedUserIds.add(user.id);
      });
    }
  }

  void _onDone() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      MentionTextFieldResult(
        text: text,
        mentionedUserIds: List<int>.unmodifiable(_mentionedUserIds),
      ),
    );
  }

  static const Color _kPrimaryBg = Color(0xFFFAFAFA);
  static const Color _kPrimaryText = Color(0xFF1A1A1A);
  static const Color _kSecondaryText = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPrimaryBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimaryText,
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kPrimaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _onDone,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryText,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Andika chapisho lako. Tumia @ kutaja rafiki na # kwa hashtag.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kSecondaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 120),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF999999).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: MentionTextField(
                        controller: _controller,
                        currentUserId: widget.currentUserId,
                        hintText: widget.hintText ?? 'Andika hapa... @mention #hashtag',
                        minLines: 4,
                        maxLines: 12,
                        focusNode: _focusNode,
                        onMentionSelected: _onMentionSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: MentionHashtagBar(
                    controller: _controller,
                    onMentionTap: () => _focusNode.requestFocus(),
                    onHashtagTap: () => _focusNode.requestFocus(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
