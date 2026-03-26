import 'package:flutter/material.dart';
import '../models/collaboration_models.dart';
import '../widgets/creator_tier_badge.dart';
import '../l10n/app_strings_scope.dart';

/// Card showing a suggested collaboration partner with accept/dismiss actions.
class CollaborationCard extends StatelessWidget {
  final CollaborationSuggestion suggestion;
  final VoidCallback? onAccept;
  final VoidCallback? onDismiss;

  const CollaborationCard({
    super.key,
    required this.suggestion,
    this.onAccept,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: suggestion.partnerAvatarUrl != null
                ? NetworkImage(suggestion.partnerAvatarUrl!)
                : null,
            child: suggestion.partnerAvatarUrl == null
                ? const Icon(Icons.person_rounded, size: 22, color: Color(0xFF999999))
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        suggestion.partnerName ?? 'Creator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    if (suggestion.partnerTier != null) ...[
                      const SizedBox(width: 6),
                      CreatorTierBadge(tier: suggestion.partnerTier!),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${strings?.sharedCategory ?? "Shared"}: ${suggestion.sharedCategory}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF999999)),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: Text(strings?.collaborate ?? 'Collaborate', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
