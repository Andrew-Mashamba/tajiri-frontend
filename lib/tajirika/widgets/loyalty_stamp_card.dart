import 'package:flutter/material.dart';
import '../services/loyalty_stamp_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kAccent = Color(0xFF1B5E20);
const Color _kAccentBg = Color(0xFFE8F5E9);

class LoyaltyStampCardWidget extends StatelessWidget {
  final LoyaltyStampCard? card;
  final bool isSwahili;

  const LoyaltyStampCardWidget({
    super.key,
    this.card,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    final earned = card?.stampsEarned ?? 0;
    final target = card?.target ?? 10;
    final progress = target > 0 ? earned / target : 0.0;
    final remaining = target - earned;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAccentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _kAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_activity_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Kadi ya Stamps' : 'Stamp Card',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSwahili
                          ? 'Stamps $earned/$target — zimesalia $remaining'
                          : 'Stamps $earned/$target — $remaining to reward',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili
                ? 'Pokea zawadi yako baada ya stamp $target!'
                : 'Claim your reward after stamp $target!',
            style: const TextStyle(
              fontSize: 11,
              color: _kSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
