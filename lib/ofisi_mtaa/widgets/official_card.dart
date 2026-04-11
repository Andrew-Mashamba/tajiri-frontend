// lib/ofisi_mtaa/widgets/official_card.dart
import 'package:flutter/material.dart';
import '../models/ofisi_mtaa_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class OfficialCard extends StatelessWidget {
  final MtaaOfficial official;
  final VoidCallback? onTap;

  const OfficialCard({super.key, required this.official, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEEEEEE),
            backgroundImage: official.photo.isNotEmpty
                ? NetworkImage(official.photo)
                : null,
            child: official.photo.isEmpty
                ? const Icon(Icons.person_rounded, color: _kSecondary, size: 22)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  official.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  official.roleLabel,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
          _statusDot(official.availabilityStatus),
          const SizedBox(width: 8),
          if (official.phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone_rounded, size: 20, color: _kPrimary),
              onPressed: () {},
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
        ],
      ),
    );
  }

  Widget _statusDot(String status) {
    final color = switch (status) {
      'available' => const Color(0xFF4CAF50),
      'out_of_office' => const Color(0xFFFFA000),
      _ => const Color(0xFFE53935),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(
          status == 'available' ? 'Yupo' : status == 'out_of_office' ? 'Hayupo' : 'Likizo',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
