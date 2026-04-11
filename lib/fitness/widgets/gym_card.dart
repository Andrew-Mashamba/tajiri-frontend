// lib/fitness/widgets/gym_card.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/fitness_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class GymCard extends StatelessWidget {
  final Gym gym;
  final VoidCallback? onTap;

  const GymCard({super.key, required this.gym, this.onTap});

  String _fmt(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: gym.imageUrl != null
                  ? CachedMediaImage(imageUrl: gym.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: _kPrimary.withValues(alpha: 0.06),
                      child: const Center(child: Icon(Icons.fitness_center_rounded, size: 40, color: _kSecondary)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(gym.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (gym.hasLiveStreaming)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.live_tv_rounded, size: 12, color: Colors.red),
                              SizedBox(width: 3),
                              Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (gym.address != null)
                    Text(gym.address!, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (gym.rating > 0) ...[
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        Text(' ${gym.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
                        const SizedBox(width: 10),
                      ],
                      Icon(Icons.people_outline, size: 14, color: _kSecondary),
                      Text(' ${gym.memberCount}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                      const Spacer(),
                      Text('TZS ${_fmt(gym.monthlyPrice)}/mwezi', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
