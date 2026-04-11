// lib/my_family/widgets/health_record_card.dart
import 'package:flutter/material.dart';
import '../models/my_family_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class HealthRecordCard extends StatelessWidget {
  final FamilyHealthRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const HealthRecordCard({
    super.key,
    required this.record,
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
              // Type icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: record.type.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  record.type.icon,
                  size: 20,
                  color: record.type.color,
                ),
              ),
              const SizedBox(width: 12),
              // Record info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: record.type.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            record.type.displayName,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: record.type.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.person_outline_rounded,
                            size: 12, color: _kSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            record.memberName,
                            style: const TextStyle(
                                fontSize: 11, color: _kSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (record.details != null &&
                        record.details!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        record.details!,
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Date and delete
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtDate(record.date),
                    style: const TextStyle(fontSize: 10, color: _kSecondary),
                  ),
                  if (onDelete != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: _kSecondary.withValues(alpha: 0.5),
                        ),
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
