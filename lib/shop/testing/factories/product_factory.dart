// Blueprint: docs/shop/shop.md — testing/factories/product_factory.dart
import '../../../models/shop_models.dart';
import '../fixtures/fake_products.dart';

Product sampleProduct() => fakeShopProducts().first;
