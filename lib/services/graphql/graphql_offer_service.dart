import '../../shop/offers/models/offer_models.dart';
import 'graphql_offer_mapper.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL shop offers — price negotiation (Phase 16).
class GraphqlOfferService {
  static const _offerFields = r'''
    id
    productId
    productTitle
    productThumbnail
    buyerId
    sellerId
    offeredPrice
    counterPrice
    originalPrice
    status
    buyerMessage
    sellerMessage
    expiresAt
    createdAt
    orderId
    savingsAmount
    savingsPercent
    buyer {
      id
      name
      username
      profileImage
    }
  ''';

  static const _myOffersQuery = '''
    query MyShopOffers(\$type: String) {
      myShopOffers(type: \$type) {
        $_offerFields
      }
    }
  ''';

  static const _productOffersQuery = '''
    query ProductShopOffers(\$productId: ID!) {
      productShopOffers(productId: \$productId) {
        $_offerFields
      }
    }
  ''';

  static const _makeOfferMutation = '''
    mutation MakeShopOffer(\$productId: ID!, \$input: MakeShopOfferInput!) {
      makeShopOffer(productId: \$productId, input: \$input) {
        $_offerFields
      }
    }
  ''';

  static const _acceptOfferMutation = '''
    mutation AcceptShopOffer(\$offerId: ID!) {
      acceptShopOffer(offerId: \$offerId) {
        $_offerFields
      }
    }
  ''';

  static const _declineOfferMutation = '''
    mutation DeclineShopOffer(\$offerId: ID!, \$message: String) {
      declineShopOffer(offerId: \$offerId, message: \$message) {
        $_offerFields
      }
    }
  ''';

  static const _counterOfferMutation = '''
    mutation CounterShopOffer(\$offerId: ID!, \$input: CounterShopOfferInput!) {
      counterShopOffer(offerId: \$offerId, input: \$input) {
        $_offerFields
      }
    }
  ''';

  static const _acceptCounterMutation = '''
    mutation AcceptShopOfferCounter(\$offerId: ID!) {
      acceptShopOfferCounter(offerId: \$offerId) {
        $_offerFields
      }
    }
  ''';

  static const _withdrawOfferMutation = '''
    mutation WithdrawShopOffer(\$offerId: ID!) {
      withdrawShopOffer(offerId: \$offerId) {
        $_offerFields
      }
    }
  ''';

  static Future<List<ProductOffer>> listMyOffers({String type = 'sent'}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _myOffersQuery,
        variables: {'type': type},
        auth: true,
      );
      return (data['myShopOffers'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlOfferMapper.offerFromGraphql)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<ProductOffer>> getProductOffers(int productId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        _productOffersQuery,
        variables: {'productId': productId.toString()},
        auth: true,
      );
      return (data['productShopOffers'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(GraphqlOfferMapper.offerFromGraphql)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> makeOffer(
    int productId,
    double price, {
    String? message,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _makeOfferMutation,
        variables: {
          'productId': productId.toString(),
          'input': {
            'offeredPrice': price,
            if (message != null && message.isNotEmpty) 'message': message,
          },
        },
        auth: true,
      );
      return data['makeShopOffer'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> acceptOffer(int offerId) async {
    return _runOfferMutation(
      _acceptOfferMutation,
      {'offerId': offerId.toString()},
      'acceptShopOffer',
    );
  }

  static Future<bool> declineOffer(int offerId, {String? message}) async {
    return _runOfferMutation(
      _declineOfferMutation,
      {
        'offerId': offerId.toString(),
        if (message != null && message.isNotEmpty) 'message': message,
      },
      'declineShopOffer',
    );
  }

  static Future<bool> counterOffer(
    int offerId,
    double counterPrice, {
    String? message,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _counterOfferMutation,
        variables: {
          'offerId': offerId.toString(),
          'input': {
            'counterPrice': counterPrice,
            if (message != null && message.isNotEmpty) 'message': message,
          },
        },
        auth: true,
      );
      return data['counterShopOffer'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> acceptCounter(int offerId) async {
    return _runOfferMutation(
      _acceptCounterMutation,
      {'offerId': offerId.toString()},
      'acceptShopOfferCounter',
    );
  }

  static Future<bool> withdrawOffer(int offerId) async {
    return _runOfferMutation(
      _withdrawOfferMutation,
      {'offerId': offerId.toString()},
      'withdrawShopOffer',
    );
  }

  static Future<bool> _runOfferMutation(
    String mutation,
    Map<String, dynamic> variables,
    String resultKey,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        mutation,
        variables: variables,
        auth: true,
      );
      return data[resultKey] != null;
    } catch (_) {
      return false;
    }
  }
}
