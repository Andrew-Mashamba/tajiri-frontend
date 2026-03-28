import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:heroicons/heroicons.dart';
import 'package:video_player/video_player.dart';
import '../../models/post_models.dart';
import '../../services/post_service.dart';

// DESIGN.md: monochromatic palette, 48dp min touch, SafeArea mandatory
const Color _kBg = Color(0xFF0D0D0D);
const Color _kSurface = Color(0xFF1A1A1A);
const Color _kAccent = Color(0xFFFFFFFF);
const Color _kMuted = Color(0xFF666666);
const double _kMinTouch = 48.0;

/// Layout mode for duet/reply video.
enum ReplyLayout {
  sideBySide,
  topBottom,
  pip,
}

/// Video Reply (Duet) screen.
/// Shows the original video alongside a camera preview.
/// User records their reaction, both videos are uploaded to backend
/// which composes them server-side.
class VideoReplyScreen extends StatefulWidget {
  final Post originalPost;
  final int currentUserId;

  const VideoReplyScreen({
    super.key,
    required this.originalPost,
    required this.currentUserId,
  });

  @override
  State<VideoReplyScreen> createState() => _VideoReplyScreenState();
}

class _VideoReplyScreenState extends State<VideoReplyScreen>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _cameraReady = false;

  // Original video playback
  VideoPlayerController? _originalVideoController;
  bool _originalVideoReady = false;

  // Recording state
  bool _isRecording = false;
  File? _recordedFile;
  bool _recordingComplete = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // Layout
  ReplyLayout _layout = ReplyLayout.sideBySide;

  // Audio
  double _originalVolume = 0.3;
  bool _micEnabled = true;

  // Upload
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Caption
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _initOriginalVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    _originalVideoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _originalVideoController?.pause();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      // Start with front camera
      _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _setupCamera(_cameraIndex);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _setupCamera(int index) async {
    if (_cameras.isEmpty) return;
    final oldController = _cameraController;

    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: _micEnabled,
    );

    try {
      await controller.initialize();
      await oldController?.dispose();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _cameraReady = controller.value.isInitialized;
      });
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }
  }

  Future<void> _initOriginalVideo() async {
    final videoMedia = widget.originalPost.primaryVideo;
    if (videoMedia == null || videoMedia.fileUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(videoMedia.fileUrl),
    );

    try {
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(_originalVolume);
      if (!mounted) return;
      setState(() {
        _originalVideoController = controller;
        _originalVideoReady = true;
      });
    } catch (e) {
      debugPrint('Original video init error: $e');
    }
  }

  void _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _setupCamera(_cameraIndex);
  }

  Future<void> _toggleMic() async {
    setState(() => _micEnabled = !_micEnabled);
    // Re-init camera with new audio setting
    await _setupCamera(_cameraIndex);
  }

  void _cycleLayout() {
    setState(() {
      final values = ReplyLayout.values;
      final next = (values.indexOf(_layout) + 1) % values.length;
      _layout = values[next];
    });
  }

  void _setOriginalVolume(double v) {
    setState(() => _originalVolume = v);
    _originalVideoController?.setVolume(v);
  }

  // --- Recording ---

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraReady) return;
    if (_isRecording) return;

    try {
      await _cameraController!.startVideoRecording();
      // Start original video playback in sync
      _originalVideoController?.seekTo(Duration.zero);
      _originalVideoController?.play();

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        // Max 60 seconds
        if (_recordingDuration.inSeconds >= 60) {
          _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();

    try {
      final file = await _cameraController!.stopVideoRecording();
      _originalVideoController?.pause();

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedFile = File(file.path);
        _recordingComplete = true;
      });
    } catch (e) {
      debugPrint('Stop recording error: $e');
      setState(() => _isRecording = false);
    }
  }

  void _retake() {
    setState(() {
      _recordedFile = null;
      _recordingComplete = false;
      _recordingDuration = Duration.zero;
    });
    _originalVideoController?.seekTo(Duration.zero);
    _originalVideoController?.pause();
  }

  // --- Upload ---

  Future<void> _uploadReply() async {
    if (_recordedFile == null || _isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Inaandaa...';
    });

    try {
      final postService = PostService();
      final caption = _captionController.text.trim();

      // Build caption with attribution
      final originalUser = widget.originalPost.user;
      final attribution = originalUser != null
          ? '#reply na @${originalUser.username ?? 'user${widget.originalPost.userId}'}'
          : '#reply';
      final fullCaption = caption.isEmpty
          ? attribution
          : '$caption\n\n$attribution';

      // Map layout enum to backend string
      String layoutString;
      switch (_layout) {
        case ReplyLayout.sideBySide:
          layoutString = 'side_by_side';
        case ReplyLayout.topBottom:
          layoutString = 'top_bottom';
        case ReplyLayout.pip:
          layoutString = 'pip';
      }

      final result = await postService.createPost(
        userId: widget.currentUserId,
        content: fullCaption,
        postType: 'short_video',
        privacy: 'public',
        media: [_recordedFile!],
        originalAudioVolume: _micEnabled ? 1.0 : 0.0,
        replyToPostId: widget.originalPost.id,
        replyLayout: layoutString,
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = p;
            _uploadStatus = 'Inapakia... ${(p * 100).toInt()}%';
          });
        },
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reply imechapishwa!'),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isUploading = false;
          _uploadStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Imeshindikana kupakia'),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadStatus = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kosa: $e'),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    if (_recordingComplete && _recordedFile != null) {
      return _buildPreviewScreen();
    }
    return _buildRecordingScreen();
  }

  Widget _buildRecordingScreen() {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            // Layout preview area
            Expanded(child: _buildLayoutPreview()),
            // Controls
            _buildRecordingControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Close
          IconButton(
            icon: HeroIcon(HeroIcons.xMark,
                style: HeroIconStyle.outline, size: 24, color: _kAccent),
            onPressed: () {
              if (_isRecording) {
                _stopRecording();
              }
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          // Layout toggle
          _ControlChip(
            icon: _layoutIcon(),
            label: _layoutLabel(),
            onTap: _isRecording ? null : _cycleLayout,
          ),
          const SizedBox(width: 8),
          // Recording timer
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _layoutIcon() {
    switch (_layout) {
      case ReplyLayout.sideBySide:
        return Icons.view_column_rounded;
      case ReplyLayout.topBottom:
        return Icons.view_agenda_rounded;
      case ReplyLayout.pip:
        return Icons.picture_in_picture_alt_rounded;
    }
  }

  String _layoutLabel() {
    switch (_layout) {
      case ReplyLayout.sideBySide:
        return 'Pembeni';
      case ReplyLayout.topBottom:
        return 'Juu-Chini';
      case ReplyLayout.pip:
        return 'PiP';
    }
  }

  Widget _buildLayoutPreview() {
    final originalWidget = _buildOriginalVideoView();
    final cameraWidget = _buildCameraPreview();

    switch (_layout) {
      case ReplyLayout.sideBySide:
        return Row(
          children: [
            Expanded(child: originalWidget),
            const SizedBox(width: 2),
            Expanded(child: cameraWidget),
          ],
        );

      case ReplyLayout.topBottom:
        return Column(
          children: [
            Expanded(child: originalWidget),
            const SizedBox(height: 2),
            Expanded(child: cameraWidget),
          ],
        );

      case ReplyLayout.pip:
        return Stack(
          children: [
            // Original fills the screen
            Positioned.fill(child: originalWidget),
            // Camera in corner (draggable)
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 0.3,
                  height: MediaQuery.sizeOf(context).width * 0.3 * 16 / 9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: cameraWidget,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildOriginalVideoView() {
    if (!_originalVideoReady || _originalVideoController == null) {
      // Fallback: show post image or placeholder
      final imageUrl = widget.originalPost.primaryImage?.fileUrl;
      return Container(
        color: _kSurface,
        child: imageUrl != null
            ? Image.network(imageUrl, fit: BoxFit.cover)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeroIcon(HeroIcons.videoCamera,
                        style: HeroIconStyle.outline,
                        size: 48,
                        color: _kMuted),
                    const SizedBox(height: 8),
                    const Text('Inapakia video...',
                        style: TextStyle(color: _kMuted, fontSize: 13)),
                  ],
                ),
              ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _originalVideoController!.value.size.width,
              height: _originalVideoController!.value.size.height,
              child: VideoPlayer(_originalVideoController!),
            ),
          ),
        ),
        // Original video label
        Positioned(
          left: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '@${widget.originalPost.user?.username ?? 'user'}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Volume control
        Positioned(
          left: 8,
          bottom: 8,
          child: GestureDetector(
            onTap: () =>
                _setOriginalVolume(_originalVolume > 0 ? 0.0 : 0.5),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _originalVolume > 0
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraReady || _cameraController == null) {
      return Container(
        color: _kSurface,
        child: const Center(
          child: CircularProgressIndicator(color: _kAccent),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1080,
              height: _cameraController!.value.previewSize?.width ?? 1920,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
        // "You" label
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Wewe',
              style: TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: _kBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Flip camera
          _ControlButton(
            icon: Icons.flip_camera_ios_rounded,
            label: 'Geuza',
            onTap: _isRecording ? null : _flipCamera,
          ),
          // Mic toggle
          _ControlButton(
            icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: _micEnabled ? 'Mic On' : 'Mic Off',
            onTap: _isRecording ? null : _toggleMic,
            active: _micEnabled,
          ),
          // Record button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isRecording ? 28 : 56,
                  height: _isRecording ? 28 : 56,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius:
                        BorderRadius.circular(_isRecording ? 6 : 28),
                  ),
                ),
              ),
            ),
          ),
          // Original volume
          _ControlButton(
            icon: _originalVolume > 0
                ? Icons.music_note_rounded
                : Icons.music_off_rounded,
            label: 'Sauti',
            onTap: () =>
                _setOriginalVolume(_originalVolume > 0 ? 0.0 : 0.3),
            active: _originalVolume > 0,
          ),
          // Placeholder for symmetry
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  // --- Preview screen after recording ---

  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: HeroIcon(HeroIcons.arrowLeft,
                        style: HeroIconStyle.outline,
                        size: 24,
                        color: _kAccent),
                    onPressed: _retake,
                  ),
                  const Spacer(),
                  Text(
                    'Hakiki Reply',
                    style: TextStyle(
                        color: _kAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeroIcon(HeroIcons.checkCircle,
                          style: HeroIconStyle.outline,
                          size: 64,
                          color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        'Video imerekodiwa (${_formatDuration(_recordingDuration)})',
                        style: const TextStyle(
                            color: _kAccent, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Layout: ${_layoutLabel()}',
                        style: const TextStyle(
                            color: _kMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Video ya awali itaunganishwa na server',
                        style: const TextStyle(
                            color: _kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Caption
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _captionController,
                style: const TextStyle(color: _kAccent, fontSize: 14),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ongeza maelezo...',
                  hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
                  filled: true,
                  fillColor: _kSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Retake
                  Expanded(
                    child: SizedBox(
                      height: _kMinTouch,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _retake,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Rekodi tena'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kAccent,
                          side: const BorderSide(color: _kMuted),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Post
                  Expanded(
                    child: SizedBox(
                      height: _kMinTouch,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadReply,
                        icon: _isUploading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: _uploadProgress > 0
                                      ? _uploadProgress
                                      : null,
                                  color: _kBg,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 20),
                        label: Text(_isUploading
                            ? _uploadStatus
                            : 'Chapisha'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccent,
                          foregroundColor: _kBg,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
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

// --- Helper Widgets ---

class _ControlChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ControlChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _kAccent, size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: _kAccent, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _kMinTouch,
              height: _kMinTouch,
              decoration: BoxDecoration(
                color: active ? Colors.white12 : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon,
                  color: active ? _kAccent : _kMuted, size: 24),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: active ? _kAccent : _kMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
