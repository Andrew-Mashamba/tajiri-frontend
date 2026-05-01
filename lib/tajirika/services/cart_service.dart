import '../models/partner_product.dart';
import '../models/product_variant.dart';

/// In-memory cart item for the cross-vertical Tajirika buyer cart.
class CartItem {
  final PartnerProduct product;
  final ProductVariant? variant;
  int quantity;
  /// Real distance delivery fee (null = not calculated yet).
  int? deliveryFeeTzs;

  CartItem({
    required this.product,
    this.variant,
    this.quantity = 1,
    this.deliveryFeeTzs,
  });

  int get unitPriceTzs => variant?.priceTzs ?? product.basePriceTzs;

  int get itemSubtotalTzs => unitPriceTzs * quantity;

  int get totalTzs => itemSubtotalTzs + (deliveryFeeTzs ?? 0);
}

/// Singleton in-memory cart service shared across vertical home pages.
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> items = <CartItem>[];

  void addItem(PartnerProduct product, ProductVariant? variant, int quantity) {
    final existingIndex = items.indexWhere(
      (i) =>
          i.product.id == product.id &&
          (i.variant?.id ?? 0) == (variant?.id ?? 0),
    );
    if (existingIndex >= 0) {
      items[existingIndex].quantity += quantity;
    } else {
      items.add(
        CartItem(product: product, variant: variant, quantity: quantity),
      );
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  void clear() => items.clear();

  int get totalTzs =>
      items.fold<int>(0, (sum, i) => sum + i.totalTzs);

  int get totalDeliveryFeeTzs =>
      items.fold<int>(0, (sum, i) => sum + (i.deliveryFeeTzs ?? 0));

  int get totalQuantity =>
      items.fold<int>(0, (sum, i) => sum + i.quantity);

  int get subtotalTzs =>
      items.fold<int>(0, (sum, i) => sum + i.itemSubtotalTzs);
}
