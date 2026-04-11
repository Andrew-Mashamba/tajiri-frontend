// lib/driving_licence/widgets/licence_card.dart
import 'package:flutter/material.dart';
import '../models/driving_licence_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);

class LicenceCardWidget extends StatelessWidget {
  final DrivingLicence licence;
  const LicenceCardWidget({super.key, required this.licence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text('DRIVING LICENCE', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: licence.isExpired ? Colors.red : licence.isExpiring ? Colors.orange : const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(4)),
            child: Text(licence.status.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(licence.licenceNumber,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: licence.classes.map((c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
          child: Text(c.code, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        )).toList()),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Exp: ${licence.expiryDate.day}/${licence.expiryDate.month}/${licence.expiryDate.year}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text('${licence.points} points', style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ]),
    );
  }
}
