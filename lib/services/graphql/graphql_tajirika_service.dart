import 'dart:io';

import '../../tajirika/models/tajirika_models.dart';
import 'graphql_media_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Tajirika partner profile (Phase 93).
class GraphqlTajirikaService {
  static const _partnerFields = r'''
    id
    userId
    displayName
    bio
    serviceArea
    skills
    tier
    isActive
    rating
    jobsCompleted
    createdAt
  ''';

  static Map<String, dynamic> _partnerToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': int.tryParse(row['userId']?.toString() ?? '') ?? 0,
      'name': row['displayName'],
      'bio': row['bio'],
      'tier': row['tier'],
      'aggregate_rating': row['rating'] ?? 0,
      'jobs_completed': row['jobsCompleted'] ?? 0,
      'is_active': row['isActive'] ?? true,
      'skills': row['skills'] is List ? row['skills'] : [],
      'created_at': row['createdAt'],
    };
  }

  static TajirikaPartner _parsePartner(Map<String, dynamic> row) {
    return TajirikaPartner.fromJson(_partnerToLegacy(row));
  }

  static String _displayNameFromData(Map<String, dynamic> data) {
    final first = data['first_name']?.toString().trim() ?? '';
    final last = data['last_name']?.toString().trim() ?? '';
    if (first.isNotEmpty || last.isNotEmpty) {
      return [first, last].where((s) => s.isNotEmpty).join(' ');
    }
    return data['name']?.toString() ?? data['display_name']?.toString() ?? '';
  }

  static Map<String, dynamic>? _serviceAreaFromData(Map<String, dynamic> data) {
    if (data['service_area'] is Map) {
      return Map<String, dynamic>.from(data['service_area'] as Map);
    }
    if (data['region_id'] != null || data['district_id'] != null) {
      return {
        if (data['region_id'] != null) 'region_id': data['region_id'],
        if (data['region'] != null) 'region': data['region'],
        if (data['district_id'] != null) 'district_id': data['district_id'],
        if (data['district'] != null) 'district': data['district'],
        if (data['ward_id'] != null) 'ward_id': data['ward_id'],
        if (data['ward'] != null) 'ward': data['ward'],
      };
    }
    return null;
  }

  static Future<PartnerResult> registerPartner(
    Map<String, dynamic> data,
  ) async {
    try {
      final displayName = _displayNameFromData(data);
      if (displayName.isEmpty) {
        return PartnerResult(
          success: false,
          message: 'Display name is required',
        );
      }
      final gqlData = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RegisterTajirikaPartner(\$input: RegisterTajirikaPartnerInput!) {
          registerTajirikaPartner(input: \$input) {
            $_partnerFields
          }
        }
        ''',
        variables: {
          'input': {
            'displayName': displayName,
            if (data['bio'] != null) 'bio': data['bio'],
            if (data['skills'] != null) 'skills': data['skills'],
            if (_serviceAreaFromData(data) != null)
              'serviceArea': _serviceAreaFromData(data),
            'tier': data['tier']?.toString() ?? 'standard',
          },
        },
        auth: true,
      );
      final row = gqlData['registerTajirikaPartner'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerResult(success: false, message: 'Registration failed');
      }
      return PartnerResult(success: true, partner: _parsePartner(row));
    } catch (e) {
      return PartnerResult(success: false, message: 'Error: $e');
    }
  }

  static Future<PartnerResult> getMyPartnerProfile() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaPartner {
          myTajirikaPartner {
            $_partnerFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['myTajirikaPartner'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerResult(success: false, message: 'not_registered');
      }
      return PartnerResult(success: true, partner: _parsePartner(row));
    } catch (e) {
      return PartnerResult(success: false, message: 'Error: $e');
    }
  }

  static Future<PartnerResult> updatePartnerProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final gqlData = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateTajirikaPartner(\$input: UpdateTajirikaPartnerInput!) {
          updateTajirikaPartner(input: \$input) {
            $_partnerFields
          }
        }
        ''',
        variables: {
          'input': {
            if (data['bio'] != null) 'bio': data['bio'],
            if (data['skills'] != null) 'skills': data['skills'],
            if (data['tier'] != null) 'tier': data['tier'],
            if (data['is_active'] != null) 'isActive': data['is_active'],
            if (_serviceAreaFromData(data) != null)
              'serviceArea': _serviceAreaFromData(data),
            if (_displayNameFromData(data).isNotEmpty)
              'displayName': _displayNameFromData(data),
          },
        },
        auth: true,
      );
      final row = gqlData['updateTajirikaPartner'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerResult(success: false, message: 'Failed to update');
      }
      return PartnerResult(success: true, partner: _parsePartner(row));
    } catch (e) {
      return PartnerResult(success: false, message: 'Error: $e');
    }
  }

  static Future<PartnerResult> getPartnerProfile(int partnerId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartner(\$partnerId: ID!) {
          tajirikaPartner(partnerId: \$partnerId) {
            $_partnerFields
          }
        }
        ''',
        variables: {'partnerId': partnerId.toString()},
        auth: true,
      );
      final row = data['tajirikaPartner'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerResult(success: false, message: 'Failed to load');
      }
      return PartnerResult(success: true, partner: _parsePartner(row));
    } catch (e) {
      return PartnerResult(success: false, message: 'Error: $e');
    }
  }

  static Future<List<TajirikaPartner>> searchPartners({
    String? query,
    String? skill,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartners(\$query: String, \$skill: String) {
          tajirikaPartners(query: \$query, skill: \$skill) {
            $_partnerFields
          }
        }
        ''',
        variables: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (skill != null && skill.isNotEmpty) 'skill': skill,
        },
        auth: true,
      );
      final rows = data['tajirikaPartners'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(_parsePartner)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<VerificationStatus> getVerificationStatus() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaVerifications {
          myTajirikaVerifications {
            nida { type status number documentUrl submittedAt verifiedAt expiresAt rejectionReason }
            tin { type status number documentUrl submittedAt verifiedAt expiresAt rejectionReason }
            professional { type status number documentUrl submittedAt verifiedAt expiresAt rejectionReason }
            background { type status number documentUrl submittedAt verifiedAt expiresAt rejectionReason }
          }
        }
        ''',
        auth: true,
      );
      final row = data['myTajirikaVerifications'] as Map<String, dynamic>?;
      if (row == null) return VerificationStatus.empty();
      return VerificationStatus.fromJson(_verificationToLegacy(row));
    } catch (_) {
      return VerificationStatus.empty();
    }
  }

  static Map<String, dynamic> _verificationItemToLegacy(Map<String, dynamic> row) {
    return {
      'type': row['type'],
      'status': row['status'],
      if (row['number'] != null) 'number': row['number'],
      if (row['documentUrl'] != null) 'document_url': row['documentUrl'],
      if (row['submittedAt'] != null) 'submitted_at': row['submittedAt'],
      if (row['verifiedAt'] != null) 'verified_at': row['verifiedAt'],
      if (row['expiresAt'] != null) 'expires_at': row['expiresAt'],
      if (row['rejectionReason'] != null) 'rejection_reason': row['rejectionReason'],
    };
  }

  static Map<String, dynamic> _verificationToLegacy(Map<String, dynamic> row) {
    return {
      'nida': _verificationItemToLegacy(row['nida'] as Map<String, dynamic>? ?? {}),
      'tin': _verificationItemToLegacy(row['tin'] as Map<String, dynamic>? ?? {}),
      'professional': _verificationItemToLegacy(
        row['professional'] as Map<String, dynamic>? ?? {},
      ),
      'background': _verificationItemToLegacy(
        row['background'] as Map<String, dynamic>? ?? {},
      ),
    };
  }

  static Future<PortfolioListResult> getPortfolio(int partnerId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerPortfolio(\$partnerId: ID!) {
          tajirikaPartnerPortfolio(partnerId: \$partnerId) {
            id
            itemType
            url
            thumbnailUrl
            caption
            skillCategory
            createdAt
          }
        }
        ''',
        variables: {'partnerId': partnerId.toString()},
        auth: true,
      );
      final rows = data['tajirikaPartnerPortfolio'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PortfolioItem.fromJson(_portfolioToLegacy(row)))
          .toList();
      return PortfolioListResult(success: true, items: items);
    } catch (e) {
      return PortfolioListResult(success: false, message: 'Error: $e');
    }
  }

  static Map<String, dynamic> _portfolioToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'type': row['itemType'] ?? 'photo',
      'url': row['url'],
      if (row['thumbnailUrl'] != null) 'thumbnail_url': row['thumbnailUrl'],
      if (row['caption'] != null) 'caption': row['caption'],
      if (row['skillCategory'] != null) 'skill_category': row['skillCategory'],
      if (row['createdAt'] != null) 'created_at': row['createdAt'],
    };
  }

  static Future<PartnerEarnings> getEarnings({String period = 'monthly'}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaEarnings(\$period: String) {
          myTajirikaEarnings(period: \$period) {
            totalEarnings
            weeklyEarnings
            monthlyEarnings
            pendingPayout
            byModule
          }
        }
        ''',
        variables: {'period': period},
        auth: true,
      );
      final row = data['myTajirikaEarnings'] as Map<String, dynamic>?;
      if (row == null) return PartnerEarnings();
      return PartnerEarnings.fromJson(_earningsToLegacy(row));
    } catch (_) {
      return PartnerEarnings();
    }
  }

  static Map<String, dynamic> _earningsToLegacy(Map<String, dynamic> row) {
    final byModule = <String, dynamic>{};
    if (row['byModule'] is Map) {
      (row['byModule'] as Map).forEach((key, value) {
        byModule[key.toString()] = value;
      });
    }
    return {
      'total_earnings': row['totalEarnings'] ?? 0,
      'weekly_earnings': row['weeklyEarnings'] ?? 0,
      'monthly_earnings': row['monthlyEarnings'] ?? 0,
      'pending_payout': row['pendingPayout'] ?? 0,
      'by_module': byModule,
    };
  }

  static Future<Map<String, double>> getEarningsByModule() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaEarningsByModule {
          myTajirikaEarningsByModule
        }
        ''',
        auth: true,
      );
      final row = data['myTajirikaEarningsByModule'];
      if (row is! Map) return {};
      final map = <String, double>{};
      row.forEach((key, value) {
        if (value is num) {
          map[key.toString()] = value.toDouble();
        } else if (value is String) {
          map[key.toString()] = double.tryParse(value) ?? 0.0;
        }
      });
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<TierProgress> getTierProgress() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaTierProgress {
          myTajirikaTierProgress {
            currentTier
            nextTier
            jobsCompleted
            jobsNeeded
            currentRating
            ratingNeeded
            trainingCompleted
            trainingNeeded
            verificationsPending
          }
        }
        ''',
        auth: true,
      );
      final row = data['myTajirikaTierProgress'] as Map<String, dynamic>?;
      if (row == null) return TierProgress(currentTier: PartnerTier.mwanafunzi);
      return TierProgress.fromJson(_tierProgressToLegacy(row));
    } catch (_) {
      return TierProgress(currentTier: PartnerTier.mwanafunzi);
    }
  }

  static Map<String, dynamic> _tierProgressToLegacy(Map<String, dynamic> row) {
    return {
      'current_tier': row['currentTier'],
      'next_tier': row['nextTier'],
      'jobs_completed': row['jobsCompleted'] ?? 0,
      'jobs_needed': row['jobsNeeded'] ?? 0,
      'current_rating': row['currentRating'] ?? 0,
      'rating_needed': row['ratingNeeded'] ?? 0,
      'training_completed': row['trainingCompleted'] ?? 0,
      'training_needed': row['trainingNeeded'] ?? 0,
      'verifications_pending': row['verificationsPending'] ?? [],
    };
  }

  static Future<BadgeListResult> getBadges() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaBadges {
          myTajirikaBadges {
            id
            name
            nameSw
            iconUrl
            description
            earnedAt
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myTajirikaBadges'] as List<dynamic>? ?? [];
      final badges = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Badge.fromJson(_badgeToLegacy(row)))
          .toList();
      return BadgeListResult(success: true, badges: badges);
    } catch (e) {
      return BadgeListResult(success: false, message: 'Error: $e');
    }
  }

  static Map<String, dynamic> _badgeToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'name_sw': row['nameSw'],
      if (row['iconUrl'] != null) 'icon_url': row['iconUrl'],
      'description': row['description'] ?? '',
      if (row['earnedAt'] != null) 'earned_at': row['earnedAt'],
    };
  }

  static Future<PartnerStats> getPartnerStats() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaPartnerStats {
          myTajirikaPartnerStats {
            jobsCompleted
            averageRating
            responseTimeMinutes
            repeatCustomerRate
            activeModules
          }
        }
        ''',
        auth: true,
      );
      final row = data['myTajirikaPartnerStats'] as Map<String, dynamic>?;
      if (row == null) return PartnerStats();
      return PartnerStats.fromJson(_partnerStatsToLegacy(row));
    } catch (_) {
      return PartnerStats();
    }
  }

  static Map<String, dynamic> _partnerStatsToLegacy(Map<String, dynamic> row) {
    return {
      'jobs_completed': row['jobsCompleted'] ?? 0,
      'average_rating': row['averageRating'] ?? 0,
      'response_time_minutes': row['responseTimeMinutes'] ?? 0,
      'repeat_customer_rate': row['repeatCustomerRate'] ?? 0,
      'active_modules': row['activeModules'] ?? [],
    };
  }

  static Future<TajirikaResult> uploadPortfolioItem(
    File file, {
    String? caption,
    String? skillCategory,
  }) async {
    try {
      final uploaded = await GraphqlMediaService.uploadFile(
        file,
        mediaType: file.path.toLowerCase().endsWith('.mp4') ? 'video' : 'image',
      );
      final path = uploaded?['file_path']?.toString();
      if (path == null) {
        return TajirikaResult(success: false, message: 'Failed to upload media');
      }
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddTajirikaPortfolioItem(\$input: AddTajirikaPortfolioItemInput!) {
          addTajirikaPortfolioItem(input: \$input) {
            id
          }
        }
        ''',
        variables: {
          'input': {
            'url': path,
            'itemType': file.path.toLowerCase().endsWith('.mp4') ? 'video' : 'photo',
            if (caption != null && caption.isNotEmpty) 'caption': caption,
            if (skillCategory != null && skillCategory.isNotEmpty)
              'skillCategory': skillCategory,
          },
        },
        auth: true,
      );
      return TajirikaResult(success: true);
    } catch (e) {
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> deletePortfolioItem(int itemId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaPortfolioItem(\$itemId: ID!) {
          deleteTajirikaPortfolioItem(itemId: \$itemId)
        }
        ''',
        variables: {'itemId': itemId.toString()},
        auth: true,
      );
      return TajirikaResult(success: true);
    } catch (e) {
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<ReferralStats> getReferralStats() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaReferralStats {
          myTajirikaReferralStats {
            referralCode
            totalReferred
            registered
            verified
            totalBonusEarned
          }
        }
        ''',
        auth: true,
      );
      final row = data['myTajirikaReferralStats'] as Map<String, dynamic>?;
      if (row == null) return ReferralStats(referralCode: '');
      return ReferralStats.fromJson(_referralStatsToLegacy(row));
    } catch (_) {
      return ReferralStats(referralCode: '');
    }
  }

  static Map<String, dynamic> _referralStatsToLegacy(Map<String, dynamic> row) {
    return {
      'referral_code': row['referralCode'] ?? '',
      'total_referred': row['totalReferred'] ?? 0,
      'registered': row['registered'] ?? 0,
      'verified': row['verified'] ?? 0,
      'total_bonus_earned': row['totalBonusEarned'] ?? 0,
    };
  }

  static Future<ReferralListResult> getReferrals() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaReferrals {
          myTajirikaReferrals {
            id
            referrerId
            referredId
            referredName
            referredPhoto
            referredSkills
            status
            bonus
            createdAt
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myTajirikaReferrals'] as List<dynamic>? ?? [];
      final referrals = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => Referral.fromJson(_referralToLegacy(row)))
          .toList();
      return ReferralListResult(success: true, referrals: referrals);
    } catch (e) {
      return ReferralListResult(success: false, message: 'Error: $e');
    }
  }

  static Map<String, dynamic> _referralToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'referrer_id': int.tryParse(row['referrerId']?.toString() ?? '') ?? 0,
      'referred_id': int.tryParse(row['referredId']?.toString() ?? '') ?? 0,
      'referred_name': row['referredName'] ?? '',
      if (row['referredPhoto'] != null) 'referred_photo': row['referredPhoto'],
      'referred_skills': row['referredSkills'] ?? [],
      'status': row['status'] ?? 'pending',
      'bonus': row['bonus'] ?? 0,
      'created_at': row['createdAt'] ?? DateTime.now().toIso8601String(),
    };
  }

  static Future<TrainingListResult> getTrainingCourses({String? category}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaTrainingCourses(\$category: String) {
          tajirikaTrainingCourses(category: \$category) {
            id
            title
            titleSw
            description
            descriptionSw
            category
            durationMinutes
            videoUrl
            thumbnailUrl
            isRequired
            progress
            isCompleted
            completedAt
            certificateUrl
          }
        }
        ''',
        variables: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
        auth: true,
      );
      final rows = data['tajirikaTrainingCourses'] as List<dynamic>? ?? [];
      final courses = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => TrainingCourse.fromJson(_trainingCourseToLegacy(row)))
          .toList();
      return TrainingListResult(success: true, courses: courses);
    } catch (e) {
      return TrainingListResult(success: false, message: 'Error: $e');
    }
  }

  static Map<String, dynamic> _trainingCourseToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'title': row['title'] ?? '',
      'title_sw': row['titleSw'] ?? '',
      'description': row['description'] ?? '',
      'description_sw': row['descriptionSw'] ?? '',
      'category': row['category'],
      'duration_minutes': row['durationMinutes'] ?? 0,
      if (row['videoUrl'] != null) 'video_url': row['videoUrl'],
      if (row['thumbnailUrl'] != null) 'thumbnail_url': row['thumbnailUrl'],
      'is_required': row['isRequired'] ?? false,
      'progress': row['progress'] ?? 0,
      'is_completed': row['isCompleted'] ?? false,
      if (row['completedAt'] != null) 'completed_at': row['completedAt'],
      if (row['certificateUrl'] != null) 'certificate_url': row['certificateUrl'],
    };
  }

  static Future<TajirikaResult> submitNidaVerification(String nidaNumber) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitTajirikaNidaVerification(\$nidaNumber: String!) {
          submitTajirikaNidaVerification(nidaNumber: \$nidaNumber)
        }
        ''',
        variables: {'nidaNumber': nidaNumber},
        auth: true,
      );
      return TajirikaResult(success: true);
    } catch (e) {
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> submitTinVerification(String tinNumber) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitTajirikaTinVerification(\$tinNumber: String!) {
          submitTajirikaTinVerification(tinNumber: \$tinNumber)
        }
        ''',
        variables: {'tinNumber': tinNumber},
        auth: true,
      );
      return TajirikaResult(success: true);
    } catch (e) {
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> submitBackgroundVerification() async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitTajirikaBackgroundVerification {
          submitTajirikaBackgroundVerification
        }
        ''',
        auth: true,
      );
      return TajirikaResult(success: true);
    } catch (e) {
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> submitProfessionalLicense(
    String licenseType,
    File file,
  ) async {
    try {
      final uploaded = await GraphqlMediaService.uploadFile(
        file,
        mediaType: 'document',
      );
      final path = uploaded?['file_path']?.toString();
      if (path == null) {
        return TajirikaResult(success: false, message: 'Failed to upload document');
      }
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitTajirikaProfessionalVerification(
          \$input: SubmitTajirikaProfessionalVerificationInput!
        ) {
          submitTajirikaProfessionalVerification(input: \$input)
        }
        ''',
        variables: {
          'input': {
            'licenseType': licenseType,
            'documentUrl': path,
          },
        },
        auth: true,
      );
      return TajirikaResult(success: true);
    } catch (e) {
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> submitPeerVouch(int partnerId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitTajirikaPeerVouch(\$partnerId: ID!) {
          submitTajirikaPeerVouch(partnerId: \$partnerId)
        }
        ''',
        variables: {'partnerId': partnerId.toString()},
        auth: true,
      );
      return TajirikaResult(success: true);
    } catch (e) {
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaResult> updateCourseProgress(
    int courseId,
    double progress,
  ) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateTajirikaTrainingProgress(\$courseId: ID!, \$progress: Float!) {
          updateTajirikaTrainingProgress(courseId: \$courseId, progress: \$progress) {
            id
            progress
            isCompleted
          }
        }
        ''',
        variables: {
          'courseId': courseId.toString(),
          'progress': progress,
        },
        auth: true,
      );
      return TajirikaResult(success: true);
    } catch (e) {
      return TajirikaResult(success: false, message: 'Error: $e');
    }
  }

  static Future<List<MentorshipMatch>> getMentorshipMatches() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaMentorshipMatches {
          myTajirikaMentorshipMatches {
            id
            mentorUserId
            mentorName
            mentorPhoto
            mentorTier
            menteeUserId
            menteeName
            menteePhoto
            status
            createdAt
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myTajirikaMentorshipMatches'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => MentorshipMatch.fromJson(_mentorshipToLegacy(row)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> _mentorshipToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'mentor_id': int.tryParse(row['mentorUserId']?.toString() ?? '') ?? 0,
      'mentor_name': row['mentorName'] ?? '',
      if (row['mentorPhoto'] != null) 'mentor_photo': row['mentorPhoto'],
      'mentor_tier': row['mentorTier'] ?? 'mwanafunzi',
      'mentee_id': int.tryParse(row['menteeUserId']?.toString() ?? '') ?? 0,
      'mentee_name': row['menteeName'] ?? '',
      if (row['menteePhoto'] != null) 'mentee_photo': row['menteePhoto'],
      'status': row['status'] ?? 'active',
      'created_at': row['createdAt'] ?? DateTime.now().toIso8601String(),
    };
  }
}
