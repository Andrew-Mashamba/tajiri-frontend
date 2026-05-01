import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec F1 #1 — Three-tier service taxonomy.
class TaxonomyNode {
  final int id;
  final String level;
  final int? parentId;
  final String nameEn;
  final String nameSw;
  final String? cluster;
  final String? skillCategory;
  final List<String> breadcrumb;

  const TaxonomyNode({
    required this.id,
    required this.level,
    this.parentId,
    required this.nameEn,
    required this.nameSw,
    this.cluster,
    this.skillCategory,
    this.breadcrumb = const [],
  });

  factory TaxonomyNode.fromJson(Map<String, dynamic> json) => TaxonomyNode(
        id: (json['id'] as num?)?.toInt() ?? 0,
        level: json['level']?.toString() ?? 'service',
        parentId: (json['parent_id'] as num?)?.toInt(),
        nameEn: json['name_en']?.toString() ?? '',
        nameSw: json['name_sw']?.toString() ?? '',
        cluster: json['cluster'] as String?,
        skillCategory: json['skill_category'] as String?,
        breadcrumb: (json['breadcrumb'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class ServiceTaxonomyService {
  static Future<List<TaxonomyNode>> categories() async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/service-taxonomy/categories')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['categories'] is List) {
      return (body['categories'] as List)
          .whereType<Map>()
          .map((m) => TaxonomyNode.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static Future<List<TaxonomyNode>> children(int parentId) async {
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/service-taxonomy/children/$parentId')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['items'] is List) {
      return (body['items'] as List)
          .whereType<Map>()
          .map((m) => TaxonomyNode.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  static Future<List<TaxonomyNode>> search(String q) async {
    if (q.trim().isEmpty) return const [];
    final encoded = Uri.encodeQueryComponent(q.trim());
    final url = ApiConfig.sanitizeUrl(
        '${ApiConfig.baseUrl}/api/service-taxonomy/search?q=$encoded')!;
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return const [];
    final body = jsonDecode(res.body);
    if (body is Map<String, dynamic> && body['items'] is List) {
      return (body['items'] as List)
          .whereType<Map>()
          .map((m) => TaxonomyNode.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }
}
