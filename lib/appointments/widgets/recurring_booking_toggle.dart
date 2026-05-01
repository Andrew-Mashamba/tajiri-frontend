import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/appointment_series_service.dart';

/// Spec F6 #41 — "Repeat" toggle for booking pages.
///
/// Drop into any booking sheet. Returns the chosen cadence + optional until
/// date via [onChanged]; when the toggle is off, [onChanged] reports null.
class RecurringBookingResult {
  final SeriesCadence cadence;
  final DateTime? untilDate;
  const RecurringBookingResult({required this.cadence, this.untilDate});
}

class RecurringBookingToggle extends StatefulWidget {
  final RecurringBookingResult? initial;
  final ValueChanged<RecurringBookingResult?> onChanged;

  const RecurringBookingToggle({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<RecurringBookingToggle> createState() => _RecurringBookingToggleState();
}

class _RecurringBookingToggleState extends State<RecurringBookingToggle> {
  late bool _enabled = widget.initial != null;
  late SeriesCadence _cadence = widget.initial?.cadence ?? SeriesCadence.weekly;
  DateTime? _until;

  @override
  void initState() {
    super.initState();
    _until = widget.initial?.untilDate;
  }

  void _emit() {
    widget.onChanged(
      _enabled
          ? RecurringBookingResult(cadence: _cadence, untilDate: _until)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              isSw ? 'Rudia mara kwa mara' : 'Repeat regularly',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A)),
            ),
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              _emit();
            },
          ),
          if (_enabled) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SeriesCadence.values.map((c) {
                final selected = _cadence == c;
                return ChoiceChip(
                  label: Text(isSw ? c.labelSw : c.labelEn),
                  selected: selected,
                  selectedColor: const Color(0xFF1A1A1A),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    setState(() => _cadence = c);
                    _emit();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_busy_rounded,
                    size: 16, color: Color(0xFF666666)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _until == null
                        ? (isSw ? 'Hakuna tarehe ya kumalizia' : 'No end date')
                        : (isSw
                            ? 'Inaisha ${_until!.day}/${_until!.month}/${_until!.year}'
                            : 'Until ${_until!.day}/${_until!.month}/${_until!.year}'),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF666666)),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _until ?? now.add(const Duration(days: 90)),
                      firstDate: now.add(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      setState(() => _until = picked);
                      _emit();
                    }
                  },
                  child: Text(isSw ? 'Chagua' : 'Pick'),
                ),
                if (_until != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () {
                      setState(() => _until = null);
                      _emit();
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
