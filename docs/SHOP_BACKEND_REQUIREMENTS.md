# TAJIRI Shop Backend Requirements (Laravel)

## Overview

This document outlines the Laravel backend requirements for the TAJIRI C2C (Consumer-to-Consumer) marketplace. Users can sell products/services from their profiles and buy from others. Payments are processed via TAJIRI Wallet.

---

## Database Schema

### 1. Products Table

```php
Schema::create('products', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade'); // seller
    $table->string('title');
    $table->string('slug')->unique();
    $table->text('description');
    $table->enum('type', ['physical', 'digital', 'service'])->default('physical');
    $table->enum('status', ['draft', 'active', 'sold_out', 'archived'])->default('draft');
    $table->decimal('price', 15, 2);
    $table->decimal('compare_at_price', 15, 2)->nullable(); // original price for discounts
    $table->string('currency', 3)->default('TZS');
    $table->integer('stock_quantity')->default(0);
    $table->json('images')->nullable(); // array of image URLs
    $table->string('thumbnail_url')->nullable();
    $table->foreignId('category_id')->nullable()->constrained('product_categories');
    $table->json('tags')->nullable();
    $table->enum('condition', ['new', 'used', 'refurbished'])->nullable();

    // Location (for pickup)
    $table->string('location_name')->nullable();
    $table->decimal('latitude', 10, 8)->nullable();
    $table->decimal('longitude', 11, 8)->nullable();

    // Delivery options
    $table->boolean('allow_pickup')->default(true);
    $table->boolean('allow_delivery')->default(false);
    $table->boolean('allow_shipping')->default(false);
    $table->decimal('delivery_fee', 15, 2)->nullable();
    $table->text('delivery_notes')->nullable();

    // Digital product
    $table->string('download_url')->nullable();

    // Service
    $table->integer('duration_minutes')->nullable();

    // Stats (denormalized for performance)
    $table->unsignedInteger('views_count')->default(0);
    $table->unsignedInteger('favorites_count')->default(0);
    $table->unsignedInteger('orders_count')->default(0);
    $table->decimal('rating', 3, 2)->default(0);
    $table->unsignedInteger('reviews_count')->default(0);

    $table->timestamps();
    $table->softDeletes();

    // Indexes
    $table->index(['user_id', 'status']);
    $table->index(['category_id', 'status']);
    $table->index(['status', 'created_at']);
    $table->index(['latitude', 'longitude']);
    $table->fullText(['title', 'description']);
});
```

### 2. Product Categories Table

```php
Schema::create('product_categories', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('name_sw')->nullable(); // Swahili name
    $table->string('slug')->unique();
    $table->string('icon')->nullable(); // icon name or URL
    $table->string('image_url')->nullable();
    $table->foreignId('parent_id')->nullable()->constrained('product_categories')->onDelete('set null');
    $table->integer('sort_order')->default(0);
    $table->boolean('is_active')->default(true);
    $table->unsignedInteger('product_count')->default(0); // denormalized
    $table->timestamps();

    $table->index(['parent_id', 'is_active', 'sort_order']);
});
```

### 3. Product Favorites Table

```php
Schema::create('product_favorites', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->foreignId('product_id')->constrained()->onDelete('cascade');
    $table->timestamps();

    $table->unique(['user_id', 'product_id']);
    $table->index(['user_id', 'created_at']);
});
```

### 4. Shopping Carts Table

```php
Schema::create('shopping_carts', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->timestamps();

    $table->unique('user_id');
});

Schema::create('cart_items', function (Blueprint $table) {
    $table->id();
    $table->foreignId('cart_id')->constrained('shopping_carts')->onDelete('cascade');
    $table->foreignId('product_id')->constrained()->onDelete('cascade');
    $table->integer('quantity')->default(1);
    $table->timestamps();

    $table->unique(['cart_id', 'product_id']);
});
```

### 5. Orders Table

