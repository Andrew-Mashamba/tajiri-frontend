import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/travel_models.dart';
import '../widgets/mode_icon.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TicketPage extends StatelessWidget {
  final TransportBooking booking;

  const TicketPage({super.key, required this.booking});

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

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green.shade700;
      case BookingStatus.cancelled:
        return Colors.red.shade700;
      case BookingStatus.completed:
        return Colors.grey.shade600;
      case BookingStatus.pending:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final ticketNumber = booking.ticket?.ticketNumber ?? booking.bookingReference;
    final qrData = booking.ticket?.qrData ?? booking.bookingReference;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiketi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'E-Ticket',
              style: TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Header with booking reference
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TAJIRI Safari',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking.bookingReference,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),

              // QR Code
              Padding(
                padding: const EdgeInsets.all(24),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: _kPrimary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: _kPrimary,
                  ),
                ),
              ),

              // Dashed divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(
                    30,
                    (_) => Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),

              // Route info
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Route with mode icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          booking.originCity,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ModeIcon(mode: booking.mode, size: 24, color: _kSecondary),
                        ),
                        Text(
                          booking.destinationCity,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date + Time
                    _detailRow('Tarehe / Date', _formatDate(booking.departure)),
                    _detailRow('Muda / Time', '${_formatTime(booking.departure)} - ${_formatTime(booking.arrival)}'),

                    const Divider(height: 24),

                    // Passengers
                    if (booking.passengers.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Abiria / Passengers',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...booking.passengers.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  p.isLead ? Icons.person_rounded : Icons.person_outline_rounded,
                                  size: 16,
                                  color: _kSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (p.isLead)
                                  const Text(
                                    'Mkuu / Lead',
                                    style: TextStyle(fontSize: 11, color: _kSecondary),
                                  ),
                              ],
                            ),
                          )),
                      const Divider(height: 24),
                    ] else ...[
                      _detailRow('Abiria / Passengers', '${booking.passengerCount}'),
                    ],

                    // Class + Operator
                    if (booking.transportClass != null)
                      _detailRow('Daraja / Class', booking.transportClass!),
                    _detailRow('Mwendeshaji / Operator', booking.operator),

                    // Ticket number
                    _detailRow('Tiketi / Ticket No.', ticketNumber),

                    const SizedBox(height: 12),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        booking.status.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final text = 'TAJIRI Safari Ticket\n'
                    'Ref: ${booking.bookingReference}\n'
                    '${booking.originCity} \u2192 ${booking.destinationCity}\n'
                    'Date: ${_formatDate(booking.departure)}\n'
                    'Time: ${_formatTime(booking.departure)} - ${_formatTime(booking.arrival)}\n'
                    'Operator: ${booking.operator}\n'
                    'Passengers: ${booking.passengerCount}';
                try {
                  await SharePlus.instance.share(ShareParams(text: text));
                } catch (_) {
                  // Share dialog dismissed or platform error — no action needed
                }
              },
              icon: const Icon(Icons.share_rounded, size: 20),
              label: const Text(
                'Shiriki Tiketi / Share Ticket',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
