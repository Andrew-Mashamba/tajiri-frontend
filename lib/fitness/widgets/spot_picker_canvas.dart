import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F6 #42/#109 — Pick-a-spot floor plan canvas.
///
/// Renders a fixed-grid layout from `partner_studio_layouts.layout_json`:
///   { grid: [[1,2,null,3]], spots: [{id:1,label:"A1"}, ...] }
/// Taken spots are dimmed; the user's tap returns the chosen spot id.
class StudioLayout {
  final List<List<int?>> grid;
  final Map<int, String> spotLabels;
  const StudioLayout({required this.grid, required this.spotLabels});

  factory StudioLayout.fromJson(Map<String, dynamic> json) {
    final raw = json['grid'];
    final grid = <List<int?>>[];
    if (raw is List) {
      for (final row in raw) {
        if (row is List) {
          grid.add(row
              .map((c) => c is num ? c.toInt() : null)
              .toList(growable: false));
        }
      }
    }
    final labels = <int, String>{};
    final spots = json['spots'];
    if (spots is List) {
      for (final s in spots) {
        if (s is Map &&
            s['id'] is num &&
            s['label'] is String) {
          labels[(s['id'] as num).toInt()] = s['label'] as String;
        }
      }
    }
    return StudioLayout(grid: grid, spotLabels: labels);
  }
}

class SpotPickerCanvas extends StatelessWidget {
  final StudioLayout layout;
  final Set<int> takenSpotIds;
  final int? selectedSpotId;
  final ValueChanged<int> onPick;

  const SpotPickerCanvas({
    super.key,
    required this.layout,
    required this.takenSpotIds,
    required this.selectedSpotId,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (layout.grid.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          isSw ? 'Mtoa huduma hajaweka ramani.' : 'No floor plan available.',
          style: const TextStyle(color: Color(0xFF666666)),
        ),
      );
    }
    final cols = layout.grid.first.length;
    return LayoutBuilder(
      builder: (ctx, c) {
        final cellSize = (c.maxWidth - (cols - 1) * 6) / cols;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: layout.grid.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (int j = 0; j < row.length; j++) ...[
                    if (j > 0) const SizedBox(width: 6),
                    SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: row[j] == null
                          ? Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            )
                          : _Spot(
                              id: row[j]!,
                              label: layout.spotLabels[row[j]] ?? '${row[j]}',
                              taken: takenSpotIds.contains(row[j]),
                              selected: selectedSpotId == row[j],
                              onPick: onPick,
                            ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Spot extends StatelessWidget {
  final int id;
  final String label;
  final bool taken;
  final bool selected;
  final ValueChanged<int> onPick;
  const _Spot({
    required this.id,
    required this.label,
    required this.taken,
    required this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: taken ? null : () => onPick(id),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: taken
              ? const Color(0xFFEEEEEE)
              : (selected ? const Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: taken
                ? const Color(0xFFCCCCCC)
                : (selected
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFE0E0E0)),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: taken
                ? const Color(0xFF999999)
                : (selected ? Colors.white : const Color(0xFF1A1A1A)),
          ),
        ),
      ),
    );
  }
}
