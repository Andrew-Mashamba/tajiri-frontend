import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class CommissionTierService {
  static Future<List<CommissionTier>> list({required int partnerUserId}) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/commission-tiers')
            .replace(queryParameters: {'partner_user_id': '$partnerUserId'}),
      );
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => CommissionTier.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int?> create({
    required int partnerUserId,
    String? skillCategory,
    required String tierName,
    int tierLevel = 1,
    int commissionPct = 10,
    int minMonthlyRevenueTzs = 0,
    int? maxMonthlyRevenueTzs,
    bool isDefault = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'partner_user_id': partnerUserId,
        'tier_name': tierName,
        'tier_level': tierLevel,
        'commission_pct': commissionPct,
        'min_monthly_revenue_tzs': minMonthlyRevenueTzs,
        'is_default': isDefault,
      };
      if (skillCategory != null) body['skill_category'] = skillCategory;
      if (maxMonthlyRevenueTzs != null) {
        body['max_monthly_revenue_tzs'] = maxMonthlyRevenueTzs;
      }
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/commission-tiers'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        return decoded['data']?['id'] as int?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> update(int id, Map<String, dynamic> fields) async {
    try {
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/commission-tiers/$id'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(fields),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> delete(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/commission-tiers/$id'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<ApplicableTierResult?> applicableTier({
    required int partnerUserId,
    String? skillCategory,
    required int orderTotalTzs,
  }) async {
    try {
      final params = <String, String>{
        'partner_user_id': '$partnerUserId',
        'order_total_tzs': '$orderTotalTzs',
      };
      if (skillCategory != null) params['skill_category'] = skillCategory;
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/commission-tiers/$partnerUserId/applies-to-order')
            .replace(queryParameters: params),
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body['success'] != true) return null;
      final d = body['data'];
      if (d == null) return null;
      return ApplicableTierResult(
        tierId: d['tier_id'] ?? 0,
        tierName: d['tier_name'] ?? '',
        tierLevel: d['tier_level'] ?? 1,
        commissionPct: d['commission_pct'] ?? 0,
        commissionTzs: d['commission_tzs'] ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

class CommissionTier {
  final int id;
  final int partnerUserId;
  final String? skillCategory;
  final String tierName;
  final int tierLevel;
  final int commissionPct;
  final int minMonthlyRevenueTzs;
  final int? maxMonthlyRevenueTzs;
  final bool isDefault;

  const CommissionTier({
    required this.id,
    required this.partnerUserId,
    this.skillCategory,
    required this.tierName,
    required this.tierLevel,
    required this.commissionPct,
    required this.minMonthlyRevenueTzs,
    this.maxMonthlyRevenueTzs,
    required this.isDefault,
  });

  factory CommissionTier.fromJson(Map<String, dynamic> j) {
    return CommissionTier(
      id: j['id'] ?? 0,
      partnerUserId: j['partner_user_id'] ?? 0,
      skillCategory: j['skill_category']?.toString(),
      tierName: j['tier_name']?.toString() ?? '',
      tierLevel: j['tier_level'] ?? 1,
      commissionPct: j['commission_pct'] ?? 0,
      minMonthlyRevenueTzs: j['min_monthly_revenue_tzs'] ?? 0,
      maxMonthlyRevenueTzs: j['max_monthly_revenue_tzs'] as int?,
      isDefault: j['is_default'] == true,
    );
  }
}

class ApplicableTierResult {
  final int tierId;
  final String tierName;
  final int tierLevel;
  final int commissionPct;
  final int commissionTzs;

  const ApplicableTierResult({
    required this.tierId,
    required this.tierName,
    required this.tierLevel,
    required this.commissionPct,
    required this.commissionTzs,
  });
}
