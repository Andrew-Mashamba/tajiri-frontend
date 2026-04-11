import 'package:flutter/material.dart';
import '../models/tajirika_models.dart';
import 'tier_badge.dart';

class TierProgressBar extends StatelessWidget {
  final TierProgress progress;
  final bool isSwahili;

  const TierProgressBar({
    super.key,
    required this.progress,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TierBadge(tier: progress.currentTier),
              if (progress.nextTier != null) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(progress.currentTier.color),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                TierBadge(tier: progress.nextTier!),
              ] else
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    isSwahili ? 'Kiwango cha juu!' : 'Highest tier!',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (progress.nextTier != null) ...[
            const SizedBox(height: 16),
            _buildRequirement(
              Icons.work_rounded,
              isSwahili ? 'Kazi zilizokamilika' : 'Jobs completed',
              '${progress.jobsCompleted}/${progress.jobsNeeded}',
              progress.jobsCompleted >= progress.jobsNeeded,
            ),
            const SizedBox(height: 8),
            _buildRequirement(
              Icons.star_rounded,
              isSwahili ? 'Kiwango cha ukadiriaji' : 'Rating',
              '${progress.currentRating.toStringAsFixed(1)}/${progress.ratingNeeded.toStringAsFixed(1)}',
              progress.currentRating >= progress.ratingNeeded,
            ),
            const SizedBox(height: 8),
            _buildRequirement(
              Icons.school_rounded,
              isSwahili ? 'Mafunzo yaliyokamilika' : 'Training completed',
              '${progress.trainingCompleted}/${progress.trainingNeeded}',
              progress.trainingCompleted >= progress.trainingNeeded,
            ),
            if (progress.verificationsPending.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRequirement(
                Icons.verified_rounded,
                isSwahili ? 'Uthibitisho unaohitajika' : 'Verifications needed',
                progress.verificationsPending.join(', '),
                false,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRequirement(IconData icon, String label, String value, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: met ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: met ? const Color(0xFF4CAF50) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
