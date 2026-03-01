import 'package:flutter/material.dart';
import '../../models/story_models.dart';

/// View stories inside a single highlight (permanent album).
/// Path: Profile → Story highlight → tap highlight.
class HighlightViewerScreen extends StatefulWidget {
  final StoryHighlight highlight;
  final int currentUserId;

  const HighlightViewerScreen({
    super.key,
    required this.highlight,
    required this.currentUserId,
  });

  @override
  State<HighlightViewerScreen> createState() => _HighlightViewerScreenState();
}

class _HighlightViewerScreenState extends State<HighlightViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;

  final List<Story> _stories = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _stories.addAll(widget.highlight.stories ?? []);
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _next();
    });
    if (_stories.isNotEmpty) _startProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward();
  }

  void _next() {
    if (_currentIndex < _stories.length - 1) {
      setState(() => _currentIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    } else {
      Navigator.pop(context);
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ),
        body: const Center(
          child: Text(
            'Hakuna hadithi katika kiangazio hiki',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final _ = _stories[_currentIndex]; // Story data available for future use
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final w = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < w / 2) {
            _previous();
          } else {
            _next();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _stories.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
                _startProgress();
              },
              itemBuilder: (context, i) {
                return _StoryContent(story: _stories[i]);
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(_stories.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _ProgressBar(
                        progress: _currentIndex > i
                            ? const AlwaysStoppedAnimation(1.0)
                            : _currentIndex == i
                                ? _progressController
                                : const AlwaysStoppedAnimation(0.0),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.highlight.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Animation<double> progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        return Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.circular(2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * progress.value,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StoryContent extends StatelessWidget {
  final Story story;

  const _StoryContent({required this.story});

  @override
  Widget build(BuildContext context) {
    final bgHex = story.backgroundColor;
    final bgColor = bgHex != null && bgHex.isNotEmpty
        ? Color(int.parse(bgHex.replaceFirst('#', '0xFF')))
        : Colors.black;
    return Container(
      color: bgColor,
      child: story.mediaType == 'image' || story.mediaType == 'video'
          ? (story.mediaUrl.isNotEmpty
              ? Image.network(
                  story.mediaUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    );
                  },
                )
              : const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                ))
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  story.caption ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
