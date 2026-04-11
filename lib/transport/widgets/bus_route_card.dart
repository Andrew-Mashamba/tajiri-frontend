// lib/transport/widgets/bus_route_card.dart
import 'package:flutter/material.dart';
import '../models/transport_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class BusRouteCard extends StatelessWidget {
  final BusRoute route;
  final VoidCallback? onBook;

  const BusRouteCard({super.key, required this.route, this.onBook});

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _fmtTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company & price
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_bus_rounded, size: 18, color: _kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.company,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (route.busType != null)
                        Text(
                          route.busType!,
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                        ),
                    ],
                  ),
                ),
                Text(
                  'TZS ${_fmtPrice(route.price)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Route
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtTime(route.departureTime),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                      Text(
                        route.from,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      if (route.durationText.isNotEmpty)
                        Text(
                          route.durationText,
                          style: const TextStyle(fontSize: 11, color: _kSecondary),
                        ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Divider(thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.arrow_forward_rounded, size: 14, color: _kSecondary),
                            ),
                            Expanded(child: Divider(thickness: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (route.arrivalTime != null)
                        Text(
                          _fmtTime(route.arrivalTime!),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                        ),
                      Text(
                        route.to,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Seats & book button
            Row(
              children: [
                Icon(Icons.event_seat_rounded, size: 14, color: _kSecondary),
                const SizedBox(width: 4),
                Text(
                  'Viti ${route.availableSeats}/${route.totalSeats}',
                  style: TextStyle(
                    fontSize: 12,
                    color: route.hasSeats ? _kSecondary : Colors.red,
                    fontWeight: route.hasSeats ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
                if (route.amenities.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      route.amenities.join(' | '),
                      style: const TextStyle(fontSize: 10, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                if (route.hasSeats && onBook != null)
                  Material(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: onBook,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Nunua',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
