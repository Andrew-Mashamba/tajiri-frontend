import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class TipPoolService {
  static Future<List<TipPoolRule>> list({required int partnerUserId}) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tip-pools')
            .replace(queryParameters: {'partner_user_id': '$partnerUserId'}),
      );
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => TipPoolRule.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int?> create({
    required int partnerUserId,
    String? skillCategory,
    int tipSplitType = 1,
    List<StaffShare>? staffShares,
    int distributionFrequencyDays = 7,
    int minTipTzs = 0,
  }) async {
    try {
      final body = <String, dynamic>{
        'partner_user_id': partnerUserId,
        'tip_split_type': tipSplitType,
        'distribution_frequency_days': distributionFrequencyDays,
        'min_tip_tzs': minTipTzs,
      };
      if (skillCategory != null) body['skill_category'] = skillCategory;
      if (staffShares != null) {
        body['staff_shares'] = staffShares
            .map((s) => {'user_id': s.userId, 'share_pct': s.sharePct, 'name': s.name})
            .toList();
      }
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tip-pools'),
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
        Uri.parse('${ApiConfig.baseUrl}/tip-pools/$id'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(fields),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<TipDistributionResult?> distribute(int id) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/tip-pools/$id/distribute'),
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body['success'] != true) return null;
      final d = body['data'];
      return TipDistributionResult(
        distributionId: d['distribution_id'] ?? 0,
        totalTipsTzs: d['total_tips_tzs'] ?? 0,
        platformFeeTzs: d['platform_fee_tzs'] ?? 0,
        netDistributedTzs: d['net_distributed_tzs'] ?? 0,
        breakdown: (d['breakdown'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => TipBreakdown.fromJson(m.cast<String, dynamic>()))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<List<TipDistributionResult>> distributions(int id) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tip-pools/$id/distributions'),
      );
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => TipDistributionResult.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class TipPoolRule {
  final int id;
  final int partnerUserId;
  final String? skillCategory;
  final bool isActive;
  final int tipSplitType;
  final List<StaffShare> staffShares;
  final int distributionFrequencyDays;
  final int minTipTzs;

  const TipPoolRule({
    required this.id,
    required this.partnerUserId,
    this.skillCategory,
    required this.isActive,
    required this.tipSplitType,
    required this.staffShares,
    required this.distributionFrequencyDays,
    required this.minTipTzs,
  });

  factory TipPoolRule.fromJson(Map<String, dynamic> j) {
    return TipPoolRule(
      id: j['id'] ?? 0,
      partnerUserId: j['partner_user_id'] ?? 0,
      skillCategory: j['skill_category']?.toString(),
      isActive: j['is_active'] == true,
      tipSplitType: j['tip_split_type'] ?? 1,
      staffShares: (j['staff_shares'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => StaffShare.fromJson(m.cast<String, dynamic>()))
          .toList(),
      distributionFrequencyDays: j['distribution_frequency_days'] ?? 7,
      minTipTzs: j['min_tip_tzs'] ?? 0,
    );
  }
}

class StaffShare {
  final int userId;
  final String name;
  final int sharePct;

  const StaffShare({required this.userId, required this.name, required this.sharePct});

  factory StaffShare.fromJson(Map<String, dynamic> j) {
    return StaffShare(
      userId: j['user_id'] ?? 0,
      name: j['name']?.toString() ?? '',
      sharePct: j['share_pct'] ?? 0,
    );
  }
}

class TipDistributionResult {
  final int distributionId;
  final int totalTipsTzs;
  final int platformFeeTzs;
  final int netDistributedTzs;
  final List<TipBreakdown> breakdown;

  const TipDistributionResult({
    required this.distributionId,
    required this.totalTipsTzs,
    required this.platformFeeTzs,
    required this.netDistributedTzs,
    required this.breakdown,
  });

  factory TipDistributionResult.fromJson(Map<String, dynamic> j) {
    return TipDistributionResult(
      distributionId: j['distribution_id'] ?? j['id'] ?? 0,
      totalTipsTzs: j['total_tips_tzs'] ?? 0,
      platformFeeTzs: j['platform_fee_tzs'] ?? 0,
      netDistributedTzs: j['net_distributed_tzs'] ?? 0,
      breakdown: (j['breakdown'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => TipBreakdown.fromJson(m.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class TipBreakdown {
  final int userId;
  final String name;
  final int sharePct;
  final int amountTzs;

  const TipBreakdown({
    required this.userId,
    required this.name,
    required this.sharePct,
    required this.amountTzs,
  });

  factory TipBreakdown.fromJson(Map<String, dynamic> j) {
    return TipBreakdown(
      userId: j['user_id'] ?? 0,
      name: j['name']?.toString() ?? '',
      sharePct: j['share_pct'] ?? 0,
      amountTzs: j['amount_tzs'] ?? 0,
    );
  }
}
