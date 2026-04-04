# TAJIRI Shop Mega Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform TAJIRI Shop from a 1.95/10 MVP to a 6+/10 social commerce platform by implementing SQLite-powered offline-first architecture, trust/conversion features, discovery/search, payments, seller tools, retention mechanics, and UX polish across 8 sub-projects.

**Architecture:** SQLite local-first with delta sync (following `MessageDatabase` pattern). `ShopDatabase` singleton stores products, cart, categories, wishlist, search history with FTS5 full-text search. `ShopService` becomes a facade: reads SQLite first, API in background, UPSERT on response. Pending mutations queue enables offline cart/wishlist. All UI follows existing TAJIRI patterns: `setState()`, monochromatic design tokens, `AppStringsScope` for i18n.

**Tech Stack:** Flutter/Dart, sqflite (already in pubspec), Hive (existing), http/Dio (existing), share_plus (existing), flutter_blurhash (already in pubspec), heroicons (existing)

**Spec:** `docs/SHOP_GAP_ANALYSIS.md`

**Existing models (already in codebase, do NOT redefine):** `Product`, `ProductSeller`, `ProductCategory`, `Order`, `Cart`, `Review`, `ReviewStats`, `SellerStats`, `SellerStatsResult`, `OrderStatus` (enum with `.label`), `ProductType`, `ProductStatus`, `ProductCondition`, `DeliveryMethod`. `ShopService` is **instance-based** (not static). `toggleFavorite()` already exists at line 751.

---

## File Structure

### New Files

| File | Sub-Project | Responsibility |
|------|-------------|---------------|
| `lib/services/shop_database.dart` | A | SQLite singleton — tables, indexes, FTS5, CRUD, sync state |
| `lib/services/shop_sync_service.dart` | A | Delta sync, pending mutation queue, background refresh |
| `lib/widgets/shop/sticky_cart_bar.dart` | B | Sticky bottom "Add to Cart / Buy Now" bar for PDP |
| `lib/widgets/shop/review_section.dart` | B | Reviews list + stats histogram for PDP |
| `lib/widgets/shop/stock_urgency_badge.dart` | B | "Only X left" urgency widget |
| `lib/widgets/shop/zoomable_image_gallery.dart` | B | Pinch-to-zoom image carousel for PDP |
| `lib/widgets/shop/filter_bottom_sheet.dart` | D | Advanced filters (price, condition, rating, delivery) |
| `lib/widgets/shop/search_suggestions.dart` | D | Autocomplete dropdown with FTS5 + search history |
| `lib/screens/shop/wishlist_screen.dart` | D | Dedicated wishlist with price-drop badges |
| `lib/screens/shop/order_tracking_screen.dart` | E | Order timeline with status history |
| ~~`lib/screens/shop/saved_addresses_screen.dart`~~ | ~~E~~ | ~~Deferred — saved addresses is a stretch goal, not in current scope~~ |
| `lib/screens/shop/seller_analytics_screen.dart` | F | Seller dashboard with stats cards and charts |
| `lib/screens/shop/flash_deals_screen.dart` | G | Time-limited deals with countdown timers |
| `lib/widgets/lazy_indexed_stack.dart` | A | Lazy tab builder (replaces IndexedStack in home_screen) |

### Modified Files

| File | Sub-Projects | Changes |
|------|-------------|---------|
| `lib/models/shop_models.dart` | A,B,D,E | Add `toJson()` completeness, new fields (blurhash), `Product.copyWith()` method |
| `lib/services/shop_service.dart` | A,D,E,F,G | SQLite-first reads, new methods (delta sync, promo codes, saved addresses) |
| `lib/screens/shop/product_detail_screen.dart` | B | Sticky CTA bar, reviews section, stock urgency, zoom gallery, share button |
| `lib/screens/shop/shop_screen.dart` | A,D,G | SQLite-first loading, filter bottom sheet, search suggestions, flash deals section |
| `lib/screens/shop/cart_screen.dart` | A,H | SQLite-backed cart, optimistic UI, swipe-to-delete |
| `lib/screens/shop/checkout_screen.dart` | C,E | M-Pesa payment, promo codes, saved addresses |
| `lib/screens/shop/order_detail_screen.dart` | E | Order tracking timeline, return initiation |
| `lib/screens/shop/seller_orders_screen.dart` | F | Bulk order actions |
| `lib/screens/shop/create_product_screen.dart` | F | Draft auto-save |
| `lib/screens/home/home_screen.dart` | A | Replace IndexedStack with LazyIndexedStack |
| `lib/widgets/shop/product_card.dart` | B,H | Stock badge, hero transition tag, haptic on favorite |
| `lib/widgets/cached_media_image.dart` | A | BlurHash placeholder (already has param, wire it) |
| `lib/widgets/gallery/shop_gallery_widget.dart` | F | Wire seller stats, analytics navigation |

---

## SUB-PROJECT A: SQLite Shop Foundation

**Goal:** Replace API-only Shop data layer with SQLite local-first architecture. Products, categories, cart, wishlist, and search history cached locally. Delta sync keeps data fresh. Lazy tab loading cuts startup API calls.

---

### Task A1: ShopDatabase — Create SQLite singleton with tables and indexes

**Files:**
- Create: `lib/services/shop_database.dart`

- [ ] **Step 1: Create ShopDatabase singleton with table creation**

