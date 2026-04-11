import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import 'mode_icon.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TransportOptionCard extends StatelessWidget {
  final TransportOption option;
  final VoidCallback? onTap;
  final bool isCheapest;
  final bool isFastest;

  const TransportOptionCard({
    super.key,
    required this.option,
    this.onTap,
    this.isCheapest = false,
    this.isFastest = false,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            if (isCheapest || isFastest)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (isCheapest)
                      _badge('Bei Nafuu / Cheapest', Colors.green.shade700),
                    if (isCheapest && isFastest) const SizedBox(width: 8),
                    if (isFastest)
                      _badge('Haraka Zaidi / Fastest', Colors.blue.shade700),
                  ],
                ),
              ),

            // Operator row
            Row(
              children: [
                ModeIcon(mode: option.mode, size: 20, color: _kSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${option.operator.name}${option.transportClass != null ? ' \u2022 ${option.transportClass}' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  option.price.formatted,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time row
            Row(
              children: [
                // Departure
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(option.departure),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    Text(
                      option.origin.code,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ),

                // Duration line
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          option.durationFormatted,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _kSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 1,
                              color: Colors.grey.shade300,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kPrimary,
                                  ),
                                ),
                                Icon(
                                  ModeIcon.iconFor(option.mode),
                                  size: 14,
                                  color: _kSecondary,
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Arrival
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(option.arrival),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    Text(
                      option.destination.code,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Seats available
            if (option.seatsAvailable > 0)
              Text(
                '${option.seatsAvailable} seats available',
                style: TextStyle(
                  fontSize: 12,
                  color: option.seatsAvailable <= 5
                      ? Colors.red.shade600
                      : _kSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
