import 'package:flutter/material.dart';
import '../../models/story_models.dart';
import '../../services/story_service.dart';
import '../../widgets/cached_media_image.dart';
import 'highlight_viewer_screen.dart';
import 'create_highlight_screen.dart';

/// Story Highlights screen: permanent highlight albums on profile.
/// Path: Profile → Story highlight. Own profile can add new highlights.
class StoryHighlightsScreen extends StatefulWidget {
  final int userId;
  final int currentUserId;

  const StoryHighlightsScreen({
    super.key,
    required this.userId,
    required this.currentUserId,
  });

  @override
  State<StoryHighlightsScreen> createState() => _StoryHighlightsScreenState();
}

class _StoryHighlightsScreenState extends State<StoryHighlightsScreen> {
  final StoryService _storyService = StoryService();
  List<StoryHighlight> _highlights = [];
  bool _isLoading = true;
  String? _error;

  bool get _isOwnProfile => widget.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _storyService.getHighlights(widget.userId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _highlights = result.highlights;
      } else {
        _error = result.message ?? 'Imeshindwa kupakia viangazio';
      }
    });
  }

  void _openHighlight(StoryHighlight highlight) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => HighlightViewerScreen(
          highlight: highlight,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  void _createNewHighlight() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => CreateHighlightScreen(
          userId: widget.currentUserId,
        ),
      ),
    ).then((created) {
      if (created == true && mounted) _loadHighlights();
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
          'Viango vya Hadithi',
          style: TextStyle(
            color: _primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryText),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
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
                  onPressed: _loadHighlights,
                  child: const Text('Jaribu tena'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHighlights,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isOwnProfile
                  ? 'Orodha ya viango vya hadithi. Bonyeza "Ongeza" kuunda kipya.'
                  : 'Viango vya hadithi',
              style: const TextStyle(
                fontSize: 14,
                color: _secondaryText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                if (_isOwnProfile) _buildNewHighlightTile(),
                ..._highlights.map((h) => _buildHighlightTile(h)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// New highlight tile (min 48dp touch target per DESIGN.md)
  Widget _buildNewHighlightTile() {
    return _HighlightTile(
      size: 88,
      onTap: _createNewHighlight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF999999), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 40, color: _primaryText),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 88,
            child: Text(
              'Ongeza',
              style: const TextStyle(
                fontSize: 12,
                color: _secondaryText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightTile(StoryHighlight highlight) {
    final hasStories = highlight.stories != null && highlight.stories!.isNotEmpty;
    return _HighlightTile(
      size: 88,
      onTap: hasStories ? () => _openHighlight(highlight) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF999999), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: highlight.coverPath != null && highlight.coverPath!.isNotEmpty
                  ? CachedMediaImage(
                      imageUrl: highlight.coverUrl,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: const Color(0xFFE0E0E0),
                      child: Icon(
                        Icons.auto_stories,
                        size: 36,
                        color: Colors.grey.shade600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 88,
            child: Text(
              highlight.title.isNotEmpty ? highlight.title : 'Hadithi',
              style: const TextStyle(
                fontSize: 12,
                color: _primaryText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final Widget child;

  const _HighlightTile({
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: size,
          child: child,
        ),
      ),
    );
  }
}
