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

/// Two-step Stitch creation:
///   Step 1 — Trim up to 5 seconds from the original video
///   Step 2 — Record your response (plays after the original clip)
/// Both clips are uploaded; backend concatenates them.
class VideoStitchScreen extends StatefulWidget {
  final Post originalPost;
  final int currentUserId;

  const VideoStitchScreen({
    super.key,
    required this.originalPost,
    required this.currentUserId,
  });

  @override
  State<VideoStitchScreen> createState() => _VideoStitchScreenState();
}

class _VideoStitchScreenState extends State<VideoStitchScreen>
    with WidgetsBindingObserver {
  // Steps: 0 = trim, 1 = record, 2 = preview
  int _step = 0;

  // Step 1: Trimmer
  VideoPlayerController? _trimController;
  bool _trimVideoReady = false;
  Duration _videoDuration = Duration.zero;
  Duration _trimStart = Duration.zero;
  Duration _trimEnd = const Duration(seconds: 5);
  static const int _maxClipSeconds = 5;
  bool _trimPlaying = false;

  // Step 2: Camera recording
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _cameraReady = false;
  bool _isRecording = false;
  File? _recordedFile;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  bool _micEnabled = true;

  // Step 3: Upload
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTrimVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _trimController?.dispose();
    _cameraController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _trimController?.pause();
      _cameraController?.dispose();
    }
  }

  // --- Step 1: Trim ---

  Future<void> _initTrimVideo() async {
    final videoMedia = widget.originalPost.primaryVideo;
    if (videoMedia == null || videoMedia.fileUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(videoMedia.fileUrl),
    );

    try {
      await controller.initialize();
      controller.setLooping(false);
      if (!mounted) return;

      final duration = controller.value.duration;
      setState(() {
        _trimController = controller;
        _trimVideoReady = true;
        _videoDuration = duration;
        _trimEnd = duration.inSeconds <= _maxClipSeconds
            ? duration
            : const Duration(seconds: _maxClipSeconds);
      });

      // Listen to playback position to loop within trim range
      controller.addListener(_trimPlaybackListener);
    } catch (e) {
      debugPrint('Trim video init error: $e');
    }
  }

  void _trimPlaybackListener() {
    if (_trimController == null || !_trimPlaying) return;
    final pos = _trimController!.value.position;
    if (pos >= _trimEnd) {
      _trimController!.seekTo(_trimStart);
      _trimController!.pause();
      if (mounted) setState(() => _trimPlaying = false);
    }
  }

  void _playTrimPreview() {
    if (_trimController == null) return;
    _trimController!.seekTo(_trimStart);
    _trimController!.play();
    setState(() => _trimPlaying = true);
  }

  void _pauseTrimPreview() {
    _trimController?.pause();
    setState(() => _trimPlaying = false);
  }

  void _onTrimStartChanged(double value) {
    final ms = value.toInt();
    final newStart = Duration(milliseconds: ms);
    // Ensure trim range doesn't exceed max clip
    Duration newEnd = _trimEnd;
    if (newEnd.inMilliseconds - ms < 1000) {
      // Min 1 second clip
      return;
    }
    if (newEnd.inMilliseconds - ms > _maxClipSeconds * 1000) {
      newEnd = Duration(milliseconds: ms + _maxClipSeconds * 1000);
      if (newEnd > _videoDuration) newEnd = _videoDuration;
    }
    setState(() {
      _trimStart = newStart;
      _trimEnd = newEnd;
    });
    _trimController?.seekTo(newStart);
  }

  void _onTrimEndChanged(double value) {
    final ms = value.toInt();
    final newEnd = Duration(milliseconds: ms);
    if (ms - _trimStart.inMilliseconds < 1000) return;
    if (ms - _trimStart.inMilliseconds > _maxClipSeconds * 1000) {
      return;
    }
    setState(() => _trimEnd = newEnd);
  }

  Duration get _clipDuration => _trimEnd - _trimStart;

  void _confirmTrim() async {
    _trimController?.pause();
    setState(() => _step = 1);
    await _initCamera();
  }

  // --- Step 2: Record ---

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
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

  void _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _setupCamera(_cameraIndex);
  }

  Future<void> _toggleMic() async {
    setState(() => _micEnabled = !_micEnabled);
    await _setupCamera(_cameraIndex);
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraReady || _isRecording) return;

    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        if (_recordingDuration.inSeconds >= 55) {
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
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedFile = File(file.path);
        _step = 2; // Go to preview
      });
    } catch (e) {
      debugPrint('Stop recording error: $e');
      setState(() => _isRecording = false);
    }
  }

  void _retakeRecording() {
    setState(() {
      _recordedFile = null;
      _recordingDuration = Duration.zero;
      _step = 1;
    });
  }

  void _backToTrimmer() {
    _cameraController?.dispose();
    setState(() {
      _cameraController = null;
      _cameraReady = false;
      _recordedFile = null;
      _recordingDuration = Duration.zero;
      _step = 0;
    });
  }

  // --- Step 3: Upload ---

  Future<void> _uploadStitch() async {
    if (_recordedFile == null || _isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Inaandaa...';
    });

    try {
      final postService = PostService();
      final caption = _captionController.text.trim();

      final originalUser = widget.originalPost.user;
      final attribution = originalUser != null
          ? '#stitch na @${originalUser.username ?? 'user${widget.originalPost.userId}'}'
          : '#stitch';
      final fullCaption =
          caption.isEmpty ? attribution : '$caption\n\n$attribution';

      final result = await postService.createPost(
        userId: widget.currentUserId,
        content: fullCaption,
        postType: 'short_video',
        privacy: 'public',
        media: [_recordedFile!],
        originalAudioVolume: _micEnabled ? 1.0 : 0.0,
        stitchFromPostId: widget.originalPost.id,
        stitchTrimStartMs: _trimStart.inMilliseconds,
        stitchTrimEndMs: _trimEnd.inMilliseconds,
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
            content: const Text('Stitch imechapishwa!'),
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
    switch (_step) {
      case 0:
        return _buildTrimmerStep();
      case 1:
        return _buildRecordStep();
      case 2:
        return _buildPreviewStep();
      default:
        return _buildTrimmerStep();
    }
  }

  // ==================== STEP 1: TRIMMER ====================

  Widget _buildTrimmerStep() {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildStepTopBar(
              title: 'Chagua sehemu (max ${_maxClipSeconds}s)',
              onBack: () => Navigator.pop(context),
              trailing: TextButton(
                onPressed: _trimVideoReady ? _confirmTrim : null,
                child: const Text('Endelea',
                    style: TextStyle(
                        color: _kAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ),
            // Video preview
            Expanded(
              child: _trimVideoReady && _trimController != null
                  ? _buildTrimVideoPreview()
                  : const Center(
                      child: CircularProgressIndicator(color: _kAccent)),
            ),
            // Trim controls
            if (_trimVideoReady) _buildTrimSliders(),
            // Play/Pause
            if (_trimVideoReady)
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _trimPlaying
                          ? _pauseTrimPreview
                          : _playTrimPreview,
                      icon: Icon(
                        _trimPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: _kAccent,
                        size: 48,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_formatDuration(_clipDuration)} kipande',
                      style: const TextStyle(color: _kMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrimVideoPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _trimController!.value.aspectRatio,
              child: VideoPlayer(_trimController!),
            ),
          ),
          // Original creator label
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '@${widget.originalPost.user?.username ?? 'user'}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimSliders() {
    final totalMs = _videoDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Timeline labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mwanzo: ${_formatDuration(_trimStart)}',
                style: const TextStyle(color: _kMuted, fontSize: 12),
              ),
              Text(
                'Mwisho: ${_formatDuration(_trimEnd)}',
                style: const TextStyle(color: _kMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Start slider
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text('Mwanzo',
                    style: TextStyle(color: _kAccent, fontSize: 12)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _kAccent,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: _kAccent,
                    overlayColor: Colors.white24,
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs,
                    value: _trimStart.inMilliseconds
                        .toDouble()
                        .clamp(0, totalMs),
                    onChanged: _onTrimStartChanged,
                  ),
                ),
              ),
            ],
          ),
          // End slider
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Text('Mwisho',
                    style: TextStyle(color: _kAccent, fontSize: 12)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _kAccent,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: _kAccent,
                    overlayColor: Colors.white24,
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs,
                    value:
                        _trimEnd.inMilliseconds.toDouble().clamp(0, totalMs),
                    onChanged: _onTrimEndChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== STEP 2: RECORD ====================

  Widget _buildRecordStep() {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildStepTopBar(
              title: 'Rekodi majibu yako',
              onBack: _backToTrimmer,
            ),
            // Camera preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _cameraReady && _cameraController != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _cameraController!
                                        .value.previewSize?.height ??
                                    1080,
                                height: _cameraController!
                                        .value.previewSize?.width ??
                                    1920,
                                child:
                                    CameraPreview(_cameraController!),
                              ),
                            ),
                          ),
                          // Stitch info banner
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              color: Colors.black54,
                              child: Row(
                                children: [
                                  HeroIcon(HeroIcons.scissors,
                                      style: HeroIconStyle.outline,
                                      size: 16,
                                      color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Stitch: ${_formatDuration(_clipDuration)} ya @${widget.originalPost.user?.username ?? 'user'} + video yako',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Recording indicator
                          if (_isRecording)
                            Positioned(
                              right: 12,
                              top: 40,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
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
                            ),
                        ],
                      )
                    : const Center(
                        child:
                            CircularProgressIndicator(color: _kAccent)),
              ),
            ),
            // Record controls
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flip camera
                  _StitchControlButton(
                    icon: Icons.flip_camera_ios_rounded,
                    label: 'Geuza',
                    onTap: _isRecording ? null : _flipCamera,
                  ),
                  // Mic
                  _StitchControlButton(
                    icon: _micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    label: _micEnabled ? 'Mic On' : 'Mic Off',
                    onTap: _isRecording ? null : _toggleMic,
                    active: _micEnabled,
                  ),
                  // Record button
                  GestureDetector(
                    onTap:
                        _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isRecording ? 28 : 56,
                          height: _isRecording ? 28 : 56,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                                _isRecording ? 6 : 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Spacers for symmetry
                  const SizedBox(width: 56),
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== STEP 3: PREVIEW ====================

  Widget _buildPreviewStep() {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildStepTopBar(
              title: 'Hakiki Stitch',
              onBack: _retakeRecording,
            ),
            // Preview info
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeroIcon(HeroIcons.scissors,
                          style: HeroIconStyle.outline,
                          size: 48,
                          color: Colors.amber),
                      const SizedBox(height: 16),
                      const Text('Stitch',
                          style: TextStyle(
                              color: _kAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Sequence visualization
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Original clip
                            Expanded(
                              flex: _clipDuration.inSeconds.clamp(1, 5),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(8)),
                                  border: Border.all(
                                      color: Colors.amber, width: 1),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.play_arrow_rounded,
                                          color: Colors.amber, size: 18),
                                      Text(
                                        _formatDuration(_clipDuration),
                                        style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Arrow
                            Container(
                              width: 24,
                              height: 56,
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Center(
                                child: Icon(Icons.arrow_forward_rounded,
                                    color: _kMuted, size: 16),
                              ),
                            ),
                            // Your recording
                            Expanded(
                              flex: _recordingDuration.inSeconds.clamp(1, 55),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _kAccent.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(8)),
                                  border:
                                      Border.all(color: _kMuted, width: 1),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.videocam_rounded,
                                          color: _kAccent, size: 18),
                                      Text(
                                        _formatDuration(_recordingDuration),
                                        style: const TextStyle(
                                            color: _kAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '@${widget.originalPost.user?.username ?? 'user'}',
                            style: const TextStyle(
                                color: _kMuted, fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _kAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('Wewe',
                              style:
                                  TextStyle(color: _kMuted, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Video zitaunganishwa na server',
                        style: TextStyle(color: _kMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Caption
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: _kMinTouch,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _retakeRecording,
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
                  Expanded(
                    child: SizedBox(
                      height: _kMinTouch,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadStitch,
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
                        label: Text(
                            _isUploading ? _uploadStatus : 'Chapisha'),
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

  // --- Shared widgets ---

  Widget _buildStepTopBar({
    required String title,
    required VoidCallback onBack,
    Widget? trailing,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: HeroIcon(HeroIcons.arrowLeft,
                style: HeroIconStyle.outline, size: 24, color: _kAccent),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: _kAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

class _StitchControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  const _StitchControlButton({
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
                color: active
                    ? Colors.white12
                    : Colors.white.withValues(alpha: 0.05),
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
