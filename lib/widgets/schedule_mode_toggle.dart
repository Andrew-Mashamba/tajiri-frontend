import 'package:flutter/material.dart';

import '../l10n/app_strings_scope.dart';

/// Spec F2 #10 — Schedule vs ASAP toggle at booking time.
///
/// Drop into any booking sheet (food cart, mafundi service request, hair/nails
/// booking, fitness class). Customer picks ASAP or a 30-min slot up to 48h out.
/// Result is persisted to `partner_product_orders.schedule_mode` ('asap' or
/// 'scheduled') and `scheduled_for_at` on the server.
enum ScheduleMode { asap, scheduled }

class ScheduleModeResult {
  final ScheduleMode mode;
  final DateTime? scheduledAt;
  const ScheduleModeResult(this.mode, this.scheduledAt);
}

class ScheduleModeToggle extends StatefulWidget {
  final ScheduleMode initialMode;
  final DateTime? initialScheduledAt;
  final ValueChanged<ScheduleModeResult> onChanged;
  final int maxHoursAhead;

  const ScheduleModeToggle({
    super.key,
    this.initialMode = ScheduleMode.asap,
    this.initialScheduledAt,
    required this.onChanged,
    this.maxHoursAhead = 48,
  });

  @override
  State<ScheduleModeToggle> createState() => _ScheduleModeToggleState();
}

class _ScheduleModeToggleState extends State<ScheduleModeToggle> {
  late ScheduleMode _mode;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _scheduledAt = widget.initialScheduledAt;
  }

  void _emit() => widget.onChanged(ScheduleModeResult(_mode, _scheduledAt));

  Future<void> _pickSlot() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final now = DateTime.now();
    final firstSlot = _ceilToHalfHour(now.add(const Duration(minutes: 30)));
    final lastSlot = now.add(Duration(hours: widget.maxHoursAhead));

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => _SlotPicker(
        first: firstSlot,
        last: lastSlot,
        isSw: isSw,
      ),
    );
    if (picked != null) {
      setState(() {
        _mode = ScheduleMode.scheduled;
        _scheduledAt = picked;
      });
      _emit();
    }
  }

  static DateTime _ceilToHalfHour(DateTime t) {
    final m = t.minute;
    if (m == 0 || m == 30) return DateTime(t.year, t.month, t.day, t.hour, m);
    if (m < 30) return DateTime(t.year, t.month, t.day, t.hour, 30);
    return DateTime(t.year, t.month, t.day, t.hour + 1, 0);
  }

  String _fmt(DateTime t, bool isSw) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final today = DateTime.now();
    final isToday = t.year == today.year && t.month == today.month && t.day == today.day;
    final tomorrow = today.add(const Duration(days: 1));
    final isTomorrow = t.year == tomorrow.year &&
        t.month == tomorrow.month &&
        t.day == tomorrow.day;
    if (isToday) return isSw ? 'Leo $hh:$mm' : 'Today $hh:$mm';
    if (isTomorrow) return isSw ? 'Kesho $hh:$mm' : 'Tomorrow $hh:$mm';
    return '${t.day}/${t.month} $hh:$mm';
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
          Text(
            isSw ? 'Lini?' : 'When?',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _modeButton(
                  selected: _mode == ScheduleMode.asap,
                  iconData: Icons.bolt_rounded,
                  label: isSw ? 'Sasa hivi' : 'ASAP',
                  onTap: () {
                    setState(() {
                      _mode = ScheduleMode.asap;
                      _scheduledAt = null;
                    });
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _modeButton(
                  selected: _mode == ScheduleMode.scheduled,
                  iconData: Icons.event_rounded,
                  label: _scheduledAt != null
                      ? _fmt(_scheduledAt!, isSw)
                      : (isSw ? 'Chagua wakati' : 'Pick time'),
                  onTap: _pickSlot,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required bool selected,
    required IconData iconData,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF666666)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF1A1A1A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotPicker extends StatelessWidget {
  final DateTime first;
  final DateTime last;
  final bool isSw;
  const _SlotPicker({required this.first, required this.last, required this.isSw});

  List<DateTime> _slots() {
    final out = <DateTime>[];
    var t = first;
    while (t.isBefore(last)) {
      out.add(t);
      t = t.add(const Duration(minutes: 30));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slots();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isSw ? 'Chagua wakati' : 'Pick a time',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
            ),
          ),
          SizedBox(
            height: 360,
            child: ListView.builder(
              itemCount: slots.length,
              itemBuilder: (_, i) {
                final s = slots[i];
                final hh = s.hour.toString().padLeft(2, '0');
                final mm = s.minute.toString().padLeft(2, '0');
                final today = DateTime.now();
                final isToday = s.day == today.day && s.month == today.month;
                final tomorrow = today.add(const Duration(days: 1));
                final isTomorrow = s.day == tomorrow.day && s.month == tomorrow.month;
                final dayLabel = isToday
                    ? (isSw ? 'Leo' : 'Today')
                    : isTomorrow
                        ? (isSw ? 'Kesho' : 'Tomorrow')
                        : '${s.day}/${s.month}';
                return ListTile(
                  title: Text('$dayLabel  $hh:$mm',
                      style: const TextStyle(fontSize: 14)),
                  onTap: () => Navigator.pop(context, s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
