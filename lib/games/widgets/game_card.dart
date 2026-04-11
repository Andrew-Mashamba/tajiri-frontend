// lib/games/widgets/game_card.dart
import 'package:flutter/material.dart';
import '../core/game_definition.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kMuted = Color(0xFF999999);

/// Game tile for 2-column grid display.
/// Shows game image, name, category, estimated time, player count.
class GameCard extends StatelessWidget {
  final GameDefinition definition;
  final VoidCallback? onTap;

  const GameCard({super.key, required this.definition, this.onTap});

  Color _categoryTint(GameDefinition def) {
    switch (def.category.name) {
      case 'puzzle':
        return const Color(0xFF6366F1);
      case 'trivia':
        return const Color(0xFF8B5CF6);
      case 'word':
        return const Color(0xFF06B6D4);
      case 'card':
        return const Color(0xFFF59E0B);
      case 'board':
        return const Color(0xFF10B981);
      case 'arcade':
        return const Color(0xFFEF4444);
      case 'math':
        return const Color(0xFF3B82F6);
      case 'strategy':
        return const Color(0xFFEC4899);
      default:
        return _kSecondary;
    }
  }

  Widget _iconFallback(Color tint) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(definition.icon, size: 36, color: tint),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              definition.category.displayName,
              style: TextStyle(fontSize: 9, color: tint, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tint = _categoryTint(definition);
    final hasImage = definition.imagePath != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — ~55% of card height
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: hasImage
                  ? Image.asset(
                      definition.imagePath!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconFallback(tint),
                    )
                  : _iconFallback(tint),
            ),

            // Text area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game name
                    Text(
                      definition.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Category name
                    Text(
                      definition.category.displayName,
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Metadata row
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: _kMuted),
                        const SizedBox(width: 2),
                        Text(
                          '~${definition.estimatedMinutes}m',
                          style: const TextStyle(fontSize: 10, color: _kMuted),
                        ),
                        const Spacer(),
                        const Icon(Icons.people_outline_rounded, size: 12, color: _kMuted),
                        const SizedBox(width: 2),
                        Text(
                          definition.playerCountLabel,
                          style: const TextStyle(fontSize: 10, color: _kMuted),
                        ),
                      ],
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
}
