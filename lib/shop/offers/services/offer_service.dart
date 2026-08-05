import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/http_retry.dart';
import '../../../config/api_config.dart';
import '../../../services/graphql/graphql_offer_service.dart';
import '../models/offer_models.dart';

class OfferService {
  OfferService._();

  static Future<bool> makeOffer(
    int productId,
    double price,
    String token, {
    String? message,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlOfferService.makeOffer(productId, price, message: message);
    }
    try {
      final body = <String, dynamic>{'offered_price': price};
      if (message != null && message.isNotEmpty) body['message'] = message;

      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/shop/products/$productId/offers'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<ProductOffer>> listMyOffers(
    String token, {
    String type = 'sent',
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlOfferService.listMyOffers(type: type);
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/shop/offers').replace(
        queryParameters: {'type': type},
      );
      final resp = await httpGetWithRetry(uri, headers: ApiConfig.authHeaders(token));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => ProductOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<ProductOffer>> getProductOffers(
    int productId,
    String token,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlOfferService.getProductOffers(productId);
    }
    try {
      final resp = await httpGetWithRetry(
        Uri.parse('${ApiConfig.baseUrl}/shop/products/$productId/offers'),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => ProductOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> acceptOffer(int offerId, String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlOfferService.acceptOffer(offerId);
    }
    return _simplePost('${ApiConfig.baseUrl}/shop/offers/$offerId/accept', token);
  }

  static Future<bool> declineOffer(
    int offerId,
    String token, {
    String? message,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlOfferService.declineOffer(offerId, message: message);
    }
    try {
      final body = <String, dynamic>{};
      if (message != null && message.isNotEmpty) body['message'] = message;
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/shop/offers/$offerId/decline'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> counterOffer(
    int offerId,
    double counterPrice,
    String token, {
    String? message,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlOfferService.counterOffer(offerId, counterPrice, message: message);
    }
    try {
      final body = <String, dynamic>{'counter_price': counterPrice};
      if (message != null && message.isNotEmpty) body['message'] = message;
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/shop/offers/$offerId/counter'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> acceptCounter(int offerId, String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlOfferService.acceptCounter(offerId);
    }
    return _simplePost(
        '${ApiConfig.baseUrl}/shop/offers/$offerId/accept-counter', token);
  }

  static Future<bool> withdrawOffer(int offerId, String token) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlOfferService.withdrawOffer(offerId);
    }
    return _simplePost(
        '${ApiConfig.baseUrl}/shop/offers/$offerId/withdraw', token);
  }

  static Future<bool> _simplePost(String url, String token) async {
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
