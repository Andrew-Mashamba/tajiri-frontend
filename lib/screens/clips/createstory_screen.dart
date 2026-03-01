// Story 50: Create Story — 24-hour story with photo/video (up to 60s), stickers, filters.
// Navigation: Home → Feed/Profile → Stories ring → Create Story.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../services/story_service.dart';

/// Named filter options sent to backend as filter field.
const List<String> _filterIds = [
  'none',
  'vivid',
  'warm',
  'cool',
  'bw',
  'sepia',
];

/// Sticker emoji options user can add to the story.
const List<String> _stickerEmojis = [
  '❤️',
  '😂',
  '🔥',
  '👍',
  '⭐',
  '🙏',
  '💯',
  '✨',
];

class CreateStoryScreen extends StatefulWidget {
  final int userId;

  const CreateStoryScreen({super.key, required this.userId});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final StoryService _storyService = StoryService();
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedMedia;
  String _mediaType = 'text';
  String _selectedFilter = 'none';
  final List<Map<String, dynamic>> _stickers = [];
  Color _backgroundColor = const Color(0xFF1E88E5);
  String _privacy = 'everyone';
  bool _allowReplies = true;
  bool _allowSharing = true;
  bool _isLoading = false;

  VideoPlayerController? _videoController;
  int? _videoDurationSeconds;

  static const double _kMinTouchTarget = 48.0;

