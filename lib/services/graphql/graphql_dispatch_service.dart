import '../../shop/shipping/models/delivery_models.dart';
import 'graphql_dispatch_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL shop delivery dispatch — quotes, book, track (Phase 18).
class GraphqlDispatchService {
  static const _quoteFields = r'''
    provider
    priceTzs
    available
    vehicleType
    etaMinutes
    unavailableReason
  ''';

  static const _trackingDetailFields = r'''
    status
    statusLabel
    riderName
    riderPhone
    riderLat
    riderLng
    updatedAt
  ''';

  static const _quotesQuery = '''
    query ShopDispatchQuotes(\$orderId: ID!, \$weightKg: Float, \$notes: String) {
      shopDispatchQuotes(orderId: \$orderId, weightKg: \$weightKg, notes: \$notes) {
        $_quoteFields
      }
    }
  ''';

  static const _trackingQuery = '''
    query ShopDispatchTracking(\$orderId: ID!) {
      shopDispatchTracking(orderId: \$orderId) {
        provider
        trackingId
        tracking {
          $_trackingDetailFields
        }
      }
    }
  ''';

  static const _bookMutation = '''
    mutation BookShopDispatch(\$orderId: ID!, \$input: BookShopDispatchInput!) {
      bookShopDispatch(orderId: \$orderId, input: \$input) {
        success
        provider
        trackingId
        trackingUrl
        message
      }
    }
  ''';

  static Future<List<DeliveryQuote>> getQuotes({
    required int orderId,
    double weightKg = 1.0,
    String? notes,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _quotesQuery,
        variables: {
          'orderId': orderId.toString(),
          'weightKg': weightKg,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final raw = data['shopDispatchQuotes'] as List? ?? [];
      return raw
          .map((q) => GraphqlDispatchMapper.quoteFromGraphql(
              q as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return DeliveryProviderType.values
          .map((p) => DeliveryQuote(
                provider: p,
                priceTzs: 0,
                available: false,
                unavailableReason: 'Could not reach server',
              ))
          .toList();
    }
  }

  static Future<DeliveryResult> dispatch({
    required int orderId,
    required DeliveryProviderType provider,
    double weightKg = 1.0,
    String? notes,
    DateTime? preferredPickupTime,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _bookMutation,
        variables: {
          'orderId': orderId.toString(),
          'input': {
            'provider': GraphqlDispatchMapper.providerSlug(provider),
            'weightKg': weightKg,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
            if (preferredPickupTime != null)
              'preferredPickupTime': preferredPickupTime.toIso8601String(),
          },
        },
        auth: true,
      );
      final result = data['bookShopDispatch'] as Map<String, dynamic>? ?? {};
      if (result['success'] == true) {
        return GraphqlDispatchMapper.resultFromGraphql(result, provider);
      }
      return DeliveryResult.failure(
        provider,
        result['message'] as String? ?? 'Dispatch failed',
      );
    } catch (e) {
      return DeliveryResult.failure(
        provider,
        'Network error: ${e.toString().split('\n').first}',
      );
    }
  }

  static Future<DeliveryTracking?> track({required int orderId}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _trackingQuery,
        variables: {'orderId': orderId.toString()},
      );
      final tracking = data['shopDispatchTracking'] as Map<String, dynamic>?;
      if (tracking == null) return null;
      return GraphqlDispatchMapper.trackingFromGraphql(tracking);
    } catch (_) {
      return null;
    }
  }
}
