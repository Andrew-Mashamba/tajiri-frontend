// lib/rita/widgets/application_timeline.dart
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class ApplicationTimeline extends StatelessWidget {
  final int currentStage;
  const ApplicationTimeline({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final stages = [
      _S(Icons.upload_file_rounded, 'Imewasilishwa', 'Submitted'),
      _S(Icons.pending_actions_rounded, 'Inashughulikiwa', 'Processing'),
      _S(Icons.print_rounded, 'Inachapishwa', 'Printing'),
      _S(Icons.check_circle_outline_rounded, 'Tayari', 'Ready'),
      _S(Icons.verified_rounded, 'Imekusanywa', 'Collected'),
    ];

    return Column(
      children: List.generate(stages.length, (i) {
        final active = i <= currentStage;
        final current = i == currentStage;
        final last = i == stages.length - 1;
        final s = stages[i];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 32, child: Column(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: active ? _kPrimary : const Color(0xFFE0E0E0),
                  shape: BoxShape.circle,
                ),
                child: Icon(s.icon, size: 14, color: active ? Colors.white : _kSecondary),
              ),
              if (!last)
                Container(width: 2, height: 24,
                    color: active ? _kPrimary : const Color(0xFFE0E0E0)),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.sw, style: TextStyle(fontSize: 13,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _kPrimary : _kSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(s.en, style: TextStyle(fontSize: 11,
                    color: active ? _kSecondary : const Color(0xFFBDBDBD)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            )),
          ],
        );
      }),
    );
  }
}

class _S {
  final IconData icon;
  final String sw;
  final String en;
  const _S(this.icon, this.sw, this.en);
}
