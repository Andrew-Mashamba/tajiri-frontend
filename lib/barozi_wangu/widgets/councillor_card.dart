// lib/barozi_wangu/widgets/councillor_card.dart
import 'package:flutter/material.dart';
import '../models/barozi_wangu_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CouncillorCard extends StatelessWidget {
  final Councillor councillor;
  final VoidCallback? onTap;

  const CouncillorCard({super.key, required this.councillor, this.onTap});

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
              radius: 28,
              backgroundColor: const Color(0xFFEEEEEE),
              backgroundImage: councillor.photo.isNotEmpty
                  ? NetworkImage(councillor.photo)
                  : null,
              child: councillor.photo.isEmpty
                  ? const Icon(Icons.person_rounded, color: _kSecondary, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    councillor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${councillor.party} | ${councillor.termStart.split("-").first}-${councillor.termEnd.split("-").first}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  if (councillor.rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFA000)),
                        const SizedBox(width: 4),
                        Text(
                          councillor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
