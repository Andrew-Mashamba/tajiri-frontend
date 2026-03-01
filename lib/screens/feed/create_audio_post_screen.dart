import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/post_models.dart';
import '../../models/draft_models.dart';
import '../../services/post_service.dart';
import '../../services/draft_service.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/mention_text_field.dart';
import '../../widgets/schedule_post_widget.dart';
import 'schedulepostwidget_screen.dart';

/// Audio post creation screen with recording, drafts and scheduling
/// Recording/playback use flutter_sound (skipped on macOS where unsupported)
class CreateAudioPostScreen extends StatefulWidget {
  final int currentUserId;
  final String? userName;
  final String? userPhotoUrl;
  final PostDraft? draft;

  const CreateAudioPostScreen({
    super.key,
    required this.currentUserId,
    this.userName,
    this.userPhotoUrl,
    this.draft,
  });

  @override
  State<CreateAudioPostScreen> createState() => _CreateAudioPostScreenState();
}

class _CreateAudioPostScreenState extends State<CreateAudioPostScreen>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final DraftService _draftService = DraftService();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Audio recorder (flutter_sound not available on macOS)
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerSubscription;

  File? _audioFile;
  File? _coverImage;
  PostPrivacy _privacy = PostPrivacy.public;
  bool _isPosting = false;
  bool _isSavingDraft = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordingDuration = 0;
  int _playbackPosition = 0;
  int _playbackDuration = 0;
  Timer? _recordingTimer;
  DateTime? _scheduledAt;
  int? _draftId;
  List<double> _waveformData = [];
  String? _recordedFilePath;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initRecorder();
    _initPlayer();
    _generatePlaceholderWaveform();
    _initializeFromDraft();
  }

  Future<void> _initRecorder() async {
    if (Platform.isMacOS) {
      debugPrint('[Audio] Recorder initialization skipped - flutter_sound not available on macOS');
      return;
    }
    _recorder = FlutterSoundRecorder();
    try {
      await _recorder!.openRecorder();
      _isRecorderInitialized = true;

      // Subscribe to recorder state
      _recorderSubscription = _recorder!.onProgress?.listen((e) {
        if (mounted) {
          setState(() {
            _recordingDuration = e.duration.inSeconds;
            // Add waveform data based on decibels
            final db = e.decibels ?? 0;
            final normalized = ((db + 60) / 60).clamp(0.1, 1.0);
            _waveformData.add(normalized);
            if (_waveformData.length > 50) {
              _waveformData.removeAt(0);
            }
          });
        }
      });

      await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Failed to init recorder: $e');
    }
  }

  Future<void> _initPlayer() async {
    if (Platform.isMacOS) {
      debugPrint('[Audio] Player initialization skipped - flutter_sound not available on macOS');
      return;
    }
    _player = FlutterSoundPlayer();
    try {
      await _player!.openPlayer();
      _isPlayerInitialized = true;

      _playerSubscription = _player!.onProgress?.listen((e) {
        if (mounted) {
          setState(() {
            _playbackPosition = e.position.inSeconds;
            _playbackDuration = e.duration.inSeconds;
          });
        }
      });

      await _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Failed to init player: $e');
    }
  }

  void _initializeFromDraft() {
    if (widget.draft != null) {
      _contentController.text = widget.draft!.content ?? '';
      _privacy = PostPrivacy.values.firstWhere(
        (p) => p.value == widget.draft!.privacy,
        orElse: () => PostPrivacy.public,
      );
      _scheduledAt = widget.draft!.scheduledAt;
      _draftId = widget.draft!.id;
      if (widget.draft!.audioWaveform != null) {
        _waveformData = widget.draft!.audioWaveform!;
      }
      _recordingDuration = widget.draft!.audioDuration ?? 0;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _recorderSubscription?.cancel();
    _playerSubscription?.cancel();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _draftService.dispose();
    super.dispose();
  }

  void _generatePlaceholderWaveform() {
    _waveformData = List.generate(50, (i) => 0.3 + 0.2 * (i % 5 == 0 ? 1 : 0));
  }

  bool get _canPost =>
      _audioFile != null || (_recordedFilePath != null && _recordingDuration > 0);
  bool get _hasChanges =>
      _audioFile != null ||
      _recordedFilePath != null ||
      _contentController.text.trim().isNotEmpty ||
      _coverImage != null;

  Future<void> _startRecording() async {
    if (Platform.isMacOS) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio recording is not available on macOS. Please use "Select audio from device" instead.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!_isRecorderInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recorder not ready. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Stop any playback
      if (_isPlaying) {
        await _stopPlayback();
      }

      // Get temp directory for recording
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordedFilePath = '${tempDir.path}/audio_$timestamp.aac';

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _waveformData = [];
        _audioFile = null;
      });

      await _recorder!.startRecorder(
        toFile: _recordedFilePath,
        codec: Codec.aacADTS,
      );
    } catch (e) {
      debugPrint('Failed to start recording: $e');
      if (mounted) {
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    if (Platform.isMacOS) {
      setState(() => _isRecording = false);
      return;
    }
    try {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        if (path != null && _recordingDuration > 0) {
          _audioFile = File(path);
          _recordedFilePath = path;
        }
      });

      if (_recordingDuration > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recorded ${_formatDuration(_recordingDuration)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to stop recording: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _playRecording() async {
    if (Platform.isMacOS) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio playback preview is not available on macOS. Your audio will work once posted.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    if (_recordedFilePath == null || !_isPlayerInitialized) return;

    try {
      setState(() => _isPlaying = true);

      await _player!.startPlayer(
        fromURI: _recordedFilePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _playbackPosition = 0;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Failed to play recording: $e');
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _stopPlayback() async {
    setState(() {
      _isPlaying = false;
      _playbackPosition = 0;
    });
    if (Platform.isMacOS) return;
    try {
      await _player?.stopPlayer();
    } catch (e) {
      debugPrint('Failed to stop playback: $e');
    }
  }

  void _deleteRecording() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text(
          'Are you sure you want to delete this recording? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _audioFile = null;
                _recordedFilePath = null;
                _recordingDuration = 0;
                _playbackPosition = 0;
                _generatePlaceholderWaveform();
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDurationFromFile(File file) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(file.path);
      final duration = player.duration;
      await player.dispose();
      if (mounted && duration != null) {
        setState(() => _recordingDuration = duration.inSeconds);
      }
    } catch (e) {
      debugPrint('Could not get audio duration: $e');
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final audioFile = File(file.path!);
          setState(() {
            _audioFile = audioFile;
            _recordedFilePath = file.path;
            _recordingDuration = 0;
            _generatePlaceholderWaveform();
          });
          await _loadDurationFromFile(audioFile);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected: ${file.name}'),
                backgroundColor: const Color(0xFF1A1A1A),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to pick audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCoverImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _coverImage = File(image.path));
    }
  }

  Future<void> _createPost() async {
    if (!_canPost) return;
    setState(() => _isPosting = true);

    try {
      final result = await _postService.createPost(
        userId: widget.currentUserId,
        content: _contentController.text.trim().isNotEmpty
            ? _contentController.text.trim()
            : null,
        privacy: _privacy.value,
        postType: 'audio',
        audioFile: _audioFile,
        audioDuration: _recordingDuration > 0 ? _recordingDuration : null,
        coverImage: _coverImage,
      );

      if (mounted) {
        setState(() => _isPosting = false);
        if (result.success) {
          if (_draftId != null) await _draftService.deleteDraft(_draftId!);
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Failed to create post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
        postType: DraftPostType.audio,
        content: _contentController.text.trim().isNotEmpty
            ? _contentController.text.trim()
            : null,
        privacy: _privacy.value,
        scheduledAt: _scheduledAt,
        audioFile: _audioFile,
        coverImage: _coverImage,
      );

      if (result.success && result.draft?.id != null) {
        final publishResult =
            await _draftService.publishDraft(result.draft!.id!);
        if (mounted) {
          setState(() => _isPosting = false);
          if (publishResult.success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(publishResult.message ?? 'Post scheduled'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(publishResult.message ?? 'Failed to schedule'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
        postType: DraftPostType.audio,
        content: _contentController.text.trim().isNotEmpty
            ? _contentController.text.trim()
            : null,
        privacy: _privacy.value,
        scheduledAt: _scheduledAt,
        audioFile: _audioFile,
        coverImage: _coverImage,
      );

      if (mounted) {
        setState(() {
          _isSavingDraft = false;
          if (result.success && result.draft != null) {
            _draftId = result.draft!.id;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result.success ? 'Draft saved' : (result.message ?? 'Failed to save')),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<bool> _onWillPop() async {
    // Stop any recording or playback
    if (_isRecording) await _stopRecording();
    if (_isPlaying) await _stopPlayback();

    if (!_hasChanges) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Draft?'),
        content: const Text(
          'You have unsaved changes. Would you like to save them as a draft?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save Draft'),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _saveDraft();
      return true;
    }
    return result == 'discard';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Who can see this?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            _buildPrivacyOption(
              Icons.public,
              'Public',
              'Everyone can see',
              PostPrivacy.public,
              Colors.green,
            ),
            _buildPrivacyOption(
              Icons.group,
              'Friends',
              'Only friends can see',
              PostPrivacy.friends,
              Colors.blue,
            ),
            _buildPrivacyOption(
              Icons.star,
              'Subscribers Only',
              'Only your subscribers can see',
              PostPrivacy.subscribers,
              Colors.amber,
            ),
            _buildPrivacyOption(
              Icons.lock,
              'Private',
              'Only you can see',
              PostPrivacy.private,
              Colors.orange,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(
    IconData icon,
    String title,
    String subtitle,
    PostPrivacy privacy,
    Color color,
  ) {
    final isSelected = _privacy == privacy;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? color : Colors.grey.shade600,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      onTap: () {
        setState(() => _privacy = privacy);
        Navigator.pop(context);
      },
    );
  }

  static const Color _primaryBg = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _accent = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allowPop = await _onWillPop();
        if (allowPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _primaryBg,
        appBar: AppBar(
          title: const Text('Audio Post'),
          backgroundColor: Colors.white,
          foregroundColor: _primaryText,
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _isSavingDraft ? null : _saveDraft,
                icon: _isSavingDraft
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: const Text('Save'),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _canPost && !_isPosting
                    ? (_scheduledAt != null ? _schedulePost : _createPost)
                    : null,
                child: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_scheduledAt != null ? 'Schedule' : 'Post'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info row
                    Row(
                      children: [
                        UserAvatar(
                          photoUrl: widget.userPhotoUrl,
                          name: widget.userName,
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName ?? 'User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildPrivacyButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recording section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _audioFile != null
                              ? _accent
                              : _primaryText.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Waveform
                          Container(
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: CustomPaint(
                              size: const Size(double.infinity, 80),
                              painter: WaveformPainter(
                                waveformData: _waveformData,
                                color: _audioFile != null
                                    ? _primaryText
                                    : _accent,
                                isRecording: _isRecording,
                                playbackProgress: _playbackDuration > 0
                                    ? _playbackPosition / _playbackDuration
                                    : 0,
                              ),
                            ),
                          ),

                          // Duration display
                          Text(
                            _isPlaying
                                ? '${_formatDuration(_playbackPosition)} / ${_formatDuration(_playbackDuration)}'
                                : _formatDuration(_recordingDuration),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _isRecording
                                  ? _primaryText
                                  : _audioFile != null
                                      ? _primaryText
                                      : _accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRecording
                                ? 'Recording...'
                                : _audioFile != null
                                    ? 'Audio ready'
                                    : 'Tap to record',
                            style: TextStyle(
                              color: _audioFile != null
                                  ? _primaryText
                                  : _accent,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Controls
                          if (_audioFile != null) ...[
                            // Playback controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Play/Pause button
                                Semantics(
                                  button: true,
                                  label: _isPlaying ? 'Pause' : 'Play',
                                  child: GestureDetector(
                                    onTap: _isPlaying
                                        ? _stopPlayback
                                        : _playRecording,
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _primaryText,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _primaryText.withOpacity(0.2),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isPlaying ? Icons.pause : Icons.play_arrow,
                                        size: 36,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Delete button
                                Semantics(
                                  button: true,
                                  label: 'Delete recording',
                                  child: GestureDetector(
                                    onTap: _deleteRecording,
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      constraints: const BoxConstraints(
                                        minWidth: 48,
                                        minHeight: 48,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _primaryBg,
                                        border: Border.all(
                                          color: _accent,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        size: 28,
                                        color: _primaryText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Recording button
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) => Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRecording
                                      ? Colors.red
                                          .withOpacity(0.1 + 0.1 * _pulseController.value)
                                      : Colors.transparent,
                                ),
                                child: child,
                              ),
                              child: Semantics(
                                button: true,
                                label: _isRecording ? 'Stop recording' : 'Start recording',
                                child: GestureDetector(
                                  onTap: _isRecording
                                      ? _stopRecording
                                      : _startRecording,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isRecording
                                          ? _primaryText
                                          : _accent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryText.withOpacity(0.2),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select from device button (min 48dp touch target)
                    Center(
                      child: SizedBox(
                        height: 48,
                        child: TextButton.icon(
                          onPressed: _pickAudioFile,
                          icon: const Icon(Icons.folder_open, size: 24),
                          label: const Text('or select audio from device'),
                          style: TextButton.styleFrom(
                            foregroundColor: _primaryText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cover image section
                    const Text(
                      'Cover Image (Optional)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          image: _coverImage != null
                              ? DecorationImage(
                                  image: FileImage(_coverImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _coverImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add cover image',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              )
                            : Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _coverImage = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Caption
                    const Text(
                      'Caption (Optional)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    MentionTextField(
                      controller: _contentController,
                      currentUserId: widget.currentUserId,
                      maxLines: null,
                      minLines: 3,
                      hintText: 'Write a caption... @ # (optional)',
                      decoration: InputDecoration(
                        hintText: 'Write a caption for your audio... @ #',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // Schedule widget (Story 85)
                    SchedulePostWidget(
                      initialScheduledAt: _scheduledAt,
                      onScheduleChanged: (date) =>
                          setState(() => _scheduledAt = date),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      button: true,
                      label: 'Open full screen date and time picker',
                      child: InkWell(
                        onTap: () async {
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.open_in_full,
                                size: 20,
                                color: const Color(0xFF666666),
                              ),
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
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPrivacyButton() {
    final color = _getPrivacyColor(_privacy);
    return InkWell(
      onTap: _showPrivacyPicker,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getPrivacyIcon(_privacy), size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              _getPrivacyLabel(_privacy),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ),
      ),
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

  Color _getPrivacyColor(PostPrivacy p) {
    switch (p) {
      case PostPrivacy.public: return Colors.green;
      case PostPrivacy.friends: return Colors.blue;
      case PostPrivacy.subscribers: return Colors.amber;
      case PostPrivacy.private: return Colors.orange;
    }
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  final bool isRecording;
  final double playbackProgress;

  WaveformPainter({
    required this.waveformData,
    required this.color,
    this.isRecording = false,
    this.playbackProgress = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) {
      final placeholderPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 50; i++) {
        final x = (size.width / 50) * i + 2;
        final height = 10 + (i % 4) * 5.0;
        canvas.drawLine(
          Offset(x, size.height / 2 - height / 2),
          Offset(x, size.height / 2 + height / 2),
          placeholderPaint,
        );
      }
      return;
    }

    final barWidth = size.width / waveformData.length;
    final playedIndex = (playbackProgress * waveformData.length).toInt();

    for (int i = 0; i < waveformData.length; i++) {
      final paint = Paint()
        ..color = i < playedIndex
            ? color
            : isRecording
                ? color
                : color.withOpacity(0.5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final x = barWidth * i + barWidth / 2;
      final amplitude = waveformData[i].clamp(0.0, 1.0);
      final barHeight = amplitude * size.height * 0.8;
      canvas.drawLine(
        Offset(x, (size.height - barHeight) / 2),
        Offset(x, (size.height + barHeight) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      oldDelegate.waveformData != waveformData ||
      oldDelegate.isRecording != isRecording ||
      oldDelegate.playbackProgress != playbackProgress;
}
