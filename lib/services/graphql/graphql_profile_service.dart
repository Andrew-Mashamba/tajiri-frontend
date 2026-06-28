import 'tajiri_graphql_client.dart';

/// GraphQL user profile demographics (Phase 97 — backend rev 058).
class GraphqlProfileService {
  static const _profileFields = r'''
    userId
    gender
    relationshipStatus
    location
    employer
    school
    sector
    dateOfBirth
    hasBusiness
    student
    profileComplete
    verified
    updatedAt
  ''';

  static const graphqlKeys = {
    'gender',
    'relationship_status',
    'location',
    'employer',
    'school',
    'sector',
    'date_of_birth',
    'has_business',
    'student',
  };

  static bool canHandlePayload(Map<String, dynamic> payload) {
    if (payload.isEmpty) return false;
    return payload.keys.every(graphqlKeys.contains);
  }

  static Map<String, dynamic> _toLegacy(Map<String, dynamic> row) {
    return {
      'gender': row['gender'],
      'relationship_status': row['relationshipStatus'],
      'location': row['location'],
      'employer': row['employer'],
      'school': row['school'],
      'sector': row['sector'],
      'date_of_birth': row['dateOfBirth'],
      'has_business': row['hasBusiness'],
      'student': row['student'],
      'profile_complete': row['profileComplete'],
      'verified': row['verified'],
    };
  }

  static Map<String, dynamic> _payloadToInput(Map<String, dynamic> payload) {
    final input = <String, dynamic>{};
    if (payload.containsKey('gender')) {
      input['gender'] = payload['gender'];
    }
    if (payload.containsKey('relationship_status')) {
      input['relationshipStatus'] = payload['relationship_status'];
    }
    if (payload.containsKey('location')) {
      input['location'] = payload['location'];
    }
    if (payload.containsKey('employer')) {
      input['employer'] = payload['employer'];
    }
    if (payload.containsKey('school')) {
      input['school'] = payload['school'];
    }
    if (payload.containsKey('sector')) {
      input['sector'] = payload['sector'];
    }
    if (payload.containsKey('date_of_birth')) {
      input['dateOfBirth'] = payload['date_of_birth'];
    }
    if (payload.containsKey('has_business')) {
      input['hasBusiness'] = payload['has_business'] == true ||
          payload['has_business'] == 1 ||
          payload['has_business'] == '1';
    }
    if (payload.containsKey('student')) {
      input['student'] = payload['student'] == true ||
          payload['student'] == 1 ||
          payload['student'] == '1';
    }
    return input;
  }

  static Future<Map<String, dynamic>> getMyUserProfile() async {
    final data = await TajiriGraphqlClient.instance.query(
      '''
      query MyUserProfile {
        myUserProfile {
          $_profileFields
        }
      }
      ''',
      auth: true,
    );
    final row = data['myUserProfile'] as Map<String, dynamic>? ?? {};
    return _toLegacy(row);
  }

  static Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> payload,
  ) async {
    final data = await TajiriGraphqlClient.instance.mutate(
      '''
      mutation UpdateUserProfile(\$input: UpdateUserProfileInput!) {
        updateUserProfile(input: \$input) {
          $_profileFields
        }
      }
      ''',
      variables: {'input': _payloadToInput(payload)},
      auth: true,
    );
    final row = data['updateUserProfile'] as Map<String, dynamic>? ?? {};
    return _toLegacy(row);
  }
}
