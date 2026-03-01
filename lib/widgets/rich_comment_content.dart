import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// DESIGN: #1A1A1A primary, #666666 secondary, 14px body. Monochrome only.
/// Renders comment content with tappable @mentions, #hashtags, and URLs.
class RichCommentContent extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final void Function(String username)? onMentionTap;
  final void Function(String hashtag)? onHashtagTap;

  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _linkMention = Color(0xFF1A1A1A); // same, but we use underline for links

  const RichCommentContent({
    super.key,
    required this.text,
    this.baseStyle,
    this.onMentionTap,
    this.onHashtagTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ??
        const TextStyle(
          fontSize: 14,
          color: _primaryText,
          height: 1.35,
        );
    final spans = _parseSpans(style);
    if (spans.isEmpty) {
      return Text(text, style: style, maxLines: 20, overflow: TextOverflow.ellipsis);
    }
    return RichText(
      maxLines: 20,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: style, children: spans),
    );
  }

  List<InlineSpan> _parseSpans(TextStyle style) {
    // Match @username (word chars), #hashtag (word chars + common unicode), and URLs
    final regex = RegExp(
      r'(@[\w\u0621-\u064A\.\-]+)|(#[\w\u0621-\u064A\.\-]+)|(https?:\/\/[^\s]+)',
      multiLine: false,
    );
    final List<InlineSpan> result = [];
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        result.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final matchText = match.group(0)!;
      if (matchText.startsWith('@')) {
        final username = matchText.substring(1);
        result.add(
          TextSpan(
            text: matchText,
            style: style.copyWith(
              color: _linkMention,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: _linkMention.withOpacity(0.6),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onMentionTap?.call(username),
          ),
        );
      } else if (matchText.startsWith('#')) {
        final hashtag = matchText.substring(1);
        result.add(
          TextSpan(
            text: matchText,
            style: style.copyWith(
              color: _linkMention,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: _linkMention.withOpacity(0.6),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onHashtagTap?.call(hashtag),
          ),
        );
      } else {
        final url = matchText;
        result.add(
          TextSpan(
            text: url,
            style: style.copyWith(
              color: _linkMention,
              decoration: TextDecoration.underline,
              decorationColor: _linkMention.withOpacity(0.6),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl(url),
          ),
        );
      }
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      result.add(TextSpan(text: text.substring(lastEnd)));
    }
    return result;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
