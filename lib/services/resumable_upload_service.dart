import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../config/api_config.dart';
import '../models/clip_models.dart' as models;

/// Professional resumable upload service with:
/// - Chunked file uploads for large videos (Story 72)
/// - Pause/resume functionality
/// - Offline state persistence
/// - Automatic retry on network failures
/// - Background upload support
///
/// API (baseUrl includes /api): POST /uploads/init, POST /uploads/{id}/chunk,
/// POST /uploads/{id}/complete; GET /uploads/{id}/status for resume.
/// See docs/BACKEND.md Story 72.
class ResumableUploadService {
  static final ResumableUploadService _instance = ResumableUploadService._internal();
  factory ResumableUploadService() => _instance;
  ResumableUploadService._internal();

  Dio? _dio;
  Box<String>? _uploadStateBox;
  final Map<String, CancelToken> _activeCancelTokens = {};
  final Map<String, StreamController<UploadProgress>> _activeControllers = {};

  static const int _defaultChunkSize = 5 * 1024 * 1024; // 5MB chunks
  static const int _maxRetries = 5;
  static const Duration _connectionTimeout = Duration(minutes: 2);
  static const Duration _receiveTimeout = Duration(minutes: 5);

  /// Initialize the service
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: _connectionTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _receiveTimeout,
      headers: {
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio!.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: true,
        logPrint: (log) => debugPrint('[ResumableUpload] $log'),
      ));
    }

    // Initialize Hive for persistent storage
    final appDir = await getApplicationDocumentsDirectory();
    Hive.init(appDir.path);
    _uploadStateBox = await Hive.openBox<String>('upload_states');
  }

  /// Start or resume a video upload
  Stream<UploadProgress> uploadVideo({
    required int userId,
    required File videoFile,
    File? thumbnailFile,
    String? caption,
    List<String>? hashtags,
    List<int>? mentions,
    String? locationName,
    double? latitude,
    double? longitude,
    String privacy = 'public',
    bool allowComments = true,
    bool allowDuet = true,
    bool allowStitch = true,
    bool allowDownload = true,
    int? originalClipId,
    String clipType = 'original',
    int? musicId,
    int? musicStart,
    String? existingUploadId, // For resuming
  }) {
    final controller = StreamController<UploadProgress>.broadcast();

    _performChunkedUpload(
      controller: controller,
      userId: userId,
      videoFile: videoFile,
      thumbnailFile: thumbnailFile,
      caption: caption,
      hashtags: hashtags,
      mentions: mentions,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      privacy: privacy,
      allowComments: allowComments,
      allowDuet: allowDuet,
      allowStitch: allowStitch,
      allowDownload: allowDownload,
      originalClipId: originalClipId,
      clipType: clipType,
      musicId: musicId,
      musicStart: musicStart,
      existingUploadId: existingUploadId,
    );

    return controller.stream;
  }

  Future<void> _performChunkedUpload({
    required StreamController<UploadProgress> controller,
    required int userId,
    required File videoFile,
    File? thumbnailFile,
    String? caption,
    List<String>? hashtags,
    List<int>? mentions,
    String? locationName,
    double? latitude,
    double? longitude,
    String privacy = 'public',
    bool allowComments = true,
    bool allowDuet = true,
    bool allowStitch = true,
    bool allowDownload = true,
    int? originalClipId,
    String clipType = 'original',
    int? musicId,
    int? musicStart,
    String? existingUploadId,
  }) async {
    if (_dio == null || _uploadStateBox == null) {
      await initialize();
    }

    String? uploadId = existingUploadId;
    CancelToken cancelToken = CancelToken();

    try {
      // Validate file exists
      if (!await videoFile.exists()) {
        controller.add(UploadProgress(
          state: UploadState.failed,
          progress: 0,
          message: 'Video file not found',
          error: 'File does not exist: ${videoFile.path}',
        ));
        await controller.close();
        return;
      }

      final fileSize = await videoFile.length();
      final totalChunks = (fileSize / _defaultChunkSize).ceil();
      final fileSizeMB = fileSize / (1024 * 1024);

      debugPrint('[ResumableUpload] File: ${videoFile.path}');
      debugPrint('[ResumableUpload] Size: ${fileSizeMB.toStringAsFixed(2)} MB');
      debugPrint('[ResumableUpload] Total chunks: $totalChunks');

      controller.add(UploadProgress(
        state: UploadState.preparing,
        progress: 0,
        message: 'Inaandaa video...',
        totalBytes: fileSize,
      ));

      // Initialize or resume upload session
      UploadSession session;

      if (uploadId != null) {
        // Resume existing upload
        debugPrint('[ResumableUpload] Resuming upload: $uploadId');
        session = await _getUploadStatus(uploadId);

        controller.add(UploadProgress(
          state: UploadState.resuming,
          progress: session.progress,
          message: 'Inaendelea kupakia... ${session.uploadedChunks}/$totalChunks chunks',
          totalBytes: fileSize,
          uploadId: uploadId,
        ));
      } else {
        // Start new upload
        debugPrint('[ResumableUpload] Starting new chunked upload');
        session = await _initUpload(
          userId: userId,
          videoFile: videoFile,
          thumbnailFile: thumbnailFile,
          caption: caption,
          hashtags: hashtags,
          mentions: mentions,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
          privacy: privacy,
          allowComments: allowComments,
          allowDuet: allowDuet,
          allowStitch: allowStitch,
          allowDownload: allowDownload,
          originalClipId: originalClipId,
          clipType: clipType,
          musicId: musicId,
          musicStart: musicStart,
        );
        uploadId = session.uploadId;
      }

      // Store cancel token (uploadId is guaranteed non-null at this point)
      _activeCancelTokens[uploadId] = cancelToken;
      _activeControllers[uploadId] = controller;

      // Save upload state for persistence
      await _saveUploadState(uploadId, UploadStateData(
        uploadId: uploadId,
        filePath: videoFile.path,
        thumbnailPath: thumbnailFile?.path,
        userId: userId,
        caption: caption,
        hashtags: hashtags,
        mentions: mentions,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        privacy: privacy,
        allowComments: allowComments,
        allowDuet: allowDuet,
        allowStitch: allowStitch,
        allowDownload: allowDownload,
        originalClipId: originalClipId,
        clipType: clipType,
        musicId: musicId,
        musicStart: musicStart,
      ));

      controller.add(UploadProgress(
        state: UploadState.uploading,
        progress: 0,
        message: 'Inapakia video... 0%',
        uploadId: uploadId,
        totalBytes: fileSize,
      ));

      // Upload chunks
      final missingChunks = session.missingChunks;
      int uploadedChunks = session.uploadedChunks;
      int uploadedBytes = session.uploadedBytes;
      DateTime startTime = DateTime.now();

      for (int chunkNumber in missingChunks) {
        if (cancelToken.isCancelled) {
          controller.add(UploadProgress(
            state: UploadState.paused,
            progress: (uploadedChunks / totalChunks * 100),
            message: 'Imesimamishwa',
            uploadId: uploadId,
            uploadedChunks: uploadedChunks,
            totalChunks: totalChunks,
            bytesSent: uploadedBytes,
            totalBytes: fileSize,
          ));
          return;
        }

        // Calculate chunk boundaries
        final start = chunkNumber * _defaultChunkSize;
        final end = (start + _defaultChunkSize > fileSize)
            ? fileSize
            : start + _defaultChunkSize;
        final chunkSize = end - start;

        // Read chunk data
        final raf = await videoFile.open();
        await raf.setPosition(start);
        final chunkData = await raf.read(chunkSize);
        await raf.close();

        // Upload chunk with retry
        bool chunkUploaded = false;
        int retryCount = 0;

        while (!chunkUploaded && retryCount < _maxRetries) {
          try {
            final formData = FormData.fromMap({
              'chunk_number': chunkNumber,
              'chunk': MultipartFile.fromBytes(
                chunkData,
                filename: 'chunk_$chunkNumber',
                contentType: DioMediaType.parse('application/octet-stream'),
              ),
            });

            final response = await _dio!.post(
              '/uploads/$uploadId/chunk',
              data: formData,
              cancelToken: cancelToken,
              onSendProgress: (sent, total) {
                // Calculate overall progress including this chunk's progress
                final chunkProgress = sent / total;
                final overallProgress = ((uploadedChunks + chunkProgress) / totalChunks * 100);
                final overallBytes = uploadedBytes + (chunkProgress * chunkSize).round();

                // Calculate speed
                final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
                final speedMBps = elapsedSeconds > 0
                    ? (overallBytes / (1024 * 1024)) / elapsedSeconds
                    : 0.0;
                final remainingBytes = fileSize - overallBytes;
                final etaSeconds = speedMBps > 0.1
                    ? (remainingBytes / (1024 * 1024) / speedMBps).round()
                    : 0;

                controller.add(UploadProgress(
                  state: UploadState.uploading,
                  progress: overallProgress,
                  message: 'Inapakia video... ${overallProgress.round()}%',
                  uploadId: uploadId,
                  uploadedChunks: uploadedChunks,
                  totalChunks: totalChunks,
                  currentChunk: chunkNumber,
                  bytesSent: overallBytes,
                  totalBytes: fileSize,
                  uploadSpeed: speedMBps,
                  estimatedTimeRemaining: etaSeconds > 0
                      ? Duration(seconds: etaSeconds)
                      : null,
                ));
              },
            );

            if (response.statusCode == 200 && response.data['success'] == true) {
              chunkUploaded = true;
              uploadedChunks++;
              uploadedBytes += chunkSize;
              debugPrint('[ResumableUpload] Chunk $chunkNumber uploaded ($uploadedChunks/$totalChunks)');
            } else {
              throw Exception('Chunk upload failed: ${response.data}');
            }
          } on DioException catch (e) {
            if (e.type == DioExceptionType.cancel) {
              // Upload was paused
              return;
            }

            retryCount++;
            if (retryCount >= _maxRetries) {
              rethrow;
            }

            // Exponential backoff
            final delay = Duration(seconds: (2 << retryCount));
            debugPrint('[ResumableUpload] Chunk $chunkNumber retry $retryCount after ${delay.inSeconds}s');

            controller.add(UploadProgress(
              state: UploadState.retrying,
              progress: (uploadedChunks / totalChunks * 100),
              message: 'Inajaribu tena chunk ${chunkNumber + 1}... ($retryCount/$_maxRetries)',
              uploadId: uploadId,
              uploadedChunks: uploadedChunks,
              totalChunks: totalChunks,
              retryCount: retryCount,
            ));

            await Future.delayed(delay);
          }
        }
      }

      // All chunks uploaded, complete the upload
      controller.add(UploadProgress(
        state: UploadState.processing,
        progress: 100,
        message: 'Inakamilisha video...',
        uploadId: uploadId,
        bytesSent: fileSize,
        totalBytes: fileSize,
      ));

      final clip = await _completeUpload(uploadId);

      // Clear saved state
      await _clearUploadState(uploadId);

      controller.add(UploadProgress(
        state: UploadState.completed,
        progress: 100,
        message: 'Video imepakiwa!',
        uploadId: uploadId,
        clip: clip,
        bytesSent: fileSize,
        totalBytes: fileSize,
      ));

    } on DioException catch (e) {
      String errorMessage;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Muda wa kuunganisha umekwisha. Angalia mtandao wako.';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Kupakia kumechukua muda mrefu. Jaribu tena.';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Server hajibu. Jaribu tena baadae.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Hitilafu ya server: ${e.response?.statusCode}';
          break;
        case DioExceptionType.cancel:
          // Paused, not an error
          return;
        case DioExceptionType.connectionError:
          errorMessage = 'Hakuna mtandao. Angalia connection yako.';
          break;
        default:
          errorMessage = 'Hitilafu: ${e.message}';
      }

      debugPrint('[ResumableUpload] Error: $errorMessage');

      controller.add(UploadProgress(
        state: UploadState.failed,
        progress: 0,
        message: errorMessage,
        uploadId: uploadId,
        error: e.toString(),
        canResume: uploadId != null,
      ));
    } catch (e, stackTrace) {
      debugPrint('[ResumableUpload] Unexpected error: $e');
      debugPrint('[ResumableUpload] Stack trace: $stackTrace');

      controller.add(UploadProgress(
        state: UploadState.failed,
        progress: 0,
        message: 'Hitilafu isiyotarajiwa: $e',
        uploadId: uploadId,
        error: e.toString(),
        canResume: uploadId != null,
      ));
    } finally {
      if (uploadId != null) {
        _activeCancelTokens.remove(uploadId);
        _activeControllers.remove(uploadId);
      }
      await controller.close();
    }
  }

  /// Initialize a new upload session
  Future<UploadSession> _initUpload({
    required int userId,
    required File videoFile,
    File? thumbnailFile,
    String? caption,
    List<String>? hashtags,
    List<int>? mentions,
    String? locationName,
    double? latitude,
    double? longitude,
    String privacy = 'public',
    bool allowComments = true,
    bool allowDuet = true,
    bool allowStitch = true,
    bool allowDownload = true,
    int? originalClipId,
    String clipType = 'original',
    int? musicId,
    int? musicStart,
  }) async {
    final fileSize = await videoFile.length();
    final fileName = videoFile.path.split('/').last;
    final mimeType = _getVideoContentType(videoFile.path);

    final response = await _dio!.post('/uploads/init', data: {
      'user_id': userId,
      'filename': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'chunk_size': _defaultChunkSize,
      'caption': caption,
      'hashtags': hashtags,
      'mentions': mentions,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'privacy': privacy,
      'allow_comments': allowComments,
      'allow_duet': allowDuet,
      'allow_stitch': allowStitch,
      'allow_download': allowDownload,
      'original_clip_id': originalClipId,
      'clip_type': clipType,
      'music_id': musicId,
      'music_start': musicStart,
    });

    final statusCode = response.statusCode ?? 0;
    if ((statusCode == 200 || statusCode == 201) && response.data['success'] == true) {
      final data = response.data['data'];
      return UploadSession(
        uploadId: data['upload_id'],
        totalChunks: data['total_chunks'],
        chunkSize: data['chunk_size'],
        uploadedChunks: 0,
        uploadedBytes: 0,
        missingChunks: List<int>.generate(data['total_chunks'], (i) => i),
        status: 'pending',
      );
    } else {
      throw Exception('Failed to initialize upload: ${response.data}');
    }
  }

  /// Get upload status from server
  Future<UploadSession> _getUploadStatus(String uploadId) async {
    final response = await _dio!.get('/uploads/$uploadId/status');
    final statusCode = response.statusCode ?? 0;

    if ((statusCode == 200 || statusCode == 201) && response.data['success'] == true) {
      final data = response.data['data'];
      return UploadSession(
        uploadId: data['upload_id'],
        totalChunks: data['total_chunks'],
        chunkSize: data['chunk_size'],
        uploadedChunks: data['uploaded_chunks'],
        uploadedBytes: data['uploaded_bytes'],
        missingChunks: List<int>.from(data['missing_chunks']),
        status: data['status'],
      );
    } else {
      throw Exception('Failed to get upload status: ${response.data}');
    }
  }

  /// Complete the upload and create the clip
  Future<models.Clip> _completeUpload(String uploadId) async {
    final response = await _dio!.post('/uploads/$uploadId/complete');
    final statusCode = response.statusCode ?? 0;

    if ((statusCode == 200 || statusCode == 201) && response.data['success'] == true) {
      // The clip data is directly in 'data', not nested under 'data.clip'
      return models.Clip.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to complete upload: ${response.data}');
    }
  }

  /// Pause an ongoing upload
  void pauseUpload(String uploadId) {
    final cancelToken = _activeCancelTokens[uploadId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('User paused upload');
      debugPrint('[ResumableUpload] Paused: $uploadId');
    }
  }

  /// Cancel an upload completely
  Future<void> cancelUpload(String uploadId) async {
    pauseUpload(uploadId);

    try {
      await _dio?.post('/uploads/$uploadId/cancel');
    } catch (e) {
      debugPrint('[ResumableUpload] Cancel API error: $e');
    }

    await _clearUploadState(uploadId);
    _activeCancelTokens.remove(uploadId);
    _activeControllers.remove(uploadId);

    debugPrint('[ResumableUpload] Cancelled: $uploadId');
  }

  /// Get list of resumable uploads for a user
  Future<List<ResumableUploadInfo>> getResumableUploads(int userId) async {
    if (_dio == null) {
      await initialize();
    }

    try {
      final response = await _dio!.get('/uploads/resumable', queryParameters: {
        'user_id': userId,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> uploads = response.data['data'];
        return uploads.map((data) => ResumableUploadInfo(
          uploadId: data['upload_id'],
          filename: data['original_filename'],
          progress: (data['uploaded_chunks'] / data['total_chunks'] * 100),
          uploadedBytes: data['uploaded_bytes'],
          totalBytes: data['total_size'],
          caption: data['caption'],
          createdAt: DateTime.parse(data['created_at']),
          expiresAt: DateTime.parse(data['expires_at']),
        )).toList();
      }
    } catch (e) {
      debugPrint('[ResumableUpload] Failed to get resumable uploads: $e');
    }

    return [];
  }

  /// Save upload state locally for persistence
  Future<void> _saveUploadState(String uploadId, UploadStateData state) async {
    await _uploadStateBox?.put(uploadId, jsonEncode(state.toJson()));
  }

  /// Get saved upload state
  Future<UploadStateData?> getSavedUploadState(String uploadId) async {
    if (_uploadStateBox == null) {
      await initialize();
    }

    final jsonStr = _uploadStateBox?.get(uploadId);
    if (jsonStr != null) {
      return UploadStateData.fromJson(jsonDecode(jsonStr));
    }
    return null;
  }

  /// Get all saved upload states
  Future<List<UploadStateData>> getAllSavedUploadStates() async {
    if (_uploadStateBox == null) {
      await initialize();
    }

    final states = <UploadStateData>[];
    for (final key in _uploadStateBox?.keys ?? []) {
      final jsonStr = _uploadStateBox?.get(key);
      if (jsonStr != null) {
        states.add(UploadStateData.fromJson(jsonDecode(jsonStr)));
      }
    }
    return states;
  }

  /// Clear saved upload state
  Future<void> _clearUploadState(String uploadId) async {
    await _uploadStateBox?.delete(uploadId);
  }

  String _getVideoContentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case '3gp':
        return 'video/3gpp';
      default:
        return 'video/mp4';
    }
  }
}

