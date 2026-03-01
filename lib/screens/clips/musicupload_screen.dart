import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/music_service.dart';

/// Music upload screen (Story 56).
/// Path: Home → Profile → Music tab → Upload button → MusicUploadScreen.
/// Uses chunked upload for large files, then POST finalize-upload.
/// Design: DOCS/DESIGN.md (monochrome, 48dp touch targets, SafeArea).
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

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  String? _currentFileName;
  String? _tempUploadId;

  @override
  void dispose() {
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
      final extractResult = await _musicService.uploadChunked(
        audioFile,
        widget.currentUserId,
        onProgress: (progress, status) {
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

      final title = extractResult.metadata?.title?.isNotEmpty == true
          ? extractResult.metadata!.title!
          : fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      setState(() {
        _uploadProgress = 0.92;
        _uploadStatus = 'Inahifadhi...';
      });

      final finalizeResult = await _musicService.finalizeUpload(
        tempUploadId: _tempUploadId!,
        userId: widget.currentUserId,
        title: title,
        album: extractResult.metadata?.album,
        genre: extractResult.metadata?.genre,
        bpm: extractResult.metadata?.bpm,
      );

      if (!finalizeResult.success) {
        throw Exception(finalizeResult.message ?? 'Imeshindikana kuhifadhi');
      }

      _tempUploadId = null;

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Imekamilika!';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        widget.onUploadComplete?.call();
        Navigator.pop(context, finalizeResult.track);
      }
    } catch (e) {
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Pakia Muziki',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _isUploading ? _buildUploadProgress() : _buildFilePicker(),
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note,
              size: 64,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pakia Muziki',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chagua faili ya muziki kupakia.\nTaarifa zitasomwa moja kwa moja.',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          const Text(
            'MP3, WAV, AAC, M4A, OGG, FLAC • Hadi MB 50',
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 32),
          _buildPickFileButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPickFileButton() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: _pickAndUpload,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Icons.folder_open,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chagua Faili',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'MP3, WAV, M4A na kadhalika',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    final percent = (_uploadProgress * 100).round();
    final isComplete = percent >= 100;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.08),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFF999999).withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                ),
                Center(
                  child: isComplete
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF1A1A1A),
                          size: 56,
                        )
                      : Text(
                          '$percent%',
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _uploadStatus,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (_currentFileName != null)
            Text(
              _currentFileName!,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              backgroundColor: const Color(0xFF999999).withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isComplete ? 'Muziki umepakiwa!' : 'Tafadhali subiri...',
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
