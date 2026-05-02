// Math card — gross → fee → net breakdown plus formula and own-statement.
// Spec §5 (math); §2 principle 6 (no competitor comparisons — own_statement
// only states TAJIRI's value).

import 'package:flutter/material.dart';
import '../models/income_source.dart';

class MathCard extends StatelessWidget {
  final MathInfo math;
  final String title;

  const MathCard({super.key, required this.math, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < math.components.length; i++)
            _MathRow(
              component: math.components[i],
              isFirst: i == 0,
              isLast: i == math.components.length - 1,
            ),
          if (math.formula.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                math.formula,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (math.ownStatement.forContext(context).isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                math.ownStatement.forContext(context),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFAFAFA),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MathRow extends StatelessWidget {
  final MathComponent component;
  final bool isFirst;
  final bool isLast;
  const _MathRow({
    required this.component,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isTotal = component.isTotal;
    final amount = component.amountMinor;
    final amountText = amount < 0
        ? '− ${formatTzsMinorBare(amount.abs())}'
        : formatTzsMinorBare(amount);

    return Container(
      padding: EdgeInsets.only(
        top: isTotal ? 10 : 6,
        bottom: 6,
      ),
      decoration: isTotal
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1A1A1A), width: 1),
              ),
            )
          : (isLast
              ? null
              : const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF0F0F0)),
                  ),
                )),
      child: Row(
        children: [
          Expanded(
            child: Text(
              component.label.forContext(context),
              style: TextStyle(
                fontSize: isTotal ? 14 : 12,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
