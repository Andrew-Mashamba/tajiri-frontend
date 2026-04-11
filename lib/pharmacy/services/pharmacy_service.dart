// lib/pharmacy/services/pharmacy_service.dart
//
// Single platform pharmacy — "Duka la Dawa Tajiri"
// Doctors create orders for patients via /pharmacy/doctor-order
// Patients pay and track orders.
//
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/pharmacy_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class PharmacyService {
  // ─── Search Medicine (in platform pharmacy) ────────────────────

  Future<PharmacyListResult<Medicine>> searchMedicine({
    required String query,
    String? category,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'query': query, 'page': '$page'};
      if (category != null) params['category'] = category;

      final uri = Uri.parse('$_baseUrl/pharmacy/medicines').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List).map((j) => Medicine.fromJson(j)).toList();
          return PharmacyListResult(success: true, items: items);
        }
      }
      return PharmacyListResult(success: false, message: 'Imeshindwa kutafuta dawa');
    } catch (e) {
      return PharmacyListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PharmacyListResult<Medicine>> getFeaturedMedicines() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacy/medicines/featured'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List).map((j) => Medicine.fromJson(j)).toList();
          return PharmacyListResult(success: true, items: items);
        }
      }
      return PharmacyListResult(success: false);
    } catch (e) {
      return PharmacyListResult(success: false);
    }
  }

  // ─── Patient Orders ────────────────────────────────────────────

  Future<PharmacyResult<PharmacyOrder>> placeOrder({
    required int userId,
    required List<Map<String, dynamic>> items,
    required bool isDelivery,
    String? deliveryAddress,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pharmacy/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'items': items,
          'is_delivery': isDelivery,
          if (deliveryAddress != null) 'delivery_address': deliveryAddress,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final order = PharmacyOrder.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: order.totalAmount,
              category: 'afya',
              description: 'Duka la Dawa: Order #${order.orderId}',
              referenceId: 'pharmacy_order_${order.id}',
              sourceModule: 'pharmacy',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[PharmacyService] expenditure tracking skipped');
        });
        return PharmacyResult(success: true, data: order);
      }
      return PharmacyResult(success: false, message: data['message'] ?? 'Imeshindwa kuagiza');
    } catch (e) {
      return PharmacyResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PharmacyListResult<PharmacyOrder>> getMyOrders(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacy/orders?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List).map((j) => PharmacyOrder.fromJson(j)).toList();
          return PharmacyListResult(success: true, items: items);
        }
      }
      return PharmacyListResult(success: false, message: 'Imeshindwa kupakia maagizo');
    } catch (e) {
      return PharmacyListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<PharmacyResult<void>> cancelOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pharmacy/orders/$orderId/cancel'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return PharmacyResult(success: true);
      }
      return PharmacyResult(success: false, message: data['message'] ?? 'Imeshindwa kughairi');
    } catch (e) {
      return PharmacyResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Doctor-Prescribed Orders ──────────────────────────────────
  // Orders created by doctors during consultation. Patient sees them
  // with status "awaiting_payment" and pays to activate.

  Future<PharmacyListResult<PharmacyOrder>> getDoctorPrescribedOrders(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacy/orders/doctor-prescribed?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List).map((j) => PharmacyOrder.fromJson(j)).toList();
          return PharmacyListResult(success: true, items: items);
        }
      }
      return PharmacyListResult(success: false);
    } catch (e) {
      return PharmacyListResult(success: false);
    }
  }

  /// Pay for a doctor-prescribed order (moves from awaiting_payment → pending)
  Future<PharmacyResult<PharmacyOrder>> payDoctorOrder({
    required int orderId,
    required String paymentMethod,
    String? phoneNumber,
    required bool isDelivery,
    String? deliveryAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pharmacy/orders/$orderId/pay'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          'is_delivery': isDelivery,
          if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final order = PharmacyOrder.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: order.totalAmount,
              category: 'afya',
              description: 'Duka la Dawa: Prescription #${order.orderId}',
              referenceId: 'pharmacy_rx_${order.id}',
              sourceModule: 'pharmacy',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[PharmacyService] expenditure tracking skipped');
        });
        return PharmacyResult(success: true, data: order);
      }
      return PharmacyResult(success: false, message: data['message'] ?? 'Imeshindwa kulipa');
    } catch (e) {
      return PharmacyResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Pharmacist Chat ───────────────────────────────────────────
  // Returns the platform pharmacist's user ID for DM conversation

  Future<PharmacyResult<int>> getPharmacistUserId() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacy/pharmacist'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return PharmacyResult(success: true, data: data['data']['user_id'] as int);
        }
      }
      return PharmacyResult(success: false, message: 'Imeshindwa kupata duka la dawa');
    } catch (e) {
      return PharmacyResult(success: false, message: 'Kosa: $e');
    }
  }
}
