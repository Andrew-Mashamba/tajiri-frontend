import '../../my_family/models/my_family_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL my family directory (Phase 79 — backend rev 212).
/// Calendar, shared lists, health records, chores, and user linking remain REST-only.
class GraphqlMyFamilyService {
  static const _memberFields = r'''
    id
    memberUserId
    name
    relationship
    dateOfBirth
    gender
    photoUrl
    bloodType
    allergies
    chronicConditions
    nhifNumber
    emergencyPhone
  ''';

  static const _contactFields = r'''
    id
    name
    phone
    relationship
    isPrimary
  ''';

  static Map<String, dynamic> _memberToLegacy(Map<String, dynamic> row) {
    final memberUserId = row['memberUserId'];
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'user_id': memberUserId != null
          ? int.tryParse(memberUserId.toString())
          : null,
      'name': row['name'],
      'relationship': row['relationship'],
      'date_of_birth': row['dateOfBirth'],
      'gender': row['gender'],
      'photo_url': row['photoUrl'],
      'blood_type': row['bloodType'],
      'allergies': row['allergies'] ?? [],
      'chronic_conditions': row['chronicConditions'] ?? [],
      'nhif_number': row['nhifNumber'],
      'emergency_phone': row['emergencyPhone'],
      'is_linked': memberUserId != null,
    };
  }

  static Map<String, dynamic> _contactToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'name': row['name'],
      'phone': row['phone'],
      'relationship': row['relationship'],
      'is_primary': row['isPrimary'] ?? false,
    };
  }

  static Future<FamilyListResult<FamilyMember>> getMembers() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query FamilyMembers {
          familyMembers {
            $_memberFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['familyMembers'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => FamilyMember.fromJson(_memberToLegacy(row)))
          .toList();
      return FamilyListResult(success: true, items: items);
    } catch (e) {
      return FamilyListResult(
        success: false,
        message: 'Imeshindwa kupakia wanafamilia: $e',
      );
    }
  }

  static Future<FamilyResult<FamilyMember>> addMember({
    required String name,
    required String relationship,
    String? gender,
    String? dateOfBirth,
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? nhifNumber,
    String? emergencyPhone,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddFamilyMember(\$input: AddFamilyMemberInput!) {
          addFamilyMember(input: \$input) {
            $_memberFields
          }
        }
        ''',
        variables: {
          'input': {
            'name': name,
            'relationship': relationship,
            if (gender != null) 'gender': gender,
            if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
            if (bloodType != null) 'bloodType': bloodType,
            if (allergies != null && allergies.isNotEmpty) 'allergies': allergies,
            if (chronicConditions != null && chronicConditions.isNotEmpty)
              'chronicConditions': chronicConditions,
            if (nhifNumber != null) 'nhifNumber': nhifNumber,
            if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
          },
        },
        auth: true,
      );
      final row = data['addFamilyMember'] as Map<String, dynamic>?;
      if (row == null) {
        return FamilyResult(success: false, message: 'Imeshindwa kuongeza mwanafamilia');
      }
      return FamilyResult(
        success: true,
        data: FamilyMember.fromJson(_memberToLegacy(row)),
      );
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<FamilyResult<FamilyMember>> updateMember({
    required int memberId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateFamilyMember(
          \$memberId: ID!
          \$name: String
          \$relationship: String
          \$bloodType: String
          \$allergies: [String!]
          \$chronicConditions: [String!]
          \$nhifNumber: String
          \$emergencyPhone: String
        ) {
          updateFamilyMember(
            memberId: \$memberId
            name: \$name
            relationship: \$relationship
            bloodType: \$bloodType
            allergies: \$allergies
            chronicConditions: \$chronicConditions
            nhifNumber: \$nhifNumber
            emergencyPhone: \$emergencyPhone
          ) {
            $_memberFields
          }
        }
        ''',
        variables: {
          'memberId': memberId.toString(),
          if (fields.containsKey('name')) 'name': fields['name'],
          if (fields.containsKey('relationship'))
            'relationship': fields['relationship'],
          if (fields.containsKey('blood_type')) 'bloodType': fields['blood_type'],
          if (fields.containsKey('allergies')) 'allergies': fields['allergies'],
          if (fields.containsKey('chronic_conditions'))
            'chronicConditions': fields['chronic_conditions'],
          if (fields.containsKey('nhif_number')) 'nhifNumber': fields['nhif_number'],
          if (fields.containsKey('emergency_phone'))
            'emergencyPhone': fields['emergency_phone'],
        },
        auth: true,
      );
      final row = data['updateFamilyMember'] as Map<String, dynamic>?;
      if (row == null) {
        return FamilyResult(
          success: false,
          message: 'Imeshindwa kubadilisha taarifa',
        );
      }
      return FamilyResult(
        success: true,
        data: FamilyMember.fromJson(_memberToLegacy(row)),
      );
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<FamilyResult<void>> removeMember(int memberId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation RemoveFamilyMember($memberId: ID!) {
          removeFamilyMember(memberId: $memberId)
        }
        ''',
        variables: {'memberId': memberId.toString()},
        auth: true,
      );
      if (data['removeFamilyMember'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(
        success: false,
        message: 'Imeshindwa kuondoa mwanafamilia',
      );
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<FamilyListResult<EmergencyContact>> getEmergencyContacts() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query EmergencyContacts {
          emergencyContacts {
            $_contactFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['emergencyContacts'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => EmergencyContact.fromJson(_contactToLegacy(row)))
          .toList();
      return FamilyListResult(success: true, items: items);
    } catch (e) {
      return FamilyListResult(
        success: false,
        message: 'Imeshindwa kupakia mawasiliano ya dharura: $e',
      );
    }
  }

  static Future<FamilyResult<EmergencyContact>> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddEmergencyContact(\$input: AddEmergencyContactInput!) {
          addEmergencyContact(input: \$input) {
            $_contactFields
          }
        }
        ''',
        variables: {
          'input': {
            'name': name,
            'phone': phone,
            if (relationship != null) 'relationship': relationship,
            'isPrimary': isPrimary,
          },
        },
        auth: true,
      );
      final row = data['addEmergencyContact'] as Map<String, dynamic>?;
      if (row == null) {
        return FamilyResult(
          success: false,
          message: 'Imeshindwa kuongeza mawasiliano',
        );
      }
      return FamilyResult(
        success: true,
        data: EmergencyContact.fromJson(_contactToLegacy(row)),
      );
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<FamilyResult<void>> deleteEmergencyContact(int contactId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'''
        mutation RemoveEmergencyContact($contactId: ID!) {
          removeEmergencyContact(contactId: $contactId)
        }
        ''',
        variables: {'contactId': contactId.toString()},
        auth: true,
      );
      if (data['removeEmergencyContact'] == true) {
        return FamilyResult(success: true);
      }
      return FamilyResult(
        success: false,
        message: 'Imeshindwa kufuta mawasiliano',
      );
    } catch (e) {
      return FamilyResult(success: false, message: 'Kosa: $e');
    }
  }
}
