import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec F7 #73 — Engagement questionnaires service.
class EngagementQuestionnaire {
  final int id;
  final String title;
  final String? skillCategory;
  final bool isActive;
  final List<EngagementQuestionField> fields;

  const EngagementQuestionnaire({
    required this.id,
    required this.title,
    this.skillCategory,
    required this.isActive,
    required this.fields,
  });

  factory EngagementQuestionnaire.fromJson(Map<String, dynamic> json) {
    final raw = json['schema_json'];
    final schema = raw is String ? jsonDecode(raw) : raw;
    final fields = <EngagementQuestionField>[];
    if (schema is Map && schema['fields'] is List) {
      for (final f in schema['fields']) {
        if (f is Map) {
          fields.add(EngagementQuestionField.fromJson(f.cast<String, dynamic>()));
        }
      }
    }
    return EngagementQuestionnaire(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      skillCategory: json['skill_category'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      fields: fields,
    );
  }

  Map<String, dynamic> toSchema() => {
        'fields': fields.map((f) => f.toJson()).toList(),
      };
}

class EngagementQuestionField {
  String key;
  String label;
  String? labelSw;
  String type;
  bool required;
  List<String>? options;
  int? min;
  int? max;

  EngagementQuestionField({
    required this.key,
    required this.label,
    this.labelSw,
    this.type = 'text',
    this.required = false,
    this.options,
    this.min,
    this.max,
  });

  factory EngagementQuestionField.fromJson(Map<String, dynamic> json) =>
      EngagementQuestionField(
        key: json['key']?.toString() ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
        label: json['label']?.toString() ?? '',
        labelSw: json['label_sw'] as String?,
        type: json['type']?.toString() ?? 'text',
        required: json['required'] == true,
        options: (json['options'] as List?)?.map((o) => o.toString()).toList(),
        min: (json['min'] as num?)?.toInt(),
        max: (json['max'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        if (labelSw != null && labelSw!.isNotEmpty) 'label_sw': labelSw,
        'type': type,
        if (required) 'required': true,
        if (options != null && options!.isNotEmpty) 'options': options,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      };
}

class EngagementQuestionnaireService {
  static Future<List<EngagementQuestionnaire>> mine({required int userId}) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagement-questionnaires/mine?user_id=$userId')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['questionnaires'] is List) {
      return (body['questionnaires'] as List)
          .whereType<Map>()
          .map((m) => EngagementQuestionnaire.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static Future<int?> save({
    required int userId,
    int? id,
    required String title,
    String? skillCategory,
    bool isActive = true,
    required Map<String, dynamic> schemaJson,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagement-questionnaires')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        if (id != null) 'id': id,
        'title': title,
        if (skillCategory != null) 'skill_category': skillCategory,
        'is_active': isActive,
        'schema_json': schemaJson,
      }),
    );
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['ok'] == true) {
      final newId = body['id'];
      if (newId is num) return newId.toInt();
    }
    return null;
  }

  static Future<EngagementQuestionnaire?> show(int id) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagement-questionnaires/$id')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic>) {
      return EngagementQuestionnaire.fromJson({
        'id': body['id'],
        'title': body['title'],
        'schema_json': body['schema'],
      });
    }
    return null;
  }

  static Future<bool> respond({
    required int userId,
    required int questionnaireId,
    int? engagementId,
    required Map<String, dynamic> answers,
  }) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/engagement-questionnaires/$questionnaireId/respond')!;
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        if (engagementId != null) 'engagement_id': engagementId,
        'answers': answers,
      }),
    );
    return res.statusCode == 200;
  }
}
