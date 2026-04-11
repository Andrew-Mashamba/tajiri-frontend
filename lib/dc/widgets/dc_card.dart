// lib/dc/widgets/dc_card.dart
import 'package:flutter/material.dart';
import '../models/dc_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class DcCard extends StatelessWidget {
  final DistrictCommissioner dc;
  final VoidCallback? onTap;

  const DcCard({super.key, required this.dc, this.onTap});

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
              backgroundImage:
                  dc.photo.isNotEmpty ? NetworkImage(dc.photo) : null,
              child: dc.photo.isEmpty
                  ? const Icon(Icons.person_rounded, color: _kSecondary, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DC: ${dc.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  if (dc.appointmentDate.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ameteuliwa: ${dc.appointmentDate.split("-").first}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
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
