// lib/my_cars/widgets/service_record_card.dart
import 'package:flutter/material.dart';
import '../models/my_cars_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ServiceRecordCard extends StatelessWidget {
  final CarServiceRecord record;
  final bool isSwahili;
  final VoidCallback? onTap;

  const ServiceRecordCard({
    super.key,
    required this.record,
    this.isSwahili = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_iconFor(record.serviceType),
                  size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.serviceType,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${record.date.day}/${record.date.month}/${record.date.year}'
                      '${record.garageName != null ? ' | ${record.garageName}' : ''}',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (record.description != null) ...[
                      const SizedBox(height: 2),
                      Text(record.description!,
                          style:
                              const TextStyle(fontSize: 11, color: _kSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('TZS ${record.cost.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
              const SizedBox(height: 2),
              Text('${record.mileageAtService.toStringAsFixed(0)} km',
                  style: const TextStyle(fontSize: 10, color: _kSecondary)),
            ]),
          ]),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'oil_change':
      case 'oil change':
        return Icons.oil_barrel_rounded;
      case 'tire':
      case 'tires':
        return Icons.tire_repair_rounded;
      case 'brake':
      case 'brakes':
        return Icons.speed_rounded;
      case 'inspection':
        return Icons.search_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}
