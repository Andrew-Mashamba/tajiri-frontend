import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/partner_availability.dart';
import '../services/partner_availability_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);

/// Read-only customer-side slot picker per spec line 1124. Pulls expanded slots
/// for (partnerUserId, skillCategory) over the configured horizon, presents a
/// horizontal date strip (showing only days that have slots), and a chip grid
/// of times for the selected day. Tap a chip → bubbles `DateTime` to caller.
///
/// Embed this in F6/F7/F10 booking pages to replace ad-hoc date+time pickers.
class SlotPicker extends StatefulWidget {
  final int partnerUserId;
  /// Skill scope (e.g. 'medical', 'djing'). null = Default scope.
  final String? skillCategory;
  /// Window length in days from today. Defaults to 14 per spec line 1189.
  final int horizonDays;
  /// Currently selected slot (re-renders the chip as selected).
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  const SlotPicker({
    super.key,
    required this.partnerUserId,
    required this.onSelected,
    this.skillCategory,
    this.horizonDays = 14,
    this.selected,
  });

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  bool _loading = true;
  String? _error;
  List<AvailableSlot> _slots = const [];
  /// "yyyy-MM-dd" → list of slots
  Map<String, List<AvailableSlot>> _byDay = const {};
  String? _selectedDay;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SlotPicker old) {
    super.didUpdateWidget(old);
    if (old.partnerUserId != widget.partnerUserId ||
        old.skillCategory != widget.skillCategory ||
        old.horizonDays != widget.horizonDays) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final from = DateTime.now();
    final to = from.add(Duration(days: widget.horizonDays));
    final res = await PartnerAvailabilityService.fetchSlots(
      partnerUserId: widget.partnerUserId,
      skillCategory: widget.skillCategory,
      from: from,
      to: to,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _slots = res.items;
        final grouped = <String, List<AvailableSlot>>{};
        for (final s in _slots) {
          final key = DateFormat('yyyy-MM-dd').format(s.startsAt.toLocal());
          grouped.putIfAbsent(key, () => []).add(s);
        }
        _byDay = grouped;
        if (widget.selected != null) {
          _selectedDay = DateFormat('yyyy-MM-dd').format(widget.selected!.toLocal());
        } else if (_byDay.isNotEmpty) {
          _selectedDay = _byDay.keys.first;
        }
      } else {
        _error = res.message ?? 'Failed';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(_error!, style: const TextStyle(color: _kMuted, fontSize: 12)),
        ),
      );
    }
    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_busy_rounded, size: 18, color: _kMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isSwahili
                    ? 'Hakuna slot zinazopatikana sasa. Jaribu baadaye au tarehe nyingine.'
                    : "No slots available right now. Try a different day or check later.",
                style: const TextStyle(fontSize: 12, color: _kMuted),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dayStrip(),
        const SizedBox(height: 8),
        _slotGrid(),
      ],
    );
  }

  Widget _dayStrip() {
    final days = _byDay.keys.toList();
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final key = days[i];
          final selected = key == _selectedDay;
          final date = DateTime.parse(key);
          final dayCount = _byDay[key]!.length;
          return InkWell(
            onTap: () => setState(() => _selectedDay = key),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _kPrimary : Colors.white,
                border: Border.all(color: selected ? _kPrimary : _kBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _kMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dayCount',
                    style: TextStyle(
                      fontSize: 9,
                      color: selected ? Colors.white70 : _kMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _slotGrid() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final slots = _byDay[_selectedDay!] ?? const <AvailableSlot>[];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: slots.map((s) {
        final isSelected = widget.selected != null
            && widget.selected!.toUtc().isAtSameMomentAs(s.startsAt.toUtc());
        return InkWell(
          onTap: () => widget.onSelected(s.startsAt.toLocal()),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? _kPrimary : Colors.white,
              border: Border.all(color: isSelected ? _kPrimary : _kBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              DateFormat('HH:mm').format(s.startsAt.toLocal()),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
