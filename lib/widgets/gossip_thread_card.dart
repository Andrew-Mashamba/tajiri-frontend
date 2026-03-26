import 'package:flutter/material.dart';
import '../models/gossip_models.dart';
import '../l10n/app_strings_scope.dart';

const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const double _kCardRadius = 16.0;

class GossipThreadCard extends StatelessWidget {
  final GossipThread thread;
  final VoidCallback? onTap;

  const GossipThreadCard({
    super.key,
    required this.thread,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStringsScope.of(context) ?? AppStrings('en');
    final isSwahili = strings.isSwahili;
    final title = thread.title(isSwahili: isSwahili);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Stack(
        children: [
          // Background card (stacked effect)
          Positioned(
            left: 4,
            right: -4,
            top: 4,
            bottom: -4,
            child: Container(
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(_kCardRadius),
              ),
            ),
          ),
          // Main card
          Material(
            color: _kSurface,
            borderRadius: BorderRadius.circular(_kCardRadius),
            elevation: 1,
            shadowColor: const Color(0x1A000000),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_kCardRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: category chip + velocity
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kPrimaryText,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _categoryLabel(thread.category, strings),
                            style: const TextStyle(
                              color: _kSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.local_fire_department_rounded,
                            size: 16, color: _kSecondaryText),
                        const SizedBox(width: 4),
                        Text(
                          thread.velocityScore.toStringAsFixed(0),
                          style: const TextStyle(
                            color: _kSecondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      title.isNotEmpty ? title : strings.trendingNow,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kPrimaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Seed post preview
                    if (thread.seedPost?.content != null &&
                        thread.seedPost!.content!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          thread.seedPost!.content!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _kSecondaryText,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    // Footer: post count + participants
                    Row(
                      children: [
                        const Icon(Icons.article_outlined,
                            size: 14, color: _kTertiaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${thread.postCount} ${strings.postsInThread}',
                          style: const TextStyle(
                              color: _kTertiaryText, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.people_outline_rounded,
                            size: 14, color: _kTertiaryText),
                        const SizedBox(width: 4),
                        Text(
                          '${thread.participantCount} ${strings.peopleTalking}',
                          style: const TextStyle(
                              color: _kTertiaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category, AppStrings strings) {
    switch (category) {
      case 'entertainment':
        return strings.entertainment;
      case 'business':
        return strings.business;
      case 'music':
        return strings.music;
      case 'sports':
        return strings.sports;
      case 'local':
        return strings.local;
      default:
        return strings.trendingNow;
    }
  }
}
