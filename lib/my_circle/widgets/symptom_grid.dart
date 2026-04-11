// lib/my_circle/widgets/symptom_grid.dart
import 'package:flutter/material.dart';
import '../models/my_circle_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class SymptomGrid extends StatelessWidget {
  final List<Symptom> selected;
  final ValueChanged<List<Symptom>> onChanged;
  final bool isSwahili;

  const SymptomGrid({super.key, required this.selected, required this.onChanged, this.isSwahili = false});

  void _toggle(Symptom symptom) {
    final updated = List<Symptom>.from(selected);
    if (updated.contains(symptom)) {
      updated.remove(symptom);
    } else {
      updated.add(symptom);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isSwahili ? 'Dalili' : 'Symptoms', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Symptom.values.map((symptom) {
            final isSelected = selected.contains(symptom);
            return GestureDetector(
              onTap: () => _toggle(symptom),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _kPrimary : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      symptom.icon,
                      size: 16,
                      color: isSelected ? Colors.white : _kSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      symptom.displayName(isSwahili),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