```dart
// lib/services/shop_database.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/shop_models.dart';

class ShopDatabase {
  static ShopDatabase? _instance;
  static Database? _database;

  ShopDatabase._();

  static ShopDatabase get instance {
    _instance ??= ShopDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tajiri_shop.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shop_products (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        compare_at_price REAL,
        currency TEXT DEFAULT 'TZS',
        category_id INTEGER,
        category_name TEXT,
        seller_id INTEGER,
        seller_name TEXT,
        seller_rating REAL,
        condition TEXT,
        type TEXT,
        status TEXT,
        rating REAL DEFAULT 0,
        review_count INTEGER DEFAULT 0,
        stock_quantity INTEGER DEFAULT 0,
        is_favorited INTEGER DEFAULT 0,
        thumbnail_url TEXT,
        blurhash TEXT,
        delivery_fee REAL,
        location_name TEXT,
        views_count INTEGER DEFAULT 0,
        favorites_count INTEGER DEFAULT 0,
        orders_count INTEGER DEFAULT 0,
        json_data TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        viewed_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS shop_products_fts USING fts5(
        title, description, category_name, seller_name,
        content=shop_products, content_rowid=id
      )
    ''');

    // Triggers to keep FTS in sync
    await db.execute('''
      CREATE TRIGGER shop_products_ai AFTER INSERT ON shop_products BEGIN
        INSERT INTO shop_products_fts(rowid, title, description, category_name, seller_name)
        VALUES (new.id, new.title, new.description, new.category_name, new.seller_name);
      END
    ''');
    await db.execute('''
      CREATE TRIGGER shop_products_ad AFTER DELETE ON shop_products BEGIN
        INSERT INTO shop_products_fts(shop_products_fts, rowid, title, description, category_name, seller_name)
        VALUES ('delete', old.id, old.title, old.description, old.category_name, old.seller_name);
      END
    ''');
    await db.execute('''
      CREATE TRIGGER shop_products_au AFTER UPDATE ON shop_products BEGIN
        INSERT INTO shop_products_fts(shop_products_fts, rowid, title, description, category_name, seller_name)
        VALUES ('delete', old.id, old.title, old.description, old.category_name, old.seller_name);
        INSERT INTO shop_products_fts(rowid, title, description, category_name, seller_name)
        VALUES (new.id, new.title, new.description, new.category_name, new.seller_name);
      END
    ''');

    await db.execute('CREATE INDEX idx_sp_category ON shop_products(category_id)');
    await db.execute('CREATE INDEX idx_sp_price ON shop_products(price)');
    await db.execute('CREATE INDEX idx_sp_rating ON shop_products(rating)');
    await db.execute('CREATE INDEX idx_sp_seller ON shop_products(seller_id)');
    await db.execute('CREATE INDEX idx_sp_cached ON shop_products(cached_at)');
    await db.execute('CREATE INDEX idx_sp_viewed ON shop_products(viewed_at)');

    await db.execute('''
      CREATE TABLE shop_categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        slug TEXT,
        icon_url TEXT,
        parent_id INTEGER,
        product_count INTEGER DEFAULT 0,
        json_data TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 1,
        delivery_method TEXT,
        selected INTEGER DEFAULT 1,
        added_at INTEGER NOT NULL,
        json_data TEXT NOT NULL,
        sync_state TEXT DEFAULT 'pending'
      )
    ''');
    await db.execute('CREATE INDEX idx_cart_product ON shop_cart(product_id)');

    await db.execute('''
      CREATE TABLE shop_wishlist (
        product_id INTEGER PRIMARY KEY,
        added_at INTEGER NOT NULL,
        added_price REAL,
        json_data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        searched_at INTEGER NOT NULL,
        result_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_sync_state (
        entity TEXT PRIMARY KEY,
        last_synced_at TEXT,
        last_synced_id INTEGER,
        last_etag TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE shop_pending_mutations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');
  }

  /// Close database (used in tests and logout)
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Clear all shop data (called on logout)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('shop_products');
    await db.delete('shop_categories');
    await db.delete('shop_cart');
    await db.delete('shop_wishlist');
    await db.delete('shop_search_history');
    await db.delete('shop_sync_state');
    await db.delete('shop_pending_mutations');
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Volumes/DATA/PROJECTS/TAJIRI/TAJIRI-FRONTEND/.claude/worktrees/shop-mega-plan && flutter analyze lib/services/shop_database.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/services/shop_database.dart
git commit -m "feat(shop): add ShopDatabase SQLite singleton with tables, FTS5, and indexes"
```

---

### Task A2: ShopDatabase — Product CRUD methods

**Files:**
- Modify: `lib/services/shop_database.dart`

- [ ] **Step 1: Add product CRUD methods to ShopDatabase**

Add these methods after `clearAll()`:

