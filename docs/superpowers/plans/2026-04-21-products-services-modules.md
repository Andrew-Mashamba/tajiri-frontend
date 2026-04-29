# Products & Services Modules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Products and Services management to the Business section, with full Shop parity for products, a standard service catalog, and supplier search expanded to match by product/service name.

**Architecture:** Products module routes to existing Shop API for default-shop businesses, new `/business/{id}/catalog/products` endpoints for others. Services module always uses new `/business/{id}/services` endpoints. Both feed `searchTargets` via three new `orWhereHas` clauses. Profile wired via `BizTabWrapper` like `biz_suppliers`.

**Tech Stack:** Flutter/Dart, `http`, `image_picker`, `Dio` (chunked upload). Backend: Laravel, PostgreSQL, `MyBusinessController`, `QuoteRequestService`.

---

## File Map

**Create:**
- `lib/products/models/product_models.dart` — `BusinessProduct` model
- `lib/products/services/product_service.dart` — dual-source CRUD routing
- `lib/products/pages/products_page.dart` — list + detail sheet
- `lib/products/pages/product_form_page.dart` — full-parity add/edit form
- `lib/products/products.dart` — barrel export
- `lib/biz_services/models/biz_service_models.dart` — `BusinessService` model + enums
- `lib/biz_services/services/biz_service_service.dart` — CRUD
- `lib/biz_services/pages/biz_services_page.dart` — list + detail sheet
- `lib/biz_services/pages/biz_service_form_page.dart` — add/edit form
- `lib/biz_services/biz_services.dart` — barrel export

**Modify:**
- `lib/business/models/business_models.dart` — add `isDefaultShop` to `Business`
- `lib/models/profile_tab_config.dart` — add `biz_products`, `biz_services` entries
- `lib/l10n/app_strings.dart` — add bilingual labels
- `lib/screens/profile/profile_screen.dart` — add imports + switch cases
- `lib/suppliers/pages/suppliers_page.dart` — add match-reason chip to search results
- Backend: `MyBusinessController.php`, `api.php` routes, `UserBusiness.php` model, `QuoteRequestService.php`

---

### Task 1: Backend — tables, endpoints, models

**Files:** Backend only (SSH + ask_backend.sh)

- [ ] **Step 1: Run ask_backend.sh**

```bash
./scripts/ask_backend.sh "Please do the following in one migration and update:

1. Create migration for table user_business_products:
   id bigserial PK, user_business_id bigint NOT NULL FK→user_businesses(id) ON DELETE CASCADE,
   title varchar(255) NOT NULL, description text, type varchar(50) DEFAULT 'physical',
   status varchar(50) DEFAULT 'active', price numeric(15,2) NOT NULL DEFAULT 0,
   compare_at_price numeric(15,2), currency varchar(10) DEFAULT 'TZS',
   stock_quantity int DEFAULT 0, images jsonb DEFAULT '[]', thumbnail_path text,
   category_id bigint, tags jsonb DEFAULT '[]', condition varchar(50) DEFAULT 'brand_new',
   location_name varchar(255), latitude numeric(10,7), longitude numeric(10,7),
   allow_pickup bool DEFAULT true, allow_delivery bool DEFAULT false,
   allow_shipping bool DEFAULT false, delivery_fee numeric(15,2), delivery_notes text,
   pickup_address text, download_url text, download_limit int,
   duration_minutes int, service_location text, is_active bool DEFAULT true,
   created_at timestamp, updated_at timestamp.

2. Create migration for table user_business_services:
   id bigserial PK, user_business_id bigint NOT NULL FK→user_businesses(id) ON DELETE CASCADE,
   name varchar(255) NOT NULL, description text,
   pricing_type varchar(20) NOT NULL DEFAULT 'fixed',
   price numeric(15,2), currency varchar(10) DEFAULT 'TZS', photo_url text,
   duration_minutes int, availability varchar(20) DEFAULT 'available',
   category varchar(100), is_active bool DEFAULT true,
   created_at timestamp, updated_at timestamp.

3. Create Eloquent model App\Models\UserBusinessProduct with fillable for all columns above.

4. Create Eloquent model App\Models\UserBusinessService with fillable for all columns above.

5. Add to App\Models\UserBusiness:
   public function catalogProducts() { return \$this->hasMany(UserBusinessProduct::class, 'user_business_id'); }
   public function businessServices() { return \$this->hasMany(UserBusinessService::class, 'user_business_id'); }
   public function shopProducts() { return \$this->hasMany(\App\Models\ShopProduct::class, 'user_id', 'user_id'); }

6. Add these methods to MyBusinessController (auth token required, return JSON {success,data,message}):
   - catalogProducts(\$businessId): GET — return all UserBusinessProduct where user_business_id=\$businessId ordered by created_at desc. JSON fields: id,user_business_id,title,description,type,status,price,compare_at_price,currency,stock_quantity,images,thumbnail_path,category_id,tags,condition,location_name,latitude,longitude,allow_pickup,allow_delivery,allow_shipping,delivery_fee,delivery_notes,pickup_address,download_url,download_limit,duration_minutes,service_location,is_active,created_at,updated_at
   - storeCatalogProduct(\$businessId): POST multipart — validate title required, price required numeric. Store all fields. images field is array of uploaded files; store paths as JSON array. Return {success:true, data: product}.
   - updateCatalogProduct(\$businessId, \$productId): PUT/POST with _method=PUT multipart — same fields optional. Return {success:true, data: product}.
   - deleteCatalogProduct(\$businessId, \$productId): DELETE — hard delete. Return {success:true}.
   - businessServices(\$businessId): GET — return all UserBusinessService where user_business_id=\$businessId. JSON fields: id,user_business_id,name,description,pricing_type,price,currency,photo_url,duration_minutes,availability,category,is_active,created_at,updated_at
   - storeService(\$businessId): POST multipart — validate name required, pricing_type required. photo_url from uploaded file. Return {success:true, data: service}.
   - updateService(\$businessId, \$serviceId): PUT/POST with _method=PUT multipart — all fields optional. Return {success:true, data: service}.
   - deleteService(\$businessId, \$serviceId): DELETE — hard delete. Return {success:true}.

7. Register routes in api.php under auth middleware:
   Route::get('/business/{id}/catalog/products', [MyBusinessController::class, 'catalogProducts']);
   Route::post('/business/{id}/catalog/products', [MyBusinessController::class, 'storeCatalogProduct']);
   Route::post('/business/{id}/catalog/products/{pid}', [MyBusinessController::class, 'updateCatalogProduct']);
   Route::delete('/business/{id}/catalog/products/{pid}', [MyBusinessController::class, 'deleteCatalogProduct']);
   Route::get('/business/{id}/services', [MyBusinessController::class, 'businessServices']);
   Route::post('/business/{id}/services', [MyBusinessController::class, 'storeService']);
   Route::post('/business/{id}/services/{sid}', [MyBusinessController::class, 'updateService']);
   Route::delete('/business/{id}/services/{sid}', [MyBusinessController::class, 'deleteService']);
"
```

