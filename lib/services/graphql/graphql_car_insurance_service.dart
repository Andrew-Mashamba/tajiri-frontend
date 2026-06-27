import '../../car_insurance/models/car_insurance_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL car / motor insurance (Phase 63).
class GraphqlCarInsuranceService {
  static const _providerFields = r'''
    id
    name
    logoUrl
    rating
    reviewCount
    phone
    email
    isVerified
  ''';

  static const _quoteFields = r'''
    id
    providerId
    providerName
    providerLogo
    coverageType
    premium
    excess
    inclusions
    exclusions
    hasNoClaimsDiscount
    discountPercent
    validUntil
  ''';

  static const _policyFields = r'''
    id
    userId
    carId
    policyNumber
    providerName
    providerLogo
    coverageType
    premium
    startDate
    endDate
    status
    vehicleMake
    vehicleModel
    plateNumber
    noClaimsYears
  ''';

  static const _claimFields = r'''
    id
    policyId
    claimNumber
    type
    status
    description
    incidentDate
    claimAmount
    settledAmount
    policeReportNumber
    createdAt
  ''';

  static Map<String, dynamic> _providerToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'logo_url': row['logoUrl'],
      'rating': row['rating'],
      'review_count': row['reviewCount'],
      'phone': row['phone'],
      'email': row['email'],
      'is_verified': row['isVerified'] == true,
    };
  }

  static Map<String, dynamic> _quoteToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'provider_id': int.parse(row['providerId'].toString()),
      'provider_name': row['providerName'],
      'provider_logo': row['providerLogo'],
      'coverage_type': row['coverageType'],
      'premium': row['premium'],
      'excess': row['excess'],
      'inclusions': row['inclusions'] ?? [],
      'exclusions': row['exclusions'] ?? [],
      'has_no_claims_discount': row['hasNoClaimsDiscount'] == true,
      'discount_percent': row['discountPercent'],
      'valid_until': row['validUntil'],
    };
  }

  static Map<String, dynamic> _policyToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'car_id': row['carId'] != null ? int.parse(row['carId'].toString()) : null,
      'policy_number': row['policyNumber'],
      'provider_name': row['providerName'],
      'provider_logo': row['providerLogo'],
      'coverage_type': row['coverageType'],
      'premium': row['premium'],
      'start_date': row['startDate'],
      'end_date': row['endDate'],
      'status': row['status'],
      'vehicle_make': row['vehicleMake'],
      'vehicle_model': row['vehicleModel'],
      'plate_number': row['plateNumber'],
      'no_claims_years': row['noClaimsYears'],
    };
  }

  static Map<String, dynamic> _claimToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'policy_id': int.parse(row['policyId'].toString()),
      'claim_number': row['claimNumber'],
      'type': row['type'],
      'status': row['status'],
      'description': row['description'],
      'incident_date': row['incidentDate'],
      'claim_amount': row['claimAmount'],
      'settled_amount': row['settledAmount'],
      'police_report_number': row['policeReportNumber'],
      'created_at': row['createdAt'],
    };
  }

  static Future<PaginatedResult<InsurancePolicy>> getMyPolicies({int page = 1}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyCarInsurancePolicies(\$page: Int, \$perPage: Int) {
          myCarInsurancePolicies(page: \$page, perPage: \$perPage) {
            currentPage
            lastPage
            total
            items {
              $_policyFields
            }
          }
        }
        ''',
        variables: {'page': page, 'perPage': 20},
        auth: true,
      );
      final conn = data['myCarInsurancePolicies'] as Map<String, dynamic>;
      final rows = conn['items'] as List<dynamic>? ?? [];
      return PaginatedResult(
        success: true,
        items: rows
            .map((row) => InsurancePolicy.fromJson(
                _policyToLegacy(row as Map<String, dynamic>)))
            .toList(),
        currentPage: (conn['currentPage'] as num?)?.toInt() ?? page,
        lastPage: (conn['lastPage'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<InsurancePolicy>> getPolicyDetail(int policyId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CarInsurancePolicy(\$policyId: ID!) {
          carInsurancePolicy(policyId: \$policyId) {
            $_policyFields
          }
        }
        ''',
        variables: {'policyId': policyId.toString()},
        auth: true,
      );
      final row = data['carInsurancePolicy'] as Map<String, dynamic>;
      return SingleResult(
        success: true,
        data: InsurancePolicy.fromJson(_policyToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<InsuranceQuote>> getQuotes({
    required String make,
    required String model,
    required int year,
    required String coverageType,
    double? vehicleValue,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RequestCarInsuranceQuotes(\$input: RequestCarInsuranceQuotesInput!) {
          requestCarInsuranceQuotes(input: \$input) {
            $_quoteFields
          }
        }
        ''',
        variables: {
          'input': {
            'make': make,
            'model': model,
            'year': year,
            'coverageType': coverageType,
            if (vehicleValue != null) 'vehicleValue': vehicleValue,
          },
        },
        auth: true,
      );
      final rows = data['requestCarInsuranceQuotes'] as List<dynamic>? ?? [];
      final items = rows
          .map((row) => InsuranceQuote.fromJson(
              _quoteToLegacy(row as Map<String, dynamic>)))
          .toList();
      return PaginatedResult(success: true, items: items);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<InsurancePolicy>> purchasePolicy(
    int quoteId,
    Map<String, dynamic> body,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PurchaseCarInsuranceQuote(\$quoteId: ID!, \$input: PurchaseCarInsuranceQuoteInput!) {
          purchaseCarInsuranceQuote(quoteId: \$quoteId, input: \$input) {
            $_policyFields
          }
        }
        ''',
        variables: {
          'quoteId': quoteId.toString(),
          'input': {
            'paymentMethod': body['payment_method'] ?? 'wallet',
            if (body['phone_number'] != null) 'phoneNumber': body['phone_number'],
            if (body['plate_number'] != null) 'plateNumber': body['plate_number'],
            if (body['car_id'] != null) 'carId': body['car_id'].toString(),
          },
        },
        auth: true,
      );
      final row = data['purchaseCarInsuranceQuote'] as Map<String, dynamic>;
      return SingleResult(
        success: true,
        data: InsurancePolicy.fromJson(_policyToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<InsuranceClaim>> getMyClaims({int page = 1}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyCarInsuranceClaims(\$page: Int, \$perPage: Int) {
          myCarInsuranceClaims(page: \$page, perPage: \$perPage) {
            currentPage
            lastPage
            total
            items {
              $_claimFields
            }
          }
        }
        ''',
        variables: {'page': page, 'perPage': 20},
        auth: true,
      );
      final conn = data['myCarInsuranceClaims'] as Map<String, dynamic>;
      final rows = conn['items'] as List<dynamic>? ?? [];
      return PaginatedResult(
        success: true,
        items: rows
            .map((row) => InsuranceClaim.fromJson(
                _claimToLegacy(row as Map<String, dynamic>)))
            .toList(),
        currentPage: (conn['currentPage'] as num?)?.toInt() ?? page,
        lastPage: (conn['lastPage'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<InsuranceClaim>> fileClaim(
      Map<String, dynamic> body) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation FileCarInsuranceClaim(\$input: FileCarInsuranceClaimInput!) {
          fileCarInsuranceClaim(input: \$input) {
            $_claimFields
          }
        }
        ''',
        variables: {
          'input': {
            'policyId': body['policy_id'].toString(),
            'type': body['type'],
            'description': body['description'],
            'incidentDate': body['incident_date'],
            if (body['claim_amount'] != null) 'claimAmount': body['claim_amount'],
            if (body['police_report_number'] != null)
              'policeReportNumber': body['police_report_number'],
          },
        },
        auth: true,
      );
      final row = data['fileCarInsuranceClaim'] as Map<String, dynamic>;
      return SingleResult(
        success: true,
        data: InsuranceClaim.fromJson(_claimToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<InsuranceProvider>> getProviders() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query CarInsuranceProviders {
          carInsuranceProviders {
            $_providerFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['carInsuranceProviders'] as List<dynamic>? ?? [];
      return PaginatedResult(
        success: true,
        items: rows
            .map((row) => InsuranceProvider.fromJson(
                _providerToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }
}
