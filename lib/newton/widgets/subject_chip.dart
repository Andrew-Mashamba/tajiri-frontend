// lib/newton/widgets/subject_chip.dart
import 'package:flutter/material.dart';
import '../models/newton_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

/// Maps SubjectMode to Material icon data.
IconData subjectIcon(SubjectMode subject) {
  switch (subject) {
    case SubjectMode.general:
      return Icons.auto_awesome_rounded;
    case SubjectMode.mathematics:
      return Icons.calculate_rounded;
    case SubjectMode.physics:
      return Icons.speed_rounded;
    case SubjectMode.chemistry:
      return Icons.science_rounded;
    case SubjectMode.biology:
      return Icons.biotech_rounded;
    case SubjectMode.history:
      return Icons.history_edu_rounded;
    case SubjectMode.geography:
      return Icons.public_rounded;
    case SubjectMode.english:
      return Icons.menu_book_rounded;
    case SubjectMode.kiswahili:
      return Icons.translate_rounded;
    case SubjectMode.commerce:
      return Icons.store_rounded;
    case SubjectMode.accounting:
      return Icons.account_balance_rounded;
    case SubjectMode.computerScience:
      return Icons.computer_rounded;
  }
}

class SubjectChip extends StatelessWidget {
  final SubjectMode subject;
  final bool selected;
  final bool isSwahili;
  final ValueChanged<SubjectMode> onSelected;

  const SubjectChip({
    super.key,
    required this.subject,
    required this.selected,
    required this.onSelected,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = isSwahili ? subject.displayNameSw : subject.displayName;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          subjectIcon(subject),
          size: 16,
          color: selected ? Colors.white : _kPrimary,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.white : _kPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        selected: selected,
        selectedColor: _kPrimary,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        onSelected: (_) => onSelected(subject),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
