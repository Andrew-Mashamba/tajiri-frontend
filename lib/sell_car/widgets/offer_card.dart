// lib/sell_car/widgets/offer_card.dart
import 'package:flutter/material.dart';
import '../models/sell_car_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class OfferCard extends StatelessWidget {
  final SellOffer offer;
  final bool isSwahili;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OfferCard({
    super.key,
    required this.offer,
    this.isSwahili = true,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = offer.status == 'accepted'
        ? const Color(0xFF4CAF50)
        : offer.status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            child: Text(
                offer.buyerName.isNotEmpty
                    ? offer.buyerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: _kPrimary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(offer.buyerName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (offer.buyerVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          size: 14, color: Color(0xFF4CAF50)),
                    ],
                  ]),
                  Text(
                      '${offer.createdAt.day}/${offer.createdAt.month}/${offer.createdAt.year}',
                      style: const TextStyle(
                          fontSize: 10, color: _kSecondary)),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('TZS ${offer.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(offer.status.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ),
          ]),
        ]),
        if (offer.message != null) ...[
          const SizedBox(height: 8),
          Text(offer.message!,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
        if (offer.status == 'pending' &&
            (onAccept != null || onReject != null)) ...[
          const SizedBox(height: 10),
          Row(children: [
            if (onReject != null)
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isSwahili ? 'Kataa' : 'Decline',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            if (onAccept != null && onReject != null)
              const SizedBox(width: 8),
            if (onAccept != null)
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isSwahili ? 'Kubali' : 'Accept',
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
          ]),
        ],
      ]),
    );
  }
}
