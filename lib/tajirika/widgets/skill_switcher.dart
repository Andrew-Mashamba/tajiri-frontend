import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/tajirika_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec §13.2 — horizontal pill row at the top of Tajirika home that lets a
/// multi-skill partner switch the active scope between "Zote / All" and a
/// specific skill. Renders nothing when the partner has fewer than 2 skills.
///
/// `selectedSkill == null` ⇒ All-skills aggregate scope.
/// `selectedSkill == SkillCategory.X` ⇒ per-skill view.
class SkillSwitcher extends StatelessWidget {
  final List<SkillCategory> skills;
  final SkillCategory? selectedSkill;
  final ValueChanged<SkillCategory?> onSelected;
  final VoidCallback? onAddTap;

  const SkillSwitcher({
    super.key,
    required this.skills,
    required this.selectedSkill,
    required this.onSelected,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    if (skills.length < 2) return const SizedBox.shrink();
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _pill(
              icon: Icons.auto_awesome_motion_rounded,
              label: isSwahili ? 'Zote' : 'All',
              selected: selectedSkill == null,
              onTap: () => onSelected(null),
            ),
            for (final s in skills) ...[
              const SizedBox(width: 6),
              _pill(
                icon: s.icon,
                label: isSwahili ? s.labelSwahili : s.label,
                selected: selectedSkill == s,
                onTap: () => onSelected(s),
              ),
            ],
            if (onAddTap != null) ...[
              const SizedBox(width: 6),
              _pill(
                icon: Icons.add_rounded,
                label: isSwahili ? 'Ongeza' : 'Add',
                selected: false,
                onTap: onAddTap!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? _kPrimary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? _kPrimary : _kBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : _kPrimary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _kPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