```php
Schema::create('orders', function (Blueprint $table) {
    $table->id();
    $table->string('order_number')->unique();
    $table->foreignId('buyer_id')->constrained('users')->onDelete('cascade');
    $table->foreignId('seller_id')->constrained('users')->onDelete('cascade');
    $table->foreignId('product_id')->constrained()->onDelete('cascade');
    $table->integer('quantity');
    $table->decimal('unit_price', 15, 2);
    $table->decimal('subtotal', 15, 2);
    $table->decimal('delivery_fee', 15, 2)->default(0);
    $table->decimal('total_amount', 15, 2);
    $table->string('currency', 3)->default('TZS');

    $table->enum('status', [
        'pending',      // awaiting seller confirmation
        'confirmed',    // seller confirmed
        'processing',   // being prepared
        'shipped',      // in transit
        'delivered',    // received by buyer
        'completed',    // buyer confirmed receipt
        'cancelled',    // cancelled
        'refunded'      // money returned
    ])->default('pending');

    $table->enum('delivery_method', ['pickup', 'delivery', 'shipping', 'digital'])->default('pickup');
    $table->text('delivery_address')->nullable();
    $table->text('delivery_notes')->nullable();
    $table->string('tracking_number')->nullable();
    $table->timestamp('estimated_delivery')->nullable();

    // Payment
    $table->foreignId('wallet_transaction_id')->nullable(); // link to wallet transaction
    $table->enum('payment_status', ['pending', 'paid', 'refunded'])->default('pending');
    $table->timestamp('paid_at')->nullable();

    // Cancellation
    $table->text('cancellation_reason')->nullable();
    $table->foreignId('cancelled_by')->nullable()->constrained('users');
    $table->timestamp('cancelled_at')->nullable();

    $table->timestamps();
    $table->softDeletes();

    // Indexes
    $table->index(['buyer_id', 'status', 'created_at']);
    $table->index(['seller_id', 'status', 'created_at']);
    $table->index(['status', 'created_at']);
});
```

### 6. Order Status History Table

```php
Schema::create('order_status_history', function (Blueprint $table) {
    $table->id();
    $table->foreignId('order_id')->constrained()->onDelete('cascade');
    $table->string('status');
    $table->text('notes')->nullable();
    $table->foreignId('changed_by')->nullable()->constrained('users');
    $table->timestamps();

    $table->index(['order_id', 'created_at']);
});
```

### 7. Product Reviews Table

```php
Schema::create('product_reviews', function (Blueprint $table) {
    $table->id();
    $table->foreignId('product_id')->constrained()->onDelete('cascade');
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->foreignId('order_id')->nullable()->constrained()->onDelete('set null');
    $table->tinyInteger('rating'); // 1-5
    $table->text('comment')->nullable();
    $table->json('images')->nullable();
    $table->boolean('is_verified_purchase')->default(false);
    $table->unsignedInteger('helpful_count')->default(0);
    $table->timestamps();
    $table->softDeletes();

    $table->unique(['product_id', 'user_id']); // one review per user per product
    $table->index(['product_id', 'rating', 'created_at']);
});
```

### 8. Review Helpful Votes Table

```php
Schema::create('review_helpful_votes', function (Blueprint $table) {
    $table->id();
    $table->foreignId('review_id')->constrained('product_reviews')->onDelete('cascade');
    $table->foreignId('user_id')->constrained()->onDelete('cascade');
    $table->timestamps();

    $table->unique(['review_id', 'user_id']);
});
```

---

## API Endpoints

### Base URL: `/api/v1/shop`

### Products

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/products` | List products with filters | Optional |
| GET | `/products/featured` | Get featured products | Optional |
| GET | `/products/trending` | Get trending products | Optional |
| GET | `/products/recommended` | Get personalized recommendations | Required |
| GET | `/products/nearby` | Get products near location | Optional |
| GET | `/products/{id}` | Get single product | Optional |
| POST | `/products` | Create new product | Required |
| PUT | `/products/{id}` | Update product | Required (owner) |
| DELETE | `/products/{id}` | Delete product | Required (owner) |
| POST | `/products/{id}/view` | Increment view count | Optional |
| GET | `/sellers/{userId}/products` | Get seller's products | Optional |

### Categories

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/categories` | List all categories | No |
| GET | `/categories/{id}` | Get category with children | No |
| GET | `/categories/{id}/products` | Get products in category | Optional |

### Favorites

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/favorites` | Get user's favorites | Required |
| POST | `/products/{id}/favorite` | Toggle favorite | Required |
| DELETE | `/products/{id}/favorite` | Remove from favorites | Required |

### Cart

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/cart` | Get user's cart | Required |
| POST | `/cart/items` | Add item to cart | Required |
| PUT | `/cart/items/{productId}` | Update item quantity | Required |
| DELETE | `/cart/items/{productId}` | Remove item from cart | Required |
| DELETE | `/cart` | Clear entire cart | Required |

