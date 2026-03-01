import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../services/resumable_upload_service.dart';

/// Video upload screen with resumable upload support
/// Features:
/// - Chunked uploads for large files
/// - Pause/resume functionality
/// - Resume interrupted uploads
/// - Video preview and caption
/// - Privacy settings
class UploadVideoScreen extends StatefulWidget {
  final int userId;
  final File? initialVideo;
  final String? resumeUploadId; // For resuming an existing upload
  final VoidCallback? onUploadComplete;

  const UploadVideoScreen({
    super.key,
    required this.userId,
    this.initialVideo,
    this.resumeUploadId,
    this.onUploadComplete,
  });

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final ResumableUploadService _uploadService = ResumableUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();

  File? _videoFile;
  File? _thumbnailFile;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Upload state
  bool _isUploading = false;
  UploadProgress? _uploadProgress;
  String? _uploadId;
  bool _showResumableUploads = false;
  List<ResumableUploadInfo> _resumableUploads = [];

  // Settings
  String _privacy = 'public';
  bool _allowComments = true;
  bool _allowDuet = true;
  bool _allowDownload = true;

  // Detected hashtags
  List<String> _hashtags = [];

  @override
  void initState() {
    super.initState();
    _initializeService();
    if (widget.initialVideo != null) {
      _setVideo(widget.initialVideo!);
    }
    _captionController.addListener(_detectHashtags);

    // Check for resumable uploads
    _loadResumableUploads();

    // Resume existing upload if provided
    if (widget.resumeUploadId != null) {
      _resumeUpload(widget.resumeUploadId!);
    }
  }

  Future<void> _initializeService() async {
    await _uploadService.initialize();
  }

  Future<void> _loadResumableUploads() async {
    final uploads = await _uploadService.getResumableUploads(widget.userId);
    if (mounted) {
      setState(() {
        _resumableUploads = uploads.where((u) => !u.isExpired).toList();
        _showResumableUploads = _resumableUploads.isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _detectHashtags() {
    final text = _captionController.text;
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);
    setState(() {
      _hashtags = matches.map((m) => m.group(1)!).toList();
    });
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10), // Extended for large files
    );

    if (video != null) {
      _setVideo(File(video.path));
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 3),
    );

    if (video != null) {
      _setVideo(File(video.path));
    }
  }

  Future<void> _setVideo(File file) async {
    // Dispose old controller
    _videoController?.dispose();

    setState(() {
      _videoFile = file;
      _isVideoInitialized = false;
      _showResumableUploads = false;
    });

    // Initialize video controller
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();
    await _videoController!.setLooping(true);

    setState(() {
      _isVideoInitialized = true;
    });

    // Auto-play preview
    _videoController!.play();
  }

