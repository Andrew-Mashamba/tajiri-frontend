import 'package:flutter/material.dart';

class ShangaziMessageBubble extends StatelessWidget {
  const ShangaziMessageBubble({
    super.key,
    required this.child,
    this.name,
    this.avatarIcon,
    this.onLongPress,
    this.footer,
  });

  final Widget child;
  final String? name;
  final IconData? avatarIcon;
  final VoidCallback? onLongPress;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final headerLabel = name ?? 'Shangazi';
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(left: 12, right: 48, top: 4, bottom: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (avatarIcon != null) ...[
                    Icon(avatarIcon, size: 14, color: const Color(0xFF1A1A1A)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    avatarIcon != null ? headerLabel : '\u{1FAD6} $headerLabel',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              child,
              if (footer != null) ...[
                const SizedBox(height: 4),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
