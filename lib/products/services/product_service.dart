import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../services/shop_service.dart';
import '../models/product_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class ProductService {
  static Future<List<BusinessProduct>> getProducts({
    required String token,
    required int businessId,
    required int userId,
    required bool isDefaultShop,
  }) async {
    try {
      if (isDefaultShop) {
        final shopService = ShopService();
        final result = await shopService.getSellerProducts(userId, perPage: 100);
        if (result.success) {
          return result.products
              .map((p) => BusinessProduct.fromShopProduct(p, businessId))
              .toList();
        }
        return [];
      } else {
        final res = await http.get(
          Uri.parse('$_baseUrl/business/$businessId/catalog/products'),
          headers: ApiConfig.authHeaders(token),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true) {
            return (data['data'] as List? ?? [])
                .map((j) => BusinessProduct.fromJson(j as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  static Future<({bool success, String? error})> createProduct({
    required String token,
    required int businessId,
    required int userId,
    required bool isDefaultShop,
    required BusinessProduct product,
    required List<XFile> images,
    void Function(int current, int total)? onImageProgress,
  }) async {
    try {
      if (isDefaultShop) {
        final shopService = ShopService();
        final result = await shopService.createProduct(
          sellerId: userId,
          title: product.title,
          description: product.description,
          type: product.type,
          price: product.price,
          compareAtPrice: product.compareAtPrice,
          currency: product.currency,
          stockQuantity: product.stockQuantity,
          categoryId: product.categoryId,
          tags: product.tags.isNotEmpty ? product.tags : null,
          condition: product.condition,
          locationName: product.locationName,
          latitude: product.latitude,
          longitude: product.longitude,
          allowPickup: product.allowPickup,
          allowDelivery: product.allowDelivery,
          allowShipping: product.allowShipping,
          deliveryFee: product.deliveryFee,
          deliveryNotes: product.deliveryNotes,
          pickupAddress: product.pickupAddress,
          downloadUrl: product.downloadUrl,
          downloadLimit: product.downloadLimit,
          durationMinutes: product.durationMinutes,
          serviceLocation: product.serviceLocation,
          images: images.map((x) => File(x.path)).toList(),
        );
        return (success: result.success, error: result.success ? null : 'Failed to save product');
      } else {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/business/$businessId/catalog/products'),
        );
        request.headers.addAll(ApiConfig.authHeaders(token));
        _addProductFields(request, product);
        for (int i = 0; i < images.length; i++) {
          onImageProgress?.call(i + 1, images.length);
          request.files.add(await http.MultipartFile.fromPath('images[]', images[i].path));
        }
        final streamed = await request.send();
        final body = await streamed.stream.bytesToString();
        final data = jsonDecode(body);
        if (streamed.statusCode == 200 || streamed.statusCode == 201) {
          if (data['success'] == true) return (success: true, error: null);
        }
        return (success: false, error: data['message']?.toString() ?? 'Failed');
      }
    } catch (e) {
      return (success: false, error: 'Error: $e');
    }
  }

  static Future<({bool success, String? error})> updateProduct({
    required String token,
    required int businessId,
    required int userId,
    required bool isDefaultShop,
    required BusinessProduct product,
    required List<XFile> newImages,
    void Function(int current, int total)? onImageProgress,
  }) async {
    try {
      if (isDefaultShop) {
        final shopService = ShopService();
        final result = await shopService.updateProduct(
          productId: product.id,
          sellerId: userId,
          title: product.title,
          description: product.description,
          price: product.price,
          compareAtPrice: product.compareAtPrice,
          stockQuantity: product.stockQuantity,
          status: product.status,
          categoryId: product.categoryId,
          tags: product.tags.isNotEmpty ? product.tags : null,
          condition: product.condition,
          locationName: product.locationName,
          allowPickup: product.allowPickup,
          allowDelivery: product.allowDelivery,
          allowShipping: product.allowShipping,
          deliveryFee: product.deliveryFee,
          deliveryNotes: product.deliveryNotes,
          pickupAddress: product.pickupAddress,
          downloadUrl: product.downloadUrl,
          downloadLimit: product.downloadLimit,
          durationMinutes: product.durationMinutes,
          serviceLocation: product.serviceLocation,
          newImages: newImages.map((x) => File(x.path)).toList(),
        );
        return (success: result.success, error: result.success ? null : 'Failed to update');
      } else {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_baseUrl/business/$businessId/catalog/products/${product.id}'),
        );
        request.headers.addAll(ApiConfig.authHeaders(token));
        request.fields['_method'] = 'PUT';
        _addProductFields(request, product);
        for (int i = 0; i < newImages.length; i++) {
          onImageProgress?.call(i + 1, newImages.length);
          request.files.add(await http.MultipartFile.fromPath('images[]', newImages[i].path));
        }
        final streamed = await request.send();
        final body = await streamed.stream.bytesToString();
        final data = jsonDecode(body);
        if (streamed.statusCode == 200) {
          if (data['success'] == true) return (success: true, error: null);
        }
        return (success: false, error: data['message']?.toString() ?? 'Failed');
      }
    } catch (e) {
      return (success: false, error: 'Error: $e');
    }
  }

  static Future<bool> deleteProduct({
    required String token,
    required int businessId,
    required int userId,
    required bool isDefaultShop,
    required int productId,
  }) async {
    try {
      if (isDefaultShop) {
        final shopService = ShopService();
        final result = await shopService.deleteProduct(productId, userId);
        return result;
      } else {
        final res = await http.delete(
          Uri.parse('$_baseUrl/business/$businessId/catalog/products/$productId'),
          headers: ApiConfig.authHeaders(token),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return data['success'] == true;
        }
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> patchProductStatus({
    required String token,
    required int businessId,
    required int userId,
    required bool isDefaultShop,
    required int productId,
    required ProductStatus status,
  }) async {
    try {
      final url = isDefaultShop
          ? '$_baseUrl/shop/products/$productId'
          : '$_baseUrl/business/$businessId/catalog/products/$productId';
      final res = await http.patch(
        Uri.parse(url),
        headers: {
          ...ApiConfig.authHeaders(token),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status.value,
          if (isDefaultShop) 'seller_id': userId,
        }),
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

  static void _addProductFields(http.MultipartRequest req, BusinessProduct p) {
    req.fields['title'] = p.title;
    if (p.description != null) req.fields['description'] = p.description!;
    req.fields['type'] = p.type.value;
    req.fields['status'] = p.status.value;
    req.fields['price'] = p.price.toString();
    if (p.compareAtPrice != null) req.fields['compare_at_price'] = p.compareAtPrice!.toString();
    req.fields['currency'] = p.currency;
    req.fields['stock_quantity'] = p.stockQuantity.toString();
    if (p.categoryId != null) req.fields['category_id'] = p.categoryId!.toString();
    if (p.categoryName != null) req.fields['category'] = p.categoryName!;
    req.fields['condition'] = p.condition.value;
    req.fields['allow_pickup'] = p.allowPickup ? '1' : '0';
    req.fields['allow_delivery'] = p.allowDelivery ? '1' : '0';
    req.fields['allow_shipping'] = p.allowShipping ? '1' : '0';
    if (p.locationName != null) req.fields['location_name'] = p.locationName!;
    if (p.deliveryFee != null) req.fields['delivery_fee'] = p.deliveryFee!.toString();
    if (p.deliveryNotes != null) req.fields['delivery_notes'] = p.deliveryNotes!;
    if (p.pickupAddress != null) req.fields['pickup_address'] = p.pickupAddress!;
    if (p.downloadUrl != null) req.fields['download_url'] = p.downloadUrl!;
    if (p.downloadLimit != null) req.fields['download_limit'] = p.downloadLimit!.toString();
    if (p.durationMinutes != null) req.fields['duration_minutes'] = p.durationMinutes!.toString();
    if (p.serviceLocation != null) req.fields['service_location'] = p.serviceLocation!;
    if (p.tags.isNotEmpty) req.fields['tags'] = jsonEncode(p.tags);
  }
}
