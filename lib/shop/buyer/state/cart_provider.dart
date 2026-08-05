import 'package:flutter/material.dart';

import '../../../models/shop_models.dart';
import '../../data/repositories/shop_repository.dart';
import '../../domain/usecases/add_to_cart.dart';

/// Global cart notifier — use with [`ListenableBuilder`] / [`AnimatedBuilder`]
/// (no `provider` package in this app).
class CartProvider extends ChangeNotifier {
  CartProvider._();
  static final CartProvider instance = CartProvider._();

  final ShopRepository _repo = ShopRepository.instance;

  int? _userId;
  Cart? _cart;
  String? _lastError;
  bool _loading = false;

  Cart? get cart => _cart;
  int? get userId => _userId;
  String? get lastError => _lastError;
  bool get isLoading => _loading;

  int get itemCount => _cart?.itemCount ?? 0;
  bool get isEmpty => _cart?.isEmpty ?? true;

  /// Apply a cart payload already fetched by a screen (avoids duplicate GETs).
  void ingestCartSnapshot(CartResult result, {required int userId}) {
    _userId = userId;
    _loading = false;
    if (result.success) {
      _cart = result.cart;
      _lastError = null;
    } else {
      _lastError = result.message;
    }
    notifyListeners();
  }

  Future<void> bindUser(int userId) async {
    _userId = userId;
    await refresh();
  }

  void clearUser() {
    _userId = null;
    _cart = null;
    _lastError = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    final uid = _userId;
    if (uid == null) return;
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      final result = await _repo.getCart(uid);
      if (result.success) {
        _cart = result.cart;
      } else {
        _lastError = result.message;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> add({
    required int productId,
    int quantity = 1,
  }) async {
    final uid = _userId;
    if (uid == null) return false;
    final result = await AddToCart().execute(
      userId: uid,
      productId: productId,
      quantity: quantity,
    );
    if (!result.success) {
      _lastError = result.message;
      notifyListeners();
      return false;
    }
    _cart = result.cart;
    notifyListeners();
    return true;
  }

  Future<bool> updateQuantity({
    required int productId,
    required int quantity,
  }) async {
    final uid = _userId;
    if (uid == null) return false;
    final result = await _repo.updateCartItem(uid, productId, quantity);
    if (!result.success) {
      _lastError = result.message;
      notifyListeners();
      return false;
    }
    _cart = result.cart;
    notifyListeners();
    return true;
  }

  Future<bool> remove({required int productId}) async {
    final uid = _userId;
    if (uid == null) return false;
    final result = await _repo.removeFromCart(uid, productId);
    if (!result.success) {
      _lastError = result.message;
      notifyListeners();
      return false;
    }
    _cart = result.cart;
    notifyListeners();
    return true;
  }
}
