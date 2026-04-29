# Products & Services Modules Design

## Goal

Add Products and Services management to the Business section of a user's profile. Products are full shop-parity catalog items (and the unified management surface for default-shop products). Services are a standard offering catalog. Both feed into supplier search so businesses are discoverable by what they sell or offer.

## Architecture

Three independent pieces built and deployed together:

1. **Products module** (`/lib/products/`) — full CRUD. For default-shop businesses, routes through the existing Shop API (`/products` seller endpoints). For non-shop businesses, uses new `/business/{id}/catalog/products` endpoints backed by a new `user_business_products` table.

2. **Business Services module** (`/lib/biz_services/`) — full CRUD via new `/business/{id}/services` endpoints backed by a new `user_business_services` table. (`/lib/services/` is taken by platform-level services.)

3. **Supplier search expansion** — backend `searchTargets` gains three additional `orWhereHas` clauses on the `$businessBase` query: shop products, catalog products, and business services.

Navigation: both modules appear as separate entries in the Business section menu in `profile_screen.dart`, matching the `biz_suppliers` pattern.

## Tech Stack

Flutter/Dart, `http` package, `image_picker` for photo upload, `Dio` for multi-image upload (chunked). Backend: Laravel, PostgreSQL. Two new tables, new controller methods on `MyBusinessController`.

---

## Data Models

### Business model update

`Business` (`lib/business/models/business_models.dart`) gains one new field:

```dart
final bool isDefaultShop;
```

Parsed in `fromJson` as `_parseBool(json['is_default_shop'])`. Backend already returns this column from the `user_businesses` table migration `add_is_default_shop_to_user_businesses`.

---

### BusinessProduct (`lib/products/models/product_models.dart`)

Unified model covering both shop products and catalog products. Maps from either source.

```dart
class BusinessProduct {
  final int id;
  final int businessId;
  final bool isShopProduct;       // true = backed by Shop API
  final String title;
  final String? description;
  final String? slug;             // shop only, null for catalog
  final ProductType type;         // physical / digital / service
  final ProductStatus status;     // active / inactive / draft
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
}
```

`ProductType`, `ProductStatus`, `ProductCondition` are re-exported from `lib/models/shop_models.dart` — not duplicated.

`fromShopProduct(Product p, int businessId)` factory — maps existing `Product` model.
`fromJson(Map<String, dynamic> json)` factory — maps catalog API response.

---

### BusinessService (`lib/biz_services/models/biz_service_models.dart`)

```dart
enum ServicePricingType { fixed, hourly, quoted }
enum ServiceAvailability { available, unavailable, byRequest }

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
}
```

---

## Backend

### New tables (via `ask_backend.sh`)

**`user_business_products`**
```
id                  bigserial primary key
user_business_id    bigint not null references user_businesses(id) on delete cascade
title               varchar(255) not null
description         text
type                varchar(50) default 'physical'
status              varchar(50) default 'active'
price               numeric(15,2) not null default 0
compare_at_price    numeric(15,2)
currency            varchar(10) default 'TZS'
stock_quantity      int default 0
images              jsonb default '[]'
thumbnail_path      text
category_id         bigint
tags                jsonb default '[]'
condition           varchar(50) default 'brand_new'
location_name       varchar(255)
latitude            numeric(10,7)
longitude           numeric(10,7)
allow_pickup        boolean default true
allow_delivery      boolean default false
allow_shipping      boolean default false
delivery_fee        numeric(15,2)
delivery_notes      text
pickup_address      text
download_url        text
download_limit      int
duration_minutes    int
service_location    text
is_active           boolean default true
created_at          timestamp
updated_at          timestamp
```

**`user_business_services`**
```
id                  bigserial primary key
user_business_id    bigint not null references user_businesses(id) on delete cascade
name                varchar(255) not null
description         text
pricing_type        varchar(20) not null default 'fixed'  -- fixed/hourly/quoted
price               numeric(15,2)
currency            varchar(10) default 'TZS'
photo_url           text
duration_minutes    int
availability        varchar(20) default 'available'  -- available/unavailable/by_request
category            varchar(100)
is_active           boolean default true
created_at          timestamp
updated_at          timestamp
```

### New endpoints (added to `MyBusinessController`)

**Catalog products** (non-shop businesses only):
```
GET    /business/{id}/catalog/products
POST   /business/{id}/catalog/products
PUT    /business/{id}/catalog/products/{pid}
DELETE /business/{id}/catalog/products/{pid}
```

**Business services**:
```
GET    /business/{id}/services
POST   /business/{id}/services
PUT    /business/{id}/services/{sid}
DELETE /business/{id}/services/{sid}
```

All endpoints require auth token. `POST`/`PUT` accept `multipart/form-data` for image upload.

### UserBusiness model relationships (for search)

Three new relationships added to `UserBusiness` Eloquent model:

```php
public function shopProducts()
{
    // Shop products belong to the seller (user_id) not directly to the business.
    // Link via user_id of the business owner.
    return $this->hasMany(\App\Models\ShopProduct::class, 'user_id', 'user_id');
}

public function catalogProducts()
{
    return $this->hasMany(\App\Models\UserBusinessProduct::class, 'user_business_id');
}

public function businessServices()
{
    return $this->hasMany(\App\Models\UserBusinessService::class, 'user_business_id');
}
```

### Supplier search expansion (`QuoteRequestService::searchTargets`)

Add to the `$businessBase` `->where(function ...)` closure:

```php
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
})
```

---

## Frontend File Structure

