import 'package:flutter/material.dart';

/// Brief celebration overlay shown between chapters.
/// Fades in over 400ms, auto-dismisses after 1.5s or on tap.
class ChapterCelebration extends StatefulWidget {
  /// Completed chapter index (0-3).
  final int completedChapter;

  /// Called when celebration dismisses (auto or tap).
  final VoidCallback onDismiss;

  static const List<String> _chapterNames = [
    'Kufahamiana',
    'Mahali',
    'Masomo',
    'Maisha',
  ];

  const ChapterCelebration({
    super.key,
    required this.completedChapter,
    required this.onDismiss,
  });

  @override
  State<ChapterCelebration> createState() => _ChapterCelebrationState();
}

class _ChapterCelebrationState extends State<ChapterCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _message {
    final name = ChapterCelebration._chapterNames[widget.completedChapter];
    final next = widget.completedChapter + 1;
    if (next < ChapterCelebration._chapterNames.length) {
      final nextName = ChapterCelebration._chapterNames[next];
      return '$name ✓ — Umefanya vizuri!\nTwende $nextName...';
    }
    return '$name ✓ — Umefanya vizuri!';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: const Color(0xFFFAFAFA),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