/// Upload state enum
enum UploadState {
  idle,
  preparing,
  uploading,
  resuming,
  processing,
  completed,
  failed,
  paused,
  retrying,
}

/// Upload progress data
class UploadProgress {
  final UploadState state;
  final double progress; // 0-100
  final String message;
  final String? uploadId;
  final int? uploadedChunks;
  final int? totalChunks;
  final int? currentChunk;
  final int? bytesSent;
  final int? totalBytes;
  final double? uploadSpeed; // MB/s
  final Duration? estimatedTimeRemaining;
  final models.Clip? clip;
  final String? error;
  final int? retryCount;
  final bool canResume;

  UploadProgress({
    required this.state,
    required this.progress,
    required this.message,
    this.uploadId,
    this.uploadedChunks,
    this.totalChunks,
    this.currentChunk,
    this.bytesSent,
    this.totalBytes,
    this.uploadSpeed,
    this.estimatedTimeRemaining,
    this.clip,
    this.error,
    this.retryCount,
    this.canResume = false,
  });

  bool get isComplete => state == UploadState.completed;
  bool get isFailed => state == UploadState.failed;
  bool get isPaused => state == UploadState.paused;
  bool get isUploading => state == UploadState.uploading;
  bool get isProcessing => state == UploadState.processing;

