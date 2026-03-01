import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/contribution_models.dart';
import '../config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

class ContributionService {
  // ==================== CAMPAIGNS ====================

  /// Get user's campaigns
  Future<CampaignsResult> getUserCampaigns(int userId, {String? status}) async {
    try {
      String url = '$_baseUrl/users/$userId/campaigns';
      if (status != null) url += '?status=$status';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final campaigns = (data['data'] as List)
              .map((c) => Campaign.fromJson(c))
              .toList();
          return CampaignsResult(success: true, campaigns: campaigns);
        }
      }
      return CampaignsResult(success: false, message: 'Imeshindwa kupakia michango');
    } catch (e) {
      return CampaignsResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Get user's campaign statistics
  Future<StatsResult> getUserCampaignStats(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/$userId/campaigns/stats'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return StatsResult(
            success: true,
            stats: CampaignStats.fromJson(data['data']),
          );
        }
      }
      return StatsResult(success: false, message: 'Imeshindwa kupakia takwimu');
    } catch (e) {
      return StatsResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Get single campaign details
  Future<CampaignResult> getCampaign(int campaignId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/campaigns/$campaignId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CampaignResult(
            success: true,
            campaign: Campaign.fromJson(data['data']),
          );
        }
      }
      return CampaignResult(success: false, message: 'Mchango haujapatikana');
    } catch (e) {
      return CampaignResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Create a new campaign
  Future<CampaignResult> createCampaign({
    required int userId,
    required String title,
    required String story,
    String? shortDescription,
    required double goalAmount,
    required CampaignCategory category,
    DateTime? deadline,
    File? coverImage,
    List<File>? mediaFiles,
    bool allowAnonymousDonations = true,
    double minimumDonation = 1000,
    bool isUrgent = false,
    String? bankName,
    String? accountNumber,
    String? mobileMoneyNumber,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/campaigns'));

      request.fields['user_id'] = userId.toString();
      request.fields['title'] = title;
      request.fields['story'] = story;
      if (shortDescription != null) request.fields['short_description'] = shortDescription;
      request.fields['goal_amount'] = goalAmount.toString();
      request.fields['category'] = category.name;
      if (deadline != null) request.fields['deadline'] = deadline.toIso8601String();
      request.fields['allow_anonymous_donations'] = allowAnonymousDonations.toString();
      request.fields['minimum_donation'] = minimumDonation.toString();
      request.fields['is_urgent'] = isUrgent.toString();
      if (bankName != null) request.fields['bank_name'] = bankName;
      if (accountNumber != null) request.fields['account_number'] = accountNumber;
      if (mobileMoneyNumber != null) request.fields['mobile_money_number'] = mobileMoneyNumber;

      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_image', coverImage.path));
      }

      if (mediaFiles != null) {
        for (var i = 0; i < mediaFiles.length; i++) {
          request.files.add(await http.MultipartFile.fromPath('media[$i]', mediaFiles[i].path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return CampaignResult(
          success: true,
          campaign: Campaign.fromJson(data['data']),
        );
      }
      return CampaignResult(success: false, message: data['message'] ?? 'Imeshindwa kuunda mchango');
    } catch (e) {
      return CampaignResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Update campaign
  Future<CampaignResult> updateCampaign(
    int campaignId, {
    String? title,
    String? story,
    String? shortDescription,
    double? goalAmount,
    CampaignCategory? category,
    DateTime? deadline,
    File? coverImage,
    bool? allowAnonymousDonations,
    double? minimumDonation,
    bool? isUrgent,
  }) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/campaigns/$campaignId'));

      if (title != null) request.fields['title'] = title;
      if (story != null) request.fields['story'] = story;
      if (shortDescription != null) request.fields['short_description'] = shortDescription;
      if (goalAmount != null) request.fields['goal_amount'] = goalAmount.toString();
      if (category != null) request.fields['category'] = category.name;
      if (deadline != null) request.fields['deadline'] = deadline.toIso8601String();
      if (allowAnonymousDonations != null) {
        request.fields['allow_anonymous_donations'] = allowAnonymousDonations.toString();
      }
      if (minimumDonation != null) request.fields['minimum_donation'] = minimumDonation.toString();
      if (isUrgent != null) request.fields['is_urgent'] = isUrgent.toString();

      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_image', coverImage.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CampaignResult(
          success: true,
          campaign: Campaign.fromJson(data['data']),
        );
      }
      return CampaignResult(success: false, message: data['message'] ?? 'Imeshindwa kuhariri');
    } catch (e) {
      return CampaignResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Publish/activate a draft campaign
  Future<CampaignResult> publishCampaign(int campaignId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/campaigns/$campaignId/publish'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CampaignResult(
            success: true,
            campaign: Campaign.fromJson(data['data']),
          );
        }
        return CampaignResult(success: false, message: data['message']);
      }
      return CampaignResult(success: false, message: 'Imeshindwa kuchapisha');
    } catch (e) {
      return CampaignResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Pause an active campaign
  Future<CampaignResult> pauseCampaign(int campaignId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/campaigns/$campaignId/pause'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CampaignResult(
            success: true,
            campaign: Campaign.fromJson(data['data']),
          );
        }
      }
      return CampaignResult(success: false, message: 'Imeshindwa kusimamisha');
    } catch (e) {
      return CampaignResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Resume a paused campaign
  Future<CampaignResult> resumeCampaign(int campaignId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/campaigns/$campaignId/resume'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CampaignResult(
            success: true,
            campaign: Campaign.fromJson(data['data']),
          );
        }
      }
      return CampaignResult(success: false, message: 'Imeshindwa kuendelea');
    } catch (e) {
      return CampaignResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Complete/close a campaign
  Future<CampaignResult> completeCampaign(int campaignId) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/campaigns/$campaignId/complete'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return CampaignResult(
            success: true,
            campaign: Campaign.fromJson(data['data']),
          );
        }
      }
      return CampaignResult(success: false, message: 'Imeshindwa kukamilisha');
    } catch (e) {
      return CampaignResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Delete a draft campaign
  Future<BaseResult> deleteCampaign(int campaignId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/campaigns/$campaignId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BaseResult(success: data['success'] == true, message: data['message']);
      }
      return BaseResult(success: false, message: 'Imeshindwa kufuta');
    } catch (e) {
      return BaseResult(success: false, message: 'Hitilafu: $e');
    }
  }

  // ==================== CAMPAIGN UPDATES ====================

  /// Post an update to campaign
  Future<UpdateResult> postCampaignUpdate(
    int campaignId, {
    required String content,
    List<File>? mediaFiles,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/campaigns/$campaignId/updates'),
      );

      request.fields['content'] = content;

      if (mediaFiles != null) {
        for (var i = 0; i < mediaFiles.length; i++) {
          request.files.add(await http.MultipartFile.fromPath('media[$i]', mediaFiles[i].path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return UpdateResult(
          success: true,
          update: CampaignUpdate.fromJson(data['data']),
        );
      }
      return UpdateResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return UpdateResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Get campaign updates
  Future<UpdatesResult> getCampaignUpdates(int campaignId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/campaigns/$campaignId/updates'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final updates = (data['data'] as List)
              .map((u) => CampaignUpdate.fromJson(u))
              .toList();
          return UpdatesResult(success: true, updates: updates);
        }
      }
      return UpdatesResult(success: false, message: 'Imeshindwa');
    } catch (e) {
      return UpdatesResult(success: false, message: 'Hitilafu: $e');
    }
  }

  // ==================== DONATIONS ====================

  /// Donate to a campaign (wallet or mobile money).
  /// POST /api/campaigns/{id}/donate
  Future<DonationResult> donateToCampaign(
    int campaignId, {
    required double amount,
    required String paymentMethod, // 'wallet' | 'mobile_money'
    String? message,
    bool isAnonymous = false,
    String? pin, // required when paymentMethod is 'wallet'
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'payment_method': paymentMethod,
        'is_anonymous': isAnonymous,
      };
      if (message != null && message.isNotEmpty) body['message'] = message;
      if (paymentMethod == 'wallet' && pin != null) body['pin'] = pin;

      final response = await http.post(
        Uri.parse('$_baseUrl/campaigns/$campaignId/donate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true && data['data'] != null) {
          return DonationResult(
            success: true,
            donation: Donation.fromJson(data['data']),
            message: data['message'],
          );
        }
      }
      return DonationResult(
        success: false,
        message: data['message'] ?? 'Imeshindwa kuchangia',
      );
    } catch (e) {
      return DonationResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Get campaign donations
  Future<DonationsResult> getCampaignDonations(int campaignId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/campaigns/$campaignId/donations?page=$page'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final donations = (data['data'] as List)
              .map((d) => Donation.fromJson(d))
              .toList();
          return DonationsResult(success: true, donations: donations);
        }
      }
      return DonationsResult(success: false, message: 'Imeshindwa');
    } catch (e) {
      return DonationsResult(success: false, message: 'Hitilafu: $e');
    }
  }

  // ==================== WITHDRAWALS ====================

  /// Get campaign withdrawals
  Future<WithdrawalsResult> getCampaignWithdrawals(int campaignId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/campaigns/$campaignId/withdrawals'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final withdrawals = (data['data'] as List)
              .map((w) => Withdrawal.fromJson(w))
              .toList();
          return WithdrawalsResult(success: true, withdrawals: withdrawals);
        }
      }
      return WithdrawalsResult(success: false, message: 'Imeshindwa');
    } catch (e) {
      return WithdrawalsResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Request withdrawal
  Future<WithdrawalResult> requestWithdrawal(
    int campaignId, {
    required double amount,
    required String destinationType, // 'bank' or 'mobile_money'
    required String destinationDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/campaigns/$campaignId/withdrawals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'destination_type': destinationType,
          'destination_details': destinationDetails,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        return WithdrawalResult(
          success: true,
          withdrawal: Withdrawal.fromJson(data['data']),
        );
      }
      return WithdrawalResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return WithdrawalResult(success: false, message: 'Hitilafu: $e');
    }
  }

  /// Get user's all withdrawals
  Future<WithdrawalsResult> getUserWithdrawals(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/$userId/withdrawals'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final withdrawals = (data['data'] as List)
              .map((w) => Withdrawal.fromJson(w))
              .toList();
          return WithdrawalsResult(success: true, withdrawals: withdrawals);
        }
      }
      return WithdrawalsResult(success: false, message: 'Imeshindwa');
    } catch (e) {
      return WithdrawalsResult(success: false, message: 'Hitilafu: $e');
    }
  }
}