### Orders

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/orders` | Create new order | Required |
| GET | `/orders/buyer` | Get buyer's orders | Required |
| GET | `/orders/seller` | Get seller's orders | Required |
| GET | `/orders/{id}` | Get order details | Required (buyer/seller) |
| PUT | `/orders/{id}/status` | Update order status | Required (seller) |
| POST | `/orders/{id}/cancel` | Cancel order | Required (buyer/seller) |

### Reviews

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/products/{id}/reviews` | Get product reviews | Optional |
| POST | `/products/{id}/reviews` | Create review | Required |
| PUT | `/reviews/{id}` | Update review | Required (owner) |
| DELETE | `/reviews/{id}` | Delete review | Required (owner) |
| POST | `/reviews/{id}/helpful` | Mark review as helpful | Required |

### Seller Dashboard

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/seller/stats` | Get seller statistics | Required |
| GET | `/seller/products` | Get own products | Required |
| GET | `/seller/orders` | Get received orders | Required |

---

## Request/Response Specifications

### GET /products

**Query Parameters:**
```
page: int (default: 1)
per_page: int (default: 20, max: 50)
category_id: int
search: string
sort_by: string (newest|oldest|price_low|price_high|popular|rating)
min_price: decimal
max_price: decimal
condition: string (new|used|refurbished)
type: string (physical|digital|service)
status: string (active) - for public, sellers can filter their own
near_lat: decimal
near_lng: decimal
radius_km: int (default: 10)
seller_id: int
```

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 1,
        "title": "iPhone 14 Pro",
        "slug": "iphone-14-pro-1234",
        "description": "Brand new iPhone...",
        "type": "physical",
        "status": "active",
        "price": 2500000,
        "compare_at_price": 3000000,
        "currency": "TZS",
        "stock_quantity": 5,
        "images": ["url1", "url2"],
        "thumbnail_url": "url1",
        "category_id": 3,
        "category": {
          "id": 3,
          "name": "Electronics",
          "slug": "electronics"
        },
        "tags": ["phone", "apple"],
        "condition": "new",
        "location_name": "Dar es Salaam",
        "latitude": -6.7924,
        "longitude": 39.2083,
        "allow_pickup": true,
        "allow_delivery": true,
        "allow_shipping": false,
        "delivery_fee": 5000,
        "views_count": 150,
        "favorites_count": 23,
        "orders_count": 8,
        "rating": 4.5,
        "reviews_count": 12,
        "seller": {
          "id": 42,
          "name": "John Doe",
          "username": "johndoe",
          "avatar_url": "url",
          "rating": 4.8,
          "products_count": 25,
          "is_verified": true
        },
        "is_favorited": false,
        "created_at": "2024-01-15T10:30:00Z",
        "updated_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 150,
      "total_pages": 8,
      "has_more": true
    }
  }
}
```

### POST /products

**Request Body:**
```json
{
  "title": "iPhone 14 Pro",
  "description": "Brand new iPhone 14 Pro, 256GB...",
  "type": "physical",
  "price": 2500000,
  "compare_at_price": 3000000,
  "stock_quantity": 5,
  "category_id": 3,
  "tags": ["phone", "apple", "iphone"],
  "condition": "new",
  "location_name": "Dar es Salaam, Masaki",
  "latitude": -6.7924,
  "longitude": 39.2083,
  "allow_pickup": true,
  "allow_delivery": true,
  "allow_shipping": false,
  "delivery_fee": 5000,
  "delivery_notes": "Available for delivery within Dar es Salaam",
  "images": ["base64_or_url_1", "base64_or_url_2"],
  "status": "active"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "product": { /* full product object */ }
  }
}
```

### GET /cart

**Response:**
```json
{
  "success": true,
  "data": {
    "cart": {
      "id": 1,
      "items": [
        {
          "product_id": 1,
          "quantity": 2,
          "product": {
            "id": 1,
            "title": "iPhone 14 Pro",
            "price": 2500000,
            "thumbnail_url": "url",
            "stock_quantity": 5,
            "status": "active",
            "seller": {
              "id": 42,
              "name": "John Doe"
            }
          },
          "line_total": 5000000
        }
      ],
      "subtotal": 5000000,
      "delivery_total": 5000,
      "grand_total": 5005000,
      "item_count": 2,
      "currency": "TZS"
    }
  }
}
```