```dart
  // ─── Product CRUD ─────────────────────────────────────────────────────

  /// Upsert a product from API response JSON
  Future<void> upsertProduct(Product product) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('shop_products', {
      'id': product.id,
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'compare_at_price': product.compareAtPrice,
      'currency': product.currency,
      'category_id': product.categoryId,
      'category_name': product.category?.name,
      'seller_id': product.sellerId,
      'seller_name': product.seller != null
          ? '${product.seller!.firstName} ${product.seller!.lastName}'.trim()
          : null,
      'seller_rating': product.seller?.rating,
      'condition': product.condition.value,
      'type': product.type.value,
      'status': product.status.value,
      'rating': product.rating,
      'review_count': product.reviewsCount,
      'stock_quantity': product.stockQuantity,
      'is_favorited': product.isFavorited ? 1 : 0,
      'thumbnail_url': product.thumbnailPath,
      'delivery_fee': product.deliveryFee,
      'location_name': product.locationName,
      'views_count': product.viewsCount,
      'favorites_count': product.favoritesCount,
      'orders_count': product.ordersCount,
      'json_data': jsonEncode(product.toJson()),
      'cached_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Upsert a batch of products (from API page response)
  Future<void> upsertProducts(List<Product> products) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final product in products) {
      batch.insert('shop_products', {
        'id': product.id,
        'title': product.title,
        'description': product.description,
        'price': product.price,
        'compare_at_price': product.compareAtPrice,
        'currency': product.currency,
        'category_id': product.categoryId,
        'category_name': product.category?.name,
        'seller_id': product.sellerId,
        'seller_name': product.seller != null
            ? '${product.seller!.firstName} ${product.seller!.lastName}'.trim()
            : null,
        'seller_rating': product.seller?.rating,
        'condition': product.condition.value,
        'type': product.type.value,
        'status': product.status.value,
        'rating': product.rating,
        'review_count': product.reviewsCount,
        'stock_quantity': product.stockQuantity,
        'is_favorited': product.isFavorited ? 1 : 0,
        'thumbnail_url': product.thumbnailPath,
        'delivery_fee': product.deliveryFee,
        'location_name': product.locationName,
        'views_count': product.viewsCount,
        'favorites_count': product.favoritesCount,
        'orders_count': product.ordersCount,
        'json_data': jsonEncode(product.toJson()),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Query products with filters, sort, and pagination (all local)
  Future<List<Product>> queryProducts({
    int? categoryId,
    String? condition,
    String? type,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String sortBy = 'newest',
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (condition != null) {
      where.add('condition = ?');
      args.add(condition);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (minPrice != null) {
      where.add('price >= ?');
      args.add(minPrice);
    }
    if (maxPrice != null) {
      where.add('price <= ?');
      args.add(maxPrice);
    }
    if (minRating != null) {
      where.add('rating >= ?');
      args.add(minRating);
    }

    String orderBy;
    switch (sortBy) {
      case 'price_asc':
        orderBy = 'price ASC';
      case 'price_desc':
        orderBy = 'price DESC';
      case 'popular':
        orderBy = 'orders_count DESC';
      case 'rating':
        orderBy = 'rating DESC';
      default:
        orderBy = 'cached_at DESC';
    }

    final rows = await db.query(
      'shop_products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return rows.map((row) {
      final jsonData = row['json_data'] as String;
      return Product.fromJson(jsonDecode(jsonData) as Map<String, dynamic>);
    }).toList();
  }

  /// Count products matching filters (for "X results" display)
  Future<int> countProducts({int? categoryId, double? minPrice, double? maxPrice}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (categoryId != null) { where.add('category_id = ?'); args.add(categoryId); }
    if (minPrice != null) { where.add('price >= ?'); args.add(minPrice); }
    if (maxPrice != null) { where.add('price <= ?'); args.add(maxPrice); }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM shop_products${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}',
      args.isEmpty ? null : args,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Full-text search products locally
  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    final db = await database;
    // FTS5 prefix match: "sams" → "sams*"
    final ftsQuery = query.trim().split(' ').map((w) => '$w*').join(' ');
    final rows = await db.rawQuery('''
      SELECT p.json_data FROM shop_products p
      INNER JOIN shop_products_fts f ON p.id = f.rowid
      WHERE shop_products_fts MATCH ?
      ORDER BY rank
      LIMIT ?
    ''', [ftsQuery, limit]);

    return rows.map((row) {
      return Product.fromJson(jsonDecode(row['json_data'] as String) as Map<String, dynamic>);
    }).toList();
  }

  /// Get recently viewed products
  Future<List<Product>> getRecentlyViewed({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'shop_products',
      where: 'viewed_at IS NOT NULL',
      orderBy: 'viewed_at DESC',
      limit: limit,
    );
    return rows.map((row) {
      return Product.fromJson(jsonDecode(row['json_data'] as String) as Map<String, dynamic>);
    }).toList();
  }

  /// Mark a product as viewed
  Future<void> markViewed(int productId) async {
    final db = await database;
    await db.update(
      'shop_products',
      {'viewed_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/services/shop_database.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/services/shop_database.dart
git commit -m "feat(shop): add product CRUD, FTS5 search, and query methods to ShopDatabase"
```

---

### Task A3: ShopDatabase — Cart, category, wishlist, search history, and sync methods

**Files:**
- Modify: `lib/services/shop_database.dart`

- [ ] **Step 1: Add cart methods**

Add after the product methods:

