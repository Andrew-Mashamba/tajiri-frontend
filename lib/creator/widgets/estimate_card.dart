// Estimate card — black hero card showing potential earnings for a locked
// source. Spec §5 (locked variant) and §6 (locked state hero).

import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/income_source.dart';

class EstimateCard extends StatelessWidget {
  final Estimate estimate;
  const EstimateCard({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (isSw ? 'UKADIRIO WAKO' : 'YOUR ESTIMATE'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xAACCCCCC),
              letterSpacing: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${formatTzsMinor(estimate.amountPerMonthMinor)} / ${isSw ? "mwezi" : "month"}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFAFAFA),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (estimate.assumptions.forContext(context).isNotEmpty)
            Text(
              estimate.assumptions.forContext(context),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xCCCCCCCC),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
