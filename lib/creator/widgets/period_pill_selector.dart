// Period pill selector — Wiki | Mwezi | Robo | Yote.
// Spec §3 (IA): rescopes the KPI tiles and source rows.

import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/income_source.dart';

class PeriodPillSelector extends StatelessWidget {
  final IncomePeriod selected;
  final ValueChanged<IncomePeriod> onChanged;

  const PeriodPillSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;

    final items = <_PillItem>[
      _PillItem(IncomePeriod.week, isSw ? 'Wiki' : 'Week'),
      _PillItem(IncomePeriod.month, isSw ? 'Mwezi' : 'Month'),
      _PillItem(IncomePeriod.quarter, isSw ? 'Robo' : 'Quarter'),
      _PillItem(IncomePeriod.all, isSw ? 'Yote' : 'All time'),
    ];

    return Row(
      children: [
        for (final item in items) ...[
          Expanded(child: _Pill(item: item, selected: selected == item.period, onTap: () => onChanged(item.period))),
          if (item != items.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _PillItem {
  final IncomePeriod period;
  final String label;
  const _PillItem(this.period, this.label);
}

class _Pill extends StatelessWidget {
  final _PillItem item;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFE5E5E5),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? const Color(0xFFFAFAFA) : const Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
