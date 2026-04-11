import 'package:flutter/material.dart';
import '../models/event_ticket.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class TicketCard extends StatelessWidget {
  final EventTicket ticket;
  final VoidCallback? onTap;
  const TicketCard({super.key, required this.ticket, this.onTap});

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: true);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // QR icon placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_rounded, size: 28, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.event?.name ?? 'Tiketi #${ticket.ticketNumber}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.event != null
                        ? strings.formatDateShort(ticket.event!.startDate)
                        : strings.formatDateShort(ticket.purchaseDate),
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#${ticket.ticketNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ticket.status == TicketStatus.active
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.status.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ticket.status == TicketStatus.active
                      ? Colors.green.shade700
                      : _kSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
