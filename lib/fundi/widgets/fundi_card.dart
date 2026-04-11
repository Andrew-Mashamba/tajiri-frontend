// lib/fundi/widgets/fundi_card.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/fundi_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class FundiCard extends StatelessWidget {
  final Fundi fundi;
  final VoidCallback? onTap;

  const FundiCard({super.key, required this.fundi, this.onTap});

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _kPrimary.withValues(alpha: 0.08),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: fundi.photoUrl != null
                        ? CachedMediaImage(
                            imageUrl: fundi.photoUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              fundi.initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                  ),
                  if (fundi.isAvailable)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: _kCardBg, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fundi.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (fundi.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4CAF50)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fundi.services.take(2).map((s) => s.displayName).join(', '),
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (fundi.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            fundi.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                          ),
                          Text(
                            ' (${fundi.totalReviews})',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (fundi.experienceYears > 0) ...[
                          const Icon(Icons.work_outline, size: 13, color: _kSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${fundi.experienceYears} miaka',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (fundi.location != null)
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: _kSecondary),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    fundi.location!,
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
              if (fundi.hourlyRate != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TZS ${_fmtPrice(fundi.hourlyRate!)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                    const Text('/saa', style: TextStyle(fontSize: 10, color: _kSecondary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
