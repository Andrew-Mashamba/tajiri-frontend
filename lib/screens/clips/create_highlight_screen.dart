import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../models/story_models.dart';
import '../../services/story_service.dart';
import '../../widgets/cached_media_image.dart';

/// Create a new story highlight: title + select stories from user's stories.
/// Path: Profile → Story highlight → Add (New). Optional [initialStoryIds] when adding from story viewer.
class CreateHighlightScreen extends StatefulWidget {
  final int userId;
  final List<int>? initialStoryIds;

  const CreateHighlightScreen({
    super.key,
    required this.userId,
    this.initialStoryIds,
  });

  @override
  State<CreateHighlightScreen> createState() => _CreateHighlightScreenState();
}

class _CreateHighlightScreenState extends State<CreateHighlightScreen> {
  final StoryService _storyService = StoryService();
  final TextEditingController _titleController = TextEditingController();

  List<Story> _userStories = [];
  final Set<int> _selectedIds = {};
  bool _isLoadingStories = true;
  bool _isCreating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserStories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStories() async {
    setState(() {
      _isLoadingStories = true;
      _error = null;
    });
    final result = await _storyService.getUserStories(widget.userId);
    if (!mounted) return;
    setState(() {
      _isLoadingStories = false;
      if (result.success) {
        _userStories = result.stories;
        if (widget.initialStoryIds != null) {
          _selectedIds.addAll(widget.initialStoryIds!);
        }
      } else {
        _error = result.message ?? 'Imeshindwa kupakia hadithi';
      }
    });
  }

  Future<void> _createHighlight() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza jina la kiangazio')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chagua angalau hadithi moja')),
      );
      return;
    }

    setState(() => _isCreating = true);
    final result = await _storyService.createHighlight(
      userId: widget.userId,
      title: title,
      storyIds: _selectedIds.toList(),
    );
    if (!mounted) return;
    setState(() => _isCreating = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiango kimeundwa')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Imeshindwa kuunda kiango'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Undakiango Kipya',
          style: TextStyle(
            color: _primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: _primaryText),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      ),
      body: SafeArea(
        child: _isLoadingStories
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Jina la kiango',
                            hintText: 'Mfano: Safari, Sherehe',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Chagua hadithi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_userStories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.auto_stories_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Hakuna hadithi za kuchagua. Unda hadithi kwanza.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _secondaryText,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: _userStories.length,
                            itemBuilder: (context, index) {
                              final story = _userStories[index];
                              final selected = _selectedIds.contains(story.id);
                              return _StoryThumbTile(
                                story: story,
                                selected: selected,
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedIds.remove(story.id);
                                    } else {
                                      _selectedIds.add(story.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed:
                                _isCreating ? null : _createHighlight,
                            child: _isCreating
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Undakiango'),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: _secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loadUserStories,
                child: const Text('Jaribu tena'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _thumbUrl(Story story) {
  if (story.thumbnailPath != null && story.thumbnailPath!.isNotEmpty) {
    return '${ApiConfig.storageUrl}/${story.thumbnailPath}';
  }
  return story.mediaUrl;
}

class _StoryThumbTile extends StatelessWidget {
  final Story story;
  final bool selected;
  final VoidCallback onTap;

  const _StoryThumbTile({
    required this.story,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _thumbUrl(story).isNotEmpty
                  ? CachedMediaImage(
                      imageUrl: _thumbUrl(story),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFE0E0E0),
                      child: Icon(
                        Icons.auto_stories,
                        color: Colors.grey.shade600,
                      ),
                    ),
            ),
            if (selected)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
