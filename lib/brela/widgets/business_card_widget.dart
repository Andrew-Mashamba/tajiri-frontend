// lib/brela/widgets/business_card_widget.dart
import 'package:flutter/material.dart';
import '../models/brela_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class BusinessCardWidget extends StatelessWidget {
  final Business business;
  final VoidCallback? onTap;
  const BusinessCardWidget({super.key, required this.business, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.store_rounded, size: 22, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(business.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(business.typeLabel, style: const TextStyle(fontSize: 12, color: _kSecondary)),
              if (business.registrationNumber != null)
                Text(business.registrationNumber!, style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: business.isActive ? const Color(0xFF4CAF50).withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
              child: Text(business.isActive ? 'Active' : business.status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: business.isActive ? const Color(0xFF4CAF50) : Colors.red)),
            ),
          ]),
        ),
      ),
    );
  }
}
