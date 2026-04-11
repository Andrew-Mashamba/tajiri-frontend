// lib/ofisi_mtaa/widgets/service_tile.dart
import 'package:flutter/material.dart';
import '../models/ofisi_mtaa_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ServiceTile extends StatelessWidget {
  final ServiceCatalog service;
  final VoidCallback? onApply;

  const ServiceTile({super.key, required this.service, this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            service.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _kSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(
                icon: Icons.attach_money_rounded,
                label: service.officialFee > 0
                    ? 'TZS ${service.officialFee.toStringAsFixed(0)}'
                    : 'Bure',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: service.processingTime.isNotEmpty
                    ? service.processingTime
                    : 'N/A',
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Omba', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          if (service.requiredDocs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Nyaraka: ${service.requiredDocs.join(", ")}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _kSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: _kSecondary)),
      ],
    );
  }
}
