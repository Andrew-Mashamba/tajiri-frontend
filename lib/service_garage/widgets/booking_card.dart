// lib/service_garage/widgets/booking_card.dart
import 'package:flutter/material.dart';
import '../models/service_garage_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BookingCard extends StatelessWidget {
  final ServiceBooking booking;
  final bool isSwahili;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.booking,
    this.isSwahili = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.build_rounded,
                        size: 20, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.serviceType,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(booking.garageName,
                              style: const TextStyle(
                                  fontSize: 11, color: _kSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(booking.statusLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(
                      '${booking.appointmentDate.day}/${booking.appointmentDate.month}/${booking.appointmentDate.year}',
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary)),
                  if (booking.carName != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.directions_car_rounded,
                        size: 13, color: _kSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(booking.carName!,
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ]),
                if (booking.estimatedCost != null ||
                    booking.actualCost != null) ...[
                  const SizedBox(height: 6),
                  Text(
                      'TZS ${(booking.actualCost ?? booking.estimatedCost)!.toStringAsFixed(0)}'
                      '${booking.actualCost == null ? ' (${isSwahili ? 'takriban' : 'est.'})' : ''}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                ],
              ]),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'in_progress':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return _kSecondary;
    }
  }
}
