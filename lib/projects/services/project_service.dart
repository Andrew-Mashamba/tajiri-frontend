// lib/projects/services/project_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/project_models.dart';

String get _base => ApiConfig.baseUrl;
void _log(String msg) => debugPrint('[ProjectService] $msg');

class ProjectResult<T> {
  final bool success;
  final T? data;
  final String? message;
  ProjectResult({required this.success, this.data, this.message});
}

class ProjectListResult<T> {
  final bool success;
  final List<T> data;
  final String? message;
  ProjectListResult(
      {required this.success, this.data = const [], this.message});
}

class ProjectService {
  ProjectService._();

  static Future<ProjectListResult<Project>> getProjects(
      String token, int businessId) async {
    try {
      final url = '$_base/business/$businessId/projects';
      _log('GET $url');
      final res = await http.get(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Project.fromJson(e as Map<String, dynamic>))
            .toList();
        return ProjectListResult(success: true, data: list);
      }
      return ProjectListResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectListResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<Project>> createProject(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_base/business/projects';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return ProjectResult(
            success: true,
            data: Project.fromJson(data['data'] ?? data));
      }
      return ProjectResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<Project>> updateProject(
      String token, int projectId, Map<String, dynamic> body) async {
    try {
      final url = '$_base/business/projects/$projectId';
      _log('PUT $url');
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ProjectResult(
            success: true,
            data: Project.fromJson(data['data'] ?? data));
      }
      return ProjectResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<void>> deleteProject(
      String token, int projectId) async {
    try {
      final url = '$_base/business/projects/$projectId';
      _log('DELETE $url');
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) return ProjectResult(success: true);
      return ProjectResult(
          success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectListResult<Task>> getTasks(
      String token, int projectId) async {
    try {
      final url = '$_base/business/projects/$projectId/tasks';
      _log('GET $url');
      final res = await http.get(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List? ?? [])
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList();
        return ProjectListResult(success: true, data: list);
      }
      return ProjectListResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectListResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<Task>> createTask(
      String token, Map<String, dynamic> body) async {
    try {
      final url = '$_base/business/tasks';
      _log('POST $url');
      final res = await http.post(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode(body));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return ProjectResult(
            success: true,
            data: Task.fromJson(data['data'] ?? data));
      }
      return ProjectResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<Task>> updateTask(
      String token, int taskId, Map<String, dynamic> body) async {
    try {
      final url = '$_base/business/tasks/$taskId';
      _log('PUT $url');
      final res = await http.put(Uri.parse(url),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode(body));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ProjectResult(
            success: true,
            data: Task.fromJson(data['data'] ?? data));
      }
      return ProjectResult(
          success: false,
          message: (jsonDecode(res.body)['message']?.toString()) ??
              'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }

  static Future<ProjectResult<void>> deleteTask(
      String token, int taskId) async {
    try {
      final url = '$_base/business/tasks/$taskId';
      _log('DELETE $url');
      final res = await http.delete(Uri.parse(url),
          headers: ApiConfig.authHeaders(token));
      if (res.statusCode == 200) return ProjectResult(success: true);
      return ProjectResult(
          success: false, message: 'Error: ${res.statusCode}');
    } catch (e) {
      return ProjectResult(success: false, message: e.toString());
    }
  }
}
