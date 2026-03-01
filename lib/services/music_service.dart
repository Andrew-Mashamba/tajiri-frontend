import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import '../models/music_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Default chunk size: 2MB (balance between speed and progress updates)
const int _defaultChunkSize = 2 * 1024 * 1024;

/// Number of parallel chunk uploads for faster speeds
const int _parallelUploads = 3;

/// Create HTTP client that accepts self-signed certificates (for development)
http.Client _createHttpClient() {
  final httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..badCertificateCallback = (cert, host, port) => true; // Accept self-signed certs
  return IOClient(httpClient);
}

class MusicService {
  Future<TracksResult> getTracks({int page = 1, int perPage = 20, int? currentUserId}) async {
    try {
      String url = '$_baseUrl/music?page=$page&per_page=$perPage';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tracks = (data['data'] as List).map((t) => MusicTrack.fromJson(t)).toList();
          return TracksResult(success: true, tracks: tracks);
        }
      }
      return TracksResult(success: false, message: 'Failed to load tracks');
    } catch (e) {
      return TracksResult(success: false, message: 'Error: $e');
    }
  }

  // Get tracks uploaded by a specific user
  Future<TracksResult> getUserTracks(int userId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/music/user/$userId?page=$page'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tracks = (data['data'] as List).map((t) => MusicTrack.fromJson(t)).toList();
          final meta = data['meta'] as Map<String, dynamic>?;
          return TracksResult(
            success: true,
            tracks: tracks,
            hasMore: meta != null && meta['current_page'] < meta['last_page'],
            total: meta?['total'] ?? tracks.length,
          );
        }
      }
      return TracksResult(success: false, message: 'Failed to load user tracks');
    } catch (e) {
      return TracksResult(success: false, message: 'Error: $e');
    }
  }

  Future<TracksResult> getFeaturedTracks({int? currentUserId}) async {
    try {
      String url = '$_baseUrl/music/featured';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tracks = (data['data'] as List).map((t) => MusicTrack.fromJson(t)).toList();
          return TracksResult(success: true, tracks: tracks);
        }
      }
      return TracksResult(success: false, message: 'Failed');
    } catch (e) {
      return TracksResult(success: false, message: 'Error: $e');
    }
  }

  Future<TracksResult> getTrendingTracks({int? currentUserId}) async {
    try {
      String url = '$_baseUrl/music/trending';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tracks = (data['data'] as List).map((t) => MusicTrack.fromJson(t)).toList();
          return TracksResult(success: true, tracks: tracks);
        }
      }
      return TracksResult(success: false, message: 'Failed');
    } catch (e) {
      return TracksResult(success: false, message: 'Error: $e');
    }
  }

  Future<TrackResult> getTrack(int trackId, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/music/$trackId';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return TrackResult(success: true, track: MusicTrack.fromJson(data['data']));
        }
      }
      return TrackResult(success: false, message: 'Track not found');
    } catch (e) {
      return TrackResult(success: false, message: 'Error: $e');
    }
  }

  Future<TracksResult> searchTracks(String query, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/music/search?q=${Uri.encodeComponent(query)}';
      if (currentUserId != null) url += '&current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tracks = (data['data'] as List).map((t) => MusicTrack.fromJson(t)).toList();
          return TracksResult(success: true, tracks: tracks);
        }
      }
      return TracksResult(success: false, message: 'Failed');
    } catch (e) {
      return TracksResult(success: false, message: 'Error: $e');
    }
  }

  Future<bool> saveTrack(int trackId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/music/$trackId/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unsaveTrack(int trackId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/music/$trackId/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<TracksResult> getSavedTracks(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/music/saved/$userId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tracks = (data['data'] as List).map((t) => MusicTrack.fromJson(t)).toList();
          return TracksResult(success: true, tracks: tracks);
        }
      }
      return TracksResult(success: false, message: 'Failed');
    } catch (e) {
      return TracksResult(success: false, message: 'Error: $e');
    }
  }

  // Artists
  Future<ArtistsResult> getArtists({int page = 1, int perPage = 20}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/music/artists?page=$page&per_page=$perPage'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final artists = (data['data'] as List).map((a) => MusicArtistModel.fromJson(a)).toList();
          return ArtistsResult(success: true, artists: artists);
        }
      }
      return ArtistsResult(success: false, message: 'Failed');
    } catch (e) {
      return ArtistsResult(success: false, message: 'Error: $e');
    }
  }

  Future<ArtistResult> getArtist(int artistId, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/music/artists/$artistId';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return ArtistResult(success: true, artist: MusicArtistModel.fromJson(data['data']));
        }
      }
      return ArtistResult(success: false, message: 'Artist not found');
    } catch (e) {
      return ArtistResult(success: false, message: 'Error: $e');
    }
  }

  // Extract metadata from audio file and store it on server
  // Returns temp_upload_id to be used when finalizing
  // onProgress callback receives values from 0.0 to 1.0
  Future<MetadataResult> extractMetadata(
    File audioFile,
    int userId, {
    Function(double progress, String status)? onProgress,
  }) async {
    print('═══════════════════════════════════════════════════════════');
    print('📤 MUSIC UPLOAD: Starting metadata extraction...');
    print('═══════════════════════════════════════════════════════════');

    http.Client? client;

    try {
      final uri = Uri.parse('$_baseUrl/music/extract-metadata');
      print('🌐 API URL: $uri');
      print('👤 User ID: $userId');
      print('📁 File path: ${audioFile.path}');

      // Check if file exists and get size
      final fileExists = await audioFile.exists();
      final fileSize = fileExists ? await audioFile.length() : 0;
      print('📊 File exists: $fileExists');
      print('📊 File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      if (!fileExists) {
        print('❌ ERROR: File does not exist!');
        return MetadataResult(success: false, message: 'Faili haipatikani');
      }

      onProgress?.call(0.05, 'Inaandaa faili...');

      // Create custom HTTP client with SSL bypass
      print('🔧 Creating HTTP client with SSL bypass...');
      client = _createHttpClient();

      final audioFileName = audioFile.path.split('/').last;
      final audioExtension = audioFileName.split('.').last.toLowerCase();
      final audioMimeType = _getAudioMimeType(audioExtension);

      print('📝 File name: $audioFileName');
      print('📝 Extension: $audioExtension');
      print('📝 MIME type: $audioMimeType');

      // Read file bytes for progress tracking
      print('⏳ Reading file bytes...');
      onProgress?.call(0.1, 'Inasoma faili...');
      final fileBytes = await audioFile.readAsBytes();
      final totalBytes = fileBytes.length;
      print('✅ File bytes read: $totalBytes bytes');

      onProgress?.call(0.15, 'Inaanza kupakia...');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      request.fields['user_id'] = userId.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'audio_file',
        fileBytes,
        filename: audioFileName,
        contentType: MediaType.parse(audioMimeType),
      ));

      print('⏳ Uploading file...');
      final stopwatch = Stopwatch()..start();

      // Send request using IOClient (handles SSL properly)
      final streamedResponse = await client.send(request);

      // Track response download progress
      final contentLength = streamedResponse.contentLength ?? 0;
      print('📥 Response content length: $contentLength');

      onProgress?.call(0.85, 'Inasubiri jibu la server...');
      print('⏳ Reading server response...');

      // Read response with timeout
      final responseBytes = <int>[];
      await for (final chunk in streamedResponse.stream.timeout(
        const Duration(minutes: 2),
        onTimeout: (sink) {
          print('❌ Response stream timeout!');
          sink.close();
        },
      )) {
        responseBytes.addAll(chunk);
      }

      stopwatch.stop();
      final responseBody = String.fromCharCodes(responseBytes);

      print('═══════════════════════════════════════════════════════════');
      print('📥 RESPONSE RECEIVED');
      print('═══════════════════════════════════════════════════════════');
      print('⏱️ Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('📊 Status code: ${streamedResponse.statusCode}');
      print('📊 Response length: ${responseBody.length} chars');
      print('📄 Response body: ${responseBody.length > 500 ? responseBody.substring(0, 500) + '...' : responseBody}');

      onProgress?.call(0.9, 'Inasoma metadata...');

      if (streamedResponse.statusCode == 200) {
        print('✅ Status 200 OK');
        onProgress?.call(0.95, 'Inakamilisha...');

        final data = jsonDecode(responseBody);
        print('📦 Parsed JSON success: ${data['success']}');

        if (data['success'] == true) {
          print('✅ Upload successful!');
          print('🔑 Temp upload ID: ${data['temp_upload_id']}');
          print('🎵 Audio URL: ${data['audio_url']}');
          print('🖼️ Cover URL: ${data['cover_url']}');

          onProgress?.call(1.0, 'Imekamilika!');

          return MetadataResult(
            success: true,
            metadata: AudioMetadata.fromJson(data['data']),
            tempUploadId: data['temp_upload_id'],
            audioUrl: data['audio_url'],
            coverUrl: data['cover_url'],
          );
        }
        print('❌ Server returned success=false: ${data['message']}');
        return MetadataResult(success: false, message: data['message'] ?? 'Server error');
      } else if (streamedResponse.statusCode == 422) {
        print('❌ Status 422 - Validation error');
        final data = jsonDecode(responseBody);
        print('📄 Errors: ${data['errors']}');
        return MetadataResult(success: false, message: data['message'] ?? 'Faili si sahihi');
      } else if (streamedResponse.statusCode == 500) {
        print('❌ Status 500 - Server error');
        return MetadataResult(success: false, message: 'Server imeshindwa kusoma faili');
      }
      print('❌ Unexpected status code: ${streamedResponse.statusCode}');
      return MetadataResult(success: false, message: 'Server error: ${streamedResponse.statusCode}');
    } on TimeoutException catch (e) {
      print('═══════════════════════════════════════════════════════════');
      print('❌ TIMEOUT EXCEPTION');
      print('═══════════════════════════════════════════════════════════');
      print('🔴 Error: $e');
      return MetadataResult(success: false, message: 'Muda umeisha - faili kubwa sana');
    } on SocketException catch (e) {
      print('═══════════════════════════════════════════════════════════');
      print('❌ SOCKET EXCEPTION (No network)');
      print('═══════════════════════════════════════════════════════════');
      print('🔴 Error: $e');
      return MetadataResult(success: false, message: 'Hakuna mtandao');
    } on HandshakeException catch (e) {
      print('═══════════════════════════════════════════════════════════');
      print('❌ SSL HANDSHAKE EXCEPTION');
      print('═══════════════════════════════════════════════════════════');
      print('🔴 Error: $e');
      return MetadataResult(success: false, message: 'Tatizo la usalama wa mtandao (SSL)');
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════════');
      print('❌ EXCEPTION CAUGHT');
      print('═══════════════════════════════════════════════════════════');
      print('🔴 Error type: ${e.runtimeType}');
      print('🔴 Error message: $e');
      print('📚 Stack trace: $stackTrace');

      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        return MetadataResult(success: false, message: 'Muda umeisha - faili kubwa sana');
      } else if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        return MetadataResult(success: false, message: 'Hakuna mtandao');
      } else if (e.toString().contains('HandshakeException') || e.toString().contains('CERTIFICATE')) {
        return MetadataResult(success: false, message: 'Tatizo la usalama wa mtandao (SSL)');
      }
      return MetadataResult(success: false, message: 'Hitilafu: $e');
    } finally {
      client?.close();
    }
  }

  // Finalize upload using temp_upload_id from extractMetadata
  Future<UploadResult> finalizeUpload({
    required String tempUploadId,
    required int userId,
    required String title,
    File? coverImage,
    String? album,
    String? genre,
    int? bpm,
    bool isExplicit = false,
    List<int>? categoryIds,
    String? privacy,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/music/finalize-upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['temp_upload_id'] = tempUploadId;
      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      if (album != null) request.fields['album'] = album;
      if (genre != null) request.fields['genre'] = genre;
      if (bpm != null) request.fields['bpm'] = bpm.toString();
      request.fields['is_explicit'] = isExplicit ? '1' : '0';
      if (categoryIds != null && categoryIds.isNotEmpty) {
        request.fields['category_ids'] = categoryIds.join(',');
      }
      if (privacy != null) request.fields['privacy'] = privacy;

      // Add cover image if provided (overrides embedded cover)
      if (coverImage != null) {
        final coverFileName = coverImage.path.split('/').last;
        final coverExtension = coverFileName.split('.').last.toLowerCase();
        final coverMimeType = _getImageMimeType(coverExtension);

        request.files.add(await http.MultipartFile.fromPath(
          'cover_image',
          coverImage.path,
          contentType: MediaType.parse(coverMimeType),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return UploadResult(
            success: true,
            track: MusicTrack.fromJson(data['data']),
            message: 'Muziki umepakiwa kikamilifu!',
          );
        }
        return UploadResult(success: false, message: data['message'] ?? 'Upload failed');
      }
      return UploadResult(success: false, message: 'Server error: ${response.statusCode}');
    } catch (e) {
      return UploadResult(success: false, message: 'Error: $e');
    }
  }

  // Cancel pending upload and clean up files
  Future<bool> cancelUpload(String tempUploadId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/music/cancel-upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'temp_upload_id': tempUploadId,
          'user_id': userId,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Upload file using chunked/resumable upload with PARALLEL uploads for speed
  /// Uploads multiple chunks simultaneously for faster upload speeds
  Future<MetadataResult> uploadChunked(
    File audioFile,
    int userId, {
    Function(double progress, String status)? onProgress,
    int chunkSize = _defaultChunkSize,
    int parallelUploads = _parallelUploads,
  }) async {
    print('═══════════════════════════════════════════════════════════');
    print('📤 PARALLEL CHUNKED UPLOAD: Starting...');
    print('═══════════════════════════════════════════════════════════');

    try {
      // Verify file exists
      if (!await audioFile.exists()) {
        print('❌ ERROR: File does not exist!');
        return MetadataResult(success: false, message: 'Faili haipatikani');
      }

      final fileSize = await audioFile.length();
      final fileName = audioFile.path.split('/').last;
      final totalChunks = (fileSize / chunkSize).ceil();

      // Generate unique identifier using file stats (fast, no full read needed)
      final fileStat = await audioFile.stat();
      final identifier = '${fileSize}_${fileStat.modified.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}';

      print('📁 File: $fileName');
      print('📊 Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      print('📊 Chunk size: ${(chunkSize / 1024 / 1024).toStringAsFixed(1)} MB');
      print('📊 Total chunks: $totalChunks');
      print('📊 Parallel uploads: $parallelUploads');
      print('🔑 Identifier: $identifier');

      onProgress?.call(0.0, 'Inaanza kupakia...');

      final uploadUri = Uri.parse('$_baseUrl/music/upload-chunk');
      final audioExtension = fileName.split('.').last.toLowerCase();
      final audioMimeType = _getAudioMimeType(audioExtension);

      // Read entire file once (for parallel access)
      final fileBytes = await audioFile.readAsBytes();

      // Track completed chunks
      int completedChunks = 0;
      MetadataResult? finalResult;
      String? errorMessage;

      // Upload chunks in parallel batches
      for (int batchStart = 1; batchStart <= totalChunks; batchStart += parallelUploads) {
        final batchEnd = min(batchStart + parallelUploads - 1, totalChunks);
        final batchSize = batchEnd - batchStart + 1;

        print('📤 Uploading batch: chunks $batchStart-$batchEnd ($batchSize chunks in parallel)');

        // Create parallel upload futures for this batch
        final futures = <Future<Map<String, dynamic>>>[];

        for (int chunkNumber = batchStart; chunkNumber <= batchEnd; chunkNumber++) {
          futures.add(_uploadSingleChunk(
            uploadUri: uploadUri,
            chunkNumber: chunkNumber,
            totalChunks: totalChunks,
            chunkSize: chunkSize,
            fileSize: fileSize,
            fileBytes: fileBytes,
            fileName: fileName,
            identifier: identifier,
            userId: userId,
            audioMimeType: audioMimeType,
          ));
        }

        // Wait for all chunks in this batch to complete
        final results = await Future.wait(futures);

        // Process results
        for (final result in results) {
          if (!result['success']) {
            errorMessage = result['message'] ?? 'Chunk upload failed';
            print('❌ Chunk ${result['chunkNumber']} failed: $errorMessage');
            return MetadataResult(success: false, message: errorMessage);
          }

          completedChunks++;

          // Check if this was the final chunk
          if (result['done'] == true) {
            print('═══════════════════════════════════════════════════════════');
            print('✅ PARALLEL CHUNKED UPLOAD COMPLETE!');
            print('═══════════════════════════════════════════════════════════');
            print('🔑 Temp upload ID: ${result['temp_upload_id']}');

            finalResult = MetadataResult(
              success: true,
              metadata: result['data'] != null ? AudioMetadata.fromJson(result['data']) : null,
              tempUploadId: result['temp_upload_id'],
              audioUrl: result['audio_url'],
              coverUrl: result['cover_url'],
            );
          }
        }

        // Update progress after batch completes
        final progress = completedChunks / totalChunks;
        final mbUploaded = (completedChunks * chunkSize / 1024 / 1024).clamp(0.0, fileSize / 1024 / 1024).toStringAsFixed(1);
        final mbTotal = (fileSize / 1024 / 1024).toStringAsFixed(1);
        onProgress?.call(progress * 0.9, 'Inapakia... $mbUploaded/$mbTotal MB');
        print('📊 Progress: ${(progress * 100).toStringAsFixed(0)}% ($completedChunks/$totalChunks chunks)');
      }

      if (finalResult != null) {
        onProgress?.call(0.95, 'Inasoma metadata...');
        return finalResult;
      }

      return MetadataResult(success: false, message: 'Upload incomplete');
    } on SocketException catch (e) {
      print('❌ SOCKET EXCEPTION: $e');
      return MetadataResult(success: false, message: 'Hakuna mtandao');
    } on HandshakeException catch (e) {
      print('❌ SSL EXCEPTION: $e');
      return MetadataResult(success: false, message: 'Tatizo la usalama wa mtandao (SSL)');
    } catch (e, stackTrace) {
      print('❌ EXCEPTION: $e');
      print('📚 Stack trace: $stackTrace');
      return MetadataResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Upload a single chunk (used by parallel uploader)
  Future<Map<String, dynamic>> _uploadSingleChunk({
    required Uri uploadUri,
    required int chunkNumber,
    required int totalChunks,
    required int chunkSize,
    required int fileSize,
    required List<int> fileBytes,
    required String fileName,
    required String identifier,
    required int userId,
    required String audioMimeType,
  }) async {
    http.Client? client;
    try {
      final startByte = (chunkNumber - 1) * chunkSize;
      final endByte = min(startByte + chunkSize, fileSize);
      final chunkBytes = fileBytes.sublist(startByte, endByte);

      // Create HTTP client with SSL bypass
      client = _createHttpClient();

      // Create multipart request for this chunk
      final request = http.MultipartRequest('POST', uploadUri);
      request.fields['user_id'] = userId.toString();
      request.fields['resumableChunkNumber'] = chunkNumber.toString();
      request.fields['resumableTotalChunks'] = totalChunks.toString();
      request.fields['resumableChunkSize'] = chunkSize.toString();
      request.fields['resumableTotalSize'] = fileSize.toString();
      request.fields['resumableIdentifier'] = identifier;
      request.fields['resumableFilename'] = fileName;

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        chunkBytes,
        filename: fileName,
        contentType: MediaType.parse(audioMimeType),
      ));

      // Send chunk
      final streamedResponse = await client.send(request);
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        return {
          'success': false,
          'chunkNumber': chunkNumber,
          'message': 'HTTP ${streamedResponse.statusCode}',
        };
      }

      final data = jsonDecode(responseBody);
      return {
        'success': true,
        'chunkNumber': chunkNumber,
        'done': data['done'] ?? false,
        'temp_upload_id': data['temp_upload_id'],
        'data': data['data'],
        'audio_url': data['audio_url'],
        'cover_url': data['cover_url'],
      };
    } catch (e) {
      return {
        'success': false,
        'chunkNumber': chunkNumber,
        'message': e.toString(),
      };
    } finally {
      client?.close();
    }
  }

  /// Check if a chunk already exists (for resume support)
  Future<bool> checkChunkExists({
    required String identifier,
    required int chunkNumber,
    required int chunkSize,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/music/upload-chunk').replace(
        queryParameters: {
          'resumableIdentifier': identifier,
          'resumableChunkNumber': chunkNumber.toString(),
          'resumableChunkSize': chunkSize.toString(),
        },
      );

      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Upload Track
  Future<UploadResult> uploadTrack({
    required int userId,
    required String title,
    required File audioFile,
    File? coverImage,
    String? album,
    String? genre,
    int? bpm,
    bool isExplicit = false,
    List<int>? categoryIds,
    Function(double)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/music/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      if (album != null) request.fields['album'] = album;
      if (genre != null) request.fields['genre'] = genre;
      if (bpm != null) request.fields['bpm'] = bpm.toString();
      request.fields['is_explicit'] = isExplicit ? '1' : '0';
      if (categoryIds != null && categoryIds.isNotEmpty) {
        request.fields['category_ids'] = categoryIds.join(',');
      }

      // Add audio file
      final audioFileName = audioFile.path.split('/').last;
      final audioExtension = audioFileName.split('.').last.toLowerCase();
      final audioMimeType = _getAudioMimeType(audioExtension);

      request.files.add(await http.MultipartFile.fromPath(
        'audio_file',
        audioFile.path,
        contentType: MediaType.parse(audioMimeType),
      ));

      // Add cover image if provided
      if (coverImage != null) {
        final coverFileName = coverImage.path.split('/').last;
        final coverExtension = coverFileName.split('.').last.toLowerCase();
        final coverMimeType = _getImageMimeType(coverExtension);

        request.files.add(await http.MultipartFile.fromPath(
          'cover_image',
          coverImage.path,
          contentType: MediaType.parse(coverMimeType),
        ));
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return UploadResult(
            success: true,
            track: MusicTrack.fromJson(data['data']),
            message: 'Muziki umepakiwa kikamilifu!',
          );
        }
        return UploadResult(success: false, message: data['message'] ?? 'Upload failed');
      }
      return UploadResult(success: false, message: 'Server error: ${response.statusCode}');
    } catch (e) {
      return UploadResult(success: false, message: 'Error: $e');
    }
  }

  String _getAudioMimeType(String extension) {
    switch (extension) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      default:
        return 'audio/mpeg';
    }
  }

  String _getImageMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Categories
  Future<CategoriesResult> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/music/categories'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final categories = (data['data'] as List).map((c) => MusicCategoryModel.fromJson(c)).toList();
          return CategoriesResult(success: true, categories: categories);
        }
      }
      return CategoriesResult(success: false, message: 'Failed');
    } catch (e) {
      return CategoriesResult(success: false, message: 'Error: $e');
    }
  }

  Future<TracksResult> getTracksByCategory(int categoryId, {int? currentUserId}) async {
    try {
      String url = '$_baseUrl/music/categories/$categoryId';
      if (currentUserId != null) url += '?current_user_id=$currentUserId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tracks = (data['data'] as List).map((t) => MusicTrack.fromJson(t)).toList();
          return TracksResult(success: true, tracks: tracks);
        }
      }
      return TracksResult(success: false, message: 'Failed');
    } catch (e) {
      return TracksResult(success: false, message: 'Error: $e');
    }
  }
}

