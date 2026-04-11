// lib/rita/widgets/certificate_card.dart
import 'package:flutter/material.dart';
import '../models/rita_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CertificateCard extends StatelessWidget {
  final CertificateApplication application;
  final VoidCallback? onTap;
  const CertificateCard({super.key, required this.application, this.onTap});

  IconData get _icon {
    switch (application.type) {
      case CertificateType.birth: return Icons.child_care_rounded;
      case CertificateType.death: return Icons.sentiment_very_dissatisfied_rounded;
      case CertificateType.marriage: return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(_icon, size: 22, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.typeLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (application.holderName != null)
                  Text(application.holderName!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('#${application.trackingNumber}',
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
              ],
            )),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
          ]),
        ),
      ),
    );
  }
}
