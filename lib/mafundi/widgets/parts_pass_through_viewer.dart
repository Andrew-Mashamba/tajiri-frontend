import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/service_request.dart';

/// Spec F4 #24 — Customer-facing parts pass-through line-item viewer.
///
/// Renders the parts list captured by the partner with the configured markup
/// shown explicitly. Spec line 410: "20–30% above cost, line-itemized".
class PartsPassThroughViewer extends StatelessWidget {
  final List<PartsLineItem> items;
  const PartsPassThroughViewer({super.key, required this.items});

  String _fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  int _lineTotal(PartsLineItem it) {
    final markup = it.markupPct ?? 0;
    return it.costTzs + ((it.costTzs * markup) ~/ 100);
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (items.isEmpty) return const SizedBox.shrink();
    final subtotal = items.fold<int>(0, (s, it) => s + it.costTzs);
    final total = items.fold<int>(0, (s, it) => s + _lineTotal(it));
    final markupAmt = total - subtotal;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            isSw ? 'Vipuri' : 'Parts',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          ...items.map((it) {
            final lineTotal = _lineTotal(it);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A))),
                        if (it.markupPct != null && it.markupPct! > 0)
                          Text(
                            isSw
                                ? 'Cost TZS ${_fmt(it.costTzs)} + ${it.markupPct}% markup'
                                : 'Cost TZS ${_fmt(it.costTzs)} + ${it.markupPct}% markup',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF666666)),
                          ),
                      ],
                    ),
                  ),
                  Text('TZS ${_fmt(lineTotal)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A))),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            children: [
              Expanded(child: Text(isSw ? 'Gharama ya vipuri' : 'Parts cost')),
              Text('TZS ${_fmt(subtotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          if (markupAmt > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isSw ? 'Markup ya mtoa huduma' : 'Partner markup',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    ),
                  ),
                  Text('TZS ${_fmt(markupAmt)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(isSw ? 'Jumla' : 'Total',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Text('TZS ${_fmt(total)}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A))),
            ],
          ),
        ],
      ),
    );
  }
}
