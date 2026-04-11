// lib/rent_car/widgets/chauffeur_card.dart
import 'package:flutter/material.dart';
import '../models/rent_car_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ChauffeurCard extends StatelessWidget {
  final Chauffeur chauffeur;
  final VoidCallback? onTap;

  const ChauffeurCard({super.key, required this.chauffeur, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE8E8E8),
                backgroundImage: chauffeur.photo != null ? NetworkImage(chauffeur.photo!) : null,
                child: chauffeur.photo == null
                    ? const Icon(Icons.person_rounded, color: _kSecondary)
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
                          child: Text(chauffeur.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (chauffeur.isSafariGuide)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Safari Guide',
                                style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${chauffeur.experienceYears} years experience',
                        style: const TextStyle(fontSize: 12, color: _kSecondary)),
                    if (chauffeur.languages.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(chauffeur.languages.join(', '),
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text(chauffeur.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: chauffeur.isAvailable ? const Color(0xFF2E7D32) : _kSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
