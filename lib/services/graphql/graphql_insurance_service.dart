import '../../insurance/models/insurance_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL insurance module (Phase 62).
class GraphqlInsuranceService {
  static const _productFields = r'''
    id
    name
    providerName
    providerLogoUrl
    category
    coverageType
    premiumMonthly
    premiumAnnual
    coverLimit
    currency
    description
    benefits
    exclusions
    waitingPeriodDays
    isPopular
    rating
  ''';

  static const _policyFields = r'''
    id
    policyNumber
    userId
    productId
    productName
    providerName
    category
    status
    premiumAmount
    premiumFrequency
    coverLimit
    startDate
    endDate
    nextPaymentDate
    beneficiaryName
    linkedModuleId
    linkedModule
  ''';

  static const _claimFields = r'''
    id
    claimNumber
    policyId
    policyNumber
    productName
    status
    claimAmount
    approvedAmount
    reason
    description
    submittedAt
    resolvedAt
    rejectionReason
  ''';

  static Map<String, dynamic> _productToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'provider_name': row['providerName'],
      'provider_logo_url': row['providerLogoUrl'],
      'category': row['category'],
      'coverage_type': row['coverageType'],
      'premium_monthly': row['premiumMonthly'],
      'premium_annual': row['premiumAnnual'],
      'cover_limit': row['coverLimit'],
      'currency': row['currency'],
      'description': row['description'],
      'benefits': row['benefits'] ?? [],
      'exclusions': row['exclusions'] ?? [],
      'waiting_period_days': row['waitingPeriodDays'],
      'is_popular': row['isPopular'] == true,
      'rating': row['rating'],
    };
  }

  static Map<String, dynamic> _policyToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'policy_number': row['policyNumber'],
      'user_id': int.parse(row['userId'].toString()),
      'product_id': int.parse(row['productId'].toString()),
      'product_name': row['productName'],
      'provider_name': row['providerName'],
      'category': row['category'],
      'status': row['status'],
      'premium_amount': row['premiumAmount'],
      'premium_frequency': row['premiumFrequency'],
      'cover_limit': row['coverLimit'],
      'start_date': row['startDate'],
      'end_date': row['endDate'],
      'next_payment_date': row['nextPaymentDate'],
      'beneficiary_name': row['beneficiaryName'],
      'linked_module_id': row['linkedModuleId'] != null
          ? int.parse(row['linkedModuleId'].toString())
          : null,
      'linked_module': row['linkedModule'],
    };
  }

  static Map<String, dynamic> _claimToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'claim_number': row['claimNumber'],
      'policy_id': int.parse(row['policyId'].toString()),
      'policy_number': row['policyNumber'],
      'product_name': row['productName'],
      'status': row['status'],
      'claim_amount': row['claimAmount'],
      'approved_amount': row['approvedAmount'],
      'reason': row['reason'],
      'description': row['description'],
      'submitted_at': row['submittedAt'],
      'resolved_at': row['resolvedAt'],
      'rejection_reason': row['rejectionReason'],
    };
  }

  static Future<InsuranceListResult<InsuranceProduct>> getProducts({
    String? category,
    String? search,
    bool? popularOnly,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query InsuranceProducts(\$category: String, \$search: String, \$popularOnly: Boolean) {
          insuranceProducts(category: \$category, search: \$search, popularOnly: \$popularOnly) {
            $_productFields
          }
        }
        ''',
        variables: {
          if (category != null) 'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
          if (popularOnly == true) 'popularOnly': true,
        },
        auth: false,
      );
      final rows = data['insuranceProducts'] as List<dynamic>? ?? [];
      return InsuranceListResult(
        success: true,
        items: rows
            .map((row) => InsuranceProduct.fromJson(
                _productToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InsuranceListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InsuranceResult<InsuranceProduct>> getProductDetail(
      int productId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query InsuranceProduct(\$productId: ID!) {
          insuranceProduct(productId: \$productId) {
            $_productFields
          }
        }
        ''',
        variables: {'productId': productId.toString()},
        auth: false,
      );
      final row = data['insuranceProduct'] as Map<String, dynamic>;
      return InsuranceResult(
        success: true,
        data: InsuranceProduct.fromJson(_productToLegacy(row)),
      );
    } catch (e) {
      return InsuranceResult(success: false);
    }
  }

  static Future<InsuranceResult<InsurancePolicy>> purchasePolicy({
    required int productId,
    required String premiumFrequency,
    String? beneficiaryName,
    required String paymentMethod,
    String? phoneNumber,
    int? linkedModuleId,
    String? linkedModule,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PurchaseInsurancePolicy(\$input: PurchaseInsurancePolicyInput!) {
          purchaseInsurancePolicy(input: \$input) {
            $_policyFields
          }
        }
        ''',
        variables: {
          'input': {
            'productId': productId.toString(),
            'premiumFrequency': premiumFrequency,
            if (beneficiaryName != null) 'beneficiaryName': beneficiaryName,
            'paymentMethod': paymentMethod,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
            if (linkedModuleId != null)
              'linkedModuleId': linkedModuleId.toString(),
            if (linkedModule != null) 'linkedModule': linkedModule,
          },
        },
        auth: true,
      );
      final row = data['purchaseInsurancePolicy'] as Map<String, dynamic>;
      return InsuranceResult(
        success: true,
        data: InsurancePolicy.fromJson(_policyToLegacy(row)),
      );
    } catch (e) {
      return InsuranceResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InsuranceListResult<InsurancePolicy>> getMyPolicies() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyInsurancePolicies {
          myInsurancePolicies {
            $_policyFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myInsurancePolicies'] as List<dynamic>? ?? [];
      return InsuranceListResult(
        success: true,
        items: rows
            .map((row) => InsurancePolicy.fromJson(
                _policyToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InsuranceListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InsuranceResult<void>> cancelPolicy(int policyId) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelInsurancePolicy(\$policyId: ID!) {
          cancelInsurancePolicy(policyId: \$policyId) {
            id
          }
        }
        ''',
        variables: {'policyId': policyId.toString()},
        auth: true,
      );
      return InsuranceResult(success: true);
    } catch (e) {
      return InsuranceResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InsuranceResult<void>> renewPolicy({
    required int policyId,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RenewInsurancePolicy(\$policyId: ID!, \$input: RenewInsurancePolicyInput!) {
          renewInsurancePolicy(policyId: \$policyId, input: \$input) {
            id
          }
        }
        ''',
        variables: {
          'policyId': policyId.toString(),
          'input': {
            'paymentMethod': paymentMethod,
            if (phoneNumber != null) 'phoneNumber': phoneNumber,
          },
        },
        auth: true,
      );
      return InsuranceResult(success: true);
    } catch (e) {
      return InsuranceResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InsuranceResult<InsuranceClaim>> submitClaim({
    required int policyId,
    required double amount,
    required String reason,
    String? description,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SubmitInsuranceClaim(\$policyId: ID!, \$input: SubmitInsuranceClaimInput!) {
          submitInsuranceClaim(policyId: \$policyId, input: \$input) {
            $_claimFields
          }
        }
        ''',
        variables: {
          'policyId': policyId.toString(),
          'input': {
            'amount': amount,
            'reason': reason,
            if (description != null) 'description': description,
          },
        },
        auth: true,
      );
      final row = data['submitInsuranceClaim'] as Map<String, dynamic>;
      return InsuranceResult(
        success: true,
        data: InsuranceClaim.fromJson(_claimToLegacy(row)),
      );
    } catch (e) {
      return InsuranceResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InsuranceListResult<InsuranceClaim>> getMyClaims() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyInsuranceClaims {
          myInsuranceClaims {
            $_claimFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myInsuranceClaims'] as List<dynamic>? ?? [];
      return InsuranceListResult(
        success: true,
        items: rows
            .map((row) => InsuranceClaim.fromJson(
                _claimToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InsuranceListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<InsuranceListResult<InsuranceProduct>> getRecommendations() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query InsuranceRecommendations {
          insuranceRecommendations {
            $_productFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['insuranceRecommendations'] as List<dynamic>? ?? [];
      return InsuranceListResult(
        success: true,
        items: rows
            .map((row) => InsuranceProduct.fromJson(
                _productToLegacy(row as Map<String, dynamic>)))
            .toList(),
      );
    } catch (e) {
      return InsuranceListResult(success: false);
    }
  }
}
