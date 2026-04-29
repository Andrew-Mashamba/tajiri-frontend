import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../tajirika/models/tajirika_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);

class ChefCard extends StatelessWidget {
  final TajirikaPartner chef;
  final VoidCallback? onTap;
  final bool compact;

  const ChefCard({
    super.key,
    required this.chef,
    this.onTap,
    this.compact = false,
  });

  static const Set<SkillCategory> _foodSkills = {
    SkillCategory.cooking,
    SkillCategory.catering,
    SkillCategory.baking,
  };

  List<SkillCategory> get _displaySkills =>
      chef.skills.where(_foodSkills.contains).toList();

  @override
  Widget build(BuildContext context) {
    final skills = _displaySkills;
    final location = chef.serviceArea.displayText;
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chef.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chef.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Wazi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _kAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: skills
                            .map((s) => _skillPill(s.labelSwahili))
                            .toList(),
                      ),
                    ],
                    if (!compact && chef.bio != null && chef.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        chef.bio!,
                        style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (chef.aggregateRating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            chef.aggregateRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                          if (chef.jobsCompleted > 0)
                            Text(
                              ' (${chef.jobsCompleted})',
                              style: const TextStyle(fontSize: 11, color: _kSecondary),
                            ),
                          const SizedBox(width: 10),
                        ] else ...[
                          const Icon(Icons.new_releases_rounded, size: 13, color: _kSecondary),
                          const SizedBox(width: 3),
                          const Text(
                            'Mpya',
                            style: TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (location.isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.place_rounded, size: 13, color: _kSecondary),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    final photoUrl = chef.photoUrl;
    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          memCacheWidth: 200,
          placeholder: (_, _) => _avatarFallback(),
          errorWidget: (_, _, _) => _avatarFallback(),
        ),
      );
    }
    return _avatarFallback();
  }

  Widget _avatarFallback() {
    final initial = chef.name.isNotEmpty ? chef.name[0].toUpperCase() : '?';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }

  Widget _skillPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
      ),
    );
  }
}
