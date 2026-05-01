import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F1 #2 + #4 — Live add-ons recalc + implicit-duration display.
///
/// Drop into any booking sheet. The product's base duration is implicit (set
/// by the partner via `duration_minutes`); customer never picks duration.
/// Each add-on carries `delta_minutes` and `delta_tzs`; this widget sums them
/// live and displays running totals. Caller passes the chosen add-on keys
/// via [selectedAddOns]; toggling is owned by the host page so it can persist.
class AddOnSpec {
  final String key;
  final String labelEn;
  final String labelSw;
  final int deltaTzs;
  final int deltaMinutes;
  const AddOnSpec({
    required this.key,
    required this.labelEn,
    required this.labelSw,
    required this.deltaTzs,
    required this.deltaMinutes,
  });

  factory AddOnSpec.fromJson(Map<String, dynamic> json) => AddOnSpec(
        key: json['key']?.toString() ?? '',
        labelEn: json['label_en']?.toString() ?? json['label']?.toString() ?? '',
        labelSw: json['label_sw']?.toString() ?? json['label']?.toString() ?? '',
        deltaTzs: (json['delta_tzs'] as num?)?.toInt() ?? 0,
        deltaMinutes: (json['delta_minutes'] as num?)?.toInt() ?? 0,
      );
}

class BookingTotalCalculator extends StatelessWidget {
  final int basePriceTzs;
  final int baseMinutes;
  final List<AddOnSpec> addOns;
  final Set<String> selectedKeys;
  final ValueChanged<String> onToggle;

  const BookingTotalCalculator({
    super.key,
    required this.basePriceTzs,
    required this.baseMinutes,
    required this.addOns,
    required this.selectedKeys,
    required this.onToggle,
  });

  String _fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final addOnTzs = addOns
        .where((a) => selectedKeys.contains(a.key))
        .fold<int>(0, (s, a) => s + a.deltaTzs);
    final addOnMin = addOns
        .where((a) => selectedKeys.contains(a.key))
        .fold<int>(0, (s, a) => s + a.deltaMinutes);
    final total = basePriceTzs + addOnTzs;
    final totalMin = baseMinutes + addOnMin;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSw ? 'Vipengele vya ziada' : 'Add-ons',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          if (addOns.isEmpty)
            Text(
              isSw ? 'Hakuna vipengele vya ziada' : 'No add-ons available',
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            )
          else
            ...addOns.map((a) {
              final selected = selectedKeys.contains(a.key);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: selected,
                onChanged: (_) => onToggle(a.key),
                title: Text(isSw ? a.labelSw : a.labelEn,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
                subtitle: Text(
                  '+TZS ${_fmt(a.deltaTzs)}'
                  '${a.deltaMinutes > 0 ? "  •  +${a.deltaMinutes}m" : ""}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                ),
              );
            }),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  isSw ? 'Jumla' : 'Total',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              Text('TZS ${_fmt(total)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  isSw ? 'Muda wa kazi' : 'Service time',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF666666)),
                ),
              ),
              Text('${totalMin}m',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
            ],
          ),
        ],
      ),
    );
  }
}
