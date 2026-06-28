import 'dart:io';

import '../../tajirika/services/dispute_counter_evidence_service.dart';
import '../../tajirika/services/engagement_questionnaire_service.dart';
import '../../tajirika/services/membership_service.dart';
import '../../tajirika/services/tajirika_plus_service.dart';
import 'graphql_media_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Tajirika subscription/engagement (Phases 167–170).
class GraphqlTajirikaSubService {
  static TajirikaPlusPlan _plusPlanFromGql(Map<String, dynamic> row) {
    return TajirikaPlusPlan.fromJson({
      'tier': row['tier'],
      'name': row['name'],
      'name_sw': row['nameSw'],
      'price_monthly_tzs': row['priceMonthlyTzs'],
      'benefits': row['benefits'] ?? [],
      'benefits_sw': row['benefitsSw'] ?? [],
    });
  }

  static TajirikaPlusStatus _plusStatusFromGql(Map<String, dynamic> row) {
    return TajirikaPlusStatus.fromJson({
      'active': row['active'],
      'tier': row['tier'],
      'expires_at': row['expiresAt'],
      'auto_renew': row['autoRenew'],
    });
  }

  static Map<String, dynamic> _membershipToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_id': int.tryParse(row['partnerId']?.toString() ?? '') ?? 0,
      if (row['partnerName'] != null) 'partner_name': row['partnerName'],
      'plan': row['plan'] ?? '',
      'credits_total': row['creditsTotal'],
      'credits_remaining': row['creditsRemaining'],
      'price_tzs': int.tryParse(row['priceTzs']?.toString() ?? '') ?? 0,
      if (row['expiresAt'] != null) 'expires_at': row['expiresAt'],
      'status': row['status'] ?? 'active',
    };
  }

  static Future<TajirikaPlusResult> getPlans() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPlusPlans {
          tajirikaPlusPlans {
            tier
            name
            nameSw
            priceMonthlyTzs
            benefits
            benefitsSw
          }
        }
        ''',
        auth: false,
      );
      final rows = data['tajirikaPlusPlans'] as List<dynamic>? ?? [];
      return TajirikaPlusResult(
        success: true,
        plans: rows
            .whereType<Map<String, dynamic>>()
            .map(_plusPlanFromGql)
            .toList(),
      );
    } catch (e) {
      return TajirikaPlusResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaPlusResult> getStatus(int partnerUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPlusStatus(\$partnerUserId: ID!) {
          tajirikaPlusStatus(partnerUserId: \$partnerUserId) {
            active
            tier
            expiresAt
            autoRenew
          }
        }
        ''',
        variables: {'partnerUserId': '$partnerUserId'},
      );
      final row = data['tajirikaPlusStatus'] as Map<String, dynamic>?;
      return TajirikaPlusResult(
        success: row != null,
        status: row != null ? _plusStatusFromGql(row) : null,
      );
    } catch (e) {
      return TajirikaPlusResult(success: false, message: 'Error: $e');
    }
  }

  static Future<TajirikaPlusResult> subscribe({
    required int partnerUserId,
    required String tier,
    String paymentMethod = 'wallet_auto_debit',
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubscribeTajirikaPlus(\$input: SubscribeTajirikaPlusInput!) {
          subscribeTajirikaPlus(input: \$input) {
            active
            tier
            expiresAt
            autoRenew
          }
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': '$partnerUserId',
            'tier': tier,
            'paymentMethod': paymentMethod,
          },
        },
        auth: true,
      );
      final row = data['subscribeTajirikaPlus'] as Map<String, dynamic>?;
      return TajirikaPlusResult(
        success: row != null,
        status: row != null ? _plusStatusFromGql(row) : null,
      );
    } catch (e) {
      return TajirikaPlusResult(success: false, message: 'Error: $e');
    }
  }

  static Future<List<Membership>> myMemberships({required int userId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaMembershipsMine {
          tajirikaMembershipsMine {
            id
            partnerId
            partnerName
            plan
            creditsTotal
            creditsRemaining
            priceTzs
            expiresAt
            status
          }
        }
        ''',
      );
      final rows = data['tajirikaMembershipsMine'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((r) => Membership.fromJson(_membershipToLegacy(r)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<Map<String, dynamic>>> partnerPlans({
    required int partnerId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaMembershipPlans(\$partnerId: ID!) {
          tajirikaMembershipPlans(partnerId: \$partnerId) {
            plan
            name
            creditsTotal
            priceTzs
            durationDays
          }
        }
        ''',
        variables: {'partnerId': '$partnerId'},
        auth: false,
      );
      final rows = data['tajirikaMembershipPlans'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(
            (r) => {
              'plan': r['plan'],
              'name': r['name'],
              'credits_total': r['creditsTotal'],
              'price_tzs': r['priceTzs'],
              'duration_days': r['durationDays'],
            },
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int?> purchase({
    required int userId,
    required int partnerId,
    required String plan,
    required int priceTzs,
    int? creditsTotal,
    int? durationDays,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PurchaseTajirikaMembership(\$input: PurchaseTajirikaMembershipInput!) {
          purchaseTajirikaMembership(input: \$input) {
            membershipId
          }
        }
        ''',
        variables: {
          'input': {
            'partnerId': '$partnerId',
            'plan': plan,
            'priceTzs': priceTzs,
            if (creditsTotal != null) 'creditsTotal': creditsTotal,
            if (durationDays != null) 'durationDays': durationDays,
          },
        },
        auth: true,
      );
      final row = data['purchaseTajirikaMembership'] as Map<String, dynamic>?;
      return int.tryParse(row?['membershipId']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deductCredit({
    required int userId,
    required int membershipId,
    int credits = 1,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeductTajirikaMembershipCredit(\$input: DeductTajirikaMembershipCreditInput!) {
          deductTajirikaMembershipCredit(input: \$input)
        }
        ''',
        variables: {
          'input': {
            'membershipId': '$membershipId',
            'credits': credits,
          },
        },
        auth: true,
      );
      return data['deductTajirikaMembershipCredit'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> uploadDisputeEvidence({
    required int disputeId,
    required int partnerUserId,
    required String evidenceType,
    String? description,
    required List<File> files,
  }) async {
    try {
      final urls = <String>[];
      for (final file in files) {
        final uploaded = await GraphqlMediaService.uploadFile(
          file,
          mediaType: 'image',
        );
        final url = uploaded?['url']?.toString();
        if (url != null && url.isNotEmpty) {
          urls.add(url);
        }
      }
      if (urls.isEmpty) return false;

      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UploadTajirikaDisputeCounterEvidence(\$input: UploadTajirikaDisputeCounterEvidenceInput!) {
          uploadTajirikaDisputeCounterEvidence(input: \$input)
        }
        ''',
        variables: {
          'input': {
            'disputeId': '$disputeId',
            'partnerUserId': '$partnerUserId',
            'evidenceType': evidenceType,
            if (description != null) 'description': description,
            'fileUrls': urls,
          },
        },
        auth: true,
      );
      return data['uploadTajirikaDisputeCounterEvidence'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<CounterEvidenceItem>> listDisputeEvidence({
    int? disputeId,
    int? partnerUserId,
    int limit = 50,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaDisputeCounterEvidence(
          \$disputeId: ID
          \$partnerUserId: ID
          \$limit: Int
        ) {
          tajirikaDisputeCounterEvidence(
            disputeId: \$disputeId
            partnerUserId: \$partnerUserId
            limit: \$limit
          ) {
            id
            disputeId
            partnerUserId
            evidenceType
            description
            files
            isLate
            submittedAt
          }
        }
        ''',
        variables: {
          if (disputeId != null) 'disputeId': '$disputeId',
          if (partnerUserId != null) 'partnerUserId': '$partnerUserId',
          'limit': limit,
        },
        auth: false,
      );
      final rows = data['tajirikaDisputeCounterEvidence'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(
            (r) => CounterEvidenceItem.fromJson({
              'id': int.tryParse(r['id']?.toString() ?? '') ?? 0,
              'dispute_id': int.tryParse(r['disputeId']?.toString() ?? '') ?? 0,
              'partner_user_id':
                  int.tryParse(r['partnerUserId']?.toString() ?? '') ?? 0,
              'evidence_type': r['evidenceType'] ?? '',
              'description': r['description'],
              'files': r['files'] ?? [],
              'is_late': r['isLate'] == true,
              'submitted_at': r['submittedAt'],
            }),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<List<EngagementQuestionnaire>> mine({required int userId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaEngagementQuestionnairesMine {
          tajirikaEngagementQuestionnairesMine {
            id
            title
            skillCategory
            isActive
            schemaJson
          }
        }
        ''',
      );
      final rows = data['tajirikaEngagementQuestionnairesMine'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map(
            (r) => EngagementQuestionnaire.fromJson({
              'id': int.tryParse(r['id']?.toString() ?? '') ?? 0,
              'title': r['title'],
              'skill_category': r['skillCategory'],
              'is_active': r['isActive'],
              'schema_json': r['schemaJson'],
            }),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int?> saveQuestionnaire({
    required int userId,
    int? id,
    required String title,
    String? skillCategory,
    bool isActive = true,
    required Map<String, dynamic> schemaJson,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SaveTajirikaEngagementQuestionnaire(\$input: SaveTajirikaEngagementQuestionnaireInput!) {
          saveTajirikaEngagementQuestionnaire(input: \$input)
        }
        ''',
        variables: {
          'input': {
            if (id != null) 'questionnaireId': '$id',
            'title': title,
            if (skillCategory != null) 'skillCategory': skillCategory,
            'isActive': isActive,
            'schemaJson': schemaJson,
          },
        },
        auth: true,
      );
      return int.tryParse(data['saveTajirikaEngagementQuestionnaire']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<EngagementQuestionnaire?> show(int id) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaEngagementQuestionnaire(\$questionnaireId: ID!) {
          tajirikaEngagementQuestionnaire(questionnaireId: \$questionnaireId) {
            id
            title
            schema
          }
        }
        ''',
        variables: {'questionnaireId': '$id'},
        auth: false,
      );
      final row = data['tajirikaEngagementQuestionnaire'] as Map<String, dynamic>?;
      if (row == null) return null;
      return EngagementQuestionnaire.fromJson({
        'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
        'title': row['title'],
        'schema_json': row['schema'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<bool> respond({
    required int userId,
    required int questionnaireId,
    int? engagementId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RespondTajirikaEngagementQuestionnaire(\$input: RespondTajirikaEngagementQuestionnaireInput!) {
          respondTajirikaEngagementQuestionnaire(input: \$input)
        }
        ''',
        variables: {
          'input': {
            'questionnaireId': '$questionnaireId',
            if (engagementId != null) 'engagementId': '$engagementId',
            'answers': answers,
          },
        },
        auth: true,
      );
      return data['respondTajirikaEngagementQuestionnaire'] == true;
    } catch (_) {
      return false;
    }
  }
}