```
lib/products/
  models/
    product_models.dart        # BusinessProduct, re-exports ProductType/Status/Condition
  services/
    product_service.dart       # routes to Shop API or catalog API based on isDefaultShop
  pages/
    products_page.dart         # list with search/filter, FAB to add
    product_form_page.dart     # add/edit full-parity form
  products.dart                # barrel: exports ProductsPage

lib/biz_services/
  models/
    biz_service_models.dart    # BusinessService, enums
  services/
    biz_service_service.dart   # CRUD via /business/{id}/services
  pages/
    biz_services_page.dart     # list with FAB
    biz_service_form_page.dart # add/edit form
  biz_services.dart            # barrel: exports BizServicesPage
```

---

## ProductService routing logic

```dart
class ProductService {
  static Future<List<BusinessProduct>> getProducts(
      String token, int businessId, bool isDefaultShop) async {
    if (isDefaultShop) {
      // use existing GET /seller/products or /products?seller_id=...
      final result = await ShopService.getSellerProducts(token);
      return result.products
          .map((p) => BusinessProduct.fromShopProduct(p, businessId))
          .toList();
    } else {
      final res = await http.get(
        Uri.parse('$_baseUrl/business/$businessId/catalog/products'),
        headers: ApiConfig.authHeaders(token),
      );
      // parse and return BusinessProduct list
    }
  }

  static Future<bool> saveProduct(
      String token, int businessId, bool isDefaultShop,
      BusinessProduct product, List<XFile> newImages) async {
    if (isDefaultShop) {
      // use existing POST /products or PUT /products/{id}
    } else {
      // POST/PUT /business/{id}/catalog/products
    }
  }
}
```

---

## UX Details

### ProductsPage

- `AppBar` title: "Products" / "Bidhaa"
- `RefreshIndicator` wrapping `ListView`
- Empty state: store icon + "No products yet" + FAB hint
- Each item: thumbnail, title, price, status badge (active/draft/out of stock)
- Tap → detail `BottomSheet` with Edit / Delete / Toggle status actions
- FAB → `ProductFormPage`

### ProductFormPage

- Scrollable `SingleChildScrollView` with sections: Basic Info, Pricing, Images, Delivery, Stock
- Multi-image picker (up to 10 images) via `image_picker`, uploaded via `Dio`
- Price field + Compare At Price field
- `DropdownButtonFormField` for type (Physical / Digital / Service), condition, status
- Stock quantity field (hidden when type = digital or service)
- Delivery section: pickup/delivery/shipping toggles, fee, address fields
- Save via `ProductService.saveProduct` — shows loading state on button

### BizServicesPage

- Same pattern as `ProductsPage` but simpler card: photo thumbnail, name, pricing badge, availability chip
- Tap → detail sheet with Edit / Delete / Toggle availability

### BizServiceFormPage

- Fields: Name, Category, Description, Photo (single), Pricing Type (Fixed/Hourly/Quoted), Price (hidden when Quoted), Duration (optional), Availability

### Profile wiring (`profile_screen.dart`)

Two new cases in the tab-content switch, following the `biz_suppliers` pattern:

```dart
case 'biz_products':
  return _buildBusinessPage((fId, uid) =>
      fId != null && first != null
          ? ProductsPage(businessId: fId, isDefaultShop: first.isDefaultShop)
          : const SizedBox.shrink());

case 'biz_services':
  return _buildBusinessPage((fId, uid) =>
      fId != null
          ? BizServicesPage(businessId: fId)
          : const SizedBox.shrink());
```

The `Business` section menu entries for both are added to `biz_tab_wrapper.dart` (or wherever `biz_suppliers` is listed).

---

## Bilingual Strings

All user-facing text uses the existing `AppStrings` pattern (`isSwahili ? 'sw' : 'en'`). New strings needed:

| Key context | English | Swahili |
|---|---|---|
| Products page title | Products | Bidhaa |
| Services page title | Services | Huduma |
| No products | No products yet | Bado kuna bidhaa |
| No services | No services yet | Bado kuna huduma |
| Add product | Add product | Ongeza bidhaa |
| Add service | Add service | Ongeza huduma |
| Product saved | Product saved | Bidhaa imehifadhiwa |
| Service saved | Service saved | Huduma imehifadhiwa |
| Pricing type fixed | Fixed | Bei ya kawaida |
| Pricing type hourly | Per hour | Kwa saa |
| Pricing type quoted | Quote only | Bei ya makubaliano |
| Availability available | Available | Inapatikana |
| Availability unavailable | Unavailable | Haipatikani |
| Availability by request | By request | Kwa ombi |

---

## Error Handling

- All service calls wrapped in `try/catch`; errors show `SnackBar` with red background
- `mounted` checked before any `setState` after `async`
- Image upload failures shown inline (per-image error, not whole-form failure)
- 401 responses → show "Session expired, please log in again"
- Empty `businessId` guard at top of both pages (same pattern as `SuppliersPage`)

---

## Self-Review

**Spec coverage:** All agreed requirements covered — Products CRUD (full parity), Services CRUD (standard), dual-source routing, profile integration, supplier search expansion, bilingual strings, error handling.

**Placeholder scan:** No TBDs or TODOs. All field names and endpoint paths are explicit.

**Type consistency:** `BusinessProduct` is used throughout. `ProductType`/`ProductStatus`/`ProductCondition` are imported from `shop_models.dart`, not redefined. `BusinessService` is distinct from `lib/services/` platform services.

**Scope check:** Three coherent pieces in one spec — they share the backend deployment (one `ask_backend.sh` call covers all table + endpoint creation) and the search patch. Splitting would require two half-deployed states. Single plan is appropriate.

**Ambiguity resolved:** Default-shop detection uses `Business.isDefaultShop` (added to model). Non-default-shop businesses get catalog endpoints. Search covers all three product/service sources.
