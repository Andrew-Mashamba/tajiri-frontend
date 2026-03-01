import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../models/music_models.dart';
import '../../services/clip_service.dart';
import '../music/music_library_screen.dart';
import 'upload_video_screen.dart';
import 'video_search_screen.dart';

/// Create Clip screen: short-form vertical video up to 60s with music overlay and filters.
/// Navigation: Home → Profile → Videos tab → Upload OR Clips discover → Create.
class CreateClipScreen extends StatefulWidget {
  final int userId;

  const CreateClipScreen({super.key, required this.userId});

  @override
  State<CreateClipScreen> createState() => _CreateClipScreenState();
}

class _CreateClipScreenState extends State<CreateClipScreen> {
  final ClipService _clipService = ClipService();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const int _maxClipSeconds = 60;

  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isLoading = false;
  List<String> _hashtags = [];
  String _privacy = 'public';
  bool _allowComments = true;
  bool _allowDuet = true;
  bool _allowStitch = true;
  bool _allowDownload = true;

  /// Music overlay: selected track and start position (seconds)
  MusicTrack? _selectedMusic;
  int _musicStartSeconds = 0;

  /// Filter for clip (e.g. normal, vivid, warm)
  String _selectedFilter = 'normal';

  static const List<Map<String, String>> _filters = [
    {'name': 'normal', 'label': 'Normal'},
    {'name': 'vivid', 'label': 'Vivid'},
    {'name': 'warm', 'label': 'Warm'},
    {'name': 'cool', 'label': 'Cool'},
    {'name': 'black_white', 'label': 'B&W'},
    {'name': 'vintage', 'label': 'Vintage'},
    {'name': 'fade', 'label': 'Fade'},
    {'name': 'dramatic', 'label': 'Dramatic'},
    {'name': 'noir', 'label': 'Noir'},
  ];