```dart
  // ─── Cart ─────────────────────────────────────────────────────────────

  /// Get all cart items with product details
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.*, p.json_data as product_json
      FROM shop_cart c
      LEFT JOIN shop_products p ON c.product_id = p.id
      ORDER BY c.added_at DESC
    ''');
  }

  /// Add item to cart (local-first)
  Future<void> addToCart(int productId, {int quantity = 1, String? deliveryMethod, String? productJson}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Check if already in cart
    final existing = await db.query('shop_cart', where: 'product_id = ?', whereArgs: [productId]);
    if (existing.isNotEmpty) {
      final currentQty = existing.first['quantity'] as int? ?? 0;
      await db.update('shop_cart', {'quantity': currentQty + quantity}, where: 'product_id = ?', whereArgs: [productId]);
    } else {
      await db.insert('shop_cart', {
        'product_id': productId,
        'quantity': quantity,
        'delivery_method': deliveryMethod,
        'selected': 1,
        'added_at': now,
        'json_data': productJson ?? '{}',
        'sync_state': 'pending',
      });
    }
    // Queue mutation for server sync
    await _queueMutation('cart', 'add', {'product_id': productId, 'quantity': quantity, 'delivery_method': deliveryMethod});
  }

  /// Update cart item quantity
  Future<void> updateCartQuantity(int productId, int quantity) async {
    final db = await database;
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }
    await db.update('shop_cart', {'quantity': quantity, 'sync_state': 'pending'}, where: 'product_id = ?', whereArgs: [productId]);
    await _queueMutation('cart', 'update', {'product_id': productId, 'quantity': quantity});
  }

  /// Remove item from cart
  Future<void> removeFromCart(int productId) async {
    final db = await database;
    await db.delete('shop_cart', where: 'product_id = ?', whereArgs: [productId]);
    await _queueMutation('cart', 'remove', {'product_id': productId});
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    final db = await database;
    await db.delete('shop_cart');
    await _queueMutation('cart', 'clear', {});
  }

  /// Get cart item count
  Future<int> getCartCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM shop_cart');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── Categories ───────────────────────────────────────────────────────

  /// Upsert categories from API
  Future<void> upsertCategories(List<ProductCategory> categories) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final cat in categories) {
      batch.insert('shop_categories', {
        'id': cat.id,
        'name': cat.name,
        'slug': cat.slug,
        'icon_url': cat.icon,
        'parent_id': cat.parentId,
        'product_count': cat.productCount,
        'json_data': jsonEncode(cat.toJson()),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Get cached categories
  Future<List<ProductCategory>> getCategories() async {
    final db = await database;
    final rows = await db.query('shop_categories', orderBy: 'name ASC');
    return rows.map((row) {
      return ProductCategory.fromJson(jsonDecode(row['json_data'] as String) as Map<String, dynamic>);
    }).toList();
  }

  // ─── Wishlist ─────────────────────────────────────────────────────────

  /// Add to wishlist with current price tracking
  Future<void> addToWishlist(int productId, double currentPrice, String productJson) async {
    final db = await database;
    await db.insert('shop_wishlist', {
      'product_id': productId,
      'added_at': DateTime.now().millisecondsSinceEpoch,
      'added_price': currentPrice,
      'json_data': productJson,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _queueMutation('wishlist', 'add', {'product_id': productId});
  }

  /// Remove from wishlist
  Future<void> removeFromWishlist(int productId) async {
    final db = await database;
    await db.delete('shop_wishlist', where: 'product_id = ?', whereArgs: [productId]);
    await _queueMutation('wishlist', 'remove', {'product_id': productId});
  }

  /// Get wishlist with price-drop detection
  Future<List<Map<String, dynamic>>> getWishlistWithPriceDrops() async {
    final db = await database;
    return db.rawQuery('''
      SELECT w.*, p.price as current_price, p.json_data as product_json,
             CASE WHEN p.price < w.added_price THEN 1 ELSE 0 END as price_dropped
      FROM shop_wishlist w
      LEFT JOIN shop_products p ON w.product_id = p.id
      ORDER BY w.added_at DESC
    ''');
  }

  // ─── Search History ───────────────────────────────────────────────────

  /// Save a search query
  Future<void> saveSearchQuery(String query, {int resultCount = 0}) async {
    final db = await database;
    // Remove duplicate if exists
    await db.delete('shop_search_history', where: 'query = ?', whereArgs: [query]);
    await db.insert('shop_search_history', {
      'query': query,
      'searched_at': DateTime.now().millisecondsSinceEpoch,
      'result_count': resultCount,
    });
    // Keep max 50 entries
    await db.rawDelete('''
      DELETE FROM shop_search_history WHERE id NOT IN (
        SELECT id FROM shop_search_history ORDER BY searched_at DESC LIMIT 50
      )
    ''');
  }

  /// Get recent search queries
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    final db = await database;
    final rows = await db.query('shop_search_history', orderBy: 'searched_at DESC', limit: limit);
    return rows.map((r) => r['query'] as String).toList();
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete('shop_search_history');
  }

  // ─── Sync State ───────────────────────────────────────────────────────

  /// Get last sync timestamp for an entity
  Future<String?> getLastSyncedAt(String entity) async {
    final db = await database;
    final rows = await db.query('shop_sync_state', where: 'entity = ?', whereArgs: [entity]);
    if (rows.isEmpty) return null;
    return rows.first['last_synced_at'] as String?;
  }

  /// Update sync checkpoint
  Future<void> updateSyncState(String entity, {String? lastSyncedAt, int? lastSyncedId, String? lastEtag}) async {
    final db = await database;
    await db.insert('shop_sync_state', {
      'entity': entity,
      'last_synced_at': lastSyncedAt,
      'last_synced_id': lastSyncedId,
      'last_etag': lastEtag,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── Pending Mutations ────────────────────────────────────────────────

  /// Queue an offline mutation
  Future<void> _queueMutation(String entity, String action, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('shop_pending_mutations', {
      'entity': entity,
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
    });
  }

  /// Get all pending mutations (for sync service to process)
  Future<List<Map<String, dynamic>>> getPendingMutations() async {
    final db = await database;
    return db.query('shop_pending_mutations', orderBy: 'created_at ASC', where: 'retry_count < 3');
  }

  /// Mark a mutation as completed (delete it)
  Future<void> completeMutation(int id) async {
    final db = await database;
    await db.delete('shop_pending_mutations', where: 'id = ?', whereArgs: [id]);
  }

  /// Increment retry count on failure
  Future<void> failMutation(int id, String error) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE shop_pending_mutations SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/services/shop_database.dart`
