import '../../tajirika/models/tajirika_models.dart';
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
}
