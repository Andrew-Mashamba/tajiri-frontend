import '../../tajirika/models/partner_availability.dart';
import '../../tajirika/models/product_variant.dart';
import '../../tajirika/services/commission_tier_service.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL Tajirika availability + variants + commission (Phases 159–162).
class GraphqlTajirikaAvailabilityService {
  static Map<String, dynamic> _weeklyHoursToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
      'weekday': int.tryParse(row['weekday']?.toString() ?? '') ?? 0,
      'open_time': row['openTime'] ?? '09:00',
      'close_time': row['closeTime'] ?? '17:00',
      'slot_minutes': int.tryParse(row['slotMinutes']?.toString() ?? '') ?? 30,
      if (row['skillCategory'] != null) 'skill_category': row['skillCategory'],
      'is_active': row['isActive'] == true,
      if (row['reminderCadenceHours'] != null)
        'reminder_cadence_hours': row['reminderCadenceHours'],
      if (row['pricingModifierPct'] != null) 'pricing_modifier_pct': row['pricingModifierPct'],
      if (row['minNoticeMinutes'] != null) 'min_notice_minutes': row['minNoticeMinutes'],
      if (row['bookingHorizonDays'] != null) 'booking_horizon_days': row['bookingHorizonDays'],
      'last_minute_discount_enabled': row['lastMinuteDiscountEnabled'] == true,
      'last_minute_discount_pct':
          int.tryParse(row['lastMinuteDiscountPct']?.toString() ?? '') ?? 0,
      'waitlist_mode': row['waitlistMode'] ?? 'fifo',
      if (row['preBufferMinutes'] != null) 'pre_buffer_minutes': row['preBufferMinutes'],
      if (row['processingMinutes'] != null) 'processing_minutes': row['processingMinutes'],
      if (row['postBufferMinutes'] != null) 'post_buffer_minutes': row['postBufferMinutes'],
      if (row['travelSurchargeTzs'] != null) 'travel_surcharge_tzs': row['travelSurchargeTzs'],
      if (row['afterHoursSurchargeTzs'] != null)
        'after_hours_surcharge_tzs': row['afterHoursSurchargeTzs'],
      if (row['holidayPremiumTzs'] != null) 'holiday_premium_tzs': row['holidayPremiumTzs'],
      if (row['parkingPassThroughTzs'] != null)
        'parking_pass_through_tzs': row['parkingPassThroughTzs'],
      if (row['createdAt'] != null) 'created_at': row['createdAt'],
      if (row['updatedAt'] != null) 'updated_at': row['updatedAt'],
    };
  }

  static Map<String, dynamic> _blackoutToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_user_id': int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
      'starts_at': row['startsAt'] ?? '',
      'ends_at': row['endsAt'] ?? '',
      if (row['reason'] != null) 'reason': row['reason'],
      'all_day': row['allDay'] == true,
      if (row['skillCategories'] != null) 'skill_categories': row['skillCategories'],
      if (row['createdAt'] != null) 'created_at': row['createdAt'],
      if (row['updatedAt'] != null) 'updated_at': row['updatedAt'],
    };
  }

  static Map<String, dynamic> _slotToLegacy(Map<String, dynamic> row) {
    return {
      'starts_at': row['startsAt'] ?? '',
      'ends_at': row['endsAt'] ?? '',
      'slot_minutes': int.tryParse(row['slotMinutes']?.toString() ?? '') ?? 30,
    };
  }

  static Map<String, dynamic> _variantToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
      'partner_product_id': int.tryParse(row['partnerProductId']?.toString() ?? '') ?? 0,
      if (row['labelSw'] != null) 'label_sw': row['labelSw'],
      if (row['labelEn'] != null) 'label_en': row['labelEn'],
      'price_tzs': int.tryParse(row['priceTzs']?.toString() ?? '') ?? 0,
      'lead_time_hours': int.tryParse(row['leadTimeHours']?.toString() ?? '') ?? 0,
      'duration_minutes': int.tryParse(row['durationMinutes']?.toString() ?? '') ?? 0,
      'sort_order': int.tryParse(row['sortOrder']?.toString() ?? '') ?? 0,
      'is_active': row['isActive'] == true,
    };
  }

  static const _weeklyHoursFields = r'''
    id
    partnerUserId
    weekday
    openTime
    closeTime
    slotMinutes
    skillCategory
    isActive
    reminderCadenceHours
    pricingModifierPct
    minNoticeMinutes
    bookingHorizonDays
    lastMinuteDiscountEnabled
    lastMinuteDiscountPct
    waitlistMode
    preBufferMinutes
    processingMinutes
    postBufferMinutes
    travelSurchargeTzs
    afterHoursSurchargeTzs
    holidayPremiumTzs
    parkingPassThroughTzs
    createdAt
    updatedAt
  ''';

  static Future<PartnerAvailabilityResult> upsertHours({
    required int partnerUserId,
    required int weekday,
    required String openTime,
    required String closeTime,
    required int slotMinutes,
    String? skillCategory,
    bool isActive = true,
    int? reminderCadenceHours,
    int? pricingModifierPct,
    int? minNoticeMinutes,
    int? bookingHorizonDays,
    bool? lastMinuteDiscountEnabled,
    int? lastMinuteDiscountPct,
    String? waitlistMode,
    int? preBufferMinutes,
    int? processingMinutes,
    int? postBufferMinutes,
    int? travelSurchargeTzs,
    int? afterHoursSurchargeTzs,
    int? holidayPremiumTzs,
    int? parkingPassThroughTzs,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpsertTajirikaPartnerWeeklyHours(\$input: UpsertTajirikaPartnerWeeklyHoursInput!) {
          upsertTajirikaPartnerWeeklyHours(input: \$input) {
            $_weeklyHoursFields
          }
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': partnerUserId.toString(),
            'weekday': weekday,
            'openTime': openTime,
            'closeTime': closeTime,
            'slotMinutes': slotMinutes,
            'isActive': isActive,
            if (skillCategory != null && skillCategory.isNotEmpty)
              'skillCategory': skillCategory,
            if (reminderCadenceHours != null) 'reminderCadenceHours': reminderCadenceHours,
            if (pricingModifierPct != null) 'pricingModifierPct': pricingModifierPct,
            if (minNoticeMinutes != null) 'minNoticeMinutes': minNoticeMinutes,
            if (bookingHorizonDays != null) 'bookingHorizonDays': bookingHorizonDays,
            if (lastMinuteDiscountEnabled != null)
              'lastMinuteDiscountEnabled': lastMinuteDiscountEnabled,
            if (lastMinuteDiscountPct != null) 'lastMinuteDiscountPct': lastMinuteDiscountPct,
            if (waitlistMode != null && waitlistMode.isNotEmpty) 'waitlistMode': waitlistMode,
            if (preBufferMinutes != null) 'preBufferMinutes': preBufferMinutes,
            if (processingMinutes != null) 'processingMinutes': processingMinutes,
            if (postBufferMinutes != null) 'postBufferMinutes': postBufferMinutes,
            if (travelSurchargeTzs != null) 'travelSurchargeTzs': travelSurchargeTzs,
            if (afterHoursSurchargeTzs != null) 'afterHoursSurchargeTzs': afterHoursSurchargeTzs,
            if (holidayPremiumTzs != null) 'holidayPremiumTzs': holidayPremiumTzs,
            if (parkingPassThroughTzs != null) 'parkingPassThroughTzs': parkingPassThroughTzs,
          },
        },
        auth: true,
      );
      final row = data['upsertTajirikaPartnerWeeklyHours'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerAvailabilityResult(success: false, message: 'Empty response');
      }
      return PartnerAvailabilityResult(
        success: true,
        hours: PartnerAvailability.fromJson(_weeklyHoursToLegacy(row)),
      );
    } catch (e) {
      return PartnerAvailabilityResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerAvailabilityListResult> listHours({
    required int partnerUserId,
    String? skillCategory,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerWeeklyHours(\$partnerUserId: ID!, \$skillCategory: String) {
          tajirikaPartnerWeeklyHours(partnerUserId: \$partnerUserId, skillCategory: \$skillCategory) {
            $_weeklyHoursFields
          }
        }
        ''',
        variables: {
          'partnerUserId': partnerUserId.toString(),
          if (skillCategory != null && skillCategory.isNotEmpty)
            'skillCategory': skillCategory,
        },
      );
      final rows = data['tajirikaPartnerWeeklyHours'] as List<dynamic>? ?? [];
      return PartnerAvailabilityListResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => PartnerAvailability.fromJson(_weeklyHoursToLegacy(row)))
            .toList(),
      );
    } catch (e) {
      return PartnerAvailabilityListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> deactivateHours({
    required int id,
    required int partnerUserId,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeactivateTajirikaPartnerWeeklyHours(\$hoursId: ID!) {
          deactivateTajirikaPartnerWeeklyHours(hoursId: \$hoursId)
        }
        ''',
        variables: {'hoursId': id.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<PartnerBlackoutResult> addBlackout({
    required int partnerUserId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? reason,
    bool allDay = false,
    List<String>? skillCategories,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation AddTajirikaPartnerBlackout(\$input: AddTajirikaPartnerBlackoutInput!) {
          addTajirikaPartnerBlackout(input: \$input) {
            id
            partnerUserId
            startsAt
            endsAt
            reason
            allDay
            skillCategories
            createdAt
            updatedAt
          }
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': partnerUserId.toString(),
            'startsAt': startsAt.toUtc().toIso8601String(),
            'endsAt': endsAt.toUtc().toIso8601String(),
            'allDay': allDay,
            if (reason != null && reason.isNotEmpty) 'reason': reason,
            if (skillCategories != null && skillCategories.isNotEmpty)
              'skillCategories': skillCategories,
          },
        },
        auth: true,
      );
      final row = data['addTajirikaPartnerBlackout'] as Map<String, dynamic>?;
      if (row == null) {
        return PartnerBlackoutResult(success: false, message: 'Empty response');
      }
      return PartnerBlackoutResult(
        success: true,
        blackout: PartnerBlackout.fromJson(_blackoutToLegacy(row)),
      );
    } catch (e) {
      return PartnerBlackoutResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<PartnerBlackoutListResult> listBlackouts({
    required int partnerUserId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerBlackouts(\$partnerUserId: ID!) {
          tajirikaPartnerBlackouts(partnerUserId: \$partnerUserId) {
            id
            partnerUserId
            startsAt
            endsAt
            reason
            allDay
            skillCategories
            createdAt
            updatedAt
          }
        }
        ''',
        variables: {'partnerUserId': partnerUserId.toString()},
      );
      final rows = data['tajirikaPartnerBlackouts'] as List<dynamic>? ?? [];
      return PartnerBlackoutListResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => PartnerBlackout.fromJson(_blackoutToLegacy(row)))
            .toList(),
      );
    } catch (e) {
      return PartnerBlackoutListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> deleteBlackout({
    required int id,
    required int partnerUserId,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaPartnerBlackout(\$blackoutId: ID!) {
          deleteTajirikaPartnerBlackout(blackoutId: \$blackoutId)
        }
        ''',
        variables: {'blackoutId': id.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<AvailableSlotListResult> fetchSlots({
    required int partnerUserId,
    String? skillCategory,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerAvailableSlots(
          \$partnerUserId: ID!,
          \$skillCategory: String,
          \$fromDate: String,
          \$toDate: String,
        ) {
          tajirikaPartnerAvailableSlots(
            partnerUserId: \$partnerUserId,
            skillCategory: \$skillCategory,
            fromDate: \$fromDate,
            toDate: \$toDate,
          ) {
            startsAt
            endsAt
            slotMinutes
          }
        }
        ''',
        variables: {
          'partnerUserId': partnerUserId.toString(),
          if (skillCategory != null && skillCategory.isNotEmpty)
            'skillCategory': skillCategory,
          if (from != null) 'fromDate': from.toIso8601String().split('T').first,
          if (to != null) 'toDate': to.toIso8601String().split('T').first,
        },
      );
      final rows = data['tajirikaPartnerAvailableSlots'] as List<dynamic>? ?? [];
      return AvailableSlotListResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => AvailableSlot.fromJson(_slotToLegacy(row)))
            .toList(),
      );
    } catch (e) {
      return AvailableSlotListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> setAvailabilityMode({
    required int partnerUserId,
    required String mode,
    DateTime? busyUntil,
    int busyEtaExtraMinutes = 0,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SetTajirikaPartnerAvailabilityMode(\$input: SetTajirikaPartnerAvailabilityModeInput!) {
          setTajirikaPartnerAvailabilityMode(input: \$input)
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': partnerUserId.toString(),
            'availabilityMode': mode,
            'busyEtaExtraMinutes': busyEtaExtraMinutes,
            if (busyUntil != null) 'busyUntil': busyUntil.toUtc().toIso8601String(),
          },
        },
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> resumeAvailability(int partnerUserId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ResumeTajirikaPartnerAvailability(\$partnerUserId: ID!) {
          resumeTajirikaPartnerAvailability(partnerUserId: \$partnerUserId)
        }
        ''',
        variables: {'partnerUserId': partnerUserId.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<ProductVariant>> listProductVariants(int productId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaPartnerProductVariants(\$partnerProductId: ID!) {
          tajirikaPartnerProductVariants(partnerProductId: \$partnerProductId) {
            id
            partnerProductId
            labelSw
            labelEn
            priceTzs
            leadTimeHours
            durationMinutes
            sortOrder
            isActive
          }
        }
        ''',
        variables: {'partnerProductId': productId.toString()},
      );
      final rows = data['tajirikaPartnerProductVariants'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => ProductVariant.fromJson(_variantToLegacy(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<ProductVariant?> createProductVariant({
    required int partnerProductId,
    String? labelSw,
    String? labelEn,
    required int priceTzs,
    int leadTimeHours = 0,
    int durationMinutes = 0,
    int sortOrder = 0,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateTajirikaPartnerProductVariant(\$input: CreateTajirikaPartnerProductVariantInput!) {
          createTajirikaPartnerProductVariant(input: \$input) {
            id
            partnerProductId
            labelSw
            labelEn
            priceTzs
            leadTimeHours
            durationMinutes
            sortOrder
            isActive
          }
        }
        ''',
        variables: {
          'input': {
            'partnerProductId': partnerProductId.toString(),
            'priceTzs': priceTzs,
            if (labelSw != null && labelSw.isNotEmpty) 'labelSw': labelSw,
            if (labelEn != null && labelEn.isNotEmpty) 'labelEn': labelEn,
            'leadTimeHours': leadTimeHours,
            'durationMinutes': durationMinutes,
            'sortOrder': sortOrder,
          },
        },
        auth: true,
      );
      final row = data['createTajirikaPartnerProductVariant'] as Map<String, dynamic>?;
      if (row == null) return null;
      return ProductVariant.fromJson(_variantToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteProductVariant(int id) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaPartnerProductVariant(\$variantId: ID!) {
          deleteTajirikaPartnerProductVariant(variantId: \$variantId)
        }
        ''',
        variables: {'variantId': id.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<CommissionTier>> listCommissionTiers({
    required int partnerUserId,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaCommissionTiers(\$partnerUserId: ID!) {
          tajirikaCommissionTiers(partnerUserId: \$partnerUserId) {
            id
            partnerUserId
            skillCategory
            tierName
            tierLevel
            commissionPct
            minMonthlyRevenueTzs
            maxMonthlyRevenueTzs
            isDefault
          }
        }
        ''',
        variables: {'partnerUserId': partnerUserId.toString()},
      );
      final rows = data['tajirikaCommissionTiers'] as List<dynamic>? ?? [];
      return rows
          .whereType<Map<String, dynamic>>()
          .map((row) => CommissionTier.fromJson({
                'id': int.tryParse(row['id']?.toString() ?? '') ?? 0,
                'partner_user_id':
                    int.tryParse(row['partnerUserId']?.toString() ?? '') ?? 0,
                if (row['skillCategory'] != null) 'skill_category': row['skillCategory'],
                'tier_name': row['tierName'] ?? '',
                'tier_level': int.tryParse(row['tierLevel']?.toString() ?? '') ?? 1,
                'commission_pct': int.tryParse(row['commissionPct']?.toString() ?? '') ?? 0,
                'min_monthly_revenue_tzs':
                    int.tryParse(row['minMonthlyRevenueTzs']?.toString() ?? '') ?? 0,
                if (row['maxMonthlyRevenueTzs'] != null)
                  'max_monthly_revenue_tzs': int.tryParse(row['maxMonthlyRevenueTzs'].toString()),
                'is_default': row['isDefault'] == true,
              }))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<int?> createCommissionTier({
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
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateTajirikaCommissionTier(\$input: CreateTajirikaCommissionTierInput!) {
          createTajirikaCommissionTier(input: \$input) {
            id
          }
        }
        ''',
        variables: {
          'input': {
            'partnerUserId': partnerUserId.toString(),
            'tierName': tierName,
            'tierLevel': tierLevel,
            'commissionPct': commissionPct,
            'minMonthlyRevenueTzs': minMonthlyRevenueTzs,
            'isDefault': isDefault,
            if (skillCategory != null) 'skillCategory': skillCategory,
            if (maxMonthlyRevenueTzs != null) 'maxMonthlyRevenueTzs': maxMonthlyRevenueTzs,
          },
        },
        auth: true,
      );
      final row = data['createTajirikaCommissionTier'] as Map<String, dynamic>?;
      return int.tryParse(row?['id']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateCommissionTier(int id, Map<String, dynamic> fields) async {
    try {
      final input = <String, dynamic>{};
      if (fields.containsKey('tier_name')) input['tierName'] = fields['tier_name'];
      if (fields.containsKey('tier_level')) input['tierLevel'] = fields['tier_level'];
      if (fields.containsKey('commission_pct')) input['commissionPct'] = fields['commission_pct'];
      if (fields.containsKey('min_monthly_revenue_tzs')) {
        input['minMonthlyRevenueTzs'] = fields['min_monthly_revenue_tzs'];
      }
      if (fields.containsKey('max_monthly_revenue_tzs')) {
        input['maxMonthlyRevenueTzs'] = fields['max_monthly_revenue_tzs'];
      }
      if (fields.containsKey('is_default')) input['isDefault'] = fields['is_default'];
      if (fields.containsKey('skill_category')) input['skillCategory'] = fields['skill_category'];
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateTajirikaCommissionTier(\$tierId: ID!, \$input: UpdateTajirikaCommissionTierInput!) {
          updateTajirikaCommissionTier(tierId: \$tierId, input: \$input)
        }
        ''',
        variables: {'tierId': id.toString(), 'input': input},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteCommissionTier(int id) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteTajirikaCommissionTier(\$tierId: ID!) {
          deleteTajirikaCommissionTier(tierId: \$tierId)
        }
        ''',
        variables: {'tierId': id.toString()},
        auth: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<ApplicableTierResult?> applicableCommissionTier({
    required int partnerUserId,
    String? skillCategory,
    required int orderTotalTzs,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TajirikaApplicableCommissionTier(
          \$partnerUserId: ID!,
          \$orderTotalTzs: Int!,
          \$skillCategory: String,
        ) {
          tajirikaApplicableCommissionTier(
            partnerUserId: \$partnerUserId,
            orderTotalTzs: \$orderTotalTzs,
            skillCategory: \$skillCategory,
          ) {
            tierId
            tierName
            tierLevel
            commissionPct
            commissionTzs
          }
        }
        ''',
        variables: {
          'partnerUserId': partnerUserId.toString(),
          'orderTotalTzs': orderTotalTzs,
          if (skillCategory != null) 'skillCategory': skillCategory,
        },
      );
      final row = data['tajirikaApplicableCommissionTier'] as Map<String, dynamic>?;
      if (row == null) return null;
      return ApplicableTierResult(
        tierId: int.tryParse(row['tierId']?.toString() ?? '') ?? 0,
        tierName: row['tierName'] ?? '',
        tierLevel: int.tryParse(row['tierLevel']?.toString() ?? '') ?? 1,
        commissionPct: int.tryParse(row['commissionPct']?.toString() ?? '') ?? 0,
        commissionTzs: int.tryParse(row['commissionTzs']?.toString() ?? '') ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
