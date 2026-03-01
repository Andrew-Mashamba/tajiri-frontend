import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post_models.dart';
import '../../models/draft_models.dart';
import '../../services/post_service.dart';
import '../../services/draft_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mention_text_field.dart';
import '../../widgets/schedule_post_widget.dart';
import 'schedulepostwidget_screen.dart';

/// Short video (<=60 seconds) creation screen with TikTok-style features, drafts and scheduling
class CreateShortVideoScreen extends StatefulWidget {
  final int currentUserId;
  final String? userName;
  final String? userPhotoUrl;
  final PostDraft? draft;

  const CreateShortVideoScreen({
    super.key,
    required this.currentUserId,
    this.userName,
    this.userPhotoUrl,
    this.draft,
  });

  @override
  State<CreateShortVideoScreen> createState() => _CreateShortVideoScreenState();
}

class _CreateShortVideoScreenState extends State<CreateShortVideoScreen> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final DraftService _draftService = DraftService();
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _videoFile;
  File? _coverImage;
  PostPrivacy _privacy = PostPrivacy.public;
  bool _isPosting = false;
  bool _isSavingDraft = false;
  String _selectedFilter = 'normal';
  double _videoSpeed = 1.0;
  bool _muteOriginalAudio = false;
  MusicTrack? _selectedMusic;
  DateTime? _scheduledAt;
  int? _draftId;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  late AnimationController _recordingPulse;

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

  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _recordingPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _initializeFromDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_videoFile == null && widget.draft == null) _showVideoSourceOptions();
    });
  }

  void _initializeFromDraft() {
    if (widget.draft != null) {
      _captionController.text = widget.draft!.content ?? '';
      _privacy = PostPrivacy.values.firstWhere((p) => p.value == widget.draft!.privacy, orElse: () => PostPrivacy.public);
      _selectedFilter = widget.draft!.videoFilter ?? 'normal';
      _videoSpeed = widget.draft!.videoSpeed;
      _muteOriginalAudio = widget.draft!.originalAudioVolume == 0;
      _scheduledAt = widget.draft!.scheduledAt;
      _draftId = widget.draft!.id;
      if (widget.draft!.coverImagePath != null) {
        final f = File(widget.draft!.coverImagePath!);
        if (f.existsSync()) _coverImage = f;
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _recordingPulse.dispose();
    _draftService.dispose();
    super.dispose();
  }

  bool get _canPost => _videoFile != null;
  bool get _hasChanges =>
      _videoFile != null ||
      _coverImage != null ||
      _captionController.text.trim().isNotEmpty;

  void _showVideoSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Create Short Video', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Videos up to 60 seconds', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _SourceOptionCard(icon: Icons.videocam, label: 'Record', color: Colors.red, onTap: () { Navigator.pop(context); _recordVideo(); })),
                  const SizedBox(width: 16),
                  Expanded(child: _SourceOptionCard(icon: Icons.video_library, label: 'Gallery', color: Colors.purple, onTap: () { Navigator.pop(context); _pickVideo(); })),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recordVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
    if (video != null) setState(() => _videoFile = File(video.path));
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (video != null) setState(() => _videoFile = File(video.path));
  }

  Future<void> _pickCoverImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, maxHeight: 720, imageQuality: 85);
    if (image != null) setState(() => _coverImage = File(image.path));
  }

  Future<void> _takeCoverPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1280, maxHeight: 720, imageQuality: 85);
    if (image != null) setState(() => _coverImage = File(image.path));
  }

  void _showCoverOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Video cover', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Optional thumbnail for your short video', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _SourceOptionCard(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      color: const Color(0xFF1A1A1A),
                      onTap: () { Navigator.pop(context); _pickCoverImage(); },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SourceOptionCard(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: const Color(0xFF1A1A1A),
                      onTap: () { Navigator.pop(context); _takeCoverPhoto(); },
                    ),
                  ),
                ],
              ),
              if (_coverImage != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () { setState(() => _coverImage = null); Navigator.pop(context); },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Remove cover'),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPost() async {
    if (!_canPost) return;
    setState(() {
      _isPosting = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparing upload...';
    });

    try {
      // Get file size for user feedback
      final fileSize = _videoFile!.lengthSync();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (fileSizeMB > 10) {
        setState(() => _uploadStatus = 'Uploading large video (${fileSizeMB.toStringAsFixed(1)} MB)...');
      }

      final result = await _postService.createPost(
        userId: widget.currentUserId,
        content: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
        privacy: _privacy.value,
        postType: 'short_video',
        media: [_videoFile!],
        coverImage: _coverImage,
        videoFilter: _selectedFilter != 'normal' ? _selectedFilter : null,
        videoSpeed: _videoSpeed != 1.0 ? _videoSpeed : null,
        musicTrackId: _selectedMusic?.id,
        originalAudioVolume: _muteOriginalAudio ? 0.0 : 1.0,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
              _uploadStatus = 'Uploading... ${(progress * 100).toInt()}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isPosting = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
        if (result.success) {
          if (_draftId != null) await _draftService.deleteDraft(_draftId!);
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video posted!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to post'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPosting = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _schedulePost() async {
    if (!_canPost || _scheduledAt == null) return;
    setState(() => _isPosting = true);

    try {
      final result = await _draftService.saveDraft(
        userId: widget.currentUserId,
        draftId: _draftId,
        postType: DraftPostType.shortVideo,
        content: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
        privacy: _privacy.value,
        scheduledAt: _scheduledAt,
        videoFilter: _selectedFilter != 'normal' ? _selectedFilter : null,
        videoSpeed: _videoSpeed != 1.0 ? _videoSpeed : null,
        musicTrackId: _selectedMusic?.id,
        originalAudioVolume: _muteOriginalAudio ? 0.0 : 1.0,
        mediaFiles: [_videoFile!],
        coverImage: _coverImage,
      );

      if (result.success && result.draft?.id != null) {
        final publishResult = await _draftService.publishDraft(result.draft!.id!);
        if (mounted) {
          setState(() => _isPosting = false);
          if (publishResult.success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(publishResult.message ?? 'Video scheduled')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(publishResult.message ?? 'Failed to schedule'), backgroundColor: Colors.red));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _saveDraft() async {
    if (!_hasChanges) return;
    setState(() => _isSavingDraft = true);

    try {
      final result = await _draftService.saveDraft(
        userId: widget.currentUserId,
        draftId: _draftId,
        postType: DraftPostType.shortVideo,
        content: _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
        privacy: _privacy.value,
        scheduledAt: _scheduledAt,
        videoFilter: _selectedFilter != 'normal' ? _selectedFilter : null,
        videoSpeed: _videoSpeed != 1.0 ? _videoSpeed : null,
        musicTrackId: _selectedMusic?.id,
        originalAudioVolume: _muteOriginalAudio ? 0.0 : 1.0,
        mediaFiles: _videoFile != null ? [_videoFile!] : null,
        coverImage: _coverImage,
      );

      if (mounted) {
        setState(() {
          _isSavingDraft = false;
          if (result.success && result.draft != null) _draftId = result.draft!.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.success ? 'Draft saved' : (result.message ?? 'Failed to save')),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _onPopInvoked(bool didPop, dynamic result) async {
    if (didPop || !_hasChanges) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Draft?'),
        content: const Text('You have unsaved changes. Would you like to save them as a draft?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'discard'), child: const Text('Discard')),
          TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save Draft')),
        ],
      ),
    );
    if (choice == 'save') {
      await _saveDraft();
      if (mounted) Navigator.pop(context, false);
    } else if (choice == 'discard' && mounted) {
      Navigator.pop(context, false);
    }
  }

  void _showFilterPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter['name'];
                  return GestureDetector(
                    onTap: () { setState(() => _selectedFilter = filter['name']!); Navigator.pop(context); },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.red : Colors.grey.shade300, width: isSelected ? 3 : 1),
                        color: isSelected ? Colors.red.shade50 : Colors.grey.shade100,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter, color: isSelected ? Colors.red : Colors.grey.shade600),
                          const SizedBox(height: 4),
                          Text(filter['label']!, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.red : Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Video Speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _speedOptions.map((speed) {
                final isSelected = _videoSpeed == speed;
                return GestureDetector(
                  onTap: () { setState(() => _videoSpeed = speed); Navigator.pop(context); },
                  child: Container(
                    width: 56,
                    height: 56,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.red : Colors.grey.shade100, border: Border.all(color: isSelected ? Colors.red : Colors.grey.shade300, width: 2)),
                    child: Center(child: Text('${speed}x', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade700))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMusicPicker() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Music library coming soon')));
  }

  void _showPrivacyPicker() {
    const primary = Color(0xFF1A1A1A);
    const secondary = Color(0xFF666666);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.all(16), child: Text('Who can see this?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primary))),
            _buildPrivacyOption(Icons.public, 'Public', 'Everyone can see', PostPrivacy.public, primary, secondary),
            _buildPrivacyOption(Icons.group, 'Friends', 'Only friends can see', PostPrivacy.friends, primary, secondary),
            _buildPrivacyOption(Icons.star, 'Subscribers Only', 'Only your subscribers can see', PostPrivacy.subscribers, primary, secondary),
            _buildPrivacyOption(Icons.lock, 'Private', 'Only you can see', PostPrivacy.private, primary, secondary),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSchedulePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SchedulePostWidget(initialScheduledAt: _scheduledAt, onScheduleChanged: (date) => setState(() => _scheduledAt = date)),
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Open full screen date and time picker',
              child: InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await SchedulePostWidgetScreen.navigate(
                    context,
                    initialScheduledAt: _scheduledAt,
                  );
                  if (mounted && picked != null) {
                    setState(() => _scheduledAt = picked);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.open_in_full, size: 20, color: const Color(0xFF666666)),
                      const SizedBox(width: 8),
                      Text(
                        'Set date & time',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(IconData icon, String title, String subtitle, PostPrivacy privacy, Color primary, Color secondary) {
    final isSelected = _privacy == privacy;
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 24),
      ),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: primary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: secondary)),
      trailing: isSelected ? Icon(Icons.check_circle, color: Color(0xFF999999)) : null,
      onTap: () { setState(() => _privacy = privacy); Navigator.pop(context); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: _isPosting && _uploadStatus.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Short Video', style: TextStyle(fontSize: 16)),
                    Text(_uploadStatus, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                )
              : const Text('Short Video'),
          actions: [
            if (_hasChanges && !_isPosting)
              TextButton(
                onPressed: _isSavingDraft ? null : _saveDraft,
                child: _isSavingDraft ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save', style: TextStyle(color: Colors.white70)),
              ),
            if (_videoFile != null)
              TextButton(
                onPressed: !_isPosting ? (_scheduledAt != null ? _schedulePost : _createPost) : null,
                child: _isPosting
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                              value: _uploadProgress > 0 ? _uploadProgress : null,
                            ),
                          ),
                          if (_uploadProgress > 0) ...[
                            const SizedBox(width: 6),
                            Text('${(_uploadProgress * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ],
                      )
                    : Text(_scheduledAt != null ? 'Schedule' : 'Post', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: SafeArea(
          child: _videoFile == null ? _buildEmptyState() : _buildEditorView(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade900), child: Icon(Icons.videocam, size: 60, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Text('No video selected', style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(onPressed: _recordVideo, icon: const Icon(Icons.videocam), label: const Text('Record'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
              const SizedBox(width: 16),
              OutlinedButton.icon(onPressed: _pickVideo, icon: const Icon(Icons.video_library), label: const Text('Gallery'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorView() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.grey.shade900),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: double.infinity, color: Colors.grey.shade800, child: const Icon(Icons.play_circle_fill, size: 80, color: Colors.white54)),
                        if (_selectedFilter != 'normal')
                          Positioned(top: 16, left: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.filter, color: Colors.white, size: 16), const SizedBox(width: 4), Text(_filters.firstWhere((f) => f['name'] == _selectedFilter)['label']!, style: const TextStyle(color: Colors.white, fontSize: 12))]))),
                        if (_videoSpeed != 1.0)
                          Positioned(top: 16, right: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)), child: Text('${_videoSpeed}x', style: const TextStyle(color: Colors.white, fontSize: 12)))),
                        if (_scheduledAt != null && !_isPosting)
                          Positioned(bottom: 16, left: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.schedule, color: Colors.white, size: 14), const SizedBox(width: 4), Text('Scheduled', style: const TextStyle(color: Colors.white, fontSize: 12))]))),
                        // Upload progress overlay
                        if (_isPosting)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          strokeWidth: 6,
                                          value: _uploadProgress > 0 ? _uploadProgress : null,
                                          color: Colors.red,
                                          backgroundColor: Colors.white24,
                                        ),
                                        if (_uploadProgress > 0)
                                          Text(
                                            '${(_uploadProgress * 100).toInt()}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _uploadStatus,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Please keep the app open',
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    _SideTool(icon: Icons.image, label: 'Cover', onTap: _showCoverOptions),
                    const SizedBox(height: 12),
                    _SideTool(icon: Icons.filter, label: 'Filter', onTap: _showFilterPicker),
                    const SizedBox(height: 12),
                    _SideTool(icon: Icons.speed, label: 'Speed', onTap: _showSpeedPicker),
                    const SizedBox(height: 12),
                    _SideTool(icon: Icons.music_note, label: 'Music', onTap: _showMusicPicker),
                    const SizedBox(height: 12),
                    _SideTool(icon: _muteOriginalAudio ? Icons.volume_off : Icons.volume_up, label: _muteOriginalAudio ? 'Muted' : 'Sound', onTap: () => setState(() => _muteOriginalAudio = !_muteOriginalAudio)),
                    const SizedBox(height: 12),
                    _SideTool(icon: Icons.schedule, label: 'Schedule', onTap: _showSchedulePicker),
                  ],
                ),
              ),
              if (_coverImage != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: _showCoverOptions,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(_coverImage!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(12)),
                  child: MentionTextField(
                    controller: _captionController,
                    currentUserId: widget.currentUserId,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    minLines: 1,
                    hintText: 'Write a caption... @ #',
                    decoration: InputDecoration(
                      hintText: 'Write a caption... @ #',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    UserAvatar(photoUrl: widget.userPhotoUrl, name: widget.userName, radius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: _showPrivacyPicker,
                            child: Row(
                              children: [
                                Icon(_getPrivacyIcon(_privacy), size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(_getPrivacyLabel(_privacy), style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade400, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: _showVideoSourceOptions, child: const Text('Change')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPrivacyIcon(PostPrivacy p) {
    switch (p) {
      case PostPrivacy.public: return Icons.public;
      case PostPrivacy.friends: return Icons.group;
      case PostPrivacy.subscribers: return Icons.star;
      case PostPrivacy.private: return Icons.lock;
    }
  }

  String _getPrivacyLabel(PostPrivacy p) {
    switch (p) {
      case PostPrivacy.public: return 'Public';
      case PostPrivacy.friends: return 'Friends';
      case PostPrivacy.subscribers: return 'Subscribers';
      case PostPrivacy.private: return 'Private';
    }
  }
}

class _SideTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SideTool({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}

class _SourceOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOptionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 32)),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
