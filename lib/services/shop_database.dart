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

  void _log(String msg) => debugPrint('[ShopDatabase] $msg');

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tajiri_shop.db');
    _log('Opening shop database');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_products (
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
      CREATE TRIGGER IF NOT EXISTS shop_products_ai AFTER INSERT ON shop_products BEGIN
        INSERT INTO shop_products_fts(rowid, title, description, category_name, seller_name)
        VALUES (new.id, new.title, new.description, new.category_name, new.seller_name);
      END
    ''');
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS shop_products_ad AFTER DELETE ON shop_products BEGIN
        INSERT INTO shop_products_fts(shop_products_fts, rowid, title, description, category_name, seller_name)
        VALUES ('delete', old.id, old.title, old.description, old.category_name, old.seller_name);
      END
    ''');
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS shop_products_au AFTER UPDATE ON shop_products BEGIN
        INSERT INTO shop_products_fts(shop_products_fts, rowid, title, description, category_name, seller_name)
        VALUES ('delete', old.id, old.title, old.description, old.category_name, old.seller_name);
        INSERT INTO shop_products_fts(rowid, title, description, category_name, seller_name)
        VALUES (new.id, new.title, new.description, new.category_name, new.seller_name);
      END
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_sp_category ON shop_products(category_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sp_price ON shop_products(price)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sp_rating ON shop_products(rating)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sp_seller ON shop_products(seller_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sp_cached ON shop_products(cached_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sp_viewed ON shop_products(viewed_at)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_categories (
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
      CREATE TABLE IF NOT EXISTS shop_cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL UNIQUE,
        quantity INTEGER DEFAULT 1,
        delivery_method TEXT,
        selected INTEGER DEFAULT 1,
        added_at INTEGER NOT NULL,
        json_data TEXT NOT NULL,
        sync_state TEXT DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_wishlist (
        product_id INTEGER PRIMARY KEY,
        added_at INTEGER NOT NULL,
        added_price REAL,
        json_data TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL UNIQUE,
        searched_at INTEGER NOT NULL,
        result_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_sync_state (
        entity TEXT PRIMARY KEY,
        last_synced_at INTEGER,
        last_synced_id INTEGER,
        last_etag TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop_pending_mutations (
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrations go here
    // if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
  }

  /// Close database (used in tests and logout)
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
    _instance = null;
    _log('Database closed');
  }

  /// Clear all shop data (called on logout)
  Future<void> clearAll() async {
    final db = await database;
    await db.execute("INSERT INTO shop_products_fts(shop_products_fts) VALUES('delete-all')");
    await db.delete('shop_products');
    await db.delete('shop_categories');
    await db.delete('shop_cart');
    await db.delete('shop_wishlist');
    await db.delete('shop_search_history');
    await db.delete('shop_sync_state');
    await db.delete('shop_pending_mutations');
    _log('All shop data cleared');
  }

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
}