  String get progressText {
    if (bytesSent != null && totalBytes != null && totalBytes! > 0) {
      final sentMB = (bytesSent! / (1024 * 1024)).toStringAsFixed(1);
      final totalMB = (totalBytes! / (1024 * 1024)).toStringAsFixed(1);
      return '$sentMB / $totalMB MB';
    }
    return '${progress.round()}%';
  }

  String get chunkText {
    if (uploadedChunks != null && totalChunks != null) {
      return 'Chunk ${uploadedChunks! + 1}/$totalChunks';
    }
    return '';
  }

  String get speedText {
    if (uploadSpeed != null && uploadSpeed! > 0) {
      return '${uploadSpeed!.toStringAsFixed(1)} MB/s';
    }
    return '';
  }

  String get etaText {
    if (estimatedTimeRemaining != null) {
      final minutes = estimatedTimeRemaining!.inMinutes;
      final seconds = estimatedTimeRemaining!.inSeconds % 60;
      if (minutes > 0) {
        return '~${minutes}m ${seconds}s';
      }
      return '~${seconds}s';
    }
    return '';
  }
}

/// Upload session info from server
class UploadSession {
  final String uploadId;
  final int totalChunks;
  final int chunkSize;
  final int uploadedChunks;
  final int uploadedBytes;
  final List<int> missingChunks;
  final String status;