// Result classes
class TracksResult {
  final bool success;
  final List<MusicTrack> tracks;
  final String? message;
  final bool hasMore;
  final int total;

  TracksResult({
    required this.success,
    this.tracks = const [],
    this.message,
    this.hasMore = false,
    this.total = 0,
  });
}

class TrackResult {
  final bool success;
  final MusicTrack? track;
  final String? message;

  TrackResult({required this.success, this.track, this.message});
}

class ArtistsResult {
  final bool success;
  final List<MusicArtistModel> artists;
  final String? message;

  ArtistsResult({required this.success, this.artists = const [], this.message});
}

class ArtistResult {
  final bool success;
  final MusicArtistModel? artist;
  final String? message;

  ArtistResult({required this.success, this.artist, this.message});
}

class CategoriesResult {
  final bool success;
  final List<MusicCategoryModel> categories;
  final String? message;

  CategoriesResult({required this.success, this.categories = const [], this.message});
}

class UploadResult {
  final bool success;
  final MusicTrack? track;
  final String? message;

  UploadResult({required this.success, this.track, this.message});
}

class MetadataResult {
  final bool success;
  final AudioMetadata? metadata;
  final String? message;
  final String? tempUploadId;
  final String? audioUrl;
  final String? coverUrl;

  MetadataResult({
    required this.success,
    this.metadata,
    this.message,
    this.tempUploadId,
    this.audioUrl,
    this.coverUrl,
  });
}

class AudioMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? duration;
  final String? durationFormatted;
  final int? bitrate;
  final String? bitrateFormatted;
  final int? sampleRate;
  final String? sampleRateFormatted;
  final int? channels;
  final String? channelsFormatted;
  final int? fileSize;
  final String? fileSizeFormatted;
  final String? codec;
  final String? fileFormat;
  final int? releaseYear;
  final int? trackNumber;
  final String? composer;
  final String? publisher;
  final int? bpm;
  final String? lyrics;
  final String? comment;
  final String? isrc;
  final String? copyright;
  final bool hasEmbeddedCover;
  final String? embeddedCoverBase64;

  AudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.duration,
    this.durationFormatted,
    this.bitrate,
    this.bitrateFormatted,
    this.sampleRate,
    this.sampleRateFormatted,
    this.channels,
    this.channelsFormatted,
    this.fileSize,
    this.fileSizeFormatted,
    this.codec,
    this.fileFormat,
    this.releaseYear,
    this.trackNumber,
    this.composer,
    this.publisher,
    this.bpm,
    this.lyrics,
    this.comment,
    this.isrc,
    this.copyright,
    this.hasEmbeddedCover = false,
    this.embeddedCoverBase64,
  });

  factory AudioMetadata.fromJson(Map<String, dynamic> json) {
    return AudioMetadata(
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      genre: json['genre'],
      duration: json['duration'],
      durationFormatted: json['duration_formatted'],
      bitrate: json['bitrate'],
      bitrateFormatted: json['bitrate_formatted'],
      sampleRate: json['sample_rate'],
      sampleRateFormatted: json['sample_rate_formatted'],
      channels: json['channels'],
      channelsFormatted: json['channels_formatted'],
      fileSize: json['file_size'],
      fileSizeFormatted: json['file_size_formatted'],
      codec: json['codec'],
      fileFormat: json['file_format'],
      releaseYear: json['release_year'],
      trackNumber: json['track_number'],
      composer: json['composer'],
      publisher: json['publisher'],
      bpm: json['bpm'],
      lyrics: json['lyrics'],
      comment: json['comment'],
      isrc: json['isrc'],
      copyright: json['copyright'],
      hasEmbeddedCover: json['has_embedded_cover'] ?? false,
      embeddedCoverBase64: json['embedded_cover_base64'],
    );
  }
}
