import 'package:flutter/material.dart';
import '../../models/story_models.dart';
import '../../services/story_service.dart';
import '../../widgets/cached_media_image.dart';
import 'create_highlight_screen.dart';

/// Add a story to a highlight: choose existing highlight or create new.
/// Path: Story viewer (own story) → Add to highlight.
class AddToHighlightScreen extends StatefulWidget {
  final int userId;
  final int storyId;

  const AddToHighlightScreen({
    super.key,
    required this.userId,
    required this.storyId,
  });

  @override
  State<AddToHighlightScreen> createState() => _AddToHighlightScreenState();
}

class _AddToHighlightScreenState extends State<AddToHighlightScreen> {
  final StoryService _storyService = StoryService();
  List<StoryHighlight> _highlights = [];
  bool _isLoading = true;
  final Set<int> _addingHighlightIds = {};

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() => _isLoading = true);
    final result = await _storyService.getHighlights(widget.userId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _highlights = result.highlights;
      }
    });
  }

  Future<void> _addToHighlight(StoryHighlight highlight) async {
    if (_addingHighlightIds.contains(highlight.id)) return;
    setState(() => _addingHighlightIds.add(highlight.id));
    final ok = await _storyService.addStoryToHighlight(highlight.id, widget.storyId);
    if (!mounted) return;
    setState(() => _addingHighlightIds.remove(highlight.id));
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hadithi imeongezwa kwenye kiango')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindwa kuongeza. Jaribu tena.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createNewWithThisStory() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => CreateHighlightScreen(
          userId: widget.userId,
          initialStoryIds: [widget.storyId],
        ),
      ),
    ).then((created) {
      if (created == true && mounted) Navigator.pop(context, true);
    });
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
          'Ongeza kwenye Kiango',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chagua kiango au unda kipya',
                      style: TextStyle(
                        fontSize: 14,
                        color: _secondaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF999999)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: _primaryText, size: 28),
                      ),
                      title: const Text(
                        'Undakiango kipya',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                      subtitle: const Text(
                        'Hadithi hii itaongezwa kwenye kiango kipya',
                        style: TextStyle(fontSize: 12, color: _secondaryText),
                      ),
                      onTap: _createNewWithThisStory,
                      minLeadingWidth: 0,
                    ),
                    const SizedBox(height: 16),
                    if (_highlights.isNotEmpty) ...[
                      const Text(
                        'Ongeza kwenye kiango kilichopo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._highlights.map((h) => _HighlightListTile(
                            highlight: h,
                            onTap: () => _addToHighlight(h),
                            isLoading: _addingHighlightIds.contains(h.id),
                          )),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _HighlightListTile extends StatelessWidget {
  final StoryHighlight highlight;
  final VoidCallback onTap;
  final bool isLoading;

  const _HighlightListTile({
    required this.highlight,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF999999)),
                  ),
                  child: ClipOval(
                    child: highlight.coverPath != null &&
                            highlight.coverPath!.isNotEmpty
                        ? CachedMediaImage(
                            imageUrl: highlight.coverUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.auto_stories,
                            color: Colors.grey.shade600,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight.title.isNotEmpty
                            ? highlight.title
                            : 'Hadithi',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${highlight.stories?.length ?? 0} hadithi',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.add_circle_outline, color: Color(0xFF1A1A1A)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
