import 'package:flutter/material.dart';
import '../../models/story_models.dart';
import '../../services/story_service.dart';
import '../clips/add_to_highlight_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _pageController = PageController(initialPage: _currentGroupIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

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

  void _startProgress() {
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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _previousGroup() {
    if (_currentGroupIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentGroupIndex = index;
      _currentStoryIndex = 0;
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

  void _navigateToSubscribe(StoryGroup group) {
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: {'userId': group.user.id},
    );
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _progressController.stop();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _progressController.forward();
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Umeitikia hadithi')),
            );
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
                    story.id, widget.currentUserId, controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jibu limetumwa')),
                );
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
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.storyGroups.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, groupIndex) {
            final group = widget.storyGroups[groupIndex];
            return Stack(
              fit: StackFit.expand,
              children: [
                // Story content
                _StoryContent(
                  story: groupIndex == _currentGroupIndex
                      ? _currentStory
                      : group.stories.first,
                  currentUserId: widget.currentUserId,
                  onSubscribe: () => _navigateToSubscribe(group),
                ),

                // Progress indicators
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
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
                ),

                // User info
                Positioned(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: group.user.avatarUrl.isNotEmpty
                            ? NetworkImage(group.user.avatarUrl)
                            : null,
                        child: group.user.avatarUrl.isEmpty
                            ? Text(group.user.firstName[0])
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
                              ),
                            ),
                            if (_currentStory != null)
                              Text(
                                _formatTime(_currentStory!.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (group.user.id == widget.currentUserId && _currentStory != null)
                        IconButton(
                          icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
                          tooltip: 'Ongeza kwenye kiango',
                          onPressed: () {
                            Navigator.push<bool>(
                              context,
                              MaterialPageRoute<bool>(
                                builder: (context) => AddToHighlightScreen(
                                  userId: widget.currentUserId,
                                  storyId: _currentStory!.id,
                                ),
                              ),
                            );
                          },
                          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                      ),
                    ],
                  ),
                ),

                // Bottom actions
                Positioned(
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
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (value) {
                            final story = _currentStory;
                            if (story != null && value.isNotEmpty) {
                              _storyService.replyToStory(
                                  story.id, widget.currentUserId, value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.favorite_border,
                            color: Colors.white),
                        onPressed: _showReactionSheet,
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}d';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}s';
    } else {
      return '${diff.inDays}s';
    }
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
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoryContent extends StatelessWidget {
  final Story? story;
  final int currentUserId;
  final VoidCallback? onSubscribe;

  const _StoryContent({
    required this.story,
    required this.currentUserId,
    this.onSubscribe,
  });

  bool get _isContentLocked {
    if (story == null) return false;
    // Own stories are never locked
    if (story!.userId == currentUserId) return false;
    // Only lock if privacy is subscribers and user is not subscribed
    return story!.privacy == 'subscribers' && !story!.isSubscribedToAuthor;
  }

  @override
  Widget build(BuildContext context) {
    if (story == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final storyContent = Container(
      color: story!.backgroundColor != null
          ? Color(int.parse(story!.backgroundColor!.replaceFirst('#', '0xFF')))
          : Colors.black,
      child: story!.mediaType == 'image' || story!.mediaType == 'video'
          ? Image.network(
              story!.mediaUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                );
              },
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  story!.caption ?? '',
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

    if (_isContentLocked) {
      return Stack(
        fit: StackFit.expand,
        children: [
          storyContent,
          _buildSubscriberOverlay(),
        ],
      );
    }

    return storyContent;
  }

  Widget _buildSubscriberOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  size: 56,
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Kwa Wasajili Pekee',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jisajili kwa ${story!.user?.fullName ?? 'msanii huyu'}\nkuona hadithi hii',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onSubscribe,
                icon: const Icon(Icons.star, size: 22),
                label: const Text(
                  'Jisajili Sasa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionSheet extends StatelessWidget {
  final Function(String) onReact;
  final VoidCallback onReply;

  const _ReactionSheet({required this.onReact, required this.onReply});

  static const _reactions = ['❤️', '😂', '😮', '😢', '😡', '👍', '🔥', '💯'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactions.map((emoji) {
              return GestureDetector(
                onTap: () => onReact(emoji),
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
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
    );
  }
}
