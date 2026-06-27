import 'tajiri_graphql_client.dart';

/// GraphQL business catalog services (`/business/{id}/services`).
class GraphqlBizServiceService {
  static const _serviceFields = r'''
    id businessId userBusinessId name description pricingType price currency
    photoUrl durationMinutes availability shopCategoryId category isActive
    inquiryCount lastInquiryAt createdAt updatedAt
  ''';

  static Map<String, dynamic> _serviceFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'user_business_id': row['userBusinessId'] ?? row['businessId'],
        'name': row['name'],
        'description': row['description'],
        'pricing_type': row['pricingType'],
        'price': row['price'],
        'currency': row['currency'],
        'photo_url': row['photoUrl'],
        'duration_minutes': row['durationMinutes'],
        'availability': row['availability'],
        'shop_category_id': row['shopCategoryId'],
        'category': row['category'],
        'is_active': row['isActive'],
        'inquiry_count': row['inquiryCount'],
        'last_inquiry_at': row['lastInquiryAt'],
        'created_at': row['createdAt'],
        'updated_at': row['updatedAt'],
      };

  static Future<List<Map<String, dynamic>>> getServices(int businessId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BusinessCatalogServices(\$businessId: ID!) {
          businessCatalogServices(businessId: \$businessId) {
            $_serviceFields
          }
        }
        ''',
        variables: {'businessId': businessId.toString()},
        auth: true,
      );
      final rows = data['businessCatalogServices'];
      if (rows is List) {
        return rows.whereType<Map<String, dynamic>>().map(_serviceFromGql).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createService(
    int businessId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBusinessCatalogService(
          \$input: CreateBusinessCatalogServiceInput!
        ) {
          createBusinessCatalogService(input: \$input) {
            $_serviceFields
          }
        }
        ''',
        variables: {
          'input': {
            'businessId': businessId.toString(),
            'name': body['name'],
            if (body['description'] != null) 'description': body['description'],
            if (body['pricing_type'] != null) 'pricingType': body['pricing_type'],
            if (body['price'] != null) 'price': body['price'],
            if (body['currency'] != null) 'currency': body['currency'],
            if (body['photo_url'] != null) 'photoUrl': body['photo_url'],
            if (body['duration_minutes'] != null)
              'durationMinutes': body['duration_minutes'],
            if (body['availability'] != null) 'availability': body['availability'],
            if (body['shop_category_id'] != null)
              'shopCategoryId': body['shop_category_id'].toString(),
            if (body['category'] != null) 'category': body['category'],
            if (body['is_active'] != null) 'isActive': body['is_active'] == true,
          },
        },
        auth: true,
      );
      final row = result['createBusinessCatalogService'];
      if (row is Map<String, dynamic>) return _serviceFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateService(
    int serviceId,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBusinessCatalogService(
          \$serviceId: ID!
          \$input: UpdateBusinessCatalogServiceInput!
        ) {
          updateBusinessCatalogService(serviceId: \$serviceId, input: \$input) {
            $_serviceFields
          }
        }
        ''',
        variables: {
          'serviceId': serviceId.toString(),
          'input': {
            if (body['name'] != null) 'name': body['name'],
            if (body['description'] != null) 'description': body['description'],
            if (body['pricing_type'] != null) 'pricingType': body['pricing_type'],
            if (body['price'] != null) 'price': body['price'],
            if (body['currency'] != null) 'currency': body['currency'],
            if (body['photo_url'] != null) 'photoUrl': body['photo_url'],
            if (body['duration_minutes'] != null)
              'durationMinutes': body['duration_minutes'],
            if (body['availability'] != null) 'availability': body['availability'],
            if (body['shop_category_id'] != null)
              'shopCategoryId': body['shop_category_id'].toString(),
            if (body['category'] != null) 'category': body['category'],
            if (body['is_active'] != null) 'isActive': body['is_active'] == true,
          },
        },
        auth: true,
      );
      final row = result['updateBusinessCatalogService'];
      if (row is Map<String, dynamic>) return _serviceFromGql(row);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteService(int serviceId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteBusinessCatalogService(\$serviceId: ID!) {
          deleteBusinessCatalogService(serviceId: \$serviceId)
        }
        ''',
        variables: {'serviceId': serviceId.toString()},
        auth: true,
      );
      return result['deleteBusinessCatalogService'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> patchAvailability(int serviceId, String availability) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PatchBusinessCatalogServiceAvailability(
          \$serviceId: ID!
          \$availability: String!
        ) {
          patchBusinessCatalogServiceAvailability(
            serviceId: \$serviceId
            availability: \$availability
          ) {
            id availability
          }
        }
        ''',
        variables: {
          'serviceId': serviceId.toString(),
          'availability': availability,
        },
        auth: true,
      );
      return result['patchBusinessCatalogServiceAvailability'] != null;
    } catch (_) {
      return false;
    }
  }
}
