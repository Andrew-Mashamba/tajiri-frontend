// lib/lawyer/widgets/lawyer_card.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/lawyer_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class LawyerCard extends StatelessWidget {
  final Lawyer lawyer;
  final VoidCallback? onTap;

  const LawyerCard({super.key, required this.lawyer, this.onTap});

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
                    child: lawyer.profilePhotoUrl != null
                        ? CachedMediaImage(
                            imageUrl: lawyer.profilePhotoUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              lawyer.initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                  ),
                  if (lawyer.isOnline)
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
                            'Wkl. ${lawyer.fullName}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lawyer.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4CAF50)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lawyer.specialty.displayName,
                      style: const TextStyle(fontSize: 13, color: _kSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (lawyer.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            lawyer.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                          ),
                          Text(
                            ' (${lawyer.totalReviews})',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (lawyer.experienceYears > 0) ...[
                          const Icon(Icons.work_outline, size: 13, color: _kSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${lawyer.experienceYears} miaka',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (lawyer.acceptsVideo) Icon(Icons.videocam_rounded, size: 14, color: Colors.grey.shade400),
                        if (lawyer.acceptsAudio) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade400),
                        ],
                        if (lawyer.acceptsChat) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.chat_rounded, size: 14, color: Colors.grey.shade400),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Fee
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TZS ${_fmt(lawyer.consultationFee)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                  ),
                  const Text('/mashauriano', style: TextStyle(fontSize: 10, color: _kSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
