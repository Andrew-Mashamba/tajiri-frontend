import 'package:flutter/material.dart';
import '../../models/story_models.dart';
import '../../services/story_service.dart';
import '../../widgets/cached_media_image.dart';

/// Story 51: View Stories — Home → Feed → Stories row → Tap to view.
/// Tap right = next, left = previous. Auto-advance ~5s. Progress bar at top.
/// Swipe down to exit. View count for own stories. 24h expiry.
class StoryViewerScreen extends StatefulWidget {
  final List<StoryGroup> storyGroups;
  final int initialGroupIndex;
  final int currentUserId;

  const StoryViewerScreen({
    super.key,
    required this.storyGroups,
    required this.initialGroupIndex,
    required this.currentUserId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  late PageController _pageController;
  late AnimationController _progressController;

  int _currentGroupIndex = 0;
  int _currentStoryIndex = 0;
  double _dragOffset = 0;
  bool _programmaticPageChange = false;

  static const Duration _defaultStoryDuration = Duration(seconds: 5);
  static const double _minDragToExit = 80;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _pageController = PageController(initialPage: _currentGroupIndex);
    final duration = _defaultStoryDuration;
    _progressController = AnimationController(vsync: this, duration: duration);

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startProgress();
    _markAsViewed();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Duration _durationForStory(Story? story) {
    if (story == null) return _defaultStoryDuration;
    final secs = story.duration;
    if (secs > 0) return Duration(seconds: secs);
    return _defaultStoryDuration;
  }

  void _startProgress() {
    final story = _currentStory;
    final duration = _durationForStory(story);
    _progressController.duration = duration;
    _progressController.reset();
    _progressController.forward();
  }

  void _markAsViewed() {
    final story = _currentStory;
    if (story != null) {
      _storyService.viewStory(story.id, widget.currentUserId);
    }
  }

  Story? get _currentStory {
    if (_currentGroupIndex >= widget.storyGroups.length) return null;
    final group = widget.storyGroups[_currentGroupIndex];
    if (_currentStoryIndex < group.stories.length) {
      return group.stories[_currentStoryIndex];
    }
    return null;
  }

  void _nextStory() {
    final group = widget.storyGroups[_currentGroupIndex];
    if (_currentStoryIndex < group.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startProgress();
      _markAsViewed();
    } else {
      _nextGroup();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startProgress();
    } else {
      _previousGroup();
    }
  }

  void _nextGroup() {
    if (_currentGroupIndex < widget.storyGroups.length - 1) {
      _programmaticPageChange = true;
      setState(() {
        _currentGroupIndex++;
        _currentStoryIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
      _markAsViewed();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousGroup() {
    if (_currentGroupIndex > 0) {
      _programmaticPageChange = true;
      setState(() {
        _currentGroupIndex--;
        final group = widget.storyGroups[_currentGroupIndex];
        _currentStoryIndex = group.stories.length - 1;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentGroupIndex = index;
      if (!_programmaticPageChange) {
        _currentStoryIndex = 0;
      }
      _programmaticPageChange = false;
    });
    _startProgress();
    _markAsViewed();
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < screenWidth / 3) {
      _previousStory();
    } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
      _nextStory();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _progressController.stop();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _progressController.forward();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      _dragOffset = _dragOffset.clamp(0.0, double.infinity);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_dragOffset >= _minDragToExit) {
      Navigator.pop(context);
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  void _showReactionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ReactionSheet(
        onReact: (emoji) {
          final story = _currentStory;
          if (story != null) {
            _storyService.reactToStory(story.id, widget.currentUserId, emoji);
            Navigator.pop(context);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Umeitikia hadithi')),
              );
            }
          }
        },
        onReply: () {
          Navigator.pop(context);
          _showReplyDialog();
        },
      ),
    );
  }

  void _showReplyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jibu Hadithi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Andika jibu...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () {
              final story = _currentStory;
              if (story != null && controller.text.isNotEmpty) {
                _storyService.replyToStory(
                  story.id,
                  widget.currentUserId,
                  controller.text,
                );
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Jibu limetumwa')),
                  );
                }
              }
            },
            child: const Text('Tuma'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Transform.translate(
          offset: Offset(0, _dragOffset * 0.3),
          child: GestureDetector(
            onTapDown: _onTapDown,
            onLongPressStart: _onLongPressStart,
            onLongPressEnd: _onLongPressEnd,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.storyGroups.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, groupIndex) {
                final group = widget.storyGroups[groupIndex];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _StoryContent(
                      story: groupIndex == _currentGroupIndex
                          ? _currentStory
                          : group.stories.isNotEmpty
                              ? group.stories.first
                              : null,
                    ),
                    _buildProgressBars(group, groupIndex),
                    _buildHeader(group, groupIndex),
                    if (groupIndex == _currentGroupIndex) _buildBottomActions(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars(StoryGroup group, int groupIndex) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(group.stories.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ProgressBar(
                progress: groupIndex == _currentGroupIndex
                    ? (index < _currentStoryIndex
                        ? const AlwaysStoppedAnimation(1.0)
                        : (index == _currentStoryIndex
                            ? _progressController
                            : const AlwaysStoppedAnimation(0.0)))
                    : const AlwaysStoppedAnimation(0.0),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(StoryGroup group, int groupIndex) {
    final story = groupIndex == _currentGroupIndex ? _currentStory : null;
    final isOwn = group.user.id == widget.currentUserId;
    final viewsCount = story?.viewsCount ?? 0;

    return Positioned(
      top: 24,
      left: 16,
      right: 16,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF1A1A1A),
            backgroundImage: group.user.avatarUrl.isNotEmpty
                ? NetworkImage(group.user.avatarUrl)
                : null,
            child: group.user.avatarUrl.isEmpty
                ? Text(
                    group.user.firstName.isNotEmpty
                        ? group.user.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (story != null)
                  Text(
                    _formatTime(story.createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                if (isOwn && viewsCount > 0)
                  Text(
                    '$viewsCount ${viewsCount == 1 ? 'mtazamaji' : 'watazamaji'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          SemanticButton(
            minSize: 48,
            icon: Icons.close,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final story = _currentStory;
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tuma ujumbe...',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onSubmitted: (value) {
                if (story != null && value.isNotEmpty) {
                  _storyService.replyToStory(
                    story.id,
                    widget.currentUserId,
                    value,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Jibu limetumwa')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          SemanticButton(
            minSize: 48,
            icon: Icons.favorite_border,
            onPressed: _showReactionSheet,
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dakika';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} saa';
    }
    return '${diff.inDays} siku';
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
  final Story? story;

  const _StoryContent({required this.story});

  @override
  Widget build(BuildContext context) {
    if (story == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final s = story!;
    final hex = s.backgroundColor != null
        ? int.tryParse(s.backgroundColor!.replaceFirst('#', '0xFF'))
        : null;
    final backgroundColor = hex != null ? Color(hex) : Colors.black;

    return Container(
      color: backgroundColor,
      child: s.mediaType == 'image' || s.mediaType == 'video'
          ? (s.mediaUrl.isNotEmpty
              ? CachedMediaImage(
                  imageUrl: s.mediaUrl,
                  fit: BoxFit.contain,
                  backgroundColor: Colors.black,
                  errorWidget: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
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
                  s.caption ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
    );
  }
}

class _ReactionSheet extends StatelessWidget {
  final void Function(String) onReact;
  final VoidCallback onReply;

  const _ReactionSheet({
    required this.onReact,
    required this.onReply,
  });

  static const List<String> _reactions = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
    '👍',
    '🔥',
    '💯',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactions.map((emoji) {
                return GestureDetector(
                  onTap: () => onReact(emoji),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Jibu hadithi'),
              onTap: onReply,
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimum 48dp touch target per DESIGN.md
class SemanticButton extends StatelessWidget {
  final double minSize;
  final IconData icon;
  final VoidCallback onPressed;

  const SemanticButton({
    super.key,
    this.minSize = 48,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(minSize / 2),
        child: SizedBox(
          width: minSize,
          height: minSize,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
