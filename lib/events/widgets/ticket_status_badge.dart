import 'package:flutter/material.dart';
import '../models/event_enums.dart';

class TicketStatusBadge extends StatelessWidget {
  final TicketStatus status;
  const TicketStatusBadge({super.key, required this.status});

  Color get _bgColor {
    switch (status) {
      case TicketStatus.active:
        return Colors.green.shade50;
      case TicketStatus.used:
        return Colors.blue.shade50;
      case TicketStatus.cancelled:
        return Colors.red.shade50;
      case TicketStatus.transferred:
        return Colors.orange.shade50;
      case TicketStatus.expired:
        return Colors.grey.shade100;
      case TicketStatus.refunded:
        return Colors.purple.shade50;
    }
  }

  Color get _textColor {
    switch (status) {
      case TicketStatus.active:
        return Colors.green.shade700;
      case TicketStatus.used:
        return Colors.blue.shade700;
      case TicketStatus.cancelled:
        return Colors.red.shade700;
      case TicketStatus.transferred:
        return Colors.orange.shade800;
      case TicketStatus.expired:
        return Colors.grey.shade600;
      case TicketStatus.refunded:
        return Colors.purple.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}
