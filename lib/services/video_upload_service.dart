import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/clip_models.dart' as models;

/// Professional video upload service with:
/// - Real-time progress tracking
/// - Retry logic with exponential backoff
/// - Cancellation support
/// - Network-aware upload quality
class VideoUploadService {
  static final VideoUploadService _instance = VideoUploadService._internal();
  factory VideoUploadService() => _instance;
  VideoUploadService._internal();

  Dio? _dio;
  final Map<String, CancelToken> _activeCancelTokens = {};

  static const int _maxRetries = 3;
  static const Duration _connectionTimeout = Duration(minutes: 5);
  static const Duration _receiveTimeout = Duration(minutes: 30);

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: _connectionTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _receiveTimeout,
      headers: {
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio!.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: true,
        logPrint: (log) => debugPrint('[VideoUpload] $log'),
      ));
    }
  }

  /// Upload a video with real-time progress tracking
  Stream<VideoUploadProgress> uploadVideo({
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
  }) {
    // Use a StreamController to manage progress updates from callback
    final controller = StreamController<VideoUploadProgress>();

    _performUpload(
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
    );

    return controller.stream;
  }

  Future<void> _performUpload({
    required StreamController<VideoUploadProgress> controller,
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
    if (_dio == null) {
      initialize();
    }

    final uploadId = DateTime.now().millisecondsSinceEpoch.toString();
    final cancelToken = CancelToken();
    _activeCancelTokens[uploadId] = cancelToken;

    try {
      // Validate file exists
      if (!await videoFile.exists()) {
        controller.add(VideoUploadProgress(
          state: VideoUploadState.failed,
          progress: 0,
          message: 'Video file not found',
          error: 'File does not exist: ${videoFile.path}',
        ));
        await controller.close();
        return;
      }

      final fileSize = await videoFile.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      debugPrint('[VideoUpload] Starting upload: ${videoFile.path}');
      debugPrint('[VideoUpload] File size: ${fileSizeMB.toStringAsFixed(2)} MB');

      controller.add(VideoUploadProgress(
        state: VideoUploadState.preparing,
        progress: 0,
        message: 'Inaandaa video...',
        totalBytes: fileSize,
      ));

      // Prepare form data
      final formData = FormData.fromMap({
        'user_id': userId.toString(),
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: _getFileName(videoFile.path),
          contentType: DioMediaType.parse(_getVideoContentType(videoFile.path)),
        ),
        if (thumbnailFile != null && await thumbnailFile.exists())
          'thumbnail': await MultipartFile.fromFile(
            thumbnailFile.path,
            filename: _getFileName(thumbnailFile.path),
            contentType: DioMediaType.parse('image/jpeg'),
          ),
        if (caption != null) 'caption': caption,
        if (hashtags != null && hashtags.isNotEmpty) 'hashtags': hashtags.join(','),
        if (mentions != null && mentions.isNotEmpty) 'mentions': mentions.join(','),
        if (locationName != null) 'location_name': locationName,
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        'privacy': privacy,
        'allow_comments': allowComments.toString(),
        'allow_duet': allowDuet.toString(),
        'allow_stitch': allowStitch.toString(),
        'allow_download': allowDownload.toString(),
        if (originalClipId != null) 'original_clip_id': originalClipId.toString(),
        'clip_type': clipType,
        if (musicId != null) 'music_id': musicId.toString(),
        if (musicStart != null) 'music_start': musicStart.toString(),
      });

      // Progress tracking variables
      int lastReportedProgress = 0;
      DateTime uploadStartTime = DateTime.now();

      controller.add(VideoUploadProgress(
        state: VideoUploadState.uploading,
        progress: 0,
        message: 'Inapakia video... 0%',
        bytesSent: 0,
        totalBytes: fileSize,
      ));

      // Upload with retry logic
      Response? response;
      int retryCount = 0;

      while (retryCount < _maxRetries) {
        uploadStartTime = DateTime.now();
        lastReportedProgress = 0;

        try {
          response = await _dio!.post(
            '/clips',
            data: formData,
            cancelToken: cancelToken,
            onSendProgress: (sent, total) {
              final progress = (sent / total * 100).round();

              // Only update if progress changed
              if (progress != lastReportedProgress) {
                lastReportedProgress = progress;

                // Calculate upload speed based on elapsed time
                final elapsedSeconds = DateTime.now().difference(uploadStartTime).inSeconds;
                final speedMBps = elapsedSeconds > 0
                    ? (sent / (1024 * 1024)) / elapsedSeconds
                    : 0.0;
                final remainingBytes = total - sent;
                final etaSeconds = speedMBps > 0.1
                    ? (remainingBytes / (1024 * 1024) / speedMBps).round()
                    : 0;

                controller.add(VideoUploadProgress(
                  state: VideoUploadState.uploading,
                  progress: progress,
                  message: 'Inapakia video... $progress%',
                  bytesSent: sent,
                  totalBytes: total,
                  uploadSpeed: speedMBps,
                  estimatedTimeRemaining: etaSeconds > 0
                      ? Duration(seconds: etaSeconds)
                      : null,
                ));
              }
            },
          );
          break; // Success, exit retry loop
        } on DioException catch (e) {
          retryCount++;

          if (e.type == DioExceptionType.cancel) {
            controller.add(VideoUploadProgress(
              state: VideoUploadState.cancelled,
              progress: lastReportedProgress,
              message: 'Imeghairiwa',
            ));
            await controller.close();
            return;
          }

          if (retryCount >= _maxRetries) {
            rethrow;
          }

          // Exponential backoff
          final delay = Duration(seconds: (2 << retryCount));
          debugPrint('[VideoUpload] Retry $retryCount after ${delay.inSeconds}s');

          controller.add(VideoUploadProgress(
            state: VideoUploadState.retrying,
            progress: lastReportedProgress,
            message: 'Inajaribu tena... ($retryCount/$_maxRetries)',
            retryCount: retryCount,
          ));

          await Future.delayed(delay);
        }
      }

      // Processing phase
      controller.add(VideoUploadProgress(
        state: VideoUploadState.processing,
        progress: 100,
        message: 'Inachakata video...',
        bytesSent: fileSize,
        totalBytes: fileSize,
      ));

      // Handle response
      if (response?.statusCode == 200 || response?.statusCode == 201) {
        final data = response?.data;
        if (data != null && data['success'] == true) {
          final clip = models.Clip.fromJson(data['data']);
          debugPrint('[VideoUpload] Upload successful: Clip ID ${clip.id}');

          controller.add(VideoUploadProgress(
            state: VideoUploadState.completed,
            progress: 100,
            message: 'Video imepakiwa!',
            clip: clip,
            bytesSent: fileSize,
            totalBytes: fileSize,
          ));
        } else {
          throw Exception(data?['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response?.statusCode}');
      }
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
          errorMessage = 'Kupakia kumeghairiwa';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Hakuna mtandao. Angalia connection yako.';
          break;
        default:
          errorMessage = 'Hitilafu: ${e.message}';
      }

      debugPrint('[VideoUpload] Error: $errorMessage');
      debugPrint('[VideoUpload] Details: $e');

      controller.add(VideoUploadProgress(
        state: VideoUploadState.failed,
        progress: 0,
        message: errorMessage,
        error: e.toString(),
      ));
    } catch (e, stackTrace) {
      debugPrint('[VideoUpload] Unexpected error: $e');
      debugPrint('[VideoUpload] Stack trace: $stackTrace');

      controller.add(VideoUploadProgress(
        state: VideoUploadState.failed,
        progress: 0,
        message: 'Hitilafu isiyotarajiwa: $e',
        error: e.toString(),
      ));
    } finally {
      _activeCancelTokens.remove(uploadId);
      await controller.close();
    }
  }

  /// Cancel an ongoing upload
  void cancelUpload(String uploadId) {
    final cancelToken = _activeCancelTokens[uploadId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled upload');
      _activeCancelTokens.remove(uploadId);
    }
  }

  /// Cancel all ongoing uploads
  void cancelAllUploads() {
    for (final entry in _activeCancelTokens.entries) {
      if (!entry.value.isCancelled) {
        entry.value.cancel('Cancelled all uploads');
      }
    }
    _activeCancelTokens.clear();
  }

  String _getFileName(String path) {
    return path.split('/').last;
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

/// Video upload state
enum VideoUploadState {
  idle,
  preparing,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
  retrying,
}

/// Video upload progress data
class VideoUploadProgress {
  final VideoUploadState state;
  final int progress; // 0-100
  final String message;
  final int? bytesSent;
  final int? totalBytes;
  final double? uploadSpeed; // MB/s
  final Duration? estimatedTimeRemaining;
  final models.Clip? clip;
  final String? error;
  final int? retryCount;

  VideoUploadProgress({
    required this.state,
    required this.progress,
    required this.message,
    this.bytesSent,
    this.totalBytes,
    this.uploadSpeed,
    this.estimatedTimeRemaining,
    this.clip,
    this.error,
    this.retryCount,
  });

  bool get isComplete => state == VideoUploadState.completed;
  bool get isFailed => state == VideoUploadState.failed;
  bool get isCancelled => state == VideoUploadState.cancelled;
  bool get isUploading => state == VideoUploadState.uploading;
  bool get isProcessing => state == VideoUploadState.processing;

  String get progressText {
    if (bytesSent != null && totalBytes != null && totalBytes! > 0) {
      final sentMB = (bytesSent! / (1024 * 1024)).toStringAsFixed(1);
      final totalMB = (totalBytes! / (1024 * 1024)).toStringAsFixed(1);
      return '$sentMB / $totalMB MB';
    }
    return '$progress%';
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