### POST /orders

**Request Body:**
```json
{
  "product_id": 1,
  "quantity": 2,
  "delivery_method": "delivery",
  "delivery_address": "123 Main St, Masaki, Dar es Salaam",
  "delivery_notes": "Call before delivery"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order placed successfully",
  "data": {
    "order": {
      "id": 1,
      "order_number": "ORD-2024-001234",
      "buyer_id": 10,
      "seller_id": 42,
      "product_id": 1,
      "quantity": 2,
      "unit_price": 2500000,
      "subtotal": 5000000,
      "delivery_fee": 5000,
      "total_amount": 5005000,
      "currency": "TZS",
      "status": "pending",
      "delivery_method": "delivery",
      "delivery_address": "123 Main St, Masaki, Dar es Salaam",
      "delivery_notes": "Call before delivery",
      "payment_status": "paid",
      "paid_at": "2024-01-15T10:30:00Z",
      "product": { /* product snapshot */ },
      "buyer": { /* buyer info */ },
      "seller": { /* seller info */ },
      "created_at": "2024-01-15T10:30:00Z"
    }
  }
}
```

### GET /seller/stats

**Response:**
```json
{
  "success": true,
  "data": {
    "stats": {
      "products": {
        "total": 25,
        "active": 20,
        "draft": 3,
        "sold_out": 2
      },
      "orders": {
        "total": 150,
        "pending": 5,
        "processing": 3,
        "completed": 140,
        "cancelled": 2
      },
      "revenue": {
        "total": 15000000,
        "this_month": 2500000,
        "last_month": 3000000,
        "currency": "TZS"
      },
      "rating": {
        "average": 4.8,
        "total_reviews": 95,
        "distribution": {
          "5": 70,
          "4": 15,
          "3": 7,
          "2": 2,
          "1": 1
        }
      },
      "views": {
        "total": 5000,
        "this_month": 800
      }
    }
  }
}
```

---

## Laravel Implementation

### Models

```
app/Models/Shop/
├── Product.php
├── ProductCategory.php
├── ProductFavorite.php
├── ShoppingCart.php
├── CartItem.php
├── Order.php
├── OrderStatusHistory.php
├── ProductReview.php
└── ReviewHelpfulVote.php
```

### Controllers

```
app/Http/Controllers/Api/V1/Shop/
├── ProductController.php
├── CategoryController.php
├── CartController.php
├── OrderController.php
├── ReviewController.php
├── FavoriteController.php
└── SellerDashboardController.php
```

### Services

```
app/Services/Shop/
├── ProductService.php
├── CartService.php
├── OrderService.php
├── ReviewService.php
├── RecommendationService.php
└── SellerStatsService.php
```

### Form Requests

```
app/Http/Requests/Shop/
├── CreateProductRequest.php
├── UpdateProductRequest.php
├── AddToCartRequest.php
├── CreateOrderRequest.php
├── UpdateOrderStatusRequest.php
└── CreateReviewRequest.php
```

### Resources (API Transformers)

```
app/Http/Resources/Shop/
├── ProductResource.php
├── ProductCollection.php
├── CategoryResource.php
├── CartResource.php
├── OrderResource.php
├── ReviewResource.php
└── SellerStatsResource.php
```

### Policies

```
app/Policies/Shop/
├── ProductPolicy.php
├── OrderPolicy.php
└── ReviewPolicy.php
```

---

## Business Logic Rules

### Product Rules

1. **Stock Management:**
   - Decrement stock when order is confirmed (not when placed)
   - Auto-set status to `sold_out` when stock reaches 0
   - Prevent purchase if stock < requested quantity

2. **Pricing:**
   - `compare_at_price` must be > `price` if set
   - All prices stored in smallest unit (cents/senti) or as decimal

3. **Images:**
   - Maximum 10 images per product
   - First image is auto-set as thumbnail
   - Support base64 upload or URL reference

4. **Slug Generation:**
   - Auto-generate from title + random suffix
   - Must be unique

### Cart Rules

