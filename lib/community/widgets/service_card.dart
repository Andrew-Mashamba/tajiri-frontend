// lib/community/widgets/service_card.dart
import 'package:flutter/material.dart';
import '../models/community_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class ServiceCard extends StatelessWidget {
  final LocalService service;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.onCall,
  });

  IconData get _typeIcon {
    switch (service.type) {
      case LocalServiceType.hospital:
        return Icons.local_hospital_rounded;
      case LocalServiceType.police:
        return Icons.local_police_rounded;
      case LocalServiceType.fire:
        return Icons.local_fire_department_rounded;
      case LocalServiceType.school:
        return Icons.school_rounded;
      case LocalServiceType.market:
        return Icons.storefront_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon, color: _kPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
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
                    service.address,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${service.distanceKm!.toStringAsFixed(1)} km mbali',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (service.phone != null)
              GestureDetector(
                onTap: onCall,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_rounded,
                      size: 20, color: _kPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