  final List<Color> _backgroundColors = [
    const Color(0xFF1E88E5),
    const Color(0xFF7B1FA2),
    const Color(0xFFE91E63),
    const Color(0xFFFF9800),
    const Color(0xFF4CAF50),
    const Color(0xFF009688),
    const Color(0xFFF44336),
    const Color(0xFF3F51B5),
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _videoController?.dispose();
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
        _videoController = null;
        _videoDurationSeconds = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (video != null) await _setVideo(File(video.path));
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _videoController?.dispose();
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
        _videoController = null;
        _videoDurationSeconds = null;
      });
    }
  }

  Future<void> _takeVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    if (video != null) await _setVideo(File(video.path));
  }

  Future<void> _setVideo(File file) async {
    _videoController?.dispose();
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    final duration = controller.value.duration.inSeconds;
    if (duration > 60) {
      controller.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video lazima iwe chini ya sekunde 60'),
          ),
        );
      }
      return;
    }
    setState(() {
      _videoController = controller;
      _selectedMedia = file;
      _mediaType = 'video';
      _videoDurationSeconds = duration;
    });
  }

  void _clearMedia() {
    _videoController?.dispose();
    setState(() {
      _selectedMedia = null;
      _mediaType = 'text';
      _videoController = null;
      _videoDurationSeconds = null;
    });
  }

  void _addSticker(String emoji) {
    setState(() {
      _stickers.add({
        'type': 'emoji',
        'value': emoji,
        'x': 0.5,
        'y': 0.5,
      });
    });
  }

  Future<void> _createStory() async {
    if (_mediaType == 'text' && _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali andika kitu au chagua picha/video')),
      );
      return;
    }
    if ((_mediaType == 'image' || _mediaType == 'video') && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali chagua picha au video')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _storyService.createStory(
      userId: widget.userId,
      mediaType: _mediaType,
      media: _selectedMedia,
      caption: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
      duration: _videoDurationSeconds,
      stickers: _stickers.isEmpty ? null : _stickers,
      filter: _selectedFilter == 'none' ? null : _selectedFilter,
      backgroundColor: _mediaType == 'text'
          ? '#${_backgroundColor.value.toRadixString(16).substring(2)}'
          : null,
      privacy: _privacy,
      allowReplies: _allowReplies,
      allowSharing: _allowSharing,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hadithi imechapishwa!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuchapisha hadithi')),
      );
    }
  }

  void _showPrivacyOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFAFAFA),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Kila mtu'),
              trailing: _privacy == 'everyone' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _privacy = 'everyone');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Wafuasi'),
              trailing: _privacy == 'followers' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _privacy = 'followers');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Marafiki wa Karibu'),
              trailing:
                  _privacy == 'close_friends' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _privacy = 'close_friends');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFAFAFA),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Faragha'),
                  subtitle: Text(_privacyLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPrivacyOptions();
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.reply),
                  title: const Text('Ruhusu Majibu'),
                  value: _allowReplies,
                  onChanged: (v) {
                    setModalState(() => _allowReplies = v);
                    setState(() => _allowReplies = v);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.share),
                  title: const Text('Ruhusu Kushiriki'),
                  value: _allowSharing,
                  onChanged: (v) {
                    setModalState(() => _allowSharing = v);
                    setState(() => _allowSharing = v);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  String get _privacyLabel {
    switch (_privacy) {
      case 'followers':
        return 'Wafuasi';
      case 'close_friends':
        return 'Marafiki wa Karibu';
      default:
        return 'Kila mtu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkContent = _mediaType == 'text' || _selectedMedia != null;
    final appBarColor = isDarkContent ? Colors.black54 : const Color(0xFFFAFAFA);
    final foregroundColor = isDarkContent ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: _mediaType == 'text' ? _backgroundColor : Colors.black,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: foregroundColor),
        title: Text(
          'Unda Hadithi',
          style: TextStyle(color: foregroundColor, fontSize: 18),
        ),
        actions: [
          if (_selectedMedia != null)
            SemanticButton(
              minSize: _kMinTouchTarget,
              icon: Icons.close,
              onPressed: _clearMedia,
              color: foregroundColor,
            ),
          SemanticButton(
            minSize: _kMinTouchTarget,
            icon: Icons.settings,
            onPressed: _showSettings,
            color: foregroundColor,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildContent(foregroundColor),
            _buildBottomControls(foregroundColor),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color foregroundColor) {
    if (_selectedMedia != null && _mediaType == 'image') {
      return Image.file(_selectedMedia!, fit: BoxFit.contain);
    }
    if (_selectedMedia != null && _mediaType == 'video' && _videoController != null) {
      return _VideoPreview(controller: _videoController!);
    }
    if (_selectedMedia != null && _mediaType == 'video') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, color: foregroundColor.withOpacity(0.7), size: 64),
            const SizedBox(height: 8),
            Text(
              'Video imechaguliwa',
              style: TextStyle(color: foregroundColor.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TextField(
          controller: _captionController,
          maxLines: null,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          decoration: const InputDecoration(
            hintText: 'Andika hadithi yako...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(Color foregroundColor) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_mediaType == 'text') _buildColorPicker(),
            if (_selectedMedia != null) ...[
              _buildFilterRow(foregroundColor),
              const SizedBox(height: 8),
              _buildStickersRow(foregroundColor),
              const SizedBox(height: 12),
            ],
            _buildMediaButtons(foregroundColor),
            const SizedBox(height: 12),
            _buildPostButton(foregroundColor),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: _kMinTouchTarget,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _backgroundColors.length,
        itemBuilder: (context, index) {
          final color = _backgroundColors[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _backgroundColor = color),
              child: Container(
                width: _kMinTouchTarget,
                height: _kMinTouchTarget,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: _backgroundColor == color
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(Color foregroundColor) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterIds.length,
        itemBuilder: (context, index) {
          final id = _filterIds[index];
          final label = _filterLabel(id);
          final selected = _selectedFilter == id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              color: selected ? const Color(0xFF1A1A1A) : Colors.white24,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => setState(() => _selectedFilter = id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 72),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _filterLabel(String id) {
    switch (id) {
      case 'vivid':
        return 'Vivid';
      case 'warm':
        return 'Joto';
      case 'cool':
        return 'Baridi';
      case 'bw':
        return 'B&W';
      case 'sepia':
        return 'Sepia';
      default:
        return 'Kawaida';
    }
  }

  Widget _buildStickersRow(Color foregroundColor) {
    return SizedBox(
      height: _kMinTouchTarget,
      child: Row(
        children: [
          Text(
            'Stickers:',
            style: TextStyle(color: foregroundColor, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _stickerEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _stickerEmojis[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: _kMinTouchTarget,
                    height: _kMinTouchTarget,
                    child: Material(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _addSticker(emoji),
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_stickers.isNotEmpty)
            Text(
              '(${_stickers.length})',
              style: TextStyle(color: foregroundColor, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaButtons(Color foregroundColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MediaButton(
          icon: Icons.photo_library,
          label: 'Picha',
          onTap: _pickImage,
          minSize: _kMinTouchTarget,
          color: foregroundColor,
        ),
        _MediaButton(
          icon: Icons.video_library,
          label: 'Video',
          onTap: _pickVideo,
          minSize: _kMinTouchTarget,
          color: foregroundColor,
        ),
        _MediaButton(
          icon: Icons.camera_alt,
          label: 'Piga',
          onTap: _takePhoto,
          minSize: _kMinTouchTarget,
          color: foregroundColor,
        ),
        _MediaButton(
          icon: Icons.videocam,
          label: 'Rekodi',
          onTap: _takeVideo,
          minSize: _kMinTouchTarget,
          color: foregroundColor,
        ),
      ],
    );
  }

  Widget _buildPostButton(Color foregroundColor) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: _isLoading ? null : _createStory,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Chapisha Hadithi',
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoPreview({required this.controller});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.setLooping(true);
    widget.controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.controller.value.isPlaying) {
          widget.controller.pause();
        } else {
          widget.controller.play();
        }
        setState(() {});
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(widget.controller),
          Center(
            child: Icon(
              widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white.withOpacity(0.8),
              size: 64,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double minSize;
  final Color color;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.minSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: minSize + 16,
        height: minSize + 24,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
    );
  }
}

/// Wrapper to meet 48dp minimum touch target (DESIGN.md).
class SemanticButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback onPressed;
  final Color color;
  final double minSize;
  final Widget? child;

  const SemanticButton({
    super.key,
    this.icon,
    required this.onPressed,
    required this.color,
    this.minSize = 48,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return SizedBox(
        width: minSize,
        height: minSize,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Center(child: child),
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: Size(minSize, minSize),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
