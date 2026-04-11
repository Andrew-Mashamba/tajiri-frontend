// lib/doctor/widgets/specialty_chip.dart
import 'package:flutter/material.dart';
import '../models/doctor_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SpecialtyChip extends StatelessWidget {
  final MedicalSpecialty specialty;
  final bool isSelected;
  final VoidCallback onTap;

  const SpecialtyChip({
    super.key,
    required this.specialty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kPrimary : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              specialty.icon,
              size: 16,
              color: isSelected ? Colors.white : _kSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              specialty.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