  Future<void> _pickThumbnail() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _thumbnailFile = File(image.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = null;
      _showResumableUploads = false;
    });

    await for (final progress in _uploadService.uploadVideo(
      userId: widget.userId,
      videoFile: _videoFile!,
      thumbnailFile: _thumbnailFile,
      caption: _captionController.text.isNotEmpty ? _captionController.text : null,
      hashtags: _hashtags.isNotEmpty ? _hashtags : null,
      privacy: _privacy,
      allowComments: _allowComments,
      allowDuet: _allowDuet,
      allowDownload: _allowDownload,
    )) {
      if (!mounted) return;

      setState(() {
        _uploadProgress = progress;
        _uploadId = progress.uploadId;
      });

      if (progress.isComplete) {
        widget.onUploadComplete?.call();
        Navigator.pop(context, progress.clip);
      } else if (progress.isFailed) {
        setState(() {
          _isUploading = false;
        });

        if (progress.canResume) {
          // Show resume option
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(progress.message),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Endelea',
                textColor: Colors.white,
                onPressed: () => _resumeUpload(progress.uploadId!),
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(progress.error ?? 'Imeshindwa kupakia video'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (progress.isPaused) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imesimamishwa - ${progress.progress.round()}%'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Endelea',
              textColor: Colors.white,
              onPressed: () => _resumeUpload(progress.uploadId!),
            ),
          ),
        );
      }
    }
  }

  Future<void> _resumeUpload(String uploadId) async {
    // Get saved state
    final savedState = await _uploadService.getSavedUploadState(uploadId);
    if (savedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Haikupata taarifa za kupakia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if file still exists
    final file = File(savedState.filePath);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video haipo tena'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = null;
      _showResumableUploads = false;
      _uploadId = uploadId;
    });

    // Resume with existing upload ID
    await for (final progress in _uploadService.uploadVideo(
      userId: savedState.userId,
      videoFile: file,
      thumbnailFile: savedState.thumbnailPath != null ? File(savedState.thumbnailPath!) : null,
      caption: savedState.caption,
      hashtags: savedState.hashtags,
      privacy: savedState.privacy,
      allowComments: savedState.allowComments,
      allowDuet: savedState.allowDuet,
      allowDownload: savedState.allowDownload,
      existingUploadId: uploadId,
    )) {
      if (!mounted) return;

      setState(() {
        _uploadProgress = progress;
      });

      if (progress.isComplete) {
        widget.onUploadComplete?.call();
        Navigator.pop(context, progress.clip);
      } else if (progress.isFailed) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(progress.error ?? 'Imeshindwa kupakia video'),
            backgroundColor: Colors.red,
            action: progress.canResume
                ? SnackBarAction(
                    label: 'Jaribu tena',
                    textColor: Colors.white,
                    onPressed: () => _resumeUpload(uploadId),
                  )
                : null,
          ),
        );
      }
    }
  }

  void _pauseUpload() {
    if (_uploadId != null) {
      _uploadService.pauseUpload(_uploadId!);
    }
  }

  Future<void> _cancelUpload() async {
    if (_uploadId != null) {
      await _uploadService.cancelUpload(_uploadId!);
    }
    setState(() {
      _isUploading = false;
      _uploadProgress = null;
      _uploadId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Pakia Video'),
        actions: [
          if (_videoFile != null && !_isUploading)
            TextButton(
              onPressed: _uploadVideo,
              child: const Text(
                'Chapisha',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _isUploading ? _buildUploadProgress() : _buildEditor(),
    );
  }

  Widget _buildUploadProgress() {
    final progress = _uploadProgress;
    final progressValue = progress != null ? progress.progress / 100.0 : 0.0;
    final isRetrying = progress?.state == UploadState.retrying;
    final isResuming = progress?.state == UploadState.resuming;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress circle
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress?.isProcessing == true ? null : progressValue,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress?.isProcessing == true
                          ? Colors.orange
                          : isRetrying
                              ? Colors.yellow
                              : isResuming
                                  ? Colors.green
                                  : Colors.blue,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${progress?.progress.round() ?? 0}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (progress?.chunkText.isNotEmpty == true)
                          Text(
                            progress!.chunkText,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Status message
            Text(
              progress?.message ?? 'Inapakia...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Progress details
            if (progress != null && progress.isUploading) ...[
              Text(
                progress.progressText,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              if (progress.speedText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.speed, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      progress.speedText,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    if (progress.etaText.isNotEmpty) ...[
                      Text(
                        ' • ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Icon(Icons.timer, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        progress.etaText,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
            const SizedBox(height: 16),
            // State indicator
            _buildStateIndicator(),
            const SizedBox(height: 32),
            // Control buttons
            if (progress?.isUploading == true ||
                progress?.state == UploadState.preparing ||
                progress?.state == UploadState.resuming)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pause button
                  OutlinedButton.icon(
                    onPressed: _pauseUpload,
                    icon: const Icon(Icons.pause),
                    label: const Text('Simamisha'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Cancel button
                  OutlinedButton.icon(
                    onPressed: _cancelUpload,
                    icon: const Icon(Icons.close),
                    label: const Text('Ghairi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIndicator() {
    final states = [
      ('Kuandaa', UploadState.preparing, Icons.hourglass_empty),
      ('Kupakia', UploadState.uploading, Icons.cloud_upload),
      ('Kuchakata', UploadState.processing, Icons.memory),
      ('Tayari', UploadState.completed, Icons.check_circle),
    ];

    final currentState = _uploadProgress?.state;
    int currentIndex = states.indexWhere((s) => s.$2 == currentState);
    if (currentIndex == -1) currentIndex = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: states.asMap().entries.map((entry) {
        final index = entry.key;
        final state = entry.value;
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.blue : Colors.grey.shade800,
                    border: isCurrent
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Icon(
                    state.$3,
                    size: 16,
                    color: isActive ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.$1,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.white : Colors.grey,
                  ),
                ),
              ],
            ),
            if (index < states.length - 1)
              Container(
                width: 40,
                height: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: isActive ? Colors.blue : Colors.grey.shade800,
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEditor() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Resumable uploads banner
          if (_showResumableUploads && _resumableUploads.isNotEmpty)
            _buildResumableUploadsBanner(),

          // Video preview or picker
          _videoFile == null ? _buildVideoPicker() : _buildVideoPreview(),

          // Caption and settings
          if (_videoFile != null) ...[
            _buildCaptionInput(),
            _buildThumbnailPicker(),
            _buildPrivacySettings(),
            _buildInteractionSettings(),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildResumableUploadsBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_sync, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Una video ambazo hazijakamilika kupakiwa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showResumableUploads = false),
                icon: const Icon(Icons.close, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._resumableUploads.map((upload) => _buildResumableUploadItem(upload)),
        ],
      ),
    );
  }

  Widget _buildResumableUploadItem(ResumableUploadInfo upload) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Progress indicator
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: upload.progress / 100,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey.shade700,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                Center(
                  child: Text(
                    '${upload.progress.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upload.filename,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  upload.progressText,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          // Resume button
          ElevatedButton(
            onPressed: () => _resumeUpload(upload.uploadId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Endelea'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPicker() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'Chagua video',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Inasaidia video kubwa hadi GB 2',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galari'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _recordVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Rekodi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVideoInitialized && _videoController != null)
              GestureDetector(
                onTap: () {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                  setState(() {});
                },
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            // Play/pause overlay
            if (_isVideoInitialized)
              Center(
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                  ),
                ),
              ),

            // Change video button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: _pickVideo,
                icon: const Icon(Icons.refresh, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),

            // File size badge
            if (_videoFile != null)
              Positioned(
                top: 8,
                left: 8,
                child: FutureBuilder<int>(
                  future: _videoFile!.length(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final sizeMB = snapshot.data! / (1024 * 1024);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${sizeMB.toStringAsFixed(1)} MB',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),

            // Duration badge
            if (_isVideoInitialized)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(_videoController!.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _captionController,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Andika maelezo... #hashtag',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          // Detected hashtags
          if (_hashtags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _hashtags.map((tag) {
                return Chip(
                  label: Text('#$tag'),
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(color: Colors.blue),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    final text = _captionController.text;
                    _captionController.text = text.replaceAll('#$tag', '').trim();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnailPicker() {
    return ListTile(
      leading: Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          image: _thumbnailFile != null
              ? DecorationImage(
                  image: FileImage(_thumbnailFile!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _thumbnailFile == null
            ? const Icon(Icons.image, color: Colors.grey)
            : null,
      ),
      title: const Text('Picha ya Jalada', style: TextStyle(color: Colors.white)),
      subtitle: Text(
        _thumbnailFile != null ? 'Imechaguliwa' : 'Chagua picha ya jalada',
        style: TextStyle(color: Colors.grey.shade500),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: _pickThumbnail,
    );
  }

  Widget _buildPrivacySettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Faragha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...['public', 'friends', 'subscribers', 'private'].map((value) {
            final labels = {
              'public': ('Wote', 'Kila mtu anaweza kuona'),
              'friends': ('Marafiki', 'Marafiki tu wanaweza kuona'),
              'subscribers': ('Wasajili Pekee', 'Wasajili wako tu wanaweza kuona'),
              'private': ('Binafsi', 'Wewe tu unaweza kuona'),
            };
            final (title, subtitle) = labels[value]!;

            return RadioListTile<String>(
              value: value,
              groupValue: _privacy,
              onChanged: (v) => setState(() => _privacy = v!),
              title: Text(title, style: TextStyle(color: value == 'subscribers' ? const Color(0xFFF59E0B) : Colors.white)),
              subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              activeColor: value == 'subscribers' ? const Color(0xFFF59E0B) : Colors.blue,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInteractionSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mipangilio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SwitchListTile(
            value: _allowComments,
            onChanged: (v) => setState(() => _allowComments = v),
            title: const Text('Ruhusu maoni', style: TextStyle(color: Colors.white)),
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _allowDuet,
            onChanged: (v) => setState(() => _allowDuet = v),
            title: const Text('Ruhusu Duet', style: TextStyle(color: Colors.white)),
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _allowDownload,
            onChanged: (v) => setState(() => _allowDownload = v),
            title: const Text('Ruhusu kupakua', style: TextStyle(color: Colors.white)),
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
