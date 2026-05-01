import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_strings_scope.dart';

/// Spec F7 #58 — Customer-side in-person consultation extras.
///
/// Renders clinic intro, parking blob, and live queue position. Host page
/// polls `/api/consultations/{id}/status` and rebuilds with new values.
class InPersonExtrasCard extends StatelessWidget {
  final String? clinicIntro;
  final String? parkingBlob;
  final int? queuePosition;

  const InPersonExtrasCard({
    super.key,
    this.clinicIntro,
    this.parkingBlob,
    this.queuePosition,
  });

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    if ((clinicIntro == null || clinicIntro!.isEmpty) &&
        (parkingBlob == null || parkingBlob!.isEmpty) &&
        queuePosition == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (queuePosition != null && queuePosition! > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      size: 18, color: Color(0xFF1976D2)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSw ? 'Mstari wako' : 'Your queue position',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666)),
                      ),
                      Text(
                        '#$queuePosition',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (clinicIntro != null && clinicIntro!.isNotEmpty) ...[
            Text(
              isSw ? 'Karibu kliniki' : 'Clinic intro',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 6),
            Text(
              clinicIntro!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 12),
          ],
          if (parkingBlob != null && parkingBlob!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.local_parking_rounded,
                    size: 16, color: Color(0xFF666666)),
                const SizedBox(width: 6),
                Text(
                  isSw ? 'Maelekezo ya maegesho' : 'Parking guide',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: isSw ? 'Nakili' : 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: parkingBlob!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(isSw ? 'Imenakiliwa' : 'Copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              parkingBlob!,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
          ],
        ],
      ),
    );
  }
}
