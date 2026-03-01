import 'package:flutter/material.dart';
import '../../models/story_models.dart';
import '../../services/story_service.dart';
import 'story_viewer_screen.dart';
import '../clips/createstory_screen.dart';

class StoriesScreen extends StatefulWidget {
  final int currentUserId;

  const StoriesScreen({super.key, required this.currentUserId});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final StoryService _storyService = StoryService();
  List<StoryGroup> _storyGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    final result = await _storyService.getStories(currentUserId: widget.currentUserId);
    if (result.success) {
      setState(() {
        _storyGroups = result.groups;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Imeshindwa kupakia hadithi')),
        );
      }
    }
  }

  void _openStoryViewer(StoryGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          storyGroups: _storyGroups,
          initialGroupIndex: _storyGroups.indexOf(group),
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _createStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStoryScreen(userId: widget.currentUserId),
      ),
    ).then((_) => _loadStories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadithi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _createStory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStories,
              child: _storyGroups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Hakuna hadithi',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _createStory,
                            icon: const Icon(Icons.add),
                            label: const Text('Unda Hadithi'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _storyGroups.length,
                      itemBuilder: (context, index) {
                        final group = _storyGroups[index];
                        return _StoryGroupTile(
                          group: group,
                          onTap: () => _openStoryViewer(group),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'stories_fab',
        onPressed: _createStory,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class _StoryGroupTile extends StatelessWidget {
  final StoryGroup group;
  final VoidCallback onTap;

  const _StoryGroupTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnviewed = group.stories.any((s) => s.isViewed != true);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasUnviewed
              ? const LinearGradient(
                  colors: [Colors.purple, Colors.orange, Colors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: hasUnviewed ? null : Border.all(color: Colors.grey[300]!, width: 2),
        ),
        padding: const EdgeInsets.all(3),
        child: CircleAvatar(
          backgroundImage: group.user.avatarUrl.isNotEmpty
              ? NetworkImage(group.user.avatarUrl)
              : null,
          child: group.user.avatarUrl.isEmpty
              ? Text(group.user.firstName[0])
              : null,
        ),
      ),
      title: Text(
        group.user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${group.stories.length} hadithi',
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }
}

class StoriesBar extends StatelessWidget {
  final int currentUserId;
  final List<StoryGroup> storyGroups;
  final VoidCallback onCreateStory;
  final Function(StoryGroup) onViewStory;

  const StoriesBar({
    super.key,
    required this.currentUserId,
    required this.storyGroups,
    required this.onCreateStory,
    required this.onViewStory,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: storyGroups.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AddStoryButton(onTap: onCreateStory);
          }
          final group = storyGroups[index - 1];
          return _StoryAvatar(
            group: group,
            onTap: () => onViewStory(group),
          );
        },
      ),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ongeza',
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final StoryGroup group;
  final VoidCallback onTap;

  const _StoryAvatar({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnviewed = group.stories.any((s) => s.isViewed != true);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? const LinearGradient(
                        colors: [Colors.purple, Colors.orange, Colors.pink],
                      )
                    : null,
                border: hasUnviewed
                    ? null
                    : Border.all(color: Colors.grey[300]!, width: 2),
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                backgroundImage: group.user.avatarUrl.isNotEmpty
                    ? NetworkImage(group.user.avatarUrl)
                    : null,
                child: group.user.avatarUrl.isEmpty
                    ? Text(group.user.firstName[0])
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              group.user.firstName,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
