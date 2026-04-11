import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import '../widgets/mode_icon.dart';
import 'ticket_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BookingConfirmationPage extends StatelessWidget {
  final TransportBooking booking;

  const BookingConfirmationPage({super.key, required this.booking});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade50,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Safari Imebukiwa!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Trip Booked!',
                style: TextStyle(fontSize: 14, color: _kSecondary),
              ),
              const SizedBox(height: 24),

              // Booking reference
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Nambari ya Buking / Booking Number',
                      style: TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.bookingReference,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Booking Reference',
                      style: TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Route summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    ModeIcon(mode: booking.mode, size: 24, color: _kPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${booking.originCity} \u2192 ${booking.destinationCity}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(booking.departure)} \u2022 ${_formatTime(booking.departure)}',
                            style: const TextStyle(fontSize: 13, color: _kSecondary),
                          ),
                          Text(
                            '${booking.operator} \u2022 ${booking.passengerCount} Abiria / Passengers',
                            style: const TextStyle(fontSize: 12, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // View ticket button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketPage(booking: booking),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tazama Tiketi / View Ticket',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Back to home button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Rudi Nyumbani / Back to Home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
