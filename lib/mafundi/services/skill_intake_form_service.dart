import 'dart:convert';

import '../../services/http_retry.dart';
import '../../config/api_config.dart';

/// Spec F4 #21 — Fetch the JSON schema for a skill's intake form.
class SkillIntakeFormService {
  static Future<Map<String, dynamic>?> fetch(String skillCategory) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/skill-intake-forms/$skillCategory')!;
    final res = await httpGetWithRetry(Uri.parse(url),
        headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      final schema = body['form_schema'];
      if (schema is Map<String, dynamic>) return schema;
    }
    return null;
  }
}
