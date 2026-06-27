import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_biz_service_service.dart';
import '../models/biz_service_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class BizServiceService {
  static Future<List<BusinessService>> getServices(String token, int businessId) async {
    if (ApiConfig.useGraphqlBackend) {
      final rows = await GraphqlBizServiceService.getServices(businessId);
      return rows.map((j) => BusinessService.fromJson(j)).toList();
    }
    try {
      final res = await httpGetWithRetry(
        Uri.parse('$_baseUrl/business/$businessId/services'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          return (data['data'] as List? ?? [])
              .map((j) => BusinessService.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> _serviceBody(BusinessService service) => {
        'name': service.name,
        if (service.description != null) 'description': service.description,
        'pricing_type': service.pricingType.value,
        if (service.price != null) 'price': service.price,
        'currency': service.currency,
        if (service.durationMinutes != null)
          'duration_minutes': service.durationMinutes,
        'availability': service.availability.value,
        if (service.shopCategoryId != null)
          'shop_category_id': service.shopCategoryId,
        if (service.category != null) 'category': service.category,
        'is_active': service.isActive,
      };

  static Future<({bool success, String? error})> createService(
    String token,
    int businessId,
    BusinessService service,
    XFile? photo,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      final body = _serviceBody(service);
      if (service.photoUrl != null && service.photoUrl!.isNotEmpty) {
        body['photo_url'] = service.photoUrl;
      }
      final row = await GraphqlBizServiceService.createService(businessId, body);
      if (row != null) return (success: true, error: null);
      return (success: false, error: 'Failed');
    }
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/business/$businessId/services'),
      );
      request.headers.addAll(ApiConfig.authHeaders(token));
      _addFields(request, service);
      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
      }
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body);
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        if (data['success'] == true) return (success: true, error: null);
      }
      return (success: false, error: data['message']?.toString() ?? 'Failed');
    } catch (e) {
      return (success: false, error: 'Error: $e');
    }
  }

  static Future<({bool success, String? error})> updateService(
    String token,
    int businessId,
    BusinessService service,
    XFile? newPhoto,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      final body = _serviceBody(service);
      if (service.photoUrl != null && service.photoUrl!.isNotEmpty) {
        body['photo_url'] = service.photoUrl;
      }
      final row = await GraphqlBizServiceService.updateService(service.id, body);
      if (row != null) return (success: true, error: null);
      return (success: false, error: 'Failed');
    }
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/business/$businessId/services/${service.id}'),
      );
      request.headers.addAll(ApiConfig.authHeaders(token));
      request.fields['_method'] = 'PUT';
      _addFields(request, service);
      if (newPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', newPhoto.path));
      }
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body);
      if (streamed.statusCode == 200) {
        if (data['success'] == true) return (success: true, error: null);
      }
      return (success: false, error: data['message']?.toString() ?? 'Failed');
    } catch (e) {
      return (success: false, error: 'Error: $e');
    }
  }

  static Future<bool> deleteService(String token, int businessId, int serviceId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlBizServiceService.deleteService(serviceId);
    }
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/business/$businessId/services/$serviceId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> patchServiceAvailability(
    String token,
    int businessId,
    int serviceId,
    ServiceAvailability availability,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlBizServiceService.patchAvailability(
        serviceId,
        availability.value,
      );
    }
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/business/$businessId/services/$serviceId'),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'availability': availability.value}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void _addFields(http.MultipartRequest req, BusinessService s) {
    req.fields['name'] = s.name;
    if (s.description != null) req.fields['description'] = s.description!;
    req.fields['pricing_type'] = s.pricingType.value;
    if (s.price != null) req.fields['price'] = s.price!.toString();
    req.fields['currency'] = s.currency;
    if (s.durationMinutes != null) req.fields['duration_minutes'] = s.durationMinutes!.toString();
    req.fields['availability'] = s.availability.value;
    if (s.shopCategoryId != null) req.fields['shop_category_id'] = s.shopCategoryId!.toString();
    if (s.category != null) req.fields['category'] = s.category!;
    req.fields['is_active'] = s.isActive ? '1' : '0';
  }
}
