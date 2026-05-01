import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F10 #86 — 50% deposit + balance T-14d (customer view).
///
/// Renders the configured payment-plan installments from
/// `event_bookings.payment_plan_installments` JSON shape:
///   [
///     {"label": "Deposit", "amount_tzs": 250000, "due_at": "2026-05-01"},
///     {"label": "Balance", "amount_tzs": 250000, "due_at": "2026-05-29",
///      "trigger": "T-14d"}
///   ]
class DepositBalanceCard extends StatelessWidget {
  final List<Map<String, dynamic>> installments;
  final DateTime? eventStartsAt;
  final void Function(int index)? onPay;

  const DepositBalanceCard({
    super.key,
    required this.installments,
    this.eventStartsAt,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if (installments.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSw ? 'Mpango wa malipo' : 'Payment plan',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          ...List.generate(installments.length, (i) {
            final ins = installments[i];
            final paid = ins['paid_at'] != null;
            final amount = (ins['amount_tzs'] as num?)?.toInt() ?? 0;
            final label = isSw
                ? (ins['label_sw'] ?? ins['label'] ?? 'Hatua ${i + 1}').toString()
                : (ins['label'] ?? 'Installment ${i + 1}').toString();
            DateTime? dueAt;
            try {
              if (ins['due_at'] != null) {
                dueAt = DateTime.parse(ins['due_at'].toString()).toLocal();
              }
            } catch (_) {}
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: paid
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      paid ? Icons.check_rounded : Icons.payment_rounded,
                      size: 18,
                      color: paid
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A)),
                        ),
                        if (dueAt != null)
                          Text(
                            isSw
                                ? 'Tarehe ya malipo: ${dueAt.day}/${dueAt.month}/${dueAt.year}'
                                : 'Due ${dueAt.day}/${dueAt.month}/${dueAt.year}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF666666)),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'TZS ${_fmt(amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: paid
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (!paid && onPay != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 30,
                      child: FilledButton(
                        onPressed: () => onPay!(i),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                        child: Text(
                          isSw ? 'Lipa' : 'Pay',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }
}
