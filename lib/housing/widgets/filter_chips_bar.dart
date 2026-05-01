import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F9 #75 — Filter chips at top + neighborhood lens.
///
/// Sticky horizontal scrollable filter chip bar for housing search. Each chip
/// toggles a single filter, and the chip set is parameterized via [chips].
/// The "Lens" chip pops a sheet that toggles map overlay layers
/// (commute / school / crime), with the active layer reported via [onLensChanged].
class HousingFilterChip {
  final String key;
  final String labelEn;
  final String labelSw;
  final IconData icon;
  const HousingFilterChip({
    required this.key,
    required this.labelEn,
    required this.labelSw,
    required this.icon,
  });
}

class HousingFilterChipsBar extends StatelessWidget {
  final List<HousingFilterChip> chips;
  final Set<String> selectedKeys;
  final void Function(String key) onToggle;
  final String? activeLensKey;
  final void Function(String? lensKey)? onLensChanged;

  const HousingFilterChipsBar({
    super.key,
    required this.chips,
    required this.selectedKeys,
    required this.onToggle,
    this.activeLensKey,
    this.onLensChanged,
  });

  static const defaults = <HousingFilterChip>[
    HousingFilterChip(
      key: 'wifi',
      labelEn: 'WiFi',
      labelSw: 'Mtandao',
      icon: Icons.wifi_rounded,
    ),
    HousingFilterChip(
      key: 'parking',
      labelEn: 'Parking',
      labelSw: 'Maegesho',
      icon: Icons.local_parking_rounded,
    ),
    HousingFilterChip(
      key: 'security',
      labelEn: 'Security',
      labelSw: 'Ulinzi',
      icon: Icons.shield_outlined,
    ),
    HousingFilterChip(
      key: 'water',
      labelEn: 'Water',
      labelSw: 'Maji',
      icon: Icons.water_drop_outlined,
    ),
    HousingFilterChip(
      key: 'furnished',
      labelEn: 'Furnished',
      labelSw: 'Imefungwa',
      icon: Icons.weekend_rounded,
    ),
    HousingFilterChip(
      key: 'pets',
      labelEn: 'Pets OK',
      labelSw: 'Wanyama OK',
      icon: Icons.pets_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          if (onLensChanged != null)
            _LensChip(
              isSw: isSw,
              activeKey: activeLensKey,
              onChanged: onLensChanged!,
            ),
          ...chips.map((c) {
            final selected = selectedKeys.contains(c.key);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(c.icon, size: 14, color: selected ? Colors.white : const Color(0xFF666666)),
                    const SizedBox(width: 4),
                    Text(
                      isSw ? c.labelSw : c.labelEn,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                selected: selected,
                showCheckmark: false,
                selectedColor: const Color(0xFF1A1A1A),
                backgroundColor: const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
                  ),
                ),
                onSelected: (_) => onToggle(c.key),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LensChip extends StatelessWidget {
  final bool isSw;
  final String? activeKey;
  final void Function(String? lensKey) onChanged;
  const _LensChip({
    required this.isSw,
    required this.activeKey,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isSw ? 'Onyesha tabaka' : 'Show overlay',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car_rounded),
              title: Text(isSw ? 'Muda wa kufika ofisini' : 'Commute time'),
              onTap: () => Navigator.pop(context, 'commute'),
            ),
            ListTile(
              leading: const Icon(Icons.school_rounded),
              title: Text(isSw ? 'Shule karibu' : 'Schools nearby'),
              onTap: () => Navigator.pop(context, 'schools'),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(isSw ? 'Usalama wa eneo' : 'Crime overlay'),
              onTap: () => Navigator.pop(context, 'crime'),
            ),
            ListTile(
              leading: const Icon(Icons.layers_clear_rounded),
              title: Text(isSw ? 'Hakuna' : 'None'),
              onTap: () => Navigator.pop(context, null),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final active = activeKey != null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          Icons.layers_rounded,
          size: 16,
          color: active ? Colors.white : const Color(0xFF666666),
        ),
        label: Text(
          isSw ? 'Tabaka' : 'Lens',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: active ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: active ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
          ),
        ),
        onPressed: () => _open(context),
      ),
    );
  }
}
