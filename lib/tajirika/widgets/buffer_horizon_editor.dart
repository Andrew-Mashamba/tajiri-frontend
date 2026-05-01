import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F1 #4 + #33 + #103 + #104 — Buffer / processing / horizon editor.
///
/// Partner-side compact form for setting:
///   • duration_minutes (the implicit base for #4)
///   • pre_buffer_minutes / processing_minutes / post_buffer_minutes (#33)
///   • travel_buffer_minutes (#34)
///   • min_notice_minutes (#103)
///   • booking_horizon_days (#103)
///   • rebook_cadence_days (#40)
class BufferHorizonValues {
  final int durationMinutes;
  final int preBufferMinutes;
  final int processingMinutes;
  final int postBufferMinutes;
  final int travelBufferMinutes;
  final int minNoticeMinutes;
  final int bookingHorizonDays;
  final int? rebookCadenceDays;

  const BufferHorizonValues({
    required this.durationMinutes,
    required this.preBufferMinutes,
    required this.processingMinutes,
    required this.postBufferMinutes,
    required this.travelBufferMinutes,
    required this.minNoticeMinutes,
    required this.bookingHorizonDays,
    this.rebookCadenceDays,
  });

  Map<String, dynamic> toJson() => {
        'duration_minutes': durationMinutes,
        'pre_buffer_minutes': preBufferMinutes,
        'processing_minutes': processingMinutes,
        'post_buffer_minutes': postBufferMinutes,
        'travel_buffer_minutes': travelBufferMinutes,
        'min_notice_minutes': minNoticeMinutes,
        'booking_horizon_days': bookingHorizonDays,
        if (rebookCadenceDays != null) 'rebook_cadence_days': rebookCadenceDays,
      };
}

class BufferHorizonEditor extends StatefulWidget {
  final BufferHorizonValues initial;
  final ValueChanged<BufferHorizonValues> onChanged;
  const BufferHorizonEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<BufferHorizonEditor> createState() => _BufferHorizonEditorState();
}

class _BufferHorizonEditorState extends State<BufferHorizonEditor> {
  late int _duration = widget.initial.durationMinutes;
  late int _pre = widget.initial.preBufferMinutes;
  late int _proc = widget.initial.processingMinutes;
  late int _post = widget.initial.postBufferMinutes;
  late int _travel = widget.initial.travelBufferMinutes;
  late int _minNotice = widget.initial.minNoticeMinutes;
  late int _horizon = widget.initial.bookingHorizonDays;
  late int? _rebook = widget.initial.rebookCadenceDays;

  void _emit() => widget.onChanged(BufferHorizonValues(
        durationMinutes: _duration,
        preBufferMinutes: _pre,
        processingMinutes: _proc,
        postBufferMinutes: _post,
        travelBufferMinutes: _travel,
        minNoticeMinutes: _minNotice,
        bookingHorizonDays: _horizon,
        rebookCadenceDays: _rebook,
      ));

  Widget _row(String label, int value, int min, int max, int step,
      ValueChanged<int> set, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
            onPressed: value > min ? () { set((value - step).clamp(min, max)); _emit(); } : null,
          ),
          SizedBox(
            width: 64,
            child: Text('$value $suffix',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            onPressed: value < max ? () { set((value + step).clamp(min, max)); _emit(); } : null,
          ),
        ],
      ),
    );
  }

  Widget _chips(String label, List<int> options, int? value,
      ValueChanged<int?> set, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              ...options.map((opt) {
                final selected = value == opt;
                return ChoiceChip(
                  label: Text('$opt $suffix'),
                  selected: selected,
                  selectedColor: const Color(0xFF1A1A1A),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                  onSelected: (_) { set(opt); _emit(); },
                );
              }),
              ChoiceChip(
                label: const Text('—'),
                selected: value == null,
                selectedColor: const Color(0xFF1A1A1A),
                labelStyle: TextStyle(
                  fontSize: 11,
                  color: value == null ? Colors.white : const Color(0xFF1A1A1A),
                ),
                onSelected: (_) { set(null); _emit(); },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Muda na nafasi' : 'Time & buffers',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 6),
          _row(isSw ? 'Muda wa huduma' : 'Service duration', _duration, 5, 480, 5,
              (v) => setState(() => _duration = v), 'm'),
          _row(isSw ? 'Maandalizi (pre)' : 'Pre-buffer', _pre, 0, 60, 5,
              (v) => setState(() => _pre = v), 'm'),
          _row(isSw ? 'Usindikaji' : 'Processing', _proc, 0, 240, 5,
              (v) => setState(() => _proc = v), 'm'),
          _row(isSw ? 'Maandalizi (baada)' : 'Post-buffer', _post, 0, 60, 5,
              (v) => setState(() => _post = v), 'm'),
          _row(isSw ? 'Buffer ya safari' : 'Travel buffer', _travel, 0, 120, 5,
              (v) => setState(() => _travel = v), 'm'),
          const Divider(),
          _row(isSw ? 'Onyo la chini' : 'Min notice', _minNotice, 0, 720, 30,
              (v) => setState(() => _minNotice = v), 'm'),
          _row(isSw ? 'Upeo wa siku' : 'Horizon', _horizon, 1, 365, 1,
              (v) => setState(() => _horizon = v), 'd'),
          _chips(isSw ? 'Rudia kila' : 'Rebook every',
              const [7, 14, 30, 60, 90], _rebook, (v) => setState(() => _rebook = v), 'd'),
        ],
      ),
    );
  }
}
