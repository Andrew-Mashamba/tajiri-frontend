// lib/services/editor_action_service.dart
//
// UN-007/8/9 — strategy posts.md §V rows 51-53. Editor transformations
// (subtitle / format / highlight) credit the editor via /posts/{id}/editor-action.
// Backend EditorActionController fires the matching earning event from the
// dto's metric (subtitle_addition / format_adaptation / highlight_selection).

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class EditorActionService {
  String get _base => ApiConfig.baseUrl;

  Future<int?> submit({
    required int postId,
    required int editorUserId,
    required String actionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{
        'editor_user_id': editorUserId,
        'action_type': actionType,
      };
      if (metadata != null && metadata.isNotEmpty) body['metadata'] = metadata;
      final resp = await http.post(
        Uri.parse('$_base/posts/$postId/editor-action'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (resp.statusCode != 200 && resp.statusCode != 201) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;
      final inner = data['data'];
      if (inner is Map && inner['id'] is num) return (inner['id'] as num).toInt();
      return null;
    } catch (_) {
      return null;
    }
  }
}
