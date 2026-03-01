import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/music_service.dart';

/// Streamlined Music Upload Screen with automatic upload
/// Features:
/// - Pick file → Upload → Done (no review step)
/// - Auto-extract metadata from audio file
/// - Auto-finalize immediately after extraction
class MusicUploadScreen extends StatefulWidget {
  final int currentUserId;
  final VoidCallback? onUploadComplete;

  const MusicUploadScreen({
    super.key,
    required this.currentUserId,
    this.onUploadComplete,
  });

  @override
  State<MusicUploadScreen> createState() => _MusicUploadScreenState();
}

class _MusicUploadScreenState extends State<MusicUploadScreen> {
  final MusicService _musicService = MusicService();

  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  String? _currentFileName;

  // Privacy setting
  String _privacy = 'public';

  // For cleanup on cancel
  String? _tempUploadId;

  @override
  void dispose() {
    // Cancel upload if user leaves during upload
    if (_tempUploadId != null) {
      _musicService.cancelUpload(_tempUploadId!, widget.currentUserId);
    }
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final audioFile = File(result.files.single.path!);
      final fileName = result.files.single.name;

      await _uploadFile(audioFile, fileName);
    }
  }

  Future<void> _uploadFile(File audioFile, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Inaandaa...';
      _currentFileName = fileName;
    });

    try {
      // Step 1: Upload using chunked upload for real progress tracking
      print('🎵 [MusicUpload] Starting chunked upload: $fileName');

      final extractResult = await _musicService.uploadChunked(
        audioFile,
        widget.currentUserId,
        onProgress: (progress, status) {
          // Real progress from chunked upload
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
              _uploadStatus = status;
            });
          }
        },
      );

      if (!extractResult.success) {
        throw Exception(extractResult.message ?? 'Imeshindikana kupakia');
      }

      _tempUploadId = extractResult.tempUploadId;
      print('🎵 [MusicUpload] Upload success. Temp ID: $_tempUploadId');

      // Get title from metadata or filename
      final title = extractResult.metadata?.title?.isNotEmpty == true
          ? extractResult.metadata!.title!
          : fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      // Step 2: Finalize upload
      setState(() {
        _uploadProgress = 0.92;
        _uploadStatus = 'Inahifadhi...';
      });

      print('🎵 [MusicUpload] Finalizing with title: $title');

      final finalizeResult = await _musicService.finalizeUpload(
        tempUploadId: _tempUploadId!,
        userId: widget.currentUserId,
        title: title,
        album: extractResult.metadata?.album,
        genre: extractResult.metadata?.genre,
        bpm: extractResult.metadata?.bpm,
        privacy: _privacy,
      );

      if (!finalizeResult.success) {
        throw Exception(finalizeResult.message ?? 'Imeshindikana kuhifadhi');
      }

      // Success!
      _tempUploadId = null; // Clear so dispose doesn't cancel

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Imekamilika!';
      });

      print('🎵 [MusicUpload] ✅ Upload complete!');

      // Show success briefly then close
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        widget.onUploadComplete?.call();
        Navigator.pop(context, finalizeResult.track);
      }

    } catch (e) {
      print('🎵 [MusicUpload] ❌ Error: $e');

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pakia Muziki'),
      ),
      body: SafeArea(
        child: _isUploading ? _buildUploadProgress() : _buildFilePicker(),
      ),
    );
  }

  Widget _buildFilePicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note,
                size: 64,
                color: Color(0xFF1DB954),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Pakia Muziki',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Chagua faili ya muziki kupakia.\nTaarifa zitasomwa moja kwa moja.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Supported formats
            Text(
              'MP3, WAV, AAC, M4A, OGG, FLAC • Hadi MB 50',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 32),

            // Privacy selector
            _buildPrivacySelector(),
            const SizedBox(height: 24),

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickAndUpload,
                icon: const Icon(Icons.folder_open, size: 22),
                label: const Text(
                  'Chagua Faili',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySelector() {
    final privacyLabels = {
      'public': ('Kila mtu', Icons.public, Colors.green),
      'friends': ('Marafiki', Icons.group, Colors.blue),
      'subscribers': ('Wasajili Pekee', Icons.star, const Color(0xFFF59E0B)),
      'private': ('Mimi Pekee', Icons.lock, Colors.orange),
    };
    final (label, icon, color) = privacyLabels[_privacy]!;

    return InkWell(
      onTap: _showPrivacyPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Faragha',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    label,
                    style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
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
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nani anaweza kusikiliza?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            _buildPrivacyOption('public', 'Kila mtu', 'Wote wanaweza kusikiliza', Icons.public, Colors.green),
            _buildPrivacyOption('friends', 'Marafiki', 'Marafiki tu wanaweza kusikiliza', Icons.group, Colors.blue),
            _buildPrivacyOption('subscribers', 'Wasajili Pekee', 'Wasajili wako tu wanaweza kusikiliza', Icons.star, const Color(0xFFF59E0B)),
            _buildPrivacyOption('private', 'Mimi Pekee', 'Wewe tu unaweza kusikiliza', Icons.lock, Colors.orange),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption(String value, String title, String subtitle, IconData icon, Color color) {
    final isSelected = _privacy == value;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isSelected ? color : Colors.grey, size: 22),
      ),
      title: Text(title, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      onTap: () {
        setState(() => _privacy = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildUploadProgress() {
    final percent = (_uploadProgress * 100).round();
    final isComplete = percent >= 100;

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
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                  ),
                  Center(
                    child: isComplete
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1DB954),
                            size: 56,
                          )
                        : Text(
                            '$percent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Status text
            Text(
              _uploadStatus,
              style: TextStyle(
                color: isComplete ? const Color(0xFF1DB954) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // File name
            if (_currentFileName != null)
              Text(
                _currentFileName!,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            // Linear progress bar
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
                minHeight: 6,
              ),
            ),

            // Hint
            const SizedBox(height: 20),
            Text(
              isComplete ? 'Muziki umepakiwa!' : 'Tafadhali subiri...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