// ==================== RESULT CLASSES ====================

class BaseResult {
  final bool success;
  final String? message;

  BaseResult({required this.success, this.message});
}

class CampaignsResult {
  final bool success;
  final List<Campaign> campaigns;
  final String? message;

  CampaignsResult({required this.success, this.campaigns = const [], this.message});
}

class CampaignResult {
  final bool success;
  final Campaign? campaign;
  final String? message;

  CampaignResult({required this.success, this.campaign, this.message});
}

class StatsResult {
  final bool success;
  final CampaignStats? stats;
  final String? message;

  StatsResult({required this.success, this.stats, this.message});
}

class UpdateResult {
  final bool success;
  final CampaignUpdate? update;
  final String? message;

  UpdateResult({required this.success, this.update, this.message});
}

class UpdatesResult {
  final bool success;
  final List<CampaignUpdate> updates;
  final String? message;

  UpdatesResult({required this.success, this.updates = const [], this.message});
}

class DonationResult {
  final bool success;
  final Donation? donation;
  final String? message;

  DonationResult({required this.success, this.donation, this.message});
}

class DonationsResult {
  final bool success;
  final List<Donation> donations;
  final String? message;

  DonationsResult({required this.success, this.donations = const [], this.message});
}

class WithdrawalResult {
  final bool success;
  final Withdrawal? withdrawal;
  final String? message;

  WithdrawalResult({required this.success, this.withdrawal, this.message});
}

class WithdrawalsResult {
  final bool success;
  final List<Withdrawal> withdrawals;
  final String? message;

  WithdrawalsResult({required this.success, this.withdrawals = const [], this.message});
}
