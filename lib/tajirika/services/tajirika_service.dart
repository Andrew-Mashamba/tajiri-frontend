import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/income_service.dart';
import '../models/tajirika_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

void _log(String message) {
  debugPrint('[TajirikaService] $message');
}

class TajirikaService {
  // ==================== REGISTRATION & PROFILE ====================

  static Future<PartnerResult> registerPartner(
    String token,
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['user_id'] = userId;
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/partners'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201 && body['success'] == true) {
        return PartnerResult(
          success: true,
          partner: TajirikaPartner.fromJson(body['data']),
        );
      }
      return PartnerResult(
        success: false,
        message: body['message'] ?? 'Registration failed',
      );
    } catch (e) {
      _log('registerPartner error: $e');
      return PartnerResult(success: false, message: 'Error: $e');
    }
  }

  static Future<PartnerResult> getMyPartnerProfile(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/me?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerResult(
          success: true,
          partner: TajirikaPartner.fromJson(body['data']),
        );
      }
      if (response.statusCode == 404) {
        return PartnerResult(success: false, message: 'not_registered');
      }
      return PartnerResult(
        success: false,
        message: body['message'] ?? 'Failed to load',
      );
    } catch (e) {
      _log('getMyPartnerProfile error: $e');
      return PartnerResult(success: false, message: 'Error: $e');
    }
  }

  static Future<PartnerResult> getPartnerProfile(
    String token,
    int partnerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/$partnerId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerResult(
          success: true,
          partner: TajirikaPartner.fromJson(body['data']),
        );
      }
      return PartnerResult(
        success: false,
        message: body['message'] ?? 'Failed to load',
      );
    } catch (e) {
      _log('getPartnerProfile error: $e');
      return PartnerResult(success: false, message: 'Error: $e');
    }
  }

  static Future<PartnerResult> updatePartnerProfile(
    String token,
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['user_id'] = userId;
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerResult(
          success: true,
          partner: TajirikaPartner.fromJson(body['data']),
        );
      }
      return PartnerResult(
        success: false,
        message: body['message'] ?? 'Failed to update',
      );
    } catch (e) {
      _log('updatePartnerProfile error: $e');
      return PartnerResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> updateServiceArea(
    String token,
    int userId,
    List<int> regionIds,
    List<int> districtIds,
    List<int> wardIds,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me/service-area?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'user_id': userId,
          'region_ids': regionIds,
          'district_ids': districtIds,
          'ward_ids': wardIds,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to update service area',
      );
    } catch (e) {
      _log('updateServiceArea error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> updateAvailability(
    String token,
    int userId,
    List<AvailabilitySlot> schedule,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me/availability?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'user_id': userId,
          'slots': schedule.map((s) => s.toJson()).toList(),
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to update schedule',
      );
    } catch (e) {
      _log('updateAvailability error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> updatePayoutAccount(
    String token,
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['user_id'] = userId;
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me/payout-account?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to update payout account',
      );
    } catch (e) {
      _log('updatePayoutAccount error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  // ==================== VERIFICATION ====================

  static Future<TajirikaResult> submitNidaVerification(
    String token,
    int userId,
    String nidaNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/verifications/nida'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'user_id': userId, 'nida_number': nidaNumber}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to submit NIDA',
      );
    } catch (e) {
      _log('submitNidaVerification error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> submitTinVerification(
    String token,
    int userId,
    String tinNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/verifications/tin'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'user_id': userId, 'tin_number': tinNumber}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to submit TIN',
      );
    } catch (e) {
      _log('submitTinVerification error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> submitProfessionalLicense(
    String token,
    int userId,
    String licenseType,
    File file,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/tajirika/verifications/professional'),
      );
      request.headers.addAll(ApiConfig.authHeaders(token));
      request.fields['user_id'] = userId.toString();
      request.fields['license_type'] = licenseType;
      request.files.add(
        await http.MultipartFile.fromPath('document', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to submit license',
      );
    } catch (e) {
      _log('submitProfessionalLicense error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> submitBackgroundCheck(String token, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/verifications/background'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'user_id': userId}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to submit',
      );
    } catch (e) {
      _log('submitBackgroundCheck error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<VerificationStatus> getVerificationStatus(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/verifications?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return VerificationStatus.fromJson(body['data']);
      }
      return VerificationStatus.empty();
    } catch (e) {
      _log('getVerificationStatus error: $e');
      return VerificationStatus.empty();
    }
  }

  static Future<TajirikaResult> submitPeerVouch(
    String token,
    int userId,
    int partnerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/partners/$partnerId/vouch'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'user_id': userId}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed',
      );
    } catch (e) {
      _log('submitPeerVouch error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  // ==================== SKILLS & CERTIFICATION ====================

  static Future<TajirikaResult> updateSkills(
    String token,
    int userId,
    List<String> skills,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/partners/me/skills?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'user_id': userId, 'skills': skills}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to update skills',
      );
    } catch (e) {
      _log('updateSkills error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> submitSkillTest(
    String token,
    int userId,
    String categoryKey,
    File file,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/tajirika/skills/test'),
      );
      request.headers.addAll(ApiConfig.authHeaders(token));
      request.fields['user_id'] = userId.toString();
      request.fields['category'] = categoryKey;
      request.files.add(
        await http.MultipartFile.fromPath('video', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to submit skill test',
      );
    } catch (e) {
      _log('submitSkillTest error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TierProgress> getTierProgress(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/me/tier-progress?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TierProgress.fromJson(body['data']);
      }
      return TierProgress(currentTier: PartnerTier.mwanafunzi);
    } catch (e) {
      _log('getTierProgress error: $e');
      return TierProgress(currentTier: PartnerTier.mwanafunzi);
    }
  }

  static Future<BadgeListResult> getBadges(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/me/badges?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final badges = (body['data'] as List)
            .map((b) => Badge.fromJson(b))
            .toList();
        return BadgeListResult(success: true, badges: badges);
      }
      return BadgeListResult(success: false);
    } catch (e) {
      _log('getBadges error: $e');
      return BadgeListResult(success: false, message: 'Error: $e');
    }
  }

  // ==================== PORTFOLIO ====================

  static Future<PortfolioListResult> getPortfolio(
    String token,
    int partnerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/$partnerId/portfolio'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final items = (body['data'] as List)
            .map((p) => PortfolioItem.fromJson(p))
            .toList();
        return PortfolioListResult(success: true, items: items);
      }
      return PortfolioListResult(success: false);
    } catch (e) {
      _log('getPortfolio error: $e');
      return PortfolioListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> uploadPortfolioItem(
    String token,
    int userId,
    File file,
    String? caption,
    String? skillCategory,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/tajirika/portfolio'),
      );
      request.headers.addAll(ApiConfig.authHeaders(token));
      request.fields['user_id'] = userId.toString();
      if (caption != null) request.fields['caption'] = caption;
      if (skillCategory != null) request.fields['skill_category'] = skillCategory;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to load',
      );
    } catch (e) {
      _log('uploadPortfolioItem error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> deletePortfolioItem(
    String token,
    int userId,
    int itemId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/tajirika/portfolio/$itemId?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to delete',
      );
    } catch (e) {
      _log('deletePortfolioItem error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  // ==================== TRAINING ====================

  static Future<TrainingListResult> getTrainingCourses(
    String token,
    int userId, {
    String? category,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'user_id': userId.toString(),
      };
      if (category != null) params['category'] = category;

      final uri = Uri.parse('$_baseUrl/tajirika/training')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final courses = (body['data'] as List)
            .map((c) => TrainingCourse.fromJson(c))
            .toList();
        return TrainingListResult(success: true, courses: courses);
      }
      return TrainingListResult(success: false);
    } catch (e) {
      _log('getTrainingCourses error: $e');
      return TrainingListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> updateCourseProgress(
    String token,
    int userId,
    int courseId,
    double progress,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/tajirika/training/$courseId/progress?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'user_id': userId, 'progress': progress}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return TajirikaResult(success: true);
      }
      return TajirikaResult(success: false);
    } catch (e) {
      _log('updateCourseProgress error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<List<MentorshipMatch>> getMentorshipMatches(
    String token,
    int userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/mentorship?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return (body['data'] as List)
            .map((m) => MentorshipMatch.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      _log('getMentorshipMatches error: $e');
      return [];
    }
  }

  // ==================== REFERRALS ====================

  static Future<ReferralListResult> getReferrals(
    String token,
    int userId, {
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/referrals?user_id=$userId&page=$page'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final referrals = (body['data'] as List)
            .map((r) => Referral.fromJson(r))
            .toList();
        return ReferralListResult(success: true, referrals: referrals);
      }
      return ReferralListResult(success: false);
    } catch (e) {
      _log('getReferrals error: $e');
      return ReferralListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ReferralStats> getReferralStats(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/referrals/stats?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return ReferralStats.fromJson(body['data']);
      }
      return ReferralStats(referralCode: '');
    } catch (e) {
      _log('getReferralStats error: $e');
      return ReferralStats(referralCode: '');
    }
  }

  // ==================== EARNINGS & ANALYTICS ====================

  static Future<PartnerEarnings> getEarnings(
    String token,
    int userId, {
    String period = 'monthly',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/earnings?user_id=$userId&period=$period'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerEarnings.fromJson(body['data']);
      }
      return PartnerEarnings();
    } catch (e) {
      _log('getEarnings error: $e');
      return PartnerEarnings();
    }
  }

  static Future<Map<String, double>> getEarningsByModule(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/earnings/by-module?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final map = <String, double>{};
        (body['data'] as Map).forEach((key, value) {
          map[key.toString()] = _parseDouble(value);
        });
        return map;
      }
      return {};
    } catch (e) {
      _log('getEarningsByModule error: $e');
      return {};
    }
  }

  static Future<TajirikaResult> requestPayout(
    String token,
    int userId,
    double amount,
    String method,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/payouts'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'user_id': userId, 'amount': amount, 'method': method}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        // Fire-and-forget: record payout as income in budget system
        IncomeService.recordIncome(
          token: token,
          amount: amount,
          source: 'tajirika_payout',
          description: 'Tajirika payout',
          referenceId: 'tajirika_payout_${DateTime.now().millisecondsSinceEpoch}',
          sourceModule: 'tajirika',
        ).catchError((_) => null);
        return TajirikaResult(success: true);
      }
      return TajirikaResult(
        success: false,
        message: body['message'] ?? 'Failed to request payout',
      );
    } catch (e) {
      _log('requestPayout error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<PayoutListResult> getPayoutHistory(
    String token,
    int userId, {
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/payouts?user_id=$userId&page=$page'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final payouts = (body['data'] as List)
            .map((p) => Payout.fromJson(p))
            .toList();
        return PayoutListResult(success: true, payouts: payouts);
      }
      return PayoutListResult(success: false);
    } catch (e) {
      _log('getPayoutHistory error: $e');
      return PayoutListResult(success: false, message: 'Error: $e');
    }
  }

  static Future<PartnerStats> getPartnerStats(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tajirika/partners/me/stats?user_id=$userId'),
        headers: ApiConfig.authHeaders(token),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return PartnerStats.fromJson(body['data']);
      }
      return PartnerStats();
    } catch (e) {
      _log('getPartnerStats error: $e');
      return PartnerStats();
    }
  }

  // ==================== PARTNER DISCOVERY (for domain modules) ====================

  static Future<List<TajirikaPartner>> searchPartners(
    String token, {
    List<String>? skills,
    int? regionId,
    String? tier,
    double? minRating,
    bool? available,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (skills != null && skills.isNotEmpty) params['skills'] = skills.join(',');
      if (regionId != null) params['region_id'] = regionId.toString();
      if (tier != null) params['tier'] = tier;
      if (minRating != null) params['min_rating'] = minRating.toString();
      if (available != null) params['available'] = available.toString();

      final uri = Uri.parse('$_baseUrl/tajirika/partners')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return (body['data'] as List)
            .map((p) => TajirikaPartner.fromJson(p))
            .toList();
      }
      return [];
    } catch (e) {
      _log('searchPartners error: $e');
      return [];
    }
  }

  static Future<TajirikaResult> reportJobCompleted(
    String token,
    int partnerId,
    String module,
    String jobId,
    double rating,
    double earnings,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tajirika/partners/$partnerId/job-completed'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'module': module,
          'job_id': jobId,
          'rating': rating,
          'earnings': earnings,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        // Fire-and-forget: record job earnings as income in budget system
        IncomeService.recordIncome(
          token: token,
          amount: earnings,
          source: 'tajirika_job',
          description: 'Tajirika: $module job completed',
          referenceId: 'tajirika_job_$jobId',
          sourceModule: 'tajirika',
          metadata: {'module': module, 'jobId': jobId},
        ).catchError((_) => null);
        return TajirikaResult(success: true);
      }
      return TajirikaResult(success: false);
    } catch (e) {
      _log('reportJobCompleted error: $e');
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }
}
