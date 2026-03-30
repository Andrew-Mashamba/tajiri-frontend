import 'package:flutter/material.dart';
import '../models/tea_models.dart';

class TeaCardWidget extends StatelessWidget {
  const TeaCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.onActionTap,
  });

  final TeaCard card;
  final VoidCallback? onTap;
  final void Function(String action)? onActionTap;

  static const _urgencyColors = {
    'fire': Color(0xFFD32F2F),
    'hot': Color(0xFFFF6F00),
    'warm': Color(0xFFFFA000),
    'cold': Color(0xFF757575),
  };

  static const _urgencyEmojis = {
    'fire': '\u{1F525}',
    'hot': '\u{1F336}\u{FE0F}',
    'warm': '\u{2615}',
    'cold': '\u{1F9CA}',
  };

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColors[card.urgency] ?? const Color(0xFF757575);
    final emoji = _urgencyEmojis[card.urgency] ?? '\u{2615}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Urgency indicator + category
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$emoji ${card.urgency.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (card.category != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.category!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF757575),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (card.topReaction != null) ...[
                  const Spacer(),
                  Text(
                    card.topReaction!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Headline
            Text(
              card.headline,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Summary
            Text(
              card.summary,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF616161),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // Action buttons
            if (card.actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: card.actions.map((action) {
                  return TextButton(
                    onPressed: () => onActionTap?.call(action),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: const Size(48, 36),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                    ),
                    child: Text(
                      action,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
