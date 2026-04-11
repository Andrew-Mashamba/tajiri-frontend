// lib/skincare/widgets/skin_profile_card.dart
import 'package:flutter/material.dart';
import '../models/skincare_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class SkinProfileCard extends StatelessWidget {
  final SkinProfile profile;
  final VoidCallback? onTap;

  const SkinProfileCard({super.key, required this.profile, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(profile.skinType.icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngozi ${profile.skinType.displayName}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.skinType.description,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${profile.score}',
                        style: TextStyle(color: _scoreColor, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Alama',
                        style: TextStyle(color: _scoreColor.withValues(alpha: 0.7), fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Concerns row
            if (profile.concerns.isNotEmpty) ...[
              const Text('Matatizo:', style: TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.concerns.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(c.icon, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(c.displayName, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    )).toList(),
              ),
            ],
            // Climate & last analysis
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  profile.climateZone.displayName,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
                const Spacer(),
                if (profile.lastAnalysisDate != null)
                  Text(
                    'Uchambuzi: ${_formatDate(profile.lastAnalysisDate!)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _scoreColor {
    if (profile.score >= 80) return const Color(0xFF4CAF50);
    if (profile.score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
