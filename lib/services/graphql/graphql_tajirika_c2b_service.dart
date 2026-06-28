import '../../tajirika/models/customer_partner_favorite.dart';
import '../../tajirika/models/partner_canned_message.dart';
import '../../tajirika/models/partner_skill_persona.dart';
import '../../tajirika/models/peer_endorsement.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Tajirika C2B engagement (Phases 151–154).
class GraphqlTajirikaC2bService {
  static const _personaFields = r'''
    partnerUserId
    skillCategory
    status
    displayName
    profilePhotoUrl
    bio
    pricingBandLowTzs
    pricingBandHighTzs
    tagPreset
    autoReplyText
    credentialsUrl
    verifiedAt
    rejectedAt
    rejectionReason
    pausedAt
    isDefault
    pricingTier
    isPaused
    publicSlug
    talaLicenseNumber
    talaVerified
  ''';

  static Map<String, dynamic> _favoriteToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'customer_user_id': int.tryParse(row['customerUserId']?.toString() ?? '') ?? 0,
      'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
      if (row['skillCategory'] != null) 'skill_category': row['skillCategory'],
      if (row['partnerName'] != null) 'name': row['partnerName'],
      if (row['partnerPhotoUrl'] != null) 'profile_photo': row['partnerPhotoUrl'],
    };
  }

  static Map<String, dynamic> _endorsementToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'endorsee_user_id': int.tryParse(row['endorseeUserId']?.toString() ?? '') ?? 0,
      'endorser_user_id': int.tryParse(row['endorserUserId']?.toString() ?? '') ?? 0,
      'skill_category': row['skillCategory'] ?? '',
      if (row['comment'] != null) 'comment': row['comment'],
      if (row['endorserName'] != null) 'endorser_name': row['endorserName'],
      if (row['endorserPhotoUrl'] != null) 'endorser_photo': row['endorserPhotoUrl'],
      if (row['createdAt'] != null) 'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _cannedMessageToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
      'label': row['label'] ?? '',
      'body': row['body'] ?? '',
      'is_active': row['isActive'] == true,
    };
  }

  static Map<String, dynamic> _personaToLegacy(Map<String, dynamic> row) {
    return {
      'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
      'skill_category': row['skillCategory'] ?? '',
      'status': row['status'] ?? 'active',
      if (row['displayName'] != null) 'display_name': row['displayName'],
      if (row['profilePhotoUrl'] != null) 'profile_photo_url': row['profilePhotoUrl'],
      if (row['bio'] != null) 'bio': row['bio'],
      if (row['pricingBandLowTzs'] != null) 'pricing_band_low_tzs': row['pricingBandLowTzs'],
      if (row['pricingBandHighTzs'] != null) 'pricing_band_high_tzs': row['pricingBandHighTzs'],
      'tag_preset': row['tagPreset'] ?? [],
      if (row['autoReplyText'] != null) 'auto_reply_text': row['autoReplyText'],
      if (row['credentialsUrl'] != null) 'credentials_url': row['credentialsUrl'],
      if (row['verifiedAt'] != null) 'verified_at': row['verifiedAt'],
      if (row['rejectedAt'] != null) 'rejected_at': row['rejectedAt'],
      if (row['rejectionReason'] != null) 'rejection_reason': row['rejectionReason'],
      if (row['pausedAt'] != null) 'paused_at': row['pausedAt'],
      'is_default': row['isDefault'] == true,
      if (row['pricingTier'] != null) 'pricing_tier': row['pricingTier'],
      'is_paused': row['isPaused'] == true,
      if (row['publicSlug'] != null) 'public_slug': row['publicSlug'],
      if (row['talaLicenseNumber'] != null) 'tala_license_number': row['talaLicenseNumber'],
      'tala_verified': row['talaVerified'] == true,
    };
  }

  static Future<List<CustomerPartnerFavorite>> listCustomerPartnerFavorites() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTajirikaCustomerPartnerFavorites {
          myTajirikaCustomerPartnerFavorites {
            id
            customerUserId
            partnerUserId
            skillCategory
            partnerName
            partnerPhotoUrl
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myTajirikaCustomerPartnerFavorites'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => CustomerPartnerFavorite.fromJson(_favoriteToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> addCustomerPartnerFavorite({
    required int partnerUserId,
    String? skillCategory,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddTajirikaCustomerPartnerFavorite(\$input: AddTajirikaCustomerPartnerFavoriteInput!) {
          addTajirikaCustomerPartnerFavorite(input: \$input) {
            id
          }
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': partnerUserId.toString(),
            if (skillCategory != null && skillCategory.isNotEmpty)
              'skillCategory': skillCategory,
          },
        },
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeCustomerPartnerFavorite(int favoriteId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RemoveTajirikaCustomerPartnerFavorite(\$favoriteId: ID!) {
          removeTajirikaCustomerPartnerFavorite(favoriteId: \$favoriteId)
        }
        ''',
        variables: {'favoriteId': favoriteId.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<PeerEndorsement>> listPeerEndorsements(int endorseeUserId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPeerEndorsements(\$endorseeUserId: ID!) {
          tajirikaPeerEndorsements(endorseeUserId: \$endorseeUserId) {
            id
            endorseeUserId
            endorserUserId
            skillCategory
            comment
            endorserName
            endorserPhotoUrl
            createdAt
          }
        }
        ''',
        variables: {'endorseeUserId': endorseeUserId.toString()},
      );
      final rows = data['tajirikaPeerEndorsements'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PeerEndorsement.fromJson(_endorsementToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> createPeerEndorsement({
    required int endorseeUserId,
    required String skillCategory,
    String? comment,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateTajirikaPeerEndorsement(\$input: CreateTajirikaPeerEndorsementInput!) {
          createTajirikaPeerEndorsement(input: \$input) {
            id
          }
        }
        ''',
        variables: {
          'input': {
            'endorseeUserId': endorseeUserId.toString(),
            'skillCategory': skillCategory,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          },
        },
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deletePeerEndorsement(int endorsementId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaPeerEndorsement(\$endorsementId: ID!) {
          deleteTajirikaPeerEndorsement(endorsementId: \$endorsementId)
        }
        ''',
        variables: {'endorsementId': endorsementId.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<PartnerCannedMessage>> listPartnerCannedMessages(
    int partnerUserId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerCannedMessages(\$partnerUserId: ID!) {
          tajirikaPartnerCannedMessages(partnerUserId: \$partnerUserId) {
            id
            partnerUserId
            label
            body
            isActive
          }
        }
        ''',
        variables: {'partnerUserId': partnerUserId.toString()},
      );
      final rows = data['tajirikaPartnerCannedMessages'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PartnerCannedMessage.fromJson(_cannedMessageToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<PartnerCannedMessage?> createPartnerCannedMessage({
    required String label,
    required String body,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateTajirikaPartnerCannedMessage(\$input: CreateTajirikaPartnerCannedMessageInput!) {
          createTajirikaPartnerCannedMessage(input: \$input) {
            id
            partnerUserId
            label
            body
            isActive
          }
        }
        ''',
        variables: {
          'input': {
            'label': label,
            'body': body,
          },
        },
        auth: true,
      );
      final row = data['createTajirikaPartnerCannedMessage'] as Map<String, dynamic>?;
      if (row == null) return null;
      return PartnerCannedMessage.fromJson(_cannedMessageToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deletePartnerCannedMessage(int messageId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaPartnerCannedMessage(\$messageId: ID!) {
          deleteTajirikaPartnerCannedMessage(messageId: \$messageId)
        }
        ''',
        variables: {'messageId': messageId.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<PartnerSkillPersonaListResult> listPartnerSkillPersonas(
    int partnerUserId,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerSkillPersonas(\$partnerUserId: ID!) {
          tajirikaPartnerSkillPersonas(partnerUserId: \$partnerUserId) {
            $_personaFields
          }
        }
        ''',
        variables: {'partnerUserId': partnerUserId.toString()},
      );
      final rows = data['tajirikaPartnerSkillPersonas'] as List<dynamic>? ?? [];
      final items = rows
          .whereType<Map<String, dynamic>>()
          .map((row) => PartnerSkillPersona.fromJson(_personaToLegacy(row)))
          .toList();
      return PartnerSkillPersonaListResult(success: true, items: items);
    } catch (e) {
      return PartnerSkillPersonaListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerSkillPersonaResult> getPartnerSkillPersona({
    required int partnerUserId,
    required String skillCategory,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerSkillPersona(\$partnerUserId: ID!, \$skillCategory: String!) {
          tajirikaPartnerSkillPersona(partnerUserId: \$partnerUserId, skillCategory: \$skillCategory) {
            $_personaFields
          }
        }
        ''',
        variables: {
          'partnerUserId': partnerUserId.toString(),
          'skillCategory': skillCategory,
        },
      );
      final row = data['tajirikaPartnerSkillPersona'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerSkillPersonaResult(success: false, message: 'not_found');
      }
      return PartnerSkillPersonaResult(
        success: true,
        persona: PartnerSkillPersona.fromJson(_personaToLegacy(row)),
      );
    } catch (e) {
      return PartnerSkillPersonaResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerSkillPersonaResult> upsertPartnerSkillPersona({
    required String skillCategory,
    String? displayName,
    String? profilePhotoUrl,
    String? bio,
    int? pricingBandLowTzs,
    int? pricingBandHighTzs,
    List<String>? tagPreset,
    String? autoReplyText,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpsertTajirikaPartnerSkillPersona(\$input: UpsertTajirikaPartnerSkillPersonaInput!) {
          upsertTajirikaPartnerSkillPersona(input: \$input) {
            $_personaFields
          }
        }
        ''',
        variables: {
          'input': {
            'skillCategory': skillCategory,
            if (displayName != null) 'displayName': displayName,
            if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
            if (bio != null) 'bio': bio,
            if (pricingBandLowTzs != null) 'pricingBandLowTzs': pricingBandLowTzs,
            if (pricingBandHighTzs != null) 'pricingBandHighTzs': pricingBandHighTzs,
            if (tagPreset != null) 'tagPreset': tagPreset,
            if (autoReplyText != null) 'autoReplyText': autoReplyText,
          },
        },
        auth: true,
      );
      final row = data['upsertTajirikaPartnerSkillPersona'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerSkillPersonaResult(success: false, message: 'Failed');
      }
      return PartnerSkillPersonaResult(
        success: true,
        persona: PartnerSkillPersona.fromJson(_personaToLegacy(row)),
      );
    } catch (e) {
      return PartnerSkillPersonaResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerSkillPersonaResult> pausePartnerSkillPersona(
    String skillCategory,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PauseTajirikaPartnerSkillPersona(\$skillCategory: String!) {
          pauseTajirikaPartnerSkillPersona(skillCategory: \$skillCategory) {
            $_personaFields
          }
        }
        ''',
        variables: {'skillCategory': skillCategory},
        auth: true,
      );
      final row = data['pauseTajirikaPartnerSkillPersona'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerSkillPersonaResult(success: false, message: 'Failed');
      }
      return PartnerSkillPersonaResult(
        success: true,
        persona: PartnerSkillPersona.fromJson(_personaToLegacy(row)),
      );
    } catch (e) {
      return PartnerSkillPersonaResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerSkillPersonaResult> resumePartnerSkillPersona(
    String skillCategory,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ResumeTajirikaPartnerSkillPersona(\$skillCategory: String!) {
          resumeTajirikaPartnerSkillPersona(skillCategory: \$skillCategory) {
            $_personaFields
          }
        }
        ''',
        variables: {'skillCategory': skillCategory},
        auth: true,
      );
      final row = data['resumeTajirikaPartnerSkillPersona'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerSkillPersonaResult(success: false, message: 'Failed');
      }
      return PartnerSkillPersonaResult(
        success: true,
        persona: PartnerSkillPersona.fromJson(_personaToLegacy(row)),
      );
    } catch (e) {
      return PartnerSkillPersonaResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<({bool success, String? message})> removePartnerSkillPersona(
    String skillCategory,
  ) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaPartnerSkillPersona(\$skillCategory: String!) {
          deleteTajirikaPartnerSkillPersona(skillCategory: \$skillCategory)
        }
        ''',
        variables: {'skillCategory': skillCategory},
        auth: true,
      );
      return (success: true, message: null);
    } catch (e) {
      return (success: false, message: 'Kosa: $e');
    }
  }

}
