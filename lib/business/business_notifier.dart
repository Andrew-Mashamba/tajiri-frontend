// lib/business/business_notifier.dart
// Global business list — ValueNotifier singleton.
// No switching. All features show data from ALL businesses,
// grouped with section headers.
//
// Usage:
//   BusinessNotifier.instance.businesses  → List<Business> (all)
//   BusinessNotifier.instance.loaded       → bool
//   BusinessNotifier.instance.load(userId) → fetch from API
//   ValueListenableBuilder(valueListenable: BusinessNotifier.instance, ...)
//
import 'package:flutter/foundation.dart';
import '../services/local_storage_service.dart';
import 'models/business_models.dart';
import 'services/business_service.dart';

class BusinessNotifier extends ValueNotifier<List<Business>> {
  BusinessNotifier._() : super([]);
  static final instance = BusinessNotifier._();

  List<Business> get businesses => value;
  bool get hasBusiness => value.isNotEmpty;
  bool get hasMultiple => value.length > 1;
  bool _loaded = false;
  bool get loaded => _loaded;

  /// Load businesses from API. Called once at app start or when needed.
  Future<void> load(int userId) async {
    if (_loaded) return;

    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return;

    final result = await BusinessService.getMyBusinesses(token, userId);
    if (result.success) {
      value = result.data;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Add a newly created business.
  void addBusiness(Business business) {
    value = [...value, business];
    notifyListeners();
  }

  /// Refresh from API.
  Future<void> refresh(int userId) async {
    final storage = await LocalStorageService.getInstance();
    final token = storage.getAuthToken();
    if (token == null) return;

    final result = await BusinessService.getMyBusinesses(token, userId);
    if (result.success) {
      value = result.data;
      notifyListeners();
    }
  }
}
