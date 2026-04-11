import 'package:flutter/material.dart';
import '../models/event_enums.dart';

class EventStatusBadge extends StatelessWidget {
  final EventStatus status;
  const EventStatusBadge({super.key, required this.status});

  Color get _bgColor {
    switch (status) {
      case EventStatus.draft:
        return Colors.grey.shade100;
      case EventStatus.published:
        return Colors.green.shade50;
      case EventStatus.cancelled:
        return Colors.red.shade50;
      case EventStatus.completed:
        return Colors.blue.shade50;
      case EventStatus.postponed:
        return Colors.orange.shade50;
    }
  }

  Color get _textColor {
    switch (status) {
      case EventStatus.draft:
        return Colors.grey.shade700;
      case EventStatus.published:
        return Colors.green.shade700;
      case EventStatus.cancelled:
        return Colors.red.shade700;
      case EventStatus.completed:
        return Colors.blue.shade700;
      case EventStatus.postponed:
        return Colors.orange.shade800;
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