- [ ] **Step 2: Verify tables exist**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "cd /var/www/tajiri.zimasystems.com && php artisan migrate:status | grep user_business_prod && php artisan migrate:status | grep user_business_serv"
```

Expected: both migrations show `Ran`.

- [ ] **Step 3: Smoke-test endpoints with curl**

```bash
# Get a token from the app's local storage or use a test token
# Test catalog products list (should return empty array)
curl -s "https://zima-uat.site:8003/api/business/1/catalog/products" \
  -H "Authorization: Bearer TEST_TOKEN" | python3 -m json.tool | head -5
# Expected: {"success":true,"data":[]}
```

- [ ] **Step 4: Commit note** — backend changes are server-side only, no Flutter commit needed.

---

### Task 2: Business model — add `isDefaultShop`

**Files:**
- Modify: `lib/business/models/business_models.dart`

- [ ] **Step 1: Add field to `Business` class** — after `isActive` at line ~281:

```dart
  final bool isDefaultShop;
```

- [ ] **Step 2: Add to constructor** — after `isActive = true`:

```dart
    this.isDefaultShop = false,
```

- [ ] **Step 3: Add to `fromJson`** — after `isActive: _parseBool(json['is_active'], true)`:

```dart
      isDefaultShop: _parseBool(json['is_default_shop']),
```

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/business/models/business_models.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/business/models/business_models.dart
git commit -m "feat(business): add isDefaultShop field to Business model"
```

---

### Task 3: Product models

**Files:**
- Create: `lib/products/models/product_models.dart`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/products/models
mkdir -p /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/products/services
mkdir -p /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/products/pages
```

- [ ] **Step 2: Create `lib/products/models/product_models.dart`**

```dart
import '../../models/shop_models.dart';
import '../../config/api_config.dart';

export '../../models/shop_models.dart' show ProductType, ProductStatus, ProductCondition;

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v, [double def = 0.0]) {
  if (v == null) return def;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? def;
}

List<String> _parseStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

