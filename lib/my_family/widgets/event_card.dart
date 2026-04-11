// lib/my_family/widgets/event_card.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class EventCard extends StatelessWidget {
  final FamilyEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onDelete,
  });

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = event.isToday;
    final isPast = event.isPast && !isToday;

    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Date column
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isToday
                      ? _kPrimary
                      : isPast
                          ? _kPrimary.withValues(alpha: 0.05)
                          : event.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${event.date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isToday ? Colors.white : _kPrimary,
                      ),
                    ),
                    Text(
                      [
                        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                        'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
                      ][event.date.month - 1],
                      style: TextStyle(
                        fontSize: 10,
                        color: isToday
                            ? Colors.white70
                            : _kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Event info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPast
                            ? _kSecondary
                            : _kPrimary,
                        decoration: isPast
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (event.time != null) ...[
                          Icon(Icons.access_time_rounded,
                              size: 12, color: _kSecondary),
                          const SizedBox(width: 3),
                          Text(
                            event.time!,
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _fmtDate(event.date),
                          style: const TextStyle(
                              fontSize: 11, color: _kSecondary),
                        ),
                      ],
                    ),
                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.notes!,
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (event.isRecurring)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat_rounded,
                              size: 10, color: _kSecondary),
                          SizedBox(width: 2),
                          Text(
                            'Inarudiwa',
                            style: TextStyle(
                                fontSize: 9, color: _kSecondary),
                          ),
                        ],
                      ),
                    ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Leo',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18,
                            color: _kSecondary.withValues(alpha: 0.5)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