  UploadSession({
    required this.uploadId,
    required this.totalChunks,
    required this.chunkSize,
    required this.uploadedChunks,
    required this.uploadedBytes,
    required this.missingChunks,
    required this.status,
  });

  double get progress => totalChunks > 0
      ? (uploadedChunks / totalChunks * 100)
      : 0;
}

/// Resumable upload info for UI
class ResumableUploadInfo {
  final String uploadId;
  final String filename;
  final double progress;
  final int uploadedBytes;
  final int totalBytes;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;

  ResumableUploadInfo({
    required this.uploadId,
    required this.filename,
    required this.progress,
    required this.uploadedBytes,
    required this.totalBytes,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
  });

  String get progressText {
    final uploadedMB = (uploadedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    return '$uploadedMB / $totalMB MB';
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Upload state for local persistence
class UploadStateData {
  final String uploadId;
  final String filePath;
  final String? thumbnailPath;
  final int userId;
  final String? caption;
  final List<String>? hashtags;
  final List<int>? mentions;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String privacy;
  final bool allowComments;
  final bool allowDuet;
  final bool allowStitch;
  final bool allowDownload;
  final int? originalClipId;
  final String clipType;
  final int? musicId;
  final int? musicStart;

  UploadStateData({
    required this.uploadId,
    required this.filePath,
    this.thumbnailPath,
    required this.userId,
    this.caption,
    this.hashtags,
    this.mentions,
    this.locationName,
    this.latitude,
    this.longitude,
    this.privacy = 'public',
    this.allowComments = true,
    this.allowDuet = true,
    this.allowStitch = true,
    this.allowDownload = true,
    this.originalClipId,
    this.clipType = 'original',
    this.musicId,
    this.musicStart,
  });

  Map<String, dynamic> toJson() => {
    'upload_id': uploadId,
    'file_path': filePath,
    'thumbnail_path': thumbnailPath,
    'user_id': userId,
    'caption': caption,
    'hashtags': hashtags,
    'mentions': mentions,
    'location_name': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'privacy': privacy,
    'allow_comments': allowComments,
    'allow_duet': allowDuet,
    'allow_stitch': allowStitch,
    'allow_download': allowDownload,
    'original_clip_id': originalClipId,
    'clip_type': clipType,
    'music_id': musicId,
    'music_start': musicStart,
  };

  factory UploadStateData.fromJson(Map<String, dynamic> json) => UploadStateData(
    uploadId: json['upload_id'],
    filePath: json['file_path'],
    thumbnailPath: json['thumbnail_path'],
    userId: json['user_id'],
    caption: json['caption'],
    hashtags: json['hashtags'] != null ? List<String>.from(json['hashtags']) : null,
    mentions: json['mentions'] != null ? List<int>.from(json['mentions']) : null,
    locationName: json['location_name'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    privacy: json['privacy'] ?? 'public',
    allowComments: json['allow_comments'] ?? true,
    allowDuet: json['allow_duet'] ?? true,
    allowStitch: json['allow_stitch'] ?? true,
    allowDownload: json['allow_download'] ?? true,
    originalClipId: json['original_clip_id'],
    clipType: json['clip_type'] ?? 'original',
    musicId: json['music_id'],
    musicStart: json['music_start'],
  );
}
