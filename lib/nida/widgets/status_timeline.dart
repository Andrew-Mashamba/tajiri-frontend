// lib/nida/widgets/status_timeline.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class StatusTimeline extends StatelessWidget {
  final int currentStage;
  const StatusTimeline({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final stages = [
      _Stage(icon: Icons.app_registration_rounded, labelSw: 'Umesajiliwa', labelEn: 'Registered'),
      _Stage(icon: Icons.fingerprint_rounded, labelSw: 'Biometrics', labelEn: 'Biometrics Captured'),
      _Stage(icon: Icons.print_rounded, labelSw: 'Inachapishwa', labelEn: 'Card Printing'),
      _Stage(icon: Icons.location_on_rounded, labelSw: 'Ofisini', labelEn: 'At Office'),
      _Stage(icon: Icons.check_circle_rounded, labelSw: 'Imekusanywa', labelEn: 'Collected'),
    ];

    return Column(
      children: List.generate(stages.length, (i) {
        final active = i <= currentStage;
        final isCurrent = i == currentStage;
        final isLast = i == stages.length - 1;
        final s = stages[i];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: active ? _kPrimary : const Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: _kPrimary, width: 2)
                          : null,
                    ),
                    child: Icon(s.icon, size: 14,
                        color: active ? Colors.white : _kSecondary),
                  ),
                  if (!isLast)
                    Container(
                      width: 2, height: 28,
                      color: active ? _kPrimary : const Color(0xFFE0E0E0),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.labelSw,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: active ? _kPrimary : _kSecondary,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(s.labelEn,
                        style: TextStyle(fontSize: 11,
                            color: active ? _kSecondary : const Color(0xFFBDBDBD)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            if (active && i < currentStage)
              const Icon(Icons.check_rounded, size: 16, color: Color(0xFF4CAF50)),
          ],
        );
      }),
    );
  }
}

class _Stage {
  final IconData icon;
  final String labelSw;
  final String labelEn;
  const _Stage({required this.icon, required this.labelSw, required this.labelEn});
}
