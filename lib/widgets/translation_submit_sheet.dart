// lib/widgets/translation_submit_sheet.dart
//
// G-F-003 / posts.md §VI. Translator submits a localized version of a post.
// Backend fires translation_create·translator. After approval (admin queue),
// translated_view·translator pays per view in the new locale.

import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';
import '../services/translation_service.dart';

class TranslationSubmitSheet extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final String? originalContent;

  const TranslationSubmitSheet({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.originalContent,
  });

  static Future<bool> show(
    BuildContext context, {
    required int postId,
    required int currentUserId,
    String? originalContent,
  }) async {
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TranslationSubmitSheet(
        postId: postId,
        currentUserId: currentUserId,
        originalContent: originalContent,
      ),
    );
    return res == true;
  }

  @override
  State<TranslationSubmitSheet> createState() => _TranslationSubmitSheetState();
}

class _TranslationSubmitSheetState extends State<TranslationSubmitSheet> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kTertiary = Color(0xFF999999);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kIconBg = Color(0xFFF5F5F5);

  // Most-spoken African + global locales — per project bilingual focus.
  static const List<({String code, String name})> _locales = [
    (code: 'sw', name: 'Kiswahili'),
    (code: 'en', name: 'English'),
    (code: 'fr', name: 'Français'),
    (code: 'ar', name: 'العربية'),
    (code: 'pt', name: 'Português'),
    (code: 'rw', name: 'Kinyarwanda'),
    (code: 'lg', name: 'Luganda'),
    (code: 'om', name: 'Afaan Oromo'),
    (code: 'am', name: 'አማርኛ'),
    (code: 'so', name: 'Soomaali'),
  ];

  String _locale = 'sw';
  final TextEditingController _content = TextEditingController();
  final TextEditingController _audioUrl = TextEditingController();
  final TranslationService _service = TranslationService();
  bool _busy = false;

  @override
  void dispose() {
    _content.dispose();
    _audioUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_content.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    final id = await _service.submit(
      postId: widget.postId,
      translatorUserId: widget.currentUserId,
      locale: _locale,
      content: _content.text.trim(),
      audioUrl: _audioUrl.text.trim().isNotEmpty ? _audioUrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (id != null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation submitted for review')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit translation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isSw ? 'Tafsiri chapisho' : 'Translate this post',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSw
                    ? 'Watafsiri waliokubaliwa hupata mapato kwa kila mtu anayetazama tafsiri yao.'
                    : 'Approved translators earn per view of their translation.',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              if (widget.originalContent != null &&
                  widget.originalContent!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kIconBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(
                    widget.originalContent!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                isSw ? 'Lugha' : 'Language',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _locales.map((l) {
                  final selected = _locale == l.code;
                  return InkWell(
                    onTap: () => setState(() => _locale = l.code),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 32),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _kPrimary : _kBorder,
                        ),
                      ),
                      child: Text(
                        l.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : _kPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                isSw ? 'Tafsiri yako' : 'Your translation',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _content,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: _kPrimary),
                decoration: InputDecoration(
                  hintText: isSw
                      ? 'Andika tafsiri kamili hapa…'
                      : 'Write the translated content…',
                  hintStyle: const TextStyle(fontSize: 13, color: _kTertiary),
                  filled: true,
                  fillColor: _kIconBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _audioUrl,
                style: const TextStyle(fontSize: 14, color: _kPrimary),
                decoration: InputDecoration(
                  hintText: isSw
                      ? 'URL ya sauti (hiari) — kufichua kama dub'
                      : 'Audio URL (optional) — registers as dub',
                  hintStyle: const TextStyle(fontSize: 13, color: _kTertiary),
                  prefixIcon:
                      const Icon(Icons.mic_rounded, color: _kTertiary, size: 20),
                  filled: true,
                  fillColor: _kIconBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      _busy || _content.text.trim().isEmpty ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isSw ? 'Tuma kwa ukaguzi' : 'Submit for review',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
