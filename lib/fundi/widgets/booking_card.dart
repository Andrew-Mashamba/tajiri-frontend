// lib/fundi/widgets/booking_card.dart
import 'package:flutter/material.dart';
import '../models/fundi_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class BookingCard extends StatelessWidget {
  final FundiBooking booking;
  final VoidCallback? onTap;

  const BookingCard({super.key, required this.booking, this.onTap});

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: booking.status.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(booking.service.icon, size: 18, color: booking.status.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.service.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: booking.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (booking.estimatedCost != null)
                        Text(
                          'TZS ${_fmtPrice(booking.estimatedCost!)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(booking.scheduledDate),
                        style: const TextStyle(fontSize: 10, color: _kSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              if (booking.fundiName != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 14, color: _kSecondary),
                    const SizedBox(width: 4),
                    Text(
                      booking.fundiName!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ),
              ],
              if (booking.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  booking.description!,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
