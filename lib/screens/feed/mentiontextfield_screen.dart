import 'package:flutter/material.dart';
import '../../widgets/mention_text_field.dart';

/// Screen that provides @mentions and #hashtags in a post text field.
/// Navigation: Create Post (any type) → @ and # in text field (Story 86).
/// Design: DOCS/DESIGN.md (SafeArea, 48dp touch targets, monochrome).
class MentionTextFieldScreen extends StatefulWidget {
  final int currentUserId;
  final String? initialText;
  final String? hintText;
  final ValueChanged<String>? onContentChanged;

  const MentionTextFieldScreen({
    super.key,
    required this.currentUserId,
    this.initialText,
    this.hintText,
    this.onContentChanged,
  });

  @override
  State<MentionTextFieldScreen> createState() => _MentionTextFieldScreenState();
}

class _MentionTextFieldScreenState extends State<MentionTextFieldScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

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
                    Text(
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
                        border: Border.all(color: const Color(0xFF999999).withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                        onChanged: widget.onContentChanged,
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
                  child: MentionHashtagBarWithTouchTargets(
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

/// Wrapper that applies DESIGN.md: min 48dp touch targets for bar actions.
/// Use this when embedding the bar in create post screens.
class MentionHashtagBarWithTouchTargets extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onMentionTap;
  final VoidCallback? onHashtagTap;

  const MentionHashtagBarWithTouchTargets({
    super.key,
    required this.controller,
    this.onMentionTap,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BarButton(
          icon: Icons.alternate_email,
          label: 'Taja',
          onPressed: () {
            final t = controller.text;
            final s = controller.selection;
            if (s.isValid) {
              controller.text =
                  '${t.substring(0, s.baseOffset)}@${t.substring(s.extentOffset)}';
              controller.selection =
                  TextSelection.collapsed(offset: s.baseOffset + 1);
            } else {
              controller.text = t + '@';
              controller.selection =
                  TextSelection.collapsed(offset: controller.text.length);
            }
            onMentionTap?.call();
          },
        ),
        const SizedBox(width: 8),
        _BarButton(
          icon: Icons.tag,
          label: 'Hashtag',
          onPressed: () {
            final t = controller.text;
            final s = controller.selection;
            if (s.isValid) {
              controller.text =
                  '${t.substring(0, s.baseOffset)}#${t.substring(s.extentOffset)}';
              controller.selection =
                  TextSelection.collapsed(offset: s.baseOffset + 1);
            } else {
              controller.text = t + '#';
              controller.selection =
                  TextSelection.collapsed(offset: controller.text.length);
            }
            onHashtagTap?.call();
          },
        ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _BarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  static const Color _kPrimaryText = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: _kPrimaryText),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _kPrimaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
