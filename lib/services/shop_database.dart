// lib/services/shop_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

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
