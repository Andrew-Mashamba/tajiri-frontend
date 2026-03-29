import 'package:flutter/material.dart';

/// 4-bar chapter progress indicator for onboarding.
/// Shows current chapter name and animated fill progress.
class ChapterProgressBar extends StatelessWidget {
  /// Current chapter index (0-3).
  final int currentChapter;

  /// Progress within current chapter (0.0 to 1.0).
  final double chapterProgress;

  /// Chapter names displayed below the bars.
  static const List<String> chapterNames = [
    'KUFAHAMIANA',
    'MAHALI',
    'MASOMO',
    'MAISHA',
  ];

  const ChapterProgressBar({
    super.key,
    required this.currentChapter,
    required this.chapterProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final double fill;
            if (index < currentChapter) {
              fill = 1.0;
            } else if (index == currentChapter) {
              fill = chapterProgress;
            } else {
              fill = 0.0;
            }
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                child: _AnimatedBar(fill: fill),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          currentChapter < chapterNames.length
              ? chapterNames[currentChapter]
              : '',
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final double fill;

  const _AnimatedBar({required this.fill});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: constraints.maxWidth * fill.clamp(0.0, 1.0),
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
