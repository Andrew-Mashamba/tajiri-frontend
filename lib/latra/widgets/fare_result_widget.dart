// lib/latra/widgets/fare_result_widget.dart
import 'package:flutter/material.dart';
import '../models/latra_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class FareResultWidget extends StatelessWidget {
  final FareResult fare;
  final bool isSwahili;

  const FareResultWidget({
    super.key,
    required this.fare,
    required this.isSwahili,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 22),
              const SizedBox(width: 8),
              Text(
                isSwahili ? 'Bei Iliyoidhinishwa' : 'Approved Fare',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isSwahili ? 'Kutoka' : 'From',
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary)),
                    Text(fare.origin,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: _kSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isSwahili ? 'Kwenda' : 'To',
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary)),
                    Text(fare.destination,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'TZS ${fare.approvedFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary),
                ),
                Text(
                  fare.vehicleType[0].toUpperCase() +
                      fare.vehicleType.substring(1),
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