  // DESIGN.md: primary #1A1A1A, background #FAFAFA, accent #999999
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _background = Color(0xFFFAFAFA);
  static const Color _secondaryText = Color(0xFF666666);

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: _maxClipSeconds),
    );
    if (video != null) {
      _setVideo(File(video.path));
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: _maxClipSeconds),
    );
    if (video != null) {
      _setVideo(File(video.path));
    }
  }

  /// Navigate to UploadVideoScreen for upload path (Profile → Videos → Upload).
  void _openUploadVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadVideoScreen(
          userId: widget.userId,
          onUploadComplete: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _setVideo(File file) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.play();
    if (mounted) {
      setState(() {
        _selectedVideo = file;
        _isInitialized = true;
      });
    }
  }

  void _addHashtag() {
    final tag = _hashtagController.text.trim();
    if (tag.isNotEmpty && !_hashtags.contains(tag)) {
      setState(() {
        _hashtags.add(tag);
      });
      _hashtagController.clear();
    }
  }

  void _removeHashtag(String tag) {
    setState(() {
      _hashtags.remove(tag);
    });
  }

  void _showMusicPicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MusicLibraryScreen(
          currentUserId: widget.userId,
          onTrackSelected: (MusicTrack track) {
            setState(() {
              _selectedMusic = track;
              _musicStartSeconds = 0;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  /// Navigation path: Create Clip → Add music → VideoSearchScreen (Story 93).
  void _openVideoSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoSearchScreen(),
      ),
    );
  }

  void _removeMusic() {
    setState(() {
      _selectedMusic = null;
      _musicStartSeconds = 0;
    });
  }

  Future<void> _createClip() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali chagua video')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _clipService.createClip(
      userId: widget.userId,
      video: _selectedVideo!,
      caption: _captionController.text.trim().isNotEmpty
          ? _captionController.text.trim()
          : null,
      musicId: _selectedMusic?.id,
      musicStart: _selectedMusic != null ? _musicStartSeconds : null,
      hashtags: _hashtags.isNotEmpty ? _hashtags : null,
      privacy: _privacy,
      allowComments: _allowComments,
      allowDuet: _allowDuet,
      allowStitch: _allowStitch,
      allowDownload: _allowDownload,
      filter: _selectedFilter != 'normal' ? _selectedFilter : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Klipu imechapishwa!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Imeshindwa kuchapisha')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        iconTheme: const IconThemeData(color: _primary),
        title: const Text(
          'Unda Klipu',
          style: TextStyle(
            color: _primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              onPressed: _isLoading ? null : _createClip,
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Chapisha',
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Video preview or picker (vertical 9:16, DESIGN.md touch targets 48dp)
                AspectRatio(
                  aspectRatio: 9 / 16,
                  child: _selectedVideo != null && _isInitialized
                      ? _buildVideoPreview()
                      : _buildVideoPicker(),
                ),

                const SizedBox(height: 24),

                // Caption
                TextField(
                  controller: _captionController,
                  maxLines: 3,
                  maxLength: 500,
                  style: const TextStyle(color: _primary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Andika maelezo...',
                    hintStyle: const TextStyle(color: _secondaryText),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Music overlay
                _buildMusicSection(),
                const SizedBox(height: 16),

                // Filters
                _buildFiltersSection(),
                const SizedBox(height: 16),

                // Hashtags
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hashtagController,
                        style: const TextStyle(color: _primary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ongeza hashtag',
                          hintStyle: const TextStyle(color: _secondaryText),
                          prefixText: '#',
                          prefixStyle: const TextStyle(color: _primary),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _addHashtag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SemanticButton(
                      icon: Icons.add,
                      onPressed: _addHashtag,
                    ),
                  ],
                ),
                if (_hashtags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _hashtags.map((tag) {
                      return Chip(
                        label: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: _primary.withOpacity(0.08),
                        deleteIcon: const Icon(Icons.close, size: 18, color: _primary),
                        onDeleted: () => _removeHashtag(tag),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // Settings
                const Text(
                  'Mipangilio',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _SettingTile(
                  icon: Icons.lock_outline,
                  title: 'Faragha',
                  value: _privacyLabel,
                  onTap: _showPrivacyOptions,
                ),
                _SettingSwitch(
                  icon: Icons.comment_outlined,
                  title: 'Ruhusu Maoni',
                  value: _allowComments,
                  onChanged: (v) => setState(() => _allowComments = v),
                ),
                _SettingSwitch(
                  icon: Icons.call_split,
                  title: 'Ruhusu Duet',
                  value: _allowDuet,
                  onChanged: (v) => setState(() => _allowDuet = v),
                ),
                _SettingSwitch(
                  icon: Icons.content_cut,
                  title: 'Ruhusu Stitch',
                  value: _allowStitch,
                  onChanged: (v) => setState(() => _allowStitch = v),
                ),
                _SettingSwitch(
                  icon: Icons.download_outlined,
                  title: 'Ruhusu Kupakua',
                  value: _allowDownload,
                  onChanged: (v) => setState(() => _allowDownload = v),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
            setState(() {});
          },
          child: VideoPlayer(_videoController!),
        ),
        Center(
          child: IconButton(
            iconSize: 64,
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white.withOpacity(0.9),
            ),
            onPressed: () {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
              setState(() {});
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: SemanticButton(
            icon: Icons.close,
            onPressed: () {
              _videoController?.dispose();
              setState(() {
                _selectedVideo = null;
                _isInitialized = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPicker() {
    return Container(
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: _secondaryText),
          const SizedBox(height: 16),
          Text(
            'Video hadi sekunde $_maxClipSeconds',
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PickerButton(
                icon: Icons.photo_library_outlined,
                label: 'Chagua',
                onPressed: _pickVideo,
              ),
              const SizedBox(width: 16),
              _PickerButton(
                icon: Icons.videocam_outlined,
                label: 'Rekodi',
                onPressed: _recordVideo,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _openUploadVideo,
            icon: const Icon(Icons.cloud_upload_outlined, size: 20),
            label: const Text('Pakia video'),
            style: TextButton.styleFrom(
              foregroundColor: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note_outlined, color: _primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Muziki',
                style: TextStyle(
                  color: _primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedMusic != null) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedMusic!.coverUrl.isNotEmpty
                      ? Image.network(
                          _selectedMusic!.coverUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _musicPlaceholder(),
                        )
                      : _musicPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMusic!.title,
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedMusic!.artist != null)
                        Text(
                          _selectedMusic!.artist!.name,
                          style: const TextStyle(
                            color: _secondaryText,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                SemanticButton(
                  icon: Icons.close,
                  onPressed: _removeMusic,
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showMusicPicker,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Ongeza muziki'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openVideoSearch,
                icon: const Icon(Icons.search, size: 20),
                label: const Text('Tafuta video'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: const BorderSide(color: _primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _musicPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: _primary.withOpacity(0.08),
      child: const Icon(Icons.music_note, color: _primary),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter',
          style: TextStyle(
            color: _primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final name = f['name']!;
              final label = f['label']!;
              final isSelected = _selectedFilter == name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFilter = name),
                  backgroundColor: Colors.white,
                  selectedColor: _primary.withOpacity(0.12),
                  side: BorderSide(
                    color: isSelected ? _primary : _primary.withOpacity(0.2),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String get _privacyLabel {
    switch (_privacy) {
      case 'followers':
        return 'Wafuasi';
      case 'subscribers':
        return 'Wasajili Pekee';
      case 'private':
        return 'Mimi Pekee';
      default:
        return 'Kila mtu';
    }
  }

  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.public, color: _primary),
              title: const Text('Kila mtu', style: TextStyle(color: _primary)),
              trailing: _privacy == 'public'
                  ? const Icon(Icons.check, color: _primary)
                  : null,
              onTap: () {
                setState(() => _privacy = 'public');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: _primary),
              title: const Text('Wafuasi', style: TextStyle(color: _primary)),
              trailing: _privacy == 'followers'
                  ? const Icon(Icons.check, color: _primary)
                  : null,
              onTap: () {
                setState(() => _privacy = 'followers');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Color(0xFFF59E0B)),
              title: const Text('Wasajili Pekee', style: TextStyle(color: _primary)),
              subtitle: const Text('Wasajili wako tu wanaweza kuona', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              trailing: _privacy == 'subscribers'
                  ? const Icon(Icons.check, color: Color(0xFFF59E0B))
                  : null,
              onTap: () {
                setState(() => _privacy = 'subscribers');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: _primary),
              title: const Text('Mimi Pekee', style: TextStyle(color: _primary)),
              trailing: _privacy == 'private'
                  ? const Icon(Icons.check, color: _primary)
                  : null,
              onTap: () {
                setState(() => _privacy = 'private');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

/// Minimum 48dp touch target (DESIGN.md).
class SemanticButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const SemanticButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(icon, color: _CreateClipScreenState._primary),
          ),
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _CreateClipScreenState._primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _CreateClipScreenState._primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _CreateClipScreenState._secondaryText, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: _CreateClipScreenState._primary,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _CreateClipScreenState._secondaryText,
              fontSize: 12,
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: _CreateClipScreenState._secondaryText,
          ),
        ],
      ),
      onTap: onTap,
      minLeadingWidth: 0,
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(
        icon,
        color: _CreateClipScreenState._secondaryText,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _CreateClipScreenState._primary,
          fontSize: 14,
        ),
      ),
      value: value,
      activeColor: _CreateClipScreenState._primary,
      onChanged: onChanged,
    );
  }
}
