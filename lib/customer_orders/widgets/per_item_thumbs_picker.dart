import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 1099 — per-item thumbs up/down for multi-line orders.
/// Customer rates each dish or service line individually. Persists into
/// `partner_reviews.per_item_thumbs` JSON column on submit.
class PerItemThumbsPicker extends StatefulWidget {
  /// Each entry: `{label, key}` where label is shown to the customer and
  /// key is what's stored back in the per_item_thumbs map.
  final List<({String key, String label})> items;
  /// Map of {item_key: 'up' | 'down'}. Mutated through onChanged.
  final Map<String, String> initialThumbs;
  final ValueChanged<Map<String, String>> onChanged;
  const PerItemThumbsPicker({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialThumbs = const {},
  });

  @override
  State<PerItemThumbsPicker> createState() => _PerItemThumbsPickerState();
}

class _PerItemThumbsPickerState extends State<PerItemThumbsPicker> {
  late Map<String, String> _thumbs;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _thumbs = Map<String, String>.from(widget.initialThumbs);
  }

  void _set(String key, String value) {
    setState(() {
      if (_thumbs[key] == value) {
        _thumbs.remove(key);
      } else {
        _thumbs[key] = value;
      }
    });
    widget.onChanged(Map<String, String>.from(_thumbs));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final isSw = _isSwahili;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSw ? 'Kila kitu (hiari)' : 'Per-item rating (optional)',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _kSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ...widget.items.map(_row),
      ],
    );
  }

  Widget _row(({String key, String label}) item) {
    final selected = _thumbs[item.key];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              selected == 'up'
                  ? Icons.thumb_up_alt_rounded
                  : Icons.thumb_up_alt_outlined,
              size: 18,
              color: selected == 'up'
                  ? const Color(0xFF1B5E20)
                  : _kSecondary,
            ),
            tooltip: 'Up',
            onPressed: () => _set(item.key, 'up'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: Icon(
              selected == 'down'
                  ? Icons.thumb_down_alt_rounded
                  : Icons.thumb_down_alt_outlined,
              size: 18,
              color: selected == 'down'
                  ? const Color(0xFFB71C1C)
                  : _kSecondary,
            ),
            tooltip: 'Down',
            onPressed: () => _set(item.key, 'down'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
