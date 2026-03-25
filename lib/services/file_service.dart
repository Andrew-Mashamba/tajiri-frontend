import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/file_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Service for user file management (Dropbox-like cloud storage)
class FileService {
  static const String _tag = '[FileService]';

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('$_tag $message');
    }
  }

  /// Get user's files with optional filters
  Future<FileListResult> getFiles({
    required int userId,
    int? folderId,
    String? path,
    FileCategory? category,
    bool? starred,
    bool? offline,
    bool? shared,
    String? search,
    String sortBy = 'updated_at',
    String sortOrder = 'desc',
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final params = <String, String>{
        'user_id': userId.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (folderId != null) params['folder_id'] = folderId.toString();
      if (path != null) params['path'] = path;
      if (category != null && category != FileCategory.all) {
        params['category'] = category.name;
      }
      if (starred == true) params['starred'] = '1';
      if (offline == true) params['offline'] = '1';
      if (shared == true) params['shared'] = '1';
      if (search != null && search.isNotEmpty) params['search'] = search;

      final uri = Uri.parse('$_baseUrl/files').replace(queryParameters: params);
      _log('GET $uri');

      final response = await http.get(uri);
      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body.length > 1500 ? '${response.body.substring(0, 1500)}...' : response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final rawList = data['data'] as List? ?? [];
          _log('Raw data count: ${rawList.length}');
          for (var i = 0; i < rawList.length && i < 5; i++) {
            _log('Item $i: ${rawList[i]}');
          }
          final files = rawList
                  .map((f) => UserFile.fromJson(f as Map<String, dynamic>))
                  .toList();
          final quota = data['quota'] != null
              ? StorageQuota.fromJson(data['quota'] as Map<String, dynamic>)
              : null;
          _log('Loaded ${files.length} files/folders');
          for (var f in files) {
            _log('  - ${f.name} (isFolder: ${f.isFolder}, path: ${f.path})');
          }
          return FileListResult(success: true, files: files, quota: quota);
        } else {
          final msg = data['message']?.toString() ?? 'API returned success=false';
          _log('API error: $msg');
          return FileListResult(success: false, message: msg);
        }
      } else if (response.statusCode == 404) {
        // API endpoint may not exist yet - return empty list
        _log('API endpoint not found (404) - returning empty list');
        return FileListResult(success: true, files: [], message: 'No files endpoint');
      } else {
        final msg = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        _log('HTTP error: $msg');
        return FileListResult(success: false, message: msg);
      }
    } catch (e, stack) {
      _log('Exception: $e');
      _log('Stack: $stack');
      return FileListResult(success: false, message: 'Error: $e');
    }
  }

  /// Get recent files
  Future<FileListResult> getRecentFiles(int userId, {int limit = 20}) async {
    try {
      final uri = Uri.parse('$_baseUrl/files/recent?user_id=$userId&limit=$limit');
      _log('GET $uri');

      final response = await http.get(uri);
      _log('Recent files response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final files = (data['data'] as List?)
                  ?.map((f) => UserFile.fromJson(f as Map<String, dynamic>))
                  .toList() ??
              [];
          _log('Loaded ${files.length} recent files');
          return FileListResult(success: true, files: files);
        }
      } else if (response.statusCode == 404) {
        _log('Recent files endpoint not found (404) - returning empty list');
        return FileListResult(success: true, files: []);
      }
      return FileListResult(success: true, files: [], message: 'No recent files');
    } catch (e, stack) {
      _log('getRecentFiles exception: $e');
      _log('Stack: $stack');
      return FileListResult(success: true, files: []);
    }
  }

  /// Get starred files
  Future<FileListResult> getStarredFiles(int userId) async {
    return getFiles(userId: userId, starred: true);
  }

  /// Get offline files
  Future<FileListResult> getOfflineFiles(int userId) async {
    return getFiles(userId: userId, offline: true);
  }

  /// Get shared files
  Future<FileListResult> getSharedFiles(int userId) async {
    return getFiles(userId: userId, shared: true);
  }

  /// Get storage quota
  Future<StorageQuota?> getStorageQuota(int userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/files/quota?user_id=$userId');
      _log('GET $uri');

      final response = await http.get(uri);
      _log('Quota response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _log('Loaded storage quota');
          return StorageQuota.fromJson(data['data'] as Map<String, dynamic>);
        }
      } else if (response.statusCode == 404) {
        _log('Quota endpoint not found (404) - returning default quota');
      }
      // Return a default quota if API not available
      return StorageQuota(used: 0, total: 5 * 1024 * 1024 * 1024, fileCount: 0, folderCount: 0);
    } catch (e, stack) {
      _log('getStorageQuota exception: $e');
      _log('Stack: $stack');
      // Return default quota on error
      return StorageQuota(used: 0, total: 5 * 1024 * 1024 * 1024, fileCount: 0, folderCount: 0);
    }
  }

  /// Upload a file
  Future<FileResult> uploadFile({
    required int userId,
    required File file,
    int? folderId,
    String? path,
    String? displayName,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/files');
      _log('POST $uri (multipart upload)');
      _log('Upload file: ${file.path}, displayName: $displayName');

      var request = http.MultipartRequest('POST', uri);
      request.fields['user_id'] = userId.toString();
      if (folderId != null) request.fields['folder_id'] = folderId.toString();
      if (path != null) request.fields['path'] = path;
      if (displayName != null) request.fields['display_name'] = displayName;

      _log('Request fields: ${request.fields}');

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _log('Upload response status: ${response.statusCode}');
      _log('Upload response body: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _log('File uploaded successfully');
        return FileResult(
          success: true,
          file: UserFile.fromJson(data['data']),
          message: data['message'],
        );
      }
      _log('Upload failed: ${data['message']}');
      return FileResult(success: false, message: data['message'] ?? 'Upload failed');
    } catch (e, stack) {
      _log('uploadFile exception: $e');
      _log('Stack: $stack');
      return FileResult(success: false, message: 'Error: $e');
    }
  }

  /// Upload multiple files
  Future<FileListResult> uploadFiles({
    required int userId,
    required List<File> files,
    int? folderId,
    String? path,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/files/batch'));
      request.fields['user_id'] = userId.toString();
      if (folderId != null) request.fields['folder_id'] = folderId.toString();
      if (path != null) request.fields['path'] = path;

      for (var file in files) {
        request.files.add(await http.MultipartFile.fromPath('files[]', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final uploadedFiles = (data['data'] as List?)
                ?.map((f) => UserFile.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [];
        return FileListResult(success: true, files: uploadedFiles);
      }
      return FileListResult(success: false, message: data['message'] ?? 'Upload failed');
    } catch (e) {
      return FileListResult(success: false, message: 'Error: $e');
    }
  }

  /// Create a folder
  Future<FolderResult> createFolder({
    required int userId,
    required String name,
    int? parentFolderId,
    String? path,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/files/folders');
      final body = {
        'user_id': userId,
        'name': name,
        if (parentFolderId != null) 'parent_folder_id': parentFolderId,
        if (path != null) 'path': path,
      };
      _log('POST $uri');
      _log('Request body: $body');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      _log('Create folder response status: ${response.statusCode}');
      _log('Create folder response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _log('Folder created successfully');
        return FolderResult(
          success: true,
          folder: UserFolder.fromJson(data['data']),
          message: data['message'],
        );
      }
      _log('Folder creation failed: ${data['message']}');
      return FolderResult(success: false, message: data['message'] ?? 'Failed to create folder');
    } catch (e, stack) {
      _log('createFolder exception: $e');
      _log('Stack: $stack');
      return FolderResult(success: false, message: 'Error: $e');
    }
  }

  /// Rename a file or folder
  Future<FileResult> renameFile(int fileId, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/files/$fileId/rename'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': newName}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return FileResult(
          success: true,
          file: UserFile.fromJson(data['data']),
          message: data['message'],
        );
      }
      return FileResult(success: false, message: data['message'] ?? 'Failed to rename');
    } catch (e) {
      return FileResult(success: false, message: 'Error: $e');
    }
  }

  /// Move a file or folder
  Future<FileResult> moveFile(int fileId, {int? targetFolderId, String? targetPath}) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/files/$fileId/move'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (targetFolderId != null) 'target_folder_id': targetFolderId,
          if (targetPath != null) 'target_path': targetPath,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return FileResult(
          success: true,
          file: UserFile.fromJson(data['data']),
          message: data['message'],
        );
      }
      return FileResult(success: false, message: data['message'] ?? 'Failed to move');
    } catch (e) {
      return FileResult(success: false, message: 'Error: $e');
    }
  }

  /// Copy a file
  Future<FileResult> copyFile(int fileId, {int? targetFolderId, String? targetPath}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/files/$fileId/copy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (targetFolderId != null) 'target_folder_id': targetFolderId,
          if (targetPath != null) 'target_path': targetPath,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return FileResult(
          success: true,
          file: UserFile.fromJson(data['data']),
          message: data['message'],
        );
      }
      return FileResult(success: false, message: data['message'] ?? 'Failed to copy');
    } catch (e) {
      return FileResult(success: false, message: 'Error: $e');
    }
  }

  /// Delete a file or folder
  Future<bool> deleteFile(int fileId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/files/$fileId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Delete multiple files
  Future<bool> deleteFiles(List<int> fileIds) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/files/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_ids': fileIds}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Toggle star status
  Future<FileResult> toggleStar(int fileId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/files/$fileId/star'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return FileResult(
          success: true,
          file: UserFile.fromJson(data['data']),
          message: data['message'],
        );
      }
      return FileResult(success: false, message: data['message'] ?? 'Failed to update');
    } catch (e) {
      return FileResult(success: false, message: 'Error: $e');
    }
  }

  /// Mark file for offline access
  Future<FileResult> toggleOffline(int fileId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/files/$fileId/offline'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return FileResult(
          success: true,
          file: UserFile.fromJson(data['data']),
          message: data['message'],
        );
      }
      return FileResult(success: false, message: data['message'] ?? 'Failed to update');
    } catch (e) {
      return FileResult(success: false, message: 'Error: $e');
    }
  }

  /// Share a file
  Future<String?> shareFile(int fileId, {List<int>? userIds, bool? publicLink}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/files/$fileId/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (userIds != null) 'user_ids': userIds,
          if (publicLink != null) 'public_link': publicLink,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['share_link'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search files
  Future<FileListResult> searchFiles(int userId, String query) async {
    return getFiles(userId: userId, search: query);
  }

  /// Get file details
  Future<FileResult> getFile(int fileId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/files/$fileId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return FileResult(
            success: true,
            file: UserFile.fromJson(data['data']),
          );
        }
      }
      return FileResult(success: false, message: 'File not found');
    } catch (e) {
      return FileResult(success: false, message: 'Error: $e');
    }
  }
}