Expected: No errors (may need to check if `ProductCategory.toJson()` exists — add if missing)

- [ ] **Step 3: Commit**

```bash
git add lib/services/shop_database.dart
git commit -m "feat(shop): add cart, category, wishlist, search history, and sync methods to ShopDatabase"
```

---

### Task A4: Complete Product.toJson() and add ProductCategory.toJson()

**Files:**
- Modify: `lib/models/shop_models.dart`

- [ ] **Step 1: Complete Product.toJson()**

The existing `toJson()` at line 380 is missing many fields present in `fromJson()`. Add the missing fields. Find the existing `toJson()` method and replace it with the complete version:

```dart
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'slug': slug,
      'type': type.value,
      'status': status.value,
      'price': price,
      if (compareAtPrice != null) 'compare_at_price': compareAtPrice,
      'currency': currency,
      'stock_quantity': stockQuantity,
      'images': images,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (categoryId != null) 'category_id': categoryId,
      if (tags != null) 'tags': tags,
      'condition': condition.value,
      if (locationName != null) 'location_name': locationName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'allow_pickup': allowPickup,
      'allow_delivery': allowDelivery,
      'allow_shipping': allowShipping,
      if (deliveryFee != null) 'delivery_fee': deliveryFee,
      if (deliveryNotes != null) 'delivery_notes': deliveryNotes,
      if (pickupAddress != null) 'pickup_address': pickupAddress,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (downloadLimit != null) 'download_limit': downloadLimit,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (serviceLocation != null) 'service_location': serviceLocation,
      'views_count': viewsCount,
      'favorites_count': favoritesCount,
      'orders_count': ordersCount,
      'rating': rating,
      'reviews_count': reviewsCount,
      if (seller != null) 'seller': seller!.toJson(),
      if (category != null) 'category': category!.toJson(),
      'is_favorited': isFavorited,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
```

- [ ] **Step 2: Add ProductSeller.toJson()**

Find the `ProductSeller` class and add:

```dart
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      if (username != null) 'username': username,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      'rating': rating,
      'total_sales': totalSales,
      'product_count': productCount,
      'is_verified': isVerified,
    };
  }
```

- [ ] **Step 3: Add ProductCategory.toJson()**

Find the `ProductCategory` class and add:

```dart
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (icon != null) 'icon': icon,
      if (imagePath != null) 'image_path': imagePath,
      if (parentId != null) 'parent_id': parentId,
      'product_count': productCount,
      if (children != null) 'children': children!.map((c) => c.toJson()).toList(),
    };
  }
```

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/models/shop_models.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/models/shop_models.dart
git commit -m "feat(shop): complete Product.toJson(), add ProductSeller.toJson() and ProductCategory.toJson()"
```

---

### Task A5: Wire ShopService to read from SQLite first

**Files:**
- Modify: `lib/services/shop_service.dart`

- [ ] **Step 1: Add ShopDatabase import and instance field**

At the top of `shop_service.dart`, add import:

```dart
import 'shop_database.dart';
```

Inside the `ShopService` class, add field:

```dart
  final ShopDatabase _db = ShopDatabase.instance;
