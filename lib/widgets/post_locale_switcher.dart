// lib/widgets/post_locale_switcher.dart
//
// UN-010 / posts.md row 55 (translated_view·translator). Pill button
// that lists approved translations for a post; tapping a locale fires
// the translated_view event and notifies the parent so the displayed
// caption can swap.
//
// Engineering playbook: monochrome, 48dp targets, _rounded icons,
// AppStringsScope bilingual, drag-handle bottom sheet, maxLines+ellipsis.

import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';
import '../services/translation_service.dart';

class PostLocaleSwitcher extends StatefulWidget {
  final int postId;
  final int currentUserId;

  /// Called when the viewer picks a translation. Pass `null` to revert
  /// to the original post content.
  final ValueChanged<PostTranslation?> onLocaleSelected;

  const PostLocaleSwitcher({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.onLocaleSelected,
  });

  @override
  State<PostLocaleSwitcher> createState() => _PostLocaleSwitcherState();
}

class _PostLocaleSwitcherState extends State<PostLocaleSwitcher> {
  static const _kPrimary = Color(0xFF1A1A1A);
  static const _kSecondary = Color(0xFF666666);
  static const _kBorder = Color(0xFFE5E5E5);
  static const _kSurface = Colors.white;
  static const _kIconBg = Color(0xFFF5F5F5);

  final TranslationService _service = TranslationService();
  List<PostTranslation> _translations = const [];
  PostTranslation? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    final list = await _service.listApproved(widget.postId);
    if (!mounted) return;
    setState(() {
      _translations = list;
      _loading = false;
    });
  }

  Future<void> _openPicker() async {
    if (_translations.isEmpty) return;
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final picked = await showModalBottomSheet<PostTranslation?>(
      context: context,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isSw ? 'Chagua lugha' : 'Pick a language',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.language_rounded,
                    color: _kPrimary, size: 20),
              ),
              title: Text(
                isSw ? 'Asili' : 'Original',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              trailing: _selected == null
                  ? const Icon(Icons.check_rounded, color: _kPrimary)
                  : null,
              onTap: () => Navigator.pop(ctx, null),
            ),
            const Divider(height: 1, color: _kBorder),
            ..._translations.map(
              (t) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kIconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t.locale.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
                title: Text(
                  _localeName(t.locale, isSw),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                subtitle: t.audioUrl != null
                    ? Text(
                        isSw ? 'Sauti ya dub' : 'Dubbed audio',
                        style: const TextStyle(fontSize: 11, color: _kSecondary),
                      )
                    : null,
                trailing: _selected?.id == t.id
                    ? const Icon(Icons.check_rounded, color: _kPrimary)
                    : null,
                onTap: () => Navigator.pop(ctx, t),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _selected = picked);
    widget.onLocaleSelected(picked);

    // Fire translated_view·translator on locale change.
    if (picked != null) {
      _service.recordView(
        postId: widget.postId,
        locale: picked.locale,
        userId: widget.currentUserId,
      );
    }
  }

  String _localeName(String code, bool isSw) {
    const names = {
      'sw': 'Kiswahili',
      'en': 'English',
      'fr': 'Français',
      'ar': 'العربية',
      'pt': 'Português',
      'rw': 'Kinyarwanda',
      'lg': 'Luganda',
      'om': 'Afaan Oromo',
      'am': 'አማርኛ',
      'so': 'Soomaali',
      'de': 'Deutsch',
      'es': 'Español',
    };
    return names[code] ?? code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _translations.isEmpty) {
      return const SizedBox.shrink();
    }
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final currentLabel = _selected == null
        ? (isSw ? 'Asili' : 'Orig')
        : _selected!.locale.toUpperCase();
    return InkWell(
      onTap: _openPicker,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              currentLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
