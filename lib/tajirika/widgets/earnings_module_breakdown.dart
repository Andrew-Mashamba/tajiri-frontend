import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';

class EarningsModuleBreakdown extends StatelessWidget {
  final Map<String, double> byModule;

  const EarningsModuleBreakdown({super.key, required this.byModule});

  static const Map<String, String> _moduleLabelsEn = {
    'mafundi': 'Trades',
    'hair_nails': 'Hair & Nails',
    'skincare': 'Skin Care',
    'lawyer': 'Legal',
    'housing': 'Housing',
    'doctor': 'Medical',
    'service_garage': 'Auto Garage',
    'fitness': 'Fitness',
    'food': 'Food',
    'events': 'Events',
    'travel': 'Travel',
    'business': 'Business',
  };

  static const Map<String, String> _moduleLabelsSw = {
    'mafundi': 'Mafundi',
    'hair_nails': 'Nywele & Kucha',
    'skincare': 'Ngozi',
    'lawyer': 'Wakili',
    'housing': 'Nyumba',
    'doctor': 'Daktari',
    'service_garage': 'Karakana',
    'fitness': 'Mazoezi',
    'food': 'Chakula',
    'events': 'Hafla',
    'travel': 'Safari',
    'business': 'Biashara',
  };

  static const Map<String, IconData> _moduleIcons = {
    'mafundi': Icons.construction_rounded,
    'hair_nails': Icons.content_cut_rounded,
    'skincare': Icons.face_retouching_natural_rounded,
    'lawyer': Icons.gavel_rounded,
    'housing': Icons.home_work_rounded,
    'doctor': Icons.medical_services_rounded,
    'service_garage': Icons.car_repair_rounded,
    'fitness': Icons.fitness_center_rounded,
    'food': Icons.restaurant_rounded,
    'events': Icons.event_rounded,
    'travel': Icons.flight_rounded,
    'business': Icons.business_center_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (byModule.isEmpty) return const SizedBox.shrink();

    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final labels = isSwahili ? _moduleLabelsSw : _moduleLabelsEn;
    final total = byModule.values.fold(0.0, (sum, v) => sum + v);
    final sorted = byModule.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.map((entry) {
        final fraction = total > 0 ? entry.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                _moduleIcons[entry.key] ?? Icons.work_rounded,
                size: 18,
                color: const Color(0xFF666666),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  labels[entry.key] ?? entry.key,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF1A1A1A)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  'TZS ${entry.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
