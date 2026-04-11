// lib/brela/widgets/name_availability.dart
import 'package:flutter/material.dart';
import '../models/brela_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NameAvailabilityWidget extends StatelessWidget {
  final NameResult result;
  final VoidCallback? onReserve;
  const NameAvailabilityWidget({super.key, required this.result, this.onReserve});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(result.available ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 22, color: result.available ? const Color(0xFF4CAF50) : Colors.red),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(result.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(result.available ? 'Linapatikana' : 'Hailipatikani',
              style: TextStyle(fontSize: 11,
                  color: result.available ? const Color(0xFF4CAF50) : Colors.red)),
        ])),
        if (result.available && onReserve != null)
          TextButton(onPressed: onReserve,
              child: const Text('Hifadhi', style: TextStyle(color: _kPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
