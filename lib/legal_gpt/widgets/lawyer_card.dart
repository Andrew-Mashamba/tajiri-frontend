// lib/legal_gpt/widgets/lawyer_card.dart
import 'package:flutter/material.dart';
import '../models/legal_gpt_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class LawyerCard extends StatelessWidget {
  final Lawyer lawyer;
  final VoidCallback? onTap;

  const LawyerCard({super.key, required this.lawyer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEEEEEE),
              backgroundImage: lawyer.photo.isNotEmpty
                  ? NetworkImage(lawyer.photo)
                  : null,
              child: lawyer.photo.isEmpty
                  ? const Icon(Icons.person_rounded,
                      color: _kSecondary, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lawyer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                      if (lawyer.verified)
                        const Icon(Icons.verified_rounded,
                            size: 16, color: Color(0xFF1E88E5)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (lawyer.specializations.isNotEmpty)
                    Text(
                      lawyer.specializations.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (lawyer.rating > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFFFA000)),
                        const SizedBox(width: 2),
                        Text(
                          lawyer.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, color: _kPrimary),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (lawyer.feeRange.isNotEmpty)
                        Text(
                          lawyer.feeRange,
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                        ),
                      const Spacer(),
                      Text(
                        lawyer.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                      ),
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
