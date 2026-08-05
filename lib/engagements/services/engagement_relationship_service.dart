import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../services/http_retry.dart';
import '../../config/api_config.dart';

class EngagementRelationship {
  final int completedCount;
  final DateTime? firstEngagementDate;

  EngagementRelationship({
    required this.completedCount,
    required this.firstEngagementDate,
  });

  factory EngagementRelationship.fromJson(Map<String, dynamic> json) {
    return EngagementRelationship(
      completedCount: json['completed_engagement_count'] is int
          ? json['completed_engagement_count'] as int
          : int.tryParse(json['completed_engagement_count']?.toString() ?? '') ?? 0,
      firstEngagementDate: json['first_engagement_date'] == null
          ? null
          : DateTime.tryParse(json['first_engagement_date'].toString()),
    );
  }
}

class EngagementRelationshipService {
  static Future<EngagementRelationship?> show({
    required int partnerUserId,
    required int customerUserId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/engagement-relationships')
        .replace(queryParameters: {
      'partner_user_id': '$partnerUserId',
      'customer_user_id': '$customerUserId',
    });
    try {
      final res = await httpGetWithRetry(uri);
      if (res.statusCode != 200) return null;
      final r = jsonDecode(res.body);
      if (r['success'] != true || r['data'] == null) return null;
      return EngagementRelationship.fromJson(
          (r['data'] as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('[EngagementRelationshipService] $e');
      return null;
    }
  }
}