1. **Cart Lifecycle:**
   - Auto-create cart on first add
   - Cart persists until checkout or manual clear
   - Items from unavailable products are flagged

2. **Quantity Validation:**
   - Cannot exceed available stock
   - Minimum quantity is 1

3. **Price Calculation:**
   - Always use current product price (not cached)
   - Recalculate totals on every cart fetch

### Order Rules

1. **Order Creation:**
   - Validate stock availability
   - Deduct from TAJIRI Wallet immediately
   - Generate unique order number: `ORD-{YEAR}-{6-digit-sequence}`

2. **Status Transitions:**
   ```
   pending → confirmed → processing → shipped → delivered → completed
                ↓              ↓           ↓          ↓
            cancelled      cancelled   cancelled   refunded
   ```

3. **Cancellation:**
   - Buyer can cancel if status is `pending`
   - Seller can cancel if status is `pending` or `confirmed`
   - Auto-refund to buyer's wallet on cancellation

4. **Completion:**
   - Buyer must confirm delivery within 7 days
   - Auto-complete after 7 days if no dispute

### Review Rules

1. **Eligibility:**
   - User must have completed order for the product
   - One review per user per product
   - Can update within 30 days

2. **Rating Calculation:**
   - Product rating = average of all review ratings
   - Update on review create/update/delete

### Payment Integration (TAJIRI Wallet)

1. **Purchase Flow:**
   ```
   1. User initiates checkout
   2. Verify wallet balance >= order total
   3. Create pending order
   4. Deduct from buyer's wallet
   5. Create wallet transaction (type: 'shop_purchase')
   6. Link transaction to order
   7. Update order payment_status to 'paid'
   8. Notify seller
   ```

2. **Refund Flow:**
   ```
   1. Order cancelled/refunded
   2. Credit buyer's wallet
   3. Create wallet transaction (type: 'shop_refund')
   4. Update order payment_status to 'refunded'
   5. Notify buyer
   ```

---

## Events & Notifications

### Events to Fire

```php
// Products
ProductCreated::class
ProductUpdated::class
ProductDeleted::class
ProductSoldOut::class

// Orders
OrderPlaced::class
OrderConfirmed::class
OrderShipped::class
OrderDelivered::class
OrderCompleted::class
OrderCancelled::class

// Reviews
ReviewCreated::class
```

### Notifications to Send

| Event | Recipient | Channel |
|-------|-----------|---------|
| Order placed | Seller | Push, In-app |
| Order confirmed | Buyer | Push, In-app |
| Order shipped | Buyer | Push, In-app |
| Order delivered | Seller | Push, In-app |
| Order cancelled | Both | Push, In-app |
| New review | Seller | In-app |
| Product sold out | Seller | Push, In-app |

---

## Search & Filtering

### Elasticsearch/Algolia Integration (Optional)

For better search performance, index products with:
- title (weighted: 3)
- description (weighted: 1)
- tags (weighted: 2)
- category name (weighted: 2)
- seller name (weighted: 1)

### Database Full-Text Search (Default)

```php
// MySQL full-text search
Product::whereRaw(
    "MATCH(title, description) AGAINST(? IN BOOLEAN MODE)",
    [$searchTerm]
)->get();
```

### Geo-Location Search

```php
// Haversine formula for nearby products
$products = Product::selectRaw("
    *,
    (6371 * acos(cos(radians(?))
    * cos(radians(latitude))
    * cos(radians(longitude) - radians(?))
    + sin(radians(?))
    * sin(radians(latitude)))) AS distance
", [$lat, $lng, $lat])
->having('distance', '<', $radiusKm)
->orderBy('distance')
->get();
```

---

## Caching Strategy

### Cache Keys

```php
// Categories (rarely change)
"shop:categories:all" => 24 hours
"shop:categories:{id}" => 24 hours

// Products (moderate change)
"shop:products:featured" => 1 hour
"shop:products:trending" => 30 minutes
"shop:products:{id}" => 15 minutes

// Seller stats (frequent change)
"shop:seller:{id}:stats" => 5 minutes

// User-specific (no cache or short)
"shop:user:{id}:cart" => no cache (real-time)
"shop:user:{id}:favorites" => 5 minutes
```

### Cache Invalidation

- Product update → invalidate product cache
- Order completion → invalidate seller stats
- Review created → invalidate product cache
- Category update → invalidate categories cache

