import 'package:flutter/material.dart';

import '../../../models/privacy_settings_model.dart';

/// Shared widgets for the Faragha sub-pages.
///
/// Centralizes the visual style (cards, switches, audience pickers) so
/// every sub-page renders the same chrome. Mirrors the patterns the
/// notification settings screen already established.

const Color kFaraghaBg = Color(0xFFFAFAFA);
const Color kFaraghaCard = Color(0xFFFFFFFF);
const Color kFaraghaPrimary = Color(0xFF1A1A1A);
const Color kFaraghaSecondary = Color(0xFF666666);
const Color kFaraghaIconBg = Color(0xFF1A1A1A);

class FaraghaSection extends StatelessWidget {
  final String title;
  const FaraghaSection({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 0, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: kFaraghaPrimary,
          ),
        ),
      );
}

class FaraghaSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const FaraghaSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        toggled: value,
        label: subtitle == null ? title : '$title. $subtitle',
        child: MergeSemantics(
          child: Material(
            color: kFaraghaCard,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kFaraghaIconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kFaraghaPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kFaraghaSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (saving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kFaraghaSecondary,
                        ),
                      )
                    else
                      Switch(
                        value: value,
                        onChanged: onChanged,
                        activeTrackColor: kFaraghaPrimary.withValues(alpha: 0.5),
                        activeThumbColor: kFaraghaPrimary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Audience picker — opens a bottom sheet, returns the chosen visibility token.
class FaraghaAudienceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String value;
  final bool saving;
  final List<String> allowedOptions; // subset of: everyone, friends, only_me, nobody
  final ValueChanged<String> onChanged;
  final bool isSwahili;

  const FaraghaAudienceTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.saving,
    required this.allowedOptions,
    required this.onChanged,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final label = privacyVisibilityLabel(value, isSwahili: isSwahili);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: subtitle == null
            ? '$title. $label'
            : '$title. $subtitle. $label',
        child: MergeSemantics(
          child: Material(
            color: kFaraghaCard,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: InkWell(
              onTap: saving ? null : () => _open(context),
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: kFaraghaIconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: kFaraghaPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kFaraghaSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (saving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kFaraghaSecondary,
                          ),
                        )
                      else
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kFaraghaSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: kFaraghaSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            ...allowedOptions.map((opt) => ListTile(
                  title: Text(privacyVisibilityLabel(opt, isSwahili: isSwahili)),
                  trailing: opt == value
                      ? const Icon(Icons.check_rounded, color: kFaraghaPrimary)
                      : null,
                  onTap: () => Navigator.pop(ctx, opt),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked != null && picked != value) onChanged(picked);
  }
}

class FaraghaInlineErrorBanner extends StatelessWidget {
  final String? message;
  final VoidCallback onDismiss;
  final String closeLabel;
  const FaraghaInlineErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
    required this.closeLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 20, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message!,
                style: const TextStyle(fontSize: 13, color: Colors.red),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              button: true,
              label: closeLabel,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                onPressed: onDismiss,
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
