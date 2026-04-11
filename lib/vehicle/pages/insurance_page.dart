// lib/vehicle/pages/insurance_page.dart
import 'package:flutter/material.dart';
import '../models/vehicle_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
class VehicleInsurancePage extends StatelessWidget {
  final Vehicle vehicle;
  const VehicleInsurancePage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        surfaceTintColor: Colors.transparent,
        title: const Text('Bima ya Gari',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.shield_rounded,
                    size: 36, color: _kPrimary),
              ),
              const SizedBox(height: 20),
              Text(vehicle.displayName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
              Text(vehicle.plateNumber,
                  style: const TextStyle(
                      fontSize: 16,
                      color: _kSecondary,
                      letterSpacing: 2)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: vehicle.hasInsurance
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
                      : Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vehicle.hasInsurance
                          ? Icons.verified_rounded
                          : Icons.warning_rounded,
                      color: vehicle.hasInsurance
                          ? const Color(0xFF4CAF50)
                          : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      vehicle.hasInsurance
                          ? 'Gari lina bima hai.'
                          : 'Gari hili halina bima.',
                      style:
                          const TextStyle(fontSize: 14, color: _kPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!vehicle.hasInsurance)
                FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Nenda kwenye sehemu ya Bima kupata bima ya gari')),
                    );
                  },
                  style:
                      FilledButton.styleFrom(backgroundColor: _kPrimary),
                  child: const Text('Pata Bima'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
