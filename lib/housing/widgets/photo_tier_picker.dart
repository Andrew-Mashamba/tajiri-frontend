import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F9 #74 — HDR / wide-angle / drone photo tiers + premium gating.
///
/// Partner-side picker. `availableTiers` reflects what the partner's plan
/// allows; locked tiers show a 🔒 + Premium badge and an upsell sheet.
enum PhotoTier { standard, hdr, wide, drone }

extension PhotoTierX on PhotoTier {
  String get key => name;
  String labelEn() {
    switch (this) {
      case PhotoTier.standard:
        return 'Standard';
      case PhotoTier.hdr:
        return 'HDR';
      case PhotoTier.wide:
        return 'Wide-angle';
      case PhotoTier.drone:
        return 'Drone';
    }
  }
  String labelSw() {
    switch (this) {
      case PhotoTier.standard:
        return 'Kawaida';
      case PhotoTier.hdr:
        return 'HDR';
      case PhotoTier.wide:
        return 'Pana';
      case PhotoTier.drone:
        return 'Droni';
    }
  }
  IconData icon() {
    switch (this) {
      case PhotoTier.standard:
        return Icons.image_rounded;
      case PhotoTier.hdr:
        return Icons.hdr_on_rounded;
      case PhotoTier.wide:
        return Icons.panorama_wide_angle_rounded;
      case PhotoTier.drone:
        return Icons.flight_rounded;
    }
  }
}

class PhotoTierPicker extends StatelessWidget {
  final Set<PhotoTier> selected;
  final Set<PhotoTier> availableTiers;
  final ValueChanged<PhotoTier> onToggle;
  final VoidCallback? onUpsell;

  const PhotoTierPicker({
    super.key,
    required this.selected,
    required this.availableTiers,
    required this.onToggle,
    this.onUpsell,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSw ? 'Aina ya picha' : 'Photo tier',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PhotoTier.values.map((t) {
            final available = availableTiers.contains(t);
            final isSelected = selected.contains(t);
            final color = isSelected ? Colors.white : const Color(0xFF1A1A1A);
            return InkWell(
              onTap: () {
                if (!available) {
                  onUpsell?.call();
                  return;
                }
                onToggle(t);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : (available ? const Color(0xFFFAFAFA) : const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon(), size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      isSw ? t.labelSw() : t.labelEn(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    if (!available) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.lock_rounded,
                          size: 11, color: Color(0xFF999999)),
                    ],
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
