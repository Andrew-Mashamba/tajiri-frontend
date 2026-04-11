// lib/land_office/widgets/plot_card.dart
import 'package:flutter/material.dart';
import '../models/land_office_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PlotCard extends StatelessWidget {
  final Plot plot;
  final VoidCallback? onTap;
  const PlotCard({super.key, required this.plot, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_on_rounded, size: 22, color: _kPrimary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('#${plot.plotNumber}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
            if (plot.registeredOwner != null)
              Text(plot.registeredOwner!, style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            if (plot.location != null)
              Text(plot.location!, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Text(plot.titleType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary))),
        ]))));
  }
}