---

## Rate Limiting

```php
// routes/api.php
Route::middleware(['throttle:shop'])->group(function () {
    // Product creation: 10/hour
    Route::post('/products', ...)->middleware('throttle:10,60');

    // Orders: 20/minute
    Route::post('/orders', ...)->middleware('throttle:20,1');

    // Search: 60/minute
    Route::get('/products', ...)->middleware('throttle:60,1');
});
```

---

## Testing Checklist

### Unit Tests
- [ ] Product model validation
- [ ] Cart calculations
- [ ] Order status transitions
- [ ] Review rating calculations

### Feature Tests
- [ ] Create product as seller
- [ ] Add to cart
- [ ] Checkout flow
- [ ] Order management
- [ ] Review submission

### Integration Tests
- [ ] Wallet payment integration
- [ ] Notification delivery
- [ ] Search functionality

---

## Seed Data

### Categories

```php
$categories = [
    ['name' => 'Electronics', 'name_sw' => 'Vifaa vya Kielektroniki', 'icon' => 'device-mobile'],
    ['name' => 'Fashion', 'name_sw' => 'Mitindo', 'icon' => 'shopping-bag'],
    ['name' => 'Home & Garden', 'name_sw' => 'Nyumba na Bustani', 'icon' => 'home'],
    ['name' => 'Vehicles', 'name_sw' => 'Magari', 'icon' => 'truck'],
    ['name' => 'Services', 'name_sw' => 'Huduma', 'icon' => 'briefcase'],
    ['name' => 'Food & Drinks', 'name_sw' => 'Chakula na Vinywaji', 'icon' => 'cake'],
    ['name' => 'Health & Beauty', 'name_sw' => 'Afya na Urembo', 'icon' => 'heart'],
    ['name' => 'Sports', 'name_sw' => 'Michezo', 'icon' => 'trophy'],
    ['name' => 'Books & Media', 'name_sw' => 'Vitabu na Media', 'icon' => 'book-open'],
    ['name' => 'Other', 'name_sw' => 'Mengineyo', 'icon' => 'squares-plus'],
];
```

---

## Migration Order

1. `create_product_categories_table`
2. `create_products_table`
3. `create_product_favorites_table`
4. `create_shopping_carts_table`
5. `create_cart_items_table`
6. `create_orders_table`
7. `create_order_status_history_table`
8. `create_product_reviews_table`
9. `create_review_helpful_votes_table`

---

## Routes Definition

```php
// routes/api.php

Route::prefix('v1/shop')->group(function () {

    // Public routes
    Route::get('categories', [CategoryController::class, 'index']);
    Route::get('categories/{id}', [CategoryController::class, 'show']);
    Route::get('products', [ProductController::class, 'index']);
    Route::get('products/featured', [ProductController::class, 'featured']);
    Route::get('products/trending', [ProductController::class, 'trending']);
    Route::get('products/nearby', [ProductController::class, 'nearby']);
    Route::get('products/{id}', [ProductController::class, 'show']);
    Route::post('products/{id}/view', [ProductController::class, 'incrementView']);
    Route::get('products/{id}/reviews', [ReviewController::class, 'index']);
    Route::get('sellers/{userId}/products', [ProductController::class, 'sellerProducts']);

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        // Products
        Route::get('products/recommended', [ProductController::class, 'recommended']);
        Route::post('products', [ProductController::class, 'store']);
        Route::put('products/{id}', [ProductController::class, 'update']);
        Route::delete('products/{id}', [ProductController::class, 'destroy']);

        // Favorites
        Route::get('favorites', [FavoriteController::class, 'index']);
        Route::post('products/{id}/favorite', [FavoriteController::class, 'toggle']);

        // Cart
        Route::get('cart', [CartController::class, 'show']);
        Route::post('cart/items', [CartController::class, 'addItem']);
        Route::put('cart/items/{productId}', [CartController::class, 'updateItem']);
        Route::delete('cart/items/{productId}', [CartController::class, 'removeItem']);
        Route::delete('cart', [CartController::class, 'clear']);

        // Orders
        Route::post('orders', [OrderController::class, 'store']);
        Route::get('orders/buyer', [OrderController::class, 'buyerOrders']);
        Route::get('orders/seller', [OrderController::class, 'sellerOrders']);
        Route::get('orders/{id}', [OrderController::class, 'show']);
        Route::put('orders/{id}/status', [OrderController::class, 'updateStatus']);
        Route::post('orders/{id}/cancel', [OrderController::class, 'cancel']);

        // Reviews
        Route::post('products/{id}/reviews', [ReviewController::class, 'store']);
        Route::put('reviews/{id}', [ReviewController::class, 'update']);
        Route::delete('reviews/{id}', [ReviewController::class, 'destroy']);
        Route::post('reviews/{id}/helpful', [ReviewController::class, 'markHelpful']);

        // Seller Dashboard
        Route::get('seller/stats', [SellerDashboardController::class, 'stats']);
        Route::get('seller/products', [SellerDashboardController::class, 'products']);
        Route::get('seller/orders', [SellerDashboardController::class, 'orders']);
    });
});
```

