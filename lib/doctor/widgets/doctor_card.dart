// lib/doctor/widgets/doctor_card.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../models/doctor_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback? onTap;

  const DoctorCard({super.key, required this.doctor, this.onTap});

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
                    child: doctor.profilePhotoUrl != null
                        ? CachedMediaImage(
                            imageUrl: doctor.profilePhotoUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              doctor.initials,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary,
                              ),
                            ),
                          ),
                  ),
                  // Online indicator
                  if (doctor.isOnline)
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
                            'Dk. ${doctor.fullName}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (doctor.isVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.verified_rounded, size: 16, color: Color(0xFF4CAF50)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty.displayName,
                      style: TextStyle(fontSize: 13, color: doctor.specialty.icon == Icons.medical_services_rounded ? _kSecondary : Colors.blue.shade700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Rating
                        if (doctor.rating > 0) ...[
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                          ),
                          Text(
                            ' (${doctor.totalReviews})',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        // Experience
                        if (doctor.experienceYears > 0) ...[
                          Icon(Icons.work_outline, size: 13, color: _kSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${doctor.experienceYears} miaka',
                            style: const TextStyle(fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        // Consultation types
                        if (doctor.acceptsVideo) Icon(Icons.videocam_rounded, size: 14, color: Colors.grey.shade400),
                        if (doctor.acceptsAudio) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.phone_rounded, size: 14, color: Colors.grey.shade400),
                        ],
                        if (doctor.acceptsChat) ...[
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
                    'TZS ${_fmt(doctor.consultationFee)}',
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