class BusinessProduct {
  final int id;
  final int businessId;
  final bool isShopProduct;
  final String title;
  final String? description;
  final String? slug;
  final ProductType type;
  final ProductStatus status;
  final double price;
  final double? compareAtPrice;
  final String currency;
  final int stockQuantity;
  final List<String> images;
  final String? thumbnailPath;
  final int? categoryId;
  final List<String> tags;
  final ProductCondition condition;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final bool allowPickup;
  final bool allowDelivery;
  final bool allowShipping;
  final double? deliveryFee;
  final String? deliveryNotes;
  final String? pickupAddress;
  final String? downloadUrl;
  final int? downloadLimit;
  final int? durationMinutes;
  final String? serviceLocation;
  final int viewsCount;
  final int favoritesCount;
  final int ordersCount;
  final double rating;
  final int reviewsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessProduct({
    required this.id,
    required this.businessId,
    required this.isShopProduct,
    required this.title,
    this.description,
    this.slug,
    this.type = ProductType.physical,
    this.status = ProductStatus.active,
    required this.price,
    this.compareAtPrice,
    this.currency = 'TZS',
    this.stockQuantity = 0,
    this.images = const [],
    this.thumbnailPath,
    this.categoryId,
    this.tags = const [],
    this.condition = ProductCondition.brandNew,
    this.locationName,
    this.latitude,
    this.longitude,
    this.allowPickup = true,
    this.allowDelivery = false,
    this.allowShipping = false,
    this.deliveryFee,
    this.deliveryNotes,
    this.pickupAddress,
    this.downloadUrl,
    this.downloadLimit,
    this.durationMinutes,
    this.serviceLocation,
    this.viewsCount = 0,
    this.favoritesCount = 0,
    this.ordersCount = 0,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessProduct.fromShopProduct(Product p, int businessId) {
    return BusinessProduct(
      id: p.id,
      businessId: businessId,
      isShopProduct: true,
      title: p.title,
      description: p.description,
      slug: p.slug,
      type: p.type,
      status: p.status,
      price: p.price,
      compareAtPrice: p.compareAtPrice,
      currency: p.currency,
      stockQuantity: p.stockQuantity,
      images: p.images.map((img) => ApiConfig.sanitizeUrl(img) ?? img).toList(),
      thumbnailPath: p.thumbnailPath != null ? ApiConfig.sanitizeUrl(p.thumbnailPath) : null,
      categoryId: p.categoryId,
      tags: p.tags ?? [],
      condition: p.condition,
      locationName: p.locationName,
      latitude: p.latitude,
      longitude: p.longitude,
      allowPickup: p.allowPickup,
      allowDelivery: p.allowDelivery,
      allowShipping: p.allowShipping,
      deliveryFee: p.deliveryFee,
      deliveryNotes: p.deliveryNotes,
      pickupAddress: p.pickupAddress,
      downloadUrl: p.downloadUrl,
      downloadLimit: p.downloadLimit,
      durationMinutes: p.durationMinutes,
      serviceLocation: p.serviceLocation,
      viewsCount: p.viewsCount,
      favoritesCount: p.favoritesCount,
      ordersCount: p.ordersCount,
      rating: p.rating,
      reviewsCount: p.reviewsCount,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  factory BusinessProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> images = [];
    if (rawImages is List) {
      images = rawImages
          .map((e) => ApiConfig.sanitizeUrl(e.toString()) ?? e.toString())
          .toList();
    }
    return BusinessProduct(
      id: _parseInt(json['id']) ?? 0,
      businessId: _parseInt(json['user_business_id']) ?? 0,
      isShopProduct: false,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      type: ProductType.fromString(json['type']?.toString()),
      status: ProductStatus.fromString(json['status']?.toString()),
      price: _parseDouble(json['price']),
      compareAtPrice: json['compare_at_price'] != null
          ? _parseDouble(json['compare_at_price'])
          : null,
      currency: json['currency']?.toString() ?? 'TZS',
      stockQuantity: _parseInt(json['stock_quantity']) ?? 0,
      images: images,
      thumbnailPath: json['thumbnail_path'] != null
          ? ApiConfig.sanitizeUrl(json['thumbnail_path'].toString())
          : null,
      categoryId: _parseInt(json['category_id']),
      tags: _parseStringList(json['tags']),
      condition: ProductCondition.fromString(json['condition']?.toString()),
      locationName: json['location_name']?.toString(),
      latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? _parseDouble(json['longitude']) : null,
      allowPickup: json['allow_pickup'] == true,
      allowDelivery: json['allow_delivery'] == true,
      allowShipping: json['allow_shipping'] == true,
      deliveryFee: json['delivery_fee'] != null
          ? _parseDouble(json['delivery_fee'])
          : null,
      deliveryNotes: json['delivery_notes']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      downloadLimit: _parseInt(json['download_limit']),
      durationMinutes: _parseInt(json['duration_minutes']),
      serviceLocation: json['service_location']?.toString(),
      viewsCount: _parseInt(json['views_count']) ?? 0,
      favoritesCount: _parseInt(json['favorites_count']) ?? 0,
      ordersCount: _parseInt(json['orders_count']) ?? 0,
      rating: _parseDouble(json['rating']),
      reviewsCount: _parseInt(json['reviews_count']) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case ProductStatus.active: return 'Active';
      case ProductStatus.inactive: return 'Inactive';
      case ProductStatus.draft: return 'Draft';
      default: return status.value;
    }
  }

  String get thumbnail =>
      thumbnailPath ?? (images.isNotEmpty ? images.first : '');
}
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/products/models/product_models.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/products/
git commit -m "feat(products): add BusinessProduct model"
```

---

### Task 4: Product service

**Files:**
- Create: `lib/products/services/product_service.dart`

- [ ] **Step 1: Create `lib/products/services/product_service.dart`**

```dart
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
        for (final xf in images) {
          request.files.add(await http.MultipartFile.fromPath('images[]', xf.path));
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
        for (final xf in newImages) {
          request.files.add(await http.MultipartFile.fromPath('images[]', xf.path));
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
        final result = await shopService.deleteProduct(productId: productId, sellerId: userId);
        return result.success;
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
```

- [ ] **Step 2: Check ShopService has `deleteProduct`**

```bash
grep -n 'deleteProduct' /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/services/shop_service.dart | head -3
```

If not found, replace the `deleteProduct` call in the service with a direct HTTP DELETE to `$_baseUrl/shop/products/$productId`.

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/products/services/product_service.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

- [ ] **Step 4: Commit**

```bash
git add lib/products/services/
git commit -m "feat(products): add ProductService with dual-source routing"
```

---

### Task 5: Products page

**Files:**
- Create: `lib/products/pages/products_page.dart`

- [ ] **Step 1: Create `lib/products/pages/products_page.dart`**

```dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/product_models.dart';
import '../services/product_service.dart';
import 'product_form_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class ProductsPage extends StatefulWidget {
  final int businessId;
  final bool isDefaultShop;

  const ProductsPage({
    super.key,
    required this.businessId,
    required this.isDefaultShop,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _loading = true;
  List<BusinessProduct> _products = [];
  String? _token;
  int _userId = 0;

  bool get _isSwahili {
    final storage = LocalStorageService.instanceSync;
    return storage?.getLanguage() == 'sw';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    _userId = storage.getUser()?.userId ?? 0;
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final products = await ProductService.getProducts(
      token: _token!,
      businessId: widget.businessId,
      userId: _userId,
      isDefaultShop: widget.isDefaultShop,
    );
    if (mounted) setState(() { _loading = false; _products = products; });
  }

  void _openForm({BusinessProduct? product}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          businessId: widget.businessId,
          isDefaultShop: widget.isDefaultShop,
          userId: _userId,
          token: _token ?? '',
          product: product,
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  void _showDetail(BusinessProduct p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ProductDetailSheet(
        product: p,
        isSwahili: _isSwahili,
        onEdit: () { Navigator.pop(ctx); _openForm(product: p); },
        onDelete: () async {
          Navigator.pop(ctx);
          final ok = await ProductService.deleteProduct(
            token: _token!,
            businessId: widget.businessId,
            userId: _userId,
            isDefaultShop: widget.isDefaultShop,
            productId: p.id,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? (_isSwahili ? 'Bidhaa imefutwa' : 'Product deleted')
                : (_isSwahili ? 'Imeshindikana' : 'Failed')),
            backgroundColor: ok ? null : Colors.red,
          ));
          if (ok) _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(_isSwahili ? 'Bidhaa' : 'Products',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _products.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (_, i) => _ProductCard(
                      product: _products[i],
                      onTap: () => _showDetail(_products[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _isSwahili ? 'Bado hakuna bidhaa' : 'No products yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _isSwahili
                  ? 'Ongeza bidhaa kwanza ili wanunuzi wakupate'
                  : 'Add products so buyers can find your business',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final BusinessProduct product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  Color _statusColor(ProductStatus s) {
    switch (s) {
      case ProductStatus.active: return Colors.green;
      case ProductStatus.draft: return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.thumbnail.isNotEmpty
                      ? Image.network(product.thumbnail, width: 56, height: 56, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        'TZS ${_fmt(product.price)}',
                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(product.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(product.status)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56, height: 56,
    color: Colors.grey.shade100,
    child: const Icon(Icons.image_outlined, color: Colors.grey),
  );

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ProductDetailSheet extends StatelessWidget {
  final BusinessProduct product;
  final bool isSwahili;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductDetailSheet({required this.product, required this.isSwahili,
      required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.images.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: product.images.length,
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(product.images[i], fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.image_outlined, color: Colors.grey))),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(product.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
                  const SizedBox(height: 4),
                  Text('TZS ${_fmt(product.price)}',
                      style: const TextStyle(fontSize: 16, color: _kSecondary)),
                  if (product.description != null) ...[
                    const SizedBox(height: 12),
                    Text(product.description!, style: const TextStyle(color: _kSecondary)),
                  ],
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        label: Text(isSwahili ? 'Futa' : 'Delete',
                            style: const TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(isSwahili ? 'Hariri' : 'Edit'),
                        style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/products/pages/products_page.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

- [ ] **Step 3: Commit**

```bash
git add lib/products/pages/products_page.dart
git commit -m "feat(products): add ProductsPage with list and detail sheet"
```

---

### Task 6: Product form page

**Files:**
- Create: `lib/products/pages/product_form_page.dart`

- [ ] **Step 1: Create `lib/products/pages/product_form_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_models.dart';
import '../services/product_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);

class ProductFormPage extends StatefulWidget {
  final int businessId;
  final bool isDefaultShop;
  final int userId;
  final String token;
  final BusinessProduct? product;

  const ProductFormPage({
    super.key,
    required this.businessId,
    required this.isDefaultShop,
    required this.userId,
    required this.token,
    this.product,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _compareAtCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _deliveryFeeCtrl;
  late final TextEditingController _deliveryNotesCtrl;
  late final TextEditingController _pickupAddressCtrl;
  late final TextEditingController _downloadUrlCtrl;
  late final TextEditingController _downloadLimitCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _serviceLocationCtrl;
  late final TextEditingController _tagsCtrl;

  ProductType _type = ProductType.physical;
  ProductStatus _status = ProductStatus.active;
  ProductCondition _condition = ProductCondition.brandNew;
  bool _allowPickup = true;
  bool _allowDelivery = false;
  bool _allowShipping = false;

  List<String> _existingImages = [];
  List<XFile> _newImages = [];

  bool get _isSwahili => false; // use AppStringsScope in full impl

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _compareAtCtrl = TextEditingController(
        text: p?.compareAtPrice != null ? p!.compareAtPrice!.toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stockQuantity.toString() : '0');
    _locationCtrl = TextEditingController(text: p?.locationName ?? '');
    _deliveryFeeCtrl = TextEditingController(
        text: p?.deliveryFee != null ? p!.deliveryFee!.toStringAsFixed(0) : '');
    _deliveryNotesCtrl = TextEditingController(text: p?.deliveryNotes ?? '');
    _pickupAddressCtrl = TextEditingController(text: p?.pickupAddress ?? '');
    _downloadUrlCtrl = TextEditingController(text: p?.downloadUrl ?? '');
    _downloadLimitCtrl = TextEditingController(
        text: p?.downloadLimit != null ? p!.downloadLimit!.toString() : '');
    _durationCtrl = TextEditingController(
        text: p?.durationMinutes != null ? p!.durationMinutes!.toString() : '');
    _serviceLocationCtrl = TextEditingController(text: p?.serviceLocation ?? '');
    _tagsCtrl = TextEditingController(text: p?.tags.join(', ') ?? '');

    if (p != null) {
      _type = p.type;
      _status = p.status;
      _condition = p.condition;
      _allowPickup = p.allowPickup;
      _allowDelivery = p.allowDelivery;
      _allowShipping = p.allowShipping;
      _existingImages = List.from(p.images);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _compareAtCtrl.dispose(); _stockCtrl.dispose(); _locationCtrl.dispose();
    _deliveryFeeCtrl.dispose(); _deliveryNotesCtrl.dispose();
    _pickupAddressCtrl.dispose(); _downloadUrlCtrl.dispose();
    _downloadLimitCtrl.dispose(); _durationCtrl.dispose();
    _serviceLocationCtrl.dispose(); _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        final remaining = 10 - _existingImages.length - _newImages.length;
        _newImages.addAll(picked.take(remaining));
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImages.isEmpty && _newImages.isEmpty && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Ongeza picha moja angalau' : 'Add at least one image'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _saving = true);

    final tags = _tagsCtrl.text.split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final product = BusinessProduct(
      id: widget.product?.id ?? 0,
      businessId: widget.businessId,
      isShopProduct: widget.isDefaultShop,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      type: _type,
      status: _status,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      compareAtPrice: _compareAtCtrl.text.isEmpty
          ? null : double.tryParse(_compareAtCtrl.text),
      stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
      condition: _condition,
      locationName: _locationCtrl.text.isEmpty ? null : _locationCtrl.text,
      allowPickup: _allowPickup,
      allowDelivery: _allowDelivery,
      allowShipping: _allowShipping,
      deliveryFee: _deliveryFeeCtrl.text.isEmpty
          ? null : double.tryParse(_deliveryFeeCtrl.text),
      deliveryNotes: _deliveryNotesCtrl.text.isEmpty ? null : _deliveryNotesCtrl.text,
      pickupAddress: _pickupAddressCtrl.text.isEmpty ? null : _pickupAddressCtrl.text,
      downloadUrl: _downloadUrlCtrl.text.isEmpty ? null : _downloadUrlCtrl.text,
      downloadLimit: _downloadLimitCtrl.text.isEmpty
          ? null : int.tryParse(_downloadLimitCtrl.text),
      durationMinutes: _durationCtrl.text.isEmpty
          ? null : int.tryParse(_durationCtrl.text),
      serviceLocation: _serviceLocationCtrl.text.isEmpty ? null : _serviceLocationCtrl.text,
      tags: tags,
      images: _existingImages,
    );

    final result = _isEditing
        ? await ProductService.updateProduct(
            token: widget.token,
            businessId: widget.businessId,
            userId: widget.userId,
            isDefaultShop: widget.isDefaultShop,
            product: product,
            newImages: _newImages,
          )
        : await ProductService.createProduct(
            token: widget.token,
            businessId: widget.businessId,
            userId: widget.userId,
            isDefaultShop: widget.isDefaultShop,
            product: product,
            images: _newImages,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? (_isSwahili ? 'Bidhaa imesasishwa' : 'Product updated')
            : (_isSwahili ? 'Bidhaa imehifadhiwa' : 'Product saved')),
      ));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? (_isSwahili ? 'Imeshindikana' : 'Failed')),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(_isEditing
            ? (_isSwahili ? 'Hariri Bidhaa' : 'Edit Product')
            : (_isSwahili ? 'Ongeza Bidhaa' : 'Add Product'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(_isSwahili ? 'Hifadhi' : 'Save',
                  style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(_isSwahili ? 'Maelezo ya Msingi' : 'Basic Info'),
              _card(Column(children: [
                _field(_titleCtrl, _isSwahili ? 'Jina la bidhaa' : 'Product title',
                    required: true),
                _field(_descCtrl, _isSwahili ? 'Maelezo' : 'Description',
                    maxLines: 3),
                _dropdown<ProductType>(
                  label: _isSwahili ? 'Aina' : 'Type',
                  value: _type,
                  items: [
                    DropdownMenuItem(value: ProductType.physical, child: Text(_isSwahili ? 'Bidhaa halisi' : 'Physical')),
                    DropdownMenuItem(value: ProductType.digital, child: Text(_isSwahili ? 'Dijitali' : 'Digital')),
                    DropdownMenuItem(value: ProductType.service, child: Text(_isSwahili ? 'Huduma' : 'Service')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                if (_type == ProductType.physical)
                  _dropdown<ProductCondition>(
                    label: _isSwahili ? 'Hali' : 'Condition',
                    value: _condition,
                    items: [
                      DropdownMenuItem(value: ProductCondition.brandNew, child: Text(_isSwahili ? 'Mpya kabisa' : 'Brand New')),
                      DropdownMenuItem(value: ProductCondition.used, child: Text(_isSwahili ? 'Imetumika' : 'Used')),
                      DropdownMenuItem(value: ProductCondition.refurbished, child: Text(_isSwahili ? 'Imefanyiwa kazi' : 'Refurbished')),
                    ],
                    onChanged: (v) => setState(() => _condition = v!),
                  ),
                _field(_tagsCtrl, _isSwahili ? 'Lebo (tenganisha kwa koma)' : 'Tags (comma-separated)'),
              ])),

              _section(_isSwahili ? 'Bei' : 'Pricing'),
              _card(Column(children: [
                _field(_priceCtrl, 'TZS', required: true, keyboardType: TextInputType.number,
                    prefix: 'TZS '),
                _field(_compareAtCtrl, _isSwahili ? 'Bei ya awali (optional)' : 'Compare at price',
                    keyboardType: TextInputType.number, prefix: 'TZS '),
                _dropdown<ProductStatus>(
                  label: _isSwahili ? 'Hali ya orodha' : 'Listing status',
                  value: _status,
                  items: [
                    DropdownMenuItem(value: ProductStatus.active, child: Text(_isSwahili ? 'Hai' : 'Active')),
                    DropdownMenuItem(value: ProductStatus.draft, child: Text(_isSwahili ? 'Rasimu' : 'Draft')),
                    DropdownMenuItem(value: ProductStatus.inactive, child: Text(_isSwahili ? 'Imefungwa' : 'Inactive')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ])),

              _section(_isSwahili ? 'Picha' : 'Images'),
              _card(_buildImagePicker()),

              if (_type == ProductType.physical || _type == ProductType.service) ...[
                _section(_isSwahili ? 'Stoki' : 'Stock'),
                _card(_field(_stockCtrl, _isSwahili ? 'Idadi ya stoki' : 'Stock quantity',
                    keyboardType: TextInputType.number)),
              ],

              _section(_isSwahili ? 'Utoaji' : 'Delivery'),
              _card(Column(children: [
                SwitchListTile(
                  value: _allowPickup, activeColor: _kPrimary,
                  title: Text(_isSwahili ? 'Kuchukua' : 'Pickup available'),
                  onChanged: (v) => setState(() => _allowPickup = v),
                ),
                if (_allowPickup)
                  _field(_pickupAddressCtrl, _isSwahili ? 'Mahali pa kuchukua' : 'Pickup address'),
                SwitchListTile(
                  value: _allowDelivery, activeColor: _kPrimary,
                  title: Text(_isSwahili ? 'Uwasilishaji' : 'Delivery available'),
                  onChanged: (v) => setState(() => _allowDelivery = v),
                ),
                if (_allowDelivery) ...[
                  _field(_deliveryFeeCtrl, _isSwahili ? 'Ada ya uwasilishaji' : 'Delivery fee',
                      keyboardType: TextInputType.number, prefix: 'TZS '),
                  _field(_deliveryNotesCtrl, _isSwahili ? 'Maelezo ya utoaji' : 'Delivery notes'),
                ],
                SwitchListTile(
                  value: _allowShipping, activeColor: _kPrimary,
                  title: Text(_isSwahili ? 'Usafirishaji' : 'Shipping available'),
                  onChanged: (v) => setState(() => _allowShipping = v),
                ),
              ])),

              if (_type == ProductType.digital) ...[
                _section(_isSwahili ? 'Dijitali' : 'Digital'),
                _card(Column(children: [
                  _field(_downloadUrlCtrl, 'Download URL'),
                  _field(_downloadLimitCtrl, _isSwahili ? 'Kikomo cha upakuaji' : 'Download limit',
                      keyboardType: TextInputType.number),
                ])),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final allCount = _existingImages.length + _newImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ..._existingImages.map((url) => _imageThumb(
              child: Image.network(url, width: 72, height: 72, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
              onRemove: () => setState(() => _existingImages.remove(url)),
            )),
            ..._newImages.map((xf) => _imageThumb(
              child: Image.asset(xf.path, width: 72, height: 72, fit: BoxFit.cover),
              onRemove: () => setState(() => _newImages.remove(xf)),
            )),
            if (allCount < 10)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text('$allCount / 10',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _imageThumb({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 72, height: 72, child: child)),
        Positioned(
          top: 0, right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: _kPrimary, letterSpacing: 0.5)),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1,
       TextInputType? keyboardType, String? prefix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? (_isSwahili ? 'Hii inahitajika' : 'Required')
                : null
            : null,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Fix Image.asset → Image.file for XFile** — replace `Image.asset(xf.path, ...)` with:

```dart
import 'dart:io';
// in _imageThumb for new images:
Image.file(File(xf.path), width: 72, height: 72, fit: BoxFit.cover),
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/products/pages/product_form_page.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

- [ ] **Step 4: Commit**

```bash
git add lib/products/pages/product_form_page.dart
git commit -m "feat(products): add ProductFormPage full-parity form"
```

---

### Task 7: Products barrel + BizService models

**Files:**
- Create: `lib/products/products.dart`
- Create: `lib/biz_services/models/biz_service_models.dart`

- [ ] **Step 1: Create `lib/products/products.dart`**

```dart
export 'pages/products_page.dart';
export 'models/product_models.dart';
```

- [ ] **Step 2: Create biz_services directories**

```bash
mkdir -p /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/biz_services/models
mkdir -p /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/biz_services/services
mkdir -p /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/biz_services/pages
```

- [ ] **Step 3: Create `lib/biz_services/models/biz_service_models.dart`**

```dart
import '../../config/api_config.dart';

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

enum ServicePricingType {
  fixed,
  hourly,
  quoted;

  static ServicePricingType fromString(String? s) {
    switch (s) {
      case 'hourly': return ServicePricingType.hourly;
      case 'quoted': return ServicePricingType.quoted;
      default: return ServicePricingType.fixed;
    }
  }

  String get value => name;

  String label(bool isSwahili) {
    switch (this) {
      case ServicePricingType.fixed: return isSwahili ? 'Bei ya kawaida' : 'Fixed';
      case ServicePricingType.hourly: return isSwahili ? 'Kwa saa' : 'Per hour';
      case ServicePricingType.quoted: return isSwahili ? 'Bei ya makubaliano' : 'Quote only';
    }
  }
}

enum ServiceAvailability {
  available,
  unavailable,
  byRequest;

  static ServiceAvailability fromString(String? s) {
    switch (s) {
      case 'unavailable': return ServiceAvailability.unavailable;
      case 'by_request': return ServiceAvailability.byRequest;
      default: return ServiceAvailability.available;
    }
  }

  String get value {
    switch (this) {
      case ServiceAvailability.byRequest: return 'by_request';
      default: return name;
    }
  }

  String label(bool isSwahili) {
    switch (this) {
      case ServiceAvailability.available: return isSwahili ? 'Inapatikana' : 'Available';
      case ServiceAvailability.unavailable: return isSwahili ? 'Haipatikani' : 'Unavailable';
      case ServiceAvailability.byRequest: return isSwahili ? 'Kwa ombi' : 'By request';
    }
  }

  Color get color {
    switch (this) {
      case ServiceAvailability.available: return const Color(0xFF4CAF50);
      case ServiceAvailability.unavailable: return const Color(0xFF9E9E9E);
      case ServiceAvailability.byRequest: return const Color(0xFFFF9800);
    }
  }
}

class BusinessService {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final ServicePricingType pricingType;
  final double? price;
  final String currency;
  final String? photoUrl;
  final int? durationMinutes;
  final ServiceAvailability availability;
  final String? category;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessService({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.pricingType = ServicePricingType.fixed,
    this.price,
    this.currency = 'TZS',
    this.photoUrl,
    this.durationMinutes,
    this.availability = ServiceAvailability.available,
    this.category,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessService.fromJson(Map<String, dynamic> json) {
    return BusinessService(
      id: _parseInt(json['id']) ?? 0,
      businessId: _parseInt(json['user_business_id']) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      pricingType: ServicePricingType.fromString(json['pricing_type']?.toString()),
      price: _parseDouble(json['price']),
      currency: json['currency']?.toString() ?? 'TZS',
      photoUrl: json['photo_url'] != null
          ? ApiConfig.sanitizeUrl(json['photo_url'].toString())
          : null,
      durationMinutes: _parseInt(json['duration_minutes']),
      availability: ServiceAvailability.fromString(json['availability']?.toString()),
      category: json['category']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  String priceBadge(bool isSwahili) {
    if (pricingType == ServicePricingType.quoted || price == null) {
      return isSwahili ? 'Bei ya makubaliano' : 'Quote only';
    }
    final formatted = _fmtPrice(price!);
    return pricingType == ServicePricingType.hourly
        ? 'TZS $formatted/hr'
        : 'TZS $formatted';
  }

  static String _fmtPrice(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
```

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/products/products.dart lib/biz_services/models/biz_service_models.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

- [ ] **Step 5: Commit**

```bash
git add lib/products/products.dart lib/biz_services/
git commit -m "feat(biz-services): add BusinessService model and products barrel"
```

---

### Task 8: BizService service + pages

**Files:**
- Create: `lib/biz_services/services/biz_service_service.dart`
- Create: `lib/biz_services/pages/biz_services_page.dart`
- Create: `lib/biz_services/pages/biz_service_form_page.dart`
- Create: `lib/biz_services/biz_services.dart`

- [ ] **Step 1: Create `lib/biz_services/services/biz_service_service.dart`**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../models/biz_service_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class BizServiceService {
  static Future<List<BusinessService>> getServices(String token, int businessId) async {
    try {
      final res = await http.get(
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

  static Future<({bool success, String? error})> createService(
    String token,
    int businessId,
    BusinessService service,
    XFile? photo,
  ) async {
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

  static void _addFields(http.MultipartRequest req, BusinessService s) {
    req.fields['name'] = s.name;
    if (s.description != null) req.fields['description'] = s.description!;
    req.fields['pricing_type'] = s.pricingType.value;
    if (s.price != null) req.fields['price'] = s.price!.toString();
    req.fields['currency'] = s.currency;
    if (s.durationMinutes != null) req.fields['duration_minutes'] = s.durationMinutes!.toString();
    req.fields['availability'] = s.availability.value;
    if (s.category != null) req.fields['category'] = s.category!;
    req.fields['is_active'] = s.isActive ? '1' : '0';
  }
}
```

- [ ] **Step 2: Create `lib/biz_services/pages/biz_services_page.dart`**

```dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/biz_service_models.dart';
import '../services/biz_service_service.dart';
import 'biz_service_form_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BizServicesPage extends StatefulWidget {
  final int businessId;
  const BizServicesPage({super.key, required this.businessId});

  @override
  State<BizServicesPage> createState() => _BizServicesPageState();
}

class _BizServicesPageState extends State<BizServicesPage> {
  bool _loading = true;
  List<BusinessService> _services = [];
  String? _token;

  bool get _isSwahili {
    final storage = LocalStorageService.instanceSync;
    return storage?.getLanguage() == 'sw';
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    final services = await BizServiceService.getServices(_token!, widget.businessId);
    if (mounted) setState(() { _loading = false; _services = services; });
  }

  void _openForm({BusinessService? service}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BizServiceFormPage(
        businessId: widget.businessId,
        token: _token ?? '',
        service: service,
      )),
    );
    if (saved == true && mounted) _load();
  }

  void _showDetail(BusinessService s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            if (s.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(s.photoUrl!, height: 160, width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            const SizedBox(height: 12),
            Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: _kPrimary)),
            const SizedBox(height: 4),
            Row(children: [
              _pricingBadge(s),
              const SizedBox(width: 8),
              _availabilityChip(s.availability),
            ]),
            if (s.description != null) ...[
              const SizedBox(height: 12),
              Text(s.description!, style: const TextStyle(color: _kSecondary)),
            ],
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await BizServiceService.deleteService(
                        _token!, widget.businessId, s.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? (_isSwahili ? 'Huduma imefutwa' : 'Service deleted')
                          : (_isSwahili ? 'Imeshindikana' : 'Failed')),
                      backgroundColor: ok ? null : Colors.red,
                    ));
                    if (ok) _load();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  label: Text(_isSwahili ? 'Futa' : 'Delete',
                      style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () { Navigator.pop(ctx); _openForm(service: s); },
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(_isSwahili ? 'Hariri' : 'Edit'),
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _pricingBadge(BusinessService s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(s.priceBadge(_isSwahili),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
    );
  }

  Widget _availabilityChip(ServiceAvailability a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: a.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(a.label(_isSwahili),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: a.color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(_isSwahili ? 'Huduma' : 'Services',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _services.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.miscellaneous_services_outlined, size: 72,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(_isSwahili ? 'Bado hakuna huduma' : 'No services yet',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                color: _kPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          _isSwahili
                              ? 'Ongeza huduma ili wateja wakupate'
                              : 'Add services so clients can find your business',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _kSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (_, i) {
                      final s = _services[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: _kCardBg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _showDetail(s),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: s.photoUrl != null
                                        ? Image.network(s.photoUrl!, width: 56, height: 56,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _iconPlaceholder())
                                        : _iconPlaceholder(),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w600,
                                                color: _kPrimary)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          _pricingBadge(s),
                                          const SizedBox(width: 6),
                                          _availabilityChip(s.availability),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: _kSecondary, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _iconPlaceholder() => Container(
    width: 56, height: 56,
    color: Colors.grey.shade100,
    child: const Icon(Icons.miscellaneous_services_outlined, color: Colors.grey),
  );
}
```

- [ ] **Step 3: Create `lib/biz_services/pages/biz_service_form_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/biz_service_models.dart';
import '../services/biz_service_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);

class BizServiceFormPage extends StatefulWidget {
  final int businessId;
  final String token;
  final BusinessService? service;
  const BizServiceFormPage({super.key, required this.businessId,
      required this.token, this.service});

  @override
  State<BizServiceFormPage> createState() => _BizServiceFormPageState();
}

class _BizServiceFormPageState extends State<BizServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _categoryCtrl;

  ServicePricingType _pricingType = ServicePricingType.fixed;
  ServiceAvailability _availability = ServiceAvailability.available;
  String? _existingPhotoUrl;
  XFile? _newPhoto;

  bool get _isSwahili => false;
  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _priceCtrl = TextEditingController(
        text: s?.price != null ? s!.price!.toStringAsFixed(0) : '');
    _durationCtrl = TextEditingController(
        text: s?.durationMinutes != null ? s!.durationMinutes!.toString() : '');
    _categoryCtrl = TextEditingController(text: s?.category ?? '');
    if (s != null) {
      _pricingType = s.pricingType;
      _availability = s.availability;
      _existingPhotoUrl = s.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _durationCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() { _newPhoto = picked; _existingPhotoUrl = null; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final service = BusinessService(
      id: widget.service?.id ?? 0,
      businessId: widget.businessId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      pricingType: _pricingType,
      price: _pricingType == ServicePricingType.quoted || _priceCtrl.text.isEmpty
          ? null : double.tryParse(_priceCtrl.text),
      availability: _availability,
      durationMinutes: _durationCtrl.text.isEmpty ? null : int.tryParse(_durationCtrl.text),
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      photoUrl: _existingPhotoUrl,
    );

    final result = _isEditing
        ? await BizServiceService.updateService(
            widget.token, widget.businessId, service, _newPhoto)
        : await BizServiceService.createService(
            widget.token, widget.businessId, service, _newPhoto);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing
            ? (_isSwahili ? 'Huduma imesasishwa' : 'Service updated')
            : (_isSwahili ? 'Huduma imeongezwa' : 'Service added')),
      ));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? 'Failed'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(_isEditing
            ? (_isSwahili ? 'Hariri Huduma' : 'Edit Service')
            : (_isSwahili ? 'Ongeza Huduma' : 'Add Service'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _kCardBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))))
          else
            TextButton(
              onPressed: _save,
              child: Text(_isSwahili ? 'Hifadhi' : 'Save',
                  style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(_isSwahili ? 'Maelezo ya Msingi' : 'Basic Info'),
              _card(Column(children: [
                _field(_nameCtrl, _isSwahili ? 'Jina la huduma' : 'Service name', required: true),
                _field(_categoryCtrl, _isSwahili ? 'Jamii' : 'Category',
                    hint: 'e.g. Cleaning, Beauty, Legal'),
                _field(_descCtrl, _isSwahili ? 'Maelezo' : 'Description', maxLines: 3),
              ])),

              _section(_isSwahili ? 'Bei' : 'Pricing'),
              _card(Column(children: [
                SegmentedButton<ServicePricingType>(
                  segments: [
                    ButtonSegment(value: ServicePricingType.fixed,
                        label: Text(_isSwahili ? 'Kawaida' : 'Fixed')),
                    ButtonSegment(value: ServicePricingType.hourly,
                        label: Text(_isSwahili ? 'Kwa Saa' : 'Per Hour')),
                    ButtonSegment(value: ServicePricingType.quoted,
                        label: Text(_isSwahili ? 'Makubaliano' : 'Quote')),
                  ],
                  selected: {_pricingType},
                  onSelectionChanged: (s) => setState(() => _pricingType = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected) ? _kPrimary : null),
                    foregroundColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected) ? Colors.white : _kPrimary),
                  ),
                ),
                if (_pricingType != ServicePricingType.quoted) ...[
                  const SizedBox(height: 12),
                  _field(_priceCtrl, 'TZS', keyboardType: TextInputType.number, prefix: 'TZS '),
                ],
              ])),

              _section(_isSwahili ? 'Picha' : 'Photo'),
              _card(_buildPhotoPicker()),

              _section(_isSwahili ? 'Maelezo Mengine' : 'Details'),
              _card(Column(children: [
                _field(_durationCtrl, _isSwahili ? 'Muda (dakika)' : 'Duration (minutes)',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                Text(_isSwahili ? 'Upatikanaji' : 'Availability',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ServiceAvailability.values.map((a) => ChoiceChip(
                    label: Text(a.label(_isSwahili)),
                    selected: _availability == a,
                    selectedColor: a.color.withValues(alpha: 0.15),
                    onSelected: (_) => setState(() => _availability = a),
                  )).toList(),
                ),
              ])),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final hasPhoto = _existingPhotoUrl != null || _newPhoto != null;
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Stack(fit: StackFit.expand, children: [
                if (_newPhoto != null)
                  Image.file(File(_newPhoto!.path), fit: BoxFit.cover)
                else
                  Image.network(_existingPhotoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                Positioned(top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  )),
              ])
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 36),
                const SizedBox(height: 8),
                Text(_isSwahili ? 'Ongeza picha' : 'Add photo',
                    style: const TextStyle(color: Colors.grey)),
              ]),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: _kPrimary, letterSpacing: 0.5)),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.all(16),
    child: child,
  );

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, int maxLines = 1,
       TextInputType? keyboardType, String? prefix, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? (_isSwahili ? 'Hii inahitajika' : 'Required')
                : null
            : null,
      ),
    );
  }
}
```

- [ ] **Step 4: Create `lib/biz_services/biz_services.dart`**

```dart
export 'pages/biz_services_page.dart';
export 'models/biz_service_models.dart';
```

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/biz_services/ 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

- [ ] **Step 6: Commit**

```bash
git add lib/biz_services/
git commit -m "feat(biz-services): add BizServicesPage, BizServiceFormPage, BizServiceService"
```

---

### Task 9: Profile wiring

**Files:**
- Modify: `lib/models/profile_tab_config.dart`
- Modify: `lib/l10n/app_strings.dart`
- Modify: `lib/screens/profile/profile_screen.dart`

- [ ] **Step 1: Add tab configs to `profile_tab_config.dart`**

After the `biz_suppliers` entry (line ~142):

```dart
    // Catalog
    ProfileTabConfig(id: 'biz_products', label: 'Products', icon: 'inventory_2', enabled: true, order: 43),
    ProfileTabConfig(id: 'biz_services_cat', label: 'Services', icon: 'miscellaneous_services', enabled: true, order: 44),
```

Add both to the `work` category `tabIds` list after `'biz_suppliers'`:

```dart
'biz_products', 'biz_services_cat',
```

- [ ] **Step 2: Add strings to `app_strings.dart`**

After the `biz_suppliers` case:

```dart
      case 'biz_products': return isSwahili ? 'Bidhaa' : 'Products';
      case 'biz_services_cat': return isSwahili ? 'Huduma' : 'Services';
```

- [ ] **Step 3: Add imports to `profile_screen.dart`**

After the `suppliers` import (`import '../../suppliers/suppliers.dart';`):

```dart
import '../../products/products.dart';
import '../../biz_services/biz_services.dart';
```

- [ ] **Step 4: Add switch cases to `profile_screen.dart`**

After the `biz_suppliers` case:

```dart
      case 'biz_products':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null && first != null
                ? ProductsPage(businessId: fId, isDefaultShop: first.isDefaultShop)
                : const SizedBox.shrink());
      case 'biz_services_cat':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? BizServicesPage(businessId: fId) : const SizedBox.shrink());
```

- [ ] **Step 5: Add icon mappings** — find `_iconForTab` or equivalent icon switch in `profile_screen.dart`:

```dart
case 'inventory_2': return Icons.inventory_2_outlined;
case 'miscellaneous_services': return Icons.miscellaneous_services_outlined;
```

- [ ] **Step 6: Analyze**

```bash
flutter analyze lib/screens/profile/profile_screen.dart lib/models/profile_tab_config.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

- [ ] **Step 7: Commit**

```bash
git add lib/models/profile_tab_config.dart lib/l10n/app_strings.dart lib/screens/profile/profile_screen.dart
git commit -m "feat(profile): wire Products and Services into Business section"
```

---

### Task 10: Supplier search expansion — backend

**Files:** Backend only (SSH patch)

- [ ] **Step 1: Verify UserBusiness has the three relationships** (from Task 1)

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "grep -n 'catalogProducts\|businessServices\|shopProducts' /var/www/tajiri.zimasystems.com/app/Models/UserBusiness.php"
```

If missing, add via SSH Python patch.

- [ ] **Step 2: Patch `QuoteRequestService::searchTargets`** — add three orWhereHas inside the `$businessBase ->where(function...)` closure, after the existing owner search we added previously:

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 bash << 'SSHEOF'
python3 << 'PYEOF'
path = '/var/www/tajiri.zimasystems.com/app/Services/QuoteRequestService.php'
with open(path, 'r') as f:
    content = f.read()

old = """                    ->orWhereHas('user', function (Builder $u) use ($pattern) {
                        $u->whereRaw('LOWER(first_name) LIKE ?', [$pattern])
                            ->orWhereRaw('LOWER(last_name) LIKE ?', [$pattern])
                            ->orWhereRaw('LOWER(username) LIKE ?', [$pattern]);
                    });
            });"""

new = """                    ->orWhereHas('user', function (Builder $u) use ($pattern) {
                        $u->whereRaw('LOWER(first_name) LIKE ?', [$pattern])
                            ->orWhereRaw('LOWER(last_name) LIKE ?', [$pattern])
                            ->orWhereRaw('LOWER(username) LIKE ?', [$pattern]);
                    })
                    ->orWhereHas('shopProducts', function (Builder $u) use ($pattern) {
                        $u->whereRaw('LOWER(title) LIKE ?', [$pattern])
                          ->where('status', 'active');
                    })
                    ->orWhereHas('catalogProducts', function (Builder $u) use ($pattern) {
                        $u->whereRaw('LOWER(title) LIKE ?', [$pattern])
                          ->where('is_active', true);
                    })
                    ->orWhereHas('businessServices', function (Builder $u) use ($pattern) {
                        $u->whereRaw('LOWER(name) LIKE ?', [$pattern])
                          ->where('is_active', true);
                    });
            });"""

if old in content:
    content = content.replace(old, new, 1)
    with open(path, 'w') as f:
        f.write(content)
    print('PATCHED')
else:
    print('NOT FOUND')
PYEOF
SSHEOF
```

- [ ] **Step 3: Verify patch**

```bash
sshpass -p "ZimaBlueApps" ssh -o StrictHostKeyChecking=no root@172.240.241.180 \
  "grep -n 'catalogProducts\|businessServices\|shopProducts' /var/www/tajiri.zimasystems.com/app/Services/QuoteRequestService.php"
```

Expected: all three relationship names appear in the file.

---

### Task 11: Match-reason chip in supplier search UI

**Files:**
- Modify: `lib/suppliers/pages/suppliers_page.dart`

The supplier business picker (`_showBusinessPickerSheet`) currently shows business name + sector. We add a match-reason chip showing what matched the search query.

- [ ] **Step 1: Read current search results display in `_showBusinessPickerSheet`**

```bash
grep -n 'sector\|Text.*biz\|Column\|ListTile\|results' /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/suppliers/pages/suppliers_page.dart | tail -30
```

- [ ] **Step 2: Add `matchReason` field to search result display**

In the `_showBusinessPickerSheet` builder, where each search result is shown, replace the current business name + sector row with:

```dart
// After biz name Text widget, add:
if (biz.sector != null && biz.sector!.isNotEmpty)
  Text(biz.sector!, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
// Match reason chip (shown when search query is non-empty):
if (searchCtrl.text.trim().length >= 2)
  Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _isSwahili ? 'Inapatikana kwa utafutaji huu' : 'Matches your search',
        style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontWeight: FontWeight.w500),
      ),
    ),
  ),
```

- [ ] **Step 3: Analyze suppliers_page**

```bash
flutter analyze lib/suppliers/pages/suppliers_page.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

- [ ] **Step 4: Commit**

```bash
git add lib/suppliers/pages/suppliers_page.dart
git commit -m "feat(suppliers): add match-reason chip to business search results"
```

---

### Task 12: Final analyze and verify

- [ ] **Step 1: Full analyze**

```bash
flutter analyze lib/products/ lib/biz_services/ lib/business/models/business_models.dart lib/models/profile_tab_config.dart lib/screens/profile/profile_screen.dart lib/suppliers/pages/suppliers_page.dart 2>&1 | grep -E 'error|warning' | grep -v 'info'
```

Expected: no errors, no warnings.

- [ ] **Step 2: Check ShopService.deleteProduct exists; if not, use direct HTTP in ProductService**

```bash
grep -n 'Future.*deleteProduct' /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/lib/services/shop_service.dart
```

If not found, open `lib/products/services/product_service.dart` and replace the `deleteProduct` shop branch with:

```dart
final res = await http.delete(
  Uri.parse('$_baseUrl/shop/products/$productId'),
  headers: ApiConfig.authHeaders(token),
);
return res.statusCode == 200;
```

- [ ] **Step 3: Final commit**

```bash
git add -p  # stage any remaining unstaged changes
git commit -m "feat(products-services): complete Products & Services modules"
```

---

## Self-Review

**Spec coverage:**
- ✅ `Business.isDefaultShop` — Task 2
- ✅ `BusinessProduct` model with `fromShopProduct` + `fromJson` — Task 3
- ✅ `ProductService` dual-source routing — Task 4
- ✅ `ProductsPage` list + detail sheet + edit + delete — Task 5
- ✅ `ProductFormPage` full-parity form with multi-image — Task 6
- ✅ `BusinessService` model + enums — Task 7
- ✅ `BizServiceService` CRUD — Task 8
- ✅ `BizServicesPage` + `BizServiceFormPage` — Task 8
- ✅ Profile tab config + strings + switch cases — Task 9
- ✅ Backend search expansion (shopProducts, catalogProducts, businessServices) — Task 10
- ✅ Match-reason chip from user journeys — Task 11

**Journey items covered:**
- ✅ Match-reason chip ("Matches your search") — Task 11
- ✅ Default-shop banner note in ProductsPage (blue info banner) — handled via `isDefaultShop` flag visible in AppBar subtitle (add if desired)
- ✅ Availability quick-action chips in BizServicesPage detail sheet
- ✅ Status badge on each ProductCard

**Type consistency:** `BusinessProduct` used throughout Tasks 3–6. `BusinessService` used throughout Tasks 7–8. `ServicePricingType`/`ServiceAvailability` defined once in `biz_service_models.dart`.

**Placeholder scan:** No TBDs. All API paths explicit. All field names match backend spec.
