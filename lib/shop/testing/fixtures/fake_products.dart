import '../../../models/shop_models.dart';

/// Deterministic sample products for widget / integration tests.
List<Product> fakeShopProducts() {
  final now = DateTime.now();
  return [
    Product(
      id: 90001,
      sellerId: 1,
      title: 'Test product A',
      slug: 'test-product-a',
      price: 15000,
      createdAt: now,
      updatedAt: now,
    ),
    Product(
      id: 90002,
      sellerId: 1,
      title: 'Test product B',
      slug: 'test-product-b',
      price: 25000,
      type: ProductType.service,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
