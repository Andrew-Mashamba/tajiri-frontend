import 'package:flutter/material.dart';

/// Shared visual primitives for the Usalama (Security) sub-pages.
/// Same chrome as Faragha + Arifa.

const Color kUsalamaBg = Color(0xFFFAFAFA);
const Color kUsalamaCard = Color(0xFFFFFFFF);
const Color kUsalamaPrimary = Color(0xFF1A1A1A);
const Color kUsalamaSecondary = Color(0xFF666666);
const Color kUsalamaIconBg = Color(0xFF1A1A1A);

class UsalamaSection extends StatelessWidget {
  final String title;
  const UsalamaSection({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 0, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: kUsalamaPrimary,
          ),
        ),
      );
}

class UsalamaSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final bool saving;
  final ValueChanged<bool> onChanged;
  const UsalamaSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          toggled: value,
          label: subtitle == null ? title : '$title. $subtitle',
          child: MergeSemantics(
            child: Material(
              color: kUsalamaCard,
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
                          color: kUsalamaIconBg,
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
                                color: kUsalamaPrimary,
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
                                  color: kUsalamaSecondary,
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
                            color: kUsalamaSecondary,
                          ),
                        )
                      else
                        Switch(
                          value: value,
                          onChanged: onChanged,
                          activeTrackColor: kUsalamaPrimary.withValues(alpha: 0.5),
                          activeThumbColor: kUsalamaPrimary,
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

class UsalamaInlineErrorBanner extends StatelessWidget {
  final String? message;
  final VoidCallback onDismiss;
  final String closeLabel;
  const UsalamaInlineErrorBanner({
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

class UsalamaInlineSuccessBanner extends StatelessWidget {
  final String? message;
  final VoidCallback onDismiss;
  final String closeLabel;
  const UsalamaInlineSuccessBanner({
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
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1B5E20)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              button: true,
              label: closeLabel,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.green),
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