```

- [ ] **Step 2: Add SQLite-first wrapper for getProducts()**

Add a new method that wraps the existing `getProducts()` with SQLite-first behavior. Do NOT replace `getProducts()` — add a companion method:

```dart
  /// Load products: SQLite first (instant), then API in background.
  /// Returns cached products immediately via [onCached], then fresh products via [onFresh].
  Future<void> loadProductsCached({
    int? categoryId,
    String? search,
    String sortBy = 'newest',
    double? minPrice,
    double? maxPrice,
    String? condition,
    int? currentUserId,
    int page = 1,
    int perPage = 20,
    required void Function(List<Product> products, bool fromCache) onData,
    void Function(String error)? onError,
  }) async {
    // 1. Return cached products instantly (skip if searching — FTS handles that)
    if (search == null || search.isEmpty) {
      try {
        final cached = await _db.queryProducts(
          categoryId: categoryId,
          sortBy: sortBy,
          minPrice: minPrice,
          maxPrice: maxPrice,
          condition: condition,
          limit: perPage,
          offset: (page - 1) * perPage,
        );
        if (cached.isNotEmpty) {
          onData(cached, true);
        }
      } catch (e) {
        debugPrint('[ShopService] SQLite cache read failed: $e');
      }
    } else {
      // FTS5 local search
      try {
        final localResults = await _db.searchProducts(search, limit: perPage);
        if (localResults.isNotEmpty) {
          onData(localResults, true);
        }
      } catch (e) {
        debugPrint('[ShopService] FTS5 search failed: $e');
      }
    }

    // 2. Fetch fresh from API in background
    try {
      final result = await getProducts(
        page: page,
        perPage: perPage,
        categoryId: categoryId,
        search: search,
        sortBy: sortBy,
        minPrice: minPrice,
        maxPrice: maxPrice,
        condition: condition,
        currentUserId: currentUserId,
      );
      if (result.success && result.products != null) {
        // Cache in SQLite
        await _db.upsertProducts(result.products!);
        onData(result.products!, false);

        // Save search query if applicable
        if (search != null && search.isNotEmpty) {
          await _db.saveSearchQuery(search, resultCount: result.products!.length);
        }
      } else if (result.message != null) {
        onError?.call(result.message!);
      }
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  /// Get categories: SQLite first, then API
  Future<List<ProductCategory>> getCategoriesCached() async {
    // Try SQLite first
    try {
      final cached = await _db.getCategories();
      if (cached.isNotEmpty) {
        // Refresh in background (fire and forget)
        _refreshCategories();
        return cached;
      }
    } catch (e) {
      debugPrint('[ShopService] Category cache read failed: $e');
    }
    // Fall through to API
    final result = await getCategories();
    if (result.success && result.categories != null) {
      await _db.upsertCategories(result.categories!);
      return result.categories!;
    }
    return [];
  }

  Future<void> _refreshCategories() async {
    try {
      final result = await getCategories();
      if (result.success && result.categories != null) {
        await _db.upsertCategories(result.categories!);
      }
    } catch (_) {}
  }
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/services/shop_service.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/services/shop_service.dart
git commit -m "feat(shop): add SQLite-first loadProductsCached() and getCategoriesCached() to ShopService"
```

---

### Task A6: LazyIndexedStack widget

**Files:**
- Create: `lib/widgets/lazy_indexed_stack.dart`

- [ ] **Step 1: Create the LazyIndexedStack widget**

```dart
// lib/widgets/lazy_indexed_stack.dart
import 'package:flutter/material.dart';

/// A lazy version of [IndexedStack] that only builds children
/// when they are first selected. Once built, children stay alive
/// (same behavior as IndexedStack for return visits).
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget Function()> builders;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.builders,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  final Set<int> _activated = {};
  final Map<int, Widget> _built = {};

  @override
  void initState() {
    super.initState();
    _activated.add(widget.index);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activated.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.builders.length; i++) {
      if (_activated.contains(i)) {
        _built[i] ??= widget.builders[i]();
        children.add(_built[i]!);
      } else {
        children.add(const SizedBox.shrink());
      }
    }
    return IndexedStack(
      index: widget.index,
      children: children,
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/widgets/lazy_indexed_stack.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/lazy_indexed_stack.dart
git commit -m "feat: add LazyIndexedStack widget for lazy tab loading"
```

---

### Task A7: Wire LazyIndexedStack into HomeScreen

**Files:**
- Modify: `lib/screens/home/home_screen.dart:95-115`

- [ ] **Step 1: Import LazyIndexedStack**

Add at top of file:

```dart
import '../../widgets/lazy_indexed_stack.dart';
```

- [ ] **Step 2: Replace IndexedStack with LazyIndexedStack**

In the `build()` method (line 103), replace:

```dart
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _screens[0],
            _screens[1],
            FriendsScreen(
              currentUserId: widget.currentUserId,
              isCurrentTab: _currentIndex == 2,
            ),
            _screens[3],
            _screens[4],
          ],
        ),
```

With:

```dart
        child: LazyIndexedStack(
          index: _currentIndex,
          builders: [
            () => _screens[0],
            () => _screens[1],
            () => FriendsScreen(
              currentUserId: widget.currentUserId,
              isCurrentTab: _currentIndex == 2,
            ),
            () => _screens[3],
            () => _screens[4],
          ],
        ),
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/screens/home/home_screen.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/screens/home/home_screen.dart lib/widgets/lazy_indexed_stack.dart
git commit -m "perf(home): replace IndexedStack with LazyIndexedStack — tabs load on first visit only"
```

---

## SUB-PROJECT B: PDP Trust & Conversion Quick Wins

**Goal:** Add reviews display, sticky Add-to-Cart bar, stock urgency badges, pinch-to-zoom images, and share button to the Product Detail Page. These are high-impact, low-effort changes using existing APIs and data.

---

### Task B1: Sticky "Add to Cart / Buy Now" bottom bar

**Files:**
- Create: `lib/widgets/shop/sticky_cart_bar.dart`
- Modify: `lib/screens/shop/product_detail_screen.dart`

- [ ] **Step 1: Create the sticky bar widget**

```dart
// lib/widgets/shop/sticky_cart_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSurface = Color(0xFFFFFFFF);

class StickyCartBar extends StatelessWidget {
  final double price;
  final double? compareAtPrice;
  final String currency;
  final bool isInStock;
  final bool isAddingToCart;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  const StickyCartBar({
    super.key,
    required this.price,
    this.compareAtPrice,
    this.currency = 'TZS',
    required this.isInStock,
    this.isAddingToCart = false,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = '${currency} ${price.toStringAsFixed(0)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price section
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compareAtPrice != null && compareAtPrice! > price)
                    Text(
                      '$currency ${compareAtPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999), decoration: TextDecoration.lineThrough),
                    ),
                  Text(priceStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryText)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add to Cart
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isInStock && !isAddingToCart ? () { HapticFeedback.lightImpact(); onAddToCart(); } : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kPrimaryText),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isAddingToCart
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Add to Cart', style: TextStyle(color: _kPrimaryText, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isInStock ? () { HapticFeedback.mediumImpact(); onBuyNow(); } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryText,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isInStock ? 'Buy Now' : 'Out of Stock', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Wire into ProductDetailScreen**

In `product_detail_screen.dart`, import the widget:

```dart
import '../../widgets/shop/sticky_cart_bar.dart';
```

In the `build()` method's `Scaffold`, add `bottomNavigationBar`:

```dart
      bottomNavigationBar: _product != null
          ? StickyCartBar(
              price: _product!.price,
              compareAtPrice: _product!.compareAtPrice,
              currency: _product!.currency,
              isInStock: _product!.isInStock,
              isAddingToCart: _addingToCart,
              onAddToCart: _addToCart,
              onBuyNow: _buyNow,
            )
          : null,
```

Add the `_buyNow` method (navigates to checkout with single product):

```dart
  void _buyNow() {
    if (_product == null) return;
    Navigator.pushNamed(context, '/shop/checkout', arguments: {
      'product': _product,
      'quantity': _quantity,
      'deliveryMethod': _selectedDelivery,
    });
  }
```

- [ ] **Step 3: Remove the old inline Add to Cart button** from the scrollable body (it should only be in the sticky bar now). Find the existing "Add to Cart" button in the body and remove it.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/widgets/shop/sticky_cart_bar.dart lib/screens/shop/product_detail_screen.dart`
Expected: No errors

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/shop/sticky_cart_bar.dart lib/screens/shop/product_detail_screen.dart
git commit -m "feat(shop): add sticky Add to Cart / Buy Now bottom bar on PDP"
```

---

### Task B2: Display reviews on PDP

**Files:**
- Create: `lib/widgets/shop/review_section.dart`
- Modify: `lib/screens/shop/product_detail_screen.dart`

- [ ] **Step 1: Create ReviewSection widget**

```dart
// lib/widgets/shop/review_section.dart
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../models/shop_models.dart';
import '../../widgets/cached_media_image.dart';
import '../../config/api_config.dart';

const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const Color _kTertiaryText = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

class ReviewSection extends StatelessWidget {
  final List<Review> reviews;
  final ReviewStats? stats;
  final bool isLoading;
  final VoidCallback? onWriteReview;
  final VoidCallback? onSeeAll;

  const ReviewSection({
    super.key,
    required this.reviews,
    this.stats,
    this.isLoading = false,
    this.onWriteReview,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryText)),
              if (stats != null) ...[
                const SizedBox(width: 8),
                Text('(${stats!.totalReviews})', style: const TextStyle(fontSize: 14, color: _kSecondaryText)),
              ],
              const Spacer(),
              if (onWriteReview != null)
                TextButton(
                  onPressed: onWriteReview,
                  child: const Text('Write Review', style: TextStyle(color: _kPrimaryText, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),

        // Rating summary
        if (stats != null) _buildRatingSummary(),

        const Divider(height: 1, color: _kDivider),

        // Review list
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No reviews yet', style: TextStyle(color: _kTertiaryText))),
          )
        else ...[
          ...reviews.take(3).map((r) => _buildReviewCard(r)),
          if (reviews.length > 3 && onSeeAll != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextButton(
                onPressed: onSeeAll,
                child: Text('See all ${stats?.totalReviews ?? reviews.length} reviews',
                    style: const TextStyle(color: _kPrimaryText, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRatingSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Big average rating
          Column(
            children: [
              Text(stats!.averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _kPrimaryText)),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < stats!.averageRating.round();
                  return Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, size: 16, color: const Color(0xFFFFB800));
                }),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Rating bars
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = stats!.ratingDistribution[star.toString()] ?? 0;
                final total = stats!.totalReviews;
                final fraction = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 12, color: _kSecondaryText)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: _kDivider,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB800)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(width: 24, child: Text('$count', style: const TextStyle(fontSize: 12, color: _kTertiaryText))),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: _kDivider,
                child: review.user?.profilePhotoPath != null
                    ? ClipOval(child: CachedMediaImage(imageUrl: ApiConfig.sanitizeUrl(review.user!.profilePhotoPath!), width: 32, height: 32))
                    : Text(review.user?.firstName?.substring(0, 1) ?? '?', style: const TextStyle(fontSize: 14, color: _kSecondaryText)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${review.user?.firstName ?? ''} ${review.user?.lastName ?? ''}'.trim(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14, color: const Color(0xFFFFB800),
                        )),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 8),
                          const HeroIcon(HeroIcons.checkBadge, size: 14, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 2),
                          const Text('Verified', style: TextStyle(fontSize: 11, color: Color(0xFF4CAF50))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(_formatDate(review.createdAt), style: const TextStyle(fontSize: 11, color: _kTertiaryText)),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(review.comment!, style: const TextStyle(fontSize: 13, color: _kSecondaryText, height: 1.4), maxLines: 4, overflow: TextOverflow.ellipsis),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: _kDivider),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}
```

- [ ] **Step 2: Wire ReviewSection into ProductDetailScreen**

In `product_detail_screen.dart`, import:

```dart
import '../../widgets/shop/review_section.dart';
```

Add the ReviewSection widget in the body's CustomScrollView or ListView, after the product description and before related products:

```dart
            ReviewSection(
              reviews: _reviews,
              stats: _reviewStats,
              isLoading: _reviewsLoading,
              onWriteReview: () => _showWriteReviewSheet(),
              onSeeAll: () => _showAllReviews(),
            ),
```

The `_loadReviews()` method already exists (line 121) and populates `_reviews` and `_reviewStats`. The `_showWriteReviewSheet()` method already exists. Add `_showAllReviews()`:

```dart
  void _showAllReviews() {
    // Show all reviews in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView.builder(
            controller: scrollController,
            itemCount: _reviews.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('All Reviews (${_reviews.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                );
              }
              final review = _reviews[index - 1];
              return _buildReviewTile(review);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReviewTile(Review review) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14, color: const Color(0xFFFFB800),
              )),
              const SizedBox(width: 8),
              Text('${review.user?.firstName ?? ''} ${review.user?.lastName ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          if (review.comment != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(review.comment!, style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.4)),
            ),
          const Divider(height: 20),
        ],
      ),
    );
  }
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/widgets/shop/review_section.dart lib/screens/shop/product_detail_screen.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/shop/review_section.dart lib/screens/shop/product_detail_screen.dart
git commit -m "feat(shop): display reviews with rating histogram on PDP"
```

---

### Task B3: Stock urgency badge ("Only X left")

**Files:**
- Create: `lib/widgets/shop/stock_urgency_badge.dart`
- Modify: `lib/screens/shop/product_detail_screen.dart`
- Modify: `lib/widgets/shop/product_card.dart`

- [ ] **Step 1: Create the badge widget**

```dart
// lib/widgets/shop/stock_urgency_badge.dart
import 'package:flutter/material.dart';

class StockUrgencyBadge extends StatelessWidget {
  final int stockQuantity;
  final int threshold;

  const StockUrgencyBadge({
    super.key,
    required this.stockQuantity,
    this.threshold = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (stockQuantity <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Out of stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
      );
    }
    if (stockQuantity > threshold) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('Only $stockQuantity left!', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100))),
    );
  }
}
```

- [ ] **Step 2: Add to PDP**

In `product_detail_screen.dart`, import:

```dart
import '../../widgets/shop/stock_urgency_badge.dart';
```

Add `StockUrgencyBadge(stockQuantity: _product!.stockQuantity)` near the price section in the PDP body.

- [ ] **Step 3: Add to ProductCard**

In `product_card.dart`, import the badge and add it in the info section when `product.stockQuantity > 0 && product.stockQuantity <= 5`:

```dart
if (product.stockQuantity > 0 && product.stockQuantity <= 5)
  StockUrgencyBadge(stockQuantity: product.stockQuantity),
```

- [ ] **Step 4: Verify and commit**

```bash
flutter analyze lib/widgets/shop/stock_urgency_badge.dart lib/screens/shop/product_detail_screen.dart lib/widgets/shop/product_card.dart
git add lib/widgets/shop/stock_urgency_badge.dart lib/screens/shop/product_detail_screen.dart lib/widgets/shop/product_card.dart
git commit -m "feat(shop): add stock urgency badge — 'Only X left!' on PDP and product cards"
```

---

### Task B4: Pinch-to-zoom image gallery

**Files:**
- Create: `lib/widgets/shop/zoomable_image_gallery.dart`
- Modify: `lib/screens/shop/product_detail_screen.dart`

- [ ] **Step 1: Create zoomable gallery**

```dart
// lib/widgets/shop/zoomable_image_gallery.dart
import 'package:flutter/material.dart';
import '../../widgets/cached_media_image.dart';
import '../../config/api_config.dart';

class ZoomableImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final double height;

  const ZoomableImageGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.height = 360,
  });

  @override
  State<ZoomableImageGallery> createState() => _ZoomableImageGalleryState();
}

class _ZoomableImageGalleryState extends State<ZoomableImageGallery> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullScreen(int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _FullScreenViewer(imageUrls: widget.imageUrls, initialIndex: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: Color(0xFFE0E0E0))),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final url = ApiConfig.sanitizeUrl(widget.imageUrls[index]);
              return GestureDetector(
                onTap: () => _openFullScreen(index),
                child: CachedMediaImage(imageUrl: url, fit: BoxFit.contain),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) => Container(
                width: i == _currentIndex ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _currentIndex ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
    );
  }
}

class _FullScreenViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenViewer({required this.imageUrls, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final url = ApiConfig.sanitizeUrl(imageUrls[index]);
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(child: CachedMediaImage(imageUrl: url, fit: BoxFit.contain)),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Replace existing image carousel in PDP**

In `product_detail_screen.dart`, import:

```dart
import '../../widgets/shop/zoomable_image_gallery.dart';
```

Replace the existing `PageView` image carousel section with:

```dart
            ZoomableImageGallery(
              imageUrls: _product!.imageUrls,
              height: 360,
            ),
```

- [ ] **Step 3: Wire share button in AppBar**

In the PDP AppBar actions, add:

```dart
          IconButton(
            icon: const HeroIcon(HeroIcons.share, style: HeroIconStyle.outline),
            onPressed: () {
              if (_product != null) {
                Share.share('Check out ${_product!.title} on TAJIRI! ${_product!.price.toStringAsFixed(0)} ${_product!.currency}');
              }
            },
          ),
```

- [ ] **Step 4: Verify and commit**

```bash
flutter analyze lib/widgets/shop/zoomable_image_gallery.dart lib/screens/shop/product_detail_screen.dart
git add lib/widgets/shop/zoomable_image_gallery.dart lib/screens/shop/product_detail_screen.dart
git commit -m "feat(shop): add pinch-to-zoom image gallery and share button on PDP"
```

---

## SUB-PROJECTS C through H are continued in the companion documents:
- `docs/superpowers/plans/2026-04-04-shop-mega-plan-part2.md` — Sub-projects C (Payments), D (Discovery), E (Checkout & Orders)
- `docs/superpowers/plans/2026-04-04-shop-mega-plan-part3.md` — Sub-projects F (Seller Tools), G (Retention), H (Polish)

Each part follows the same task structure and can be executed independently after Sub-project A is complete.

---

## Dependency Graph

```
A (SQLite Foundation) ──┬──→ D (Discovery — uses FTS5)
                        ├──→ H (Polish — uses offline)
                        └──→ G (Retention — uses local data)

B (PDP Quick Wins) ─────── independent (can start immediately)

C (Payments) ───────────→ E (Checkout — uses payment methods)

F (Seller Tools) ────────── mostly independent
```

**Recommended execution:** Start A + B in parallel (A with subagent, B with subagent). Then D + C in parallel. Then E + F. Finally G + H.
