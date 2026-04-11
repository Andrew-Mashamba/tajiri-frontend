// lib/car_insurance/widgets/quote_card.dart
import 'package:flutter/material.dart';
import '../models/car_insurance_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class QuoteCard extends StatelessWidget {
  final InsuranceQuote quote;
  final bool isSwahili;
  final VoidCallback? onPurchase;

  const QuoteCard({
    super.key,
    required this.quote,
    this.isSwahili = true,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: quote.providerLogo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(quote.providerLogo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.shield_rounded,
                            size: 20,
                            color: _kPrimary)))
                : const Icon(Icons.shield_rounded,
                    size: 20, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quote.providerName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(quote.coverageLabel,
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary)),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('TZS ${quote.premium.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            Text(isSwahili ? '/mwaka' : '/year',
                style: const TextStyle(fontSize: 10, color: _kSecondary)),
          ]),
        ]),
        const SizedBox(height: 10),
        // Inclusions
        if (quote.inclusions.isNotEmpty) ...[
          Text(isSwahili ? 'Inajumuisha:' : 'Includes:',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: quote.inclusions
                .take(4)
                .map((i) => _tag(i, const Color(0xFF4CAF50)))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(children: [
          _infoBadge('Excess: TZS ${quote.excess.toStringAsFixed(0)}'),
          if (quote.hasNoClaimsDiscount) ...[
            const SizedBox(width: 6),
            _infoBadge('NCD ${quote.discountPercent?.toStringAsFixed(0) ?? ''}%'),
          ],
        ]),
        if (onPurchase != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: onPurchase,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kPrimary,
                side: const BorderSide(color: _kPrimary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isSwahili ? 'Nunua' : 'Purchase',
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 9, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }

  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 10, color: _kSecondary)),
    );
  }
}