---

## Environment Variables

```env
# Shop Configuration
SHOP_MAX_IMAGES_PER_PRODUCT=10
SHOP_MAX_CART_ITEMS=50
SHOP_ORDER_AUTO_COMPLETE_DAYS=7
SHOP_REVIEW_EDIT_WINDOW_DAYS=30

# Search
SHOP_SEARCH_DRIVER=database  # database, elasticsearch, algolia
ELASTICSEARCH_HOST=localhost:9200
ALGOLIA_APP_ID=
ALGOLIA_SECRET=

# Delivery
SHOP_DEFAULT_CURRENCY=TZS
SHOP_NEARBY_DEFAULT_RADIUS_KM=10
```

---

## File Structure Summary

```
app/
├── Models/Shop/
│   ├── Product.php
│   ├── ProductCategory.php
│   ├── ProductFavorite.php
│   ├── ShoppingCart.php
│   ├── CartItem.php
│   ├── Order.php
│   ├── OrderStatusHistory.php
│   ├── ProductReview.php
│   └── ReviewHelpfulVote.php
├── Http/
│   ├── Controllers/Api/V1/Shop/
│   │   ├── ProductController.php
│   │   ├── CategoryController.php
│   │   ├── CartController.php
│   │   ├── OrderController.php
│   │   ├── ReviewController.php
│   │   ├── FavoriteController.php
│   │   └── SellerDashboardController.php
│   ├── Requests/Shop/
│   │   ├── CreateProductRequest.php
│   │   ├── UpdateProductRequest.php
│   │   ├── AddToCartRequest.php
│   │   ├── CreateOrderRequest.php
│   │   ├── UpdateOrderStatusRequest.php
│   │   └── CreateReviewRequest.php
│   └── Resources/Shop/
│       ├── ProductResource.php
│       ├── ProductCollection.php
│       ├── CategoryResource.php
│       ├── CartResource.php
│       ├── OrderResource.php
│       ├── ReviewResource.php
│       └── SellerStatsResource.php
├── Services/Shop/
│   ├── ProductService.php
│   ├── CartService.php
│   ├── OrderService.php
│   ├── ReviewService.php
│   ├── RecommendationService.php
│   └── SellerStatsService.php
├── Policies/Shop/
│   ├── ProductPolicy.php
│   ├── OrderPolicy.php
│   └── ReviewPolicy.php
├── Events/Shop/
│   ├── OrderPlaced.php
│   ├── OrderStatusChanged.php
│   ├── ProductSoldOut.php
│   └── ReviewCreated.php
└── Notifications/Shop/
    ├── NewOrderNotification.php
    ├── OrderStatusNotification.php
    └── NewReviewNotification.php

database/
├── migrations/
│   ├── 2024_01_01_000001_create_product_categories_table.php
│   ├── 2024_01_01_000002_create_products_table.php
│   ├── 2024_01_01_000003_create_product_favorites_table.php
│   ├── 2024_01_01_000004_create_shopping_carts_table.php
│   ├── 2024_01_01_000005_create_cart_items_table.php
│   ├── 2024_01_01_000006_create_orders_table.php
│   ├── 2024_01_01_000007_create_order_status_history_table.php
│   ├── 2024_01_01_000008_create_product_reviews_table.php
│   └── 2024_01_01_000009_create_review_helpful_votes_table.php
└── seeders/
    ├── ProductCategorySeeder.php
    └── ShopDemoSeeder.php

routes/
└── api.php (shop routes added)
```
