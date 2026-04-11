// lib/calendar/widgets/event_card.dart
import 'package:flutter/material.dart';
import '../models/calendar_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EventCard({super.key, required this.event, this.onTap, this.onDelete});

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    // time is "HH:mm" or "HH:mm:ss"
    final parts = time.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts[1];
      final amPm = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:$m $amPm';
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = event.source.dotColor;

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Color stripe
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(event.source.icon, size: 20, color: dotColor),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (event.isAllDay)
                          const Text(
                            'Siku nzima',
                            style:
                                TextStyle(fontSize: 12, color: _kSecondary),
                          )
                        else if (event.startTime != null) ...[
                          Icon(Icons.access_time_rounded,
                              size: 12, color: _kSecondary),
                          const SizedBox(width: 3),
                          Text(
                            _formatTime(event.startTime),
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary),
                          ),
                          if (event.endTime != null) ...[
                            const Text(' - ',
                                style: TextStyle(
                                    fontSize: 12, color: _kSecondary)),
                            Text(
                              _formatTime(event.endTime),
                              style: const TextStyle(
                                  fontSize: 12, color: _kSecondary),
                            ),
                          ],
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: dotColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.source.displayName,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: dotColor),
                          ),
                        ),
                      ],
                    ),
                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.notes!,
                        style: const TextStyle(
                            fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (event.repeat != EventRepeat.none)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.repeat_rounded,
                      size: 16, color: _kSecondary),
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: _kSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
