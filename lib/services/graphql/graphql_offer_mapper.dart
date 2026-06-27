import '../../config/api_config.dart';
import '../../shop/offers/models/offer_models.dart';

/// Maps greenfield GraphQL shop offers → legacy REST JSON for [ProductOffer.fromJson].
class GraphqlOfferMapper {
  static String? _relativeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (!url.startsWith('http')) return url;
    final storage = ApiConfig.graphqlStorageUrl;
    if (url.startsWith(storage)) {
      return url.substring(storage.length).replaceFirst(RegExp(r'^/'), '');
    }
    return url;
  }

  static Map<String, dynamic> offerToLegacy(Map<String, dynamic> gql) {
    final buyer = gql['buyer'] as Map<String, dynamic>?;
    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'product_id': int.tryParse(gql['productId']?.toString() ?? '') ?? 0,
      'product_title': gql['productTitle'] ?? '',
      'product_thumbnail': _relativeUrl(gql['productThumbnail']?.toString()) ?? '',
      'buyer_id': int.tryParse(gql['buyerId']?.toString() ?? '') ?? 0,
      'seller_id': int.tryParse(gql['sellerId']?.toString() ?? '') ?? 0,
      if (buyer != null)
        'buyer': {
          'id': int.tryParse(buyer['id']?.toString() ?? '') ?? 0,
          'name': buyer['name'] ?? '',
          'username': buyer['username'] ?? '',
          'profile_image': _relativeUrl(buyer['profileImage']?.toString()),
        },
      'offered_price': gql['offeredPrice'] ?? 0,
      if (gql['counterPrice'] != null) 'counter_price': gql['counterPrice'],
      'original_price': gql['originalPrice'] ?? 0,
      'status': gql['status'] ?? 'pending',
      if (gql['buyerMessage'] != null) 'buyer_message': gql['buyerMessage'],
      if (gql['sellerMessage'] != null) 'seller_message': gql['sellerMessage'],
      'expires_at': gql['expiresAt']?.toString() ?? DateTime.now().toIso8601String(),
      'created_at': gql['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      if (gql['orderId'] != null) 'order_id': int.tryParse(gql['orderId'].toString()),
      'savings_amount': gql['savingsAmount'] ?? 0,
      'savings_percent': gql['savingsPercent'] ?? 0,
    };
  }

  static ProductOffer offerFromGraphql(Map<String, dynamic> gql) {
    return ProductOffer.fromJson(offerToLegacy(gql));
  }
}
