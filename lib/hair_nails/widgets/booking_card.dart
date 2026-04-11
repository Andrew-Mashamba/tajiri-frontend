// lib/hair_nails/widgets/booking_card.dart
import 'package:flutter/material.dart';
import '../models/hair_nails_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;

  const BookingCard({super.key, required this.booking, this.onTap, this.onCancel, this.onRate});

  String _fmtPrice(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _fmtDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salon name + status
              Row(
                children: [
                  Expanded(
                    child: Text(booking.salonName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: booking.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(booking.status.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: booking.status.color)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Service
              Text(booking.serviceName, style: const TextStyle(fontSize: 13, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),

              // Date + price
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 13, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(_fmtDate(booking.dateTime), style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  const Spacer(),
                  Text('TZS ${_fmtPrice(booking.totalAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                ],
              ),

              // Payment status
              if (booking.paymentStatus != PaymentStatus.paid) ...[
                const SizedBox(height: 4),
                Text('Malipo: ${booking.paymentStatus.displayName}', style: TextStyle(fontSize: 11, color: booking.paymentStatus == PaymentStatus.unpaid ? Colors.orange : _kSecondary)),
              ],

              // Actions
              if (booking.isUpcoming && onCancel != null || booking.status == BookingStatus.completed && onRate != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (booking.isUpcoming && onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 12)),
                        child: const Text('Futa', style: TextStyle(fontSize: 12)),
                      ),
                    if (booking.status == BookingStatus.completed && onRate != null)
                      TextButton(
                        onPressed: onRate,
                        style: TextButton.styleFrom(foregroundColor: _kPrimary, padding: const EdgeInsets.symmetric(horizontal: 12)),
                        child: const Text('Toa Tathmini', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
