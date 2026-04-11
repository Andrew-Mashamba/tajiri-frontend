// lib/bills/services/bills_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/bills_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class BillsService {
  // ─── Payment History ──────────────────────────────────────────

  Future<BillsListResult<BillPayment>> getPaymentHistory(int userId,
      {String? type}) async {
    try {
      final params = <String, String>{'user_id': userId.toString()};
      if (type != null) params['type'] = type;
      final uri = Uri.parse('$_baseUrl/bills/payments')
          .replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => BillPayment.fromJson(j))
              .toList();
          return BillsListResult(success: true, items: items);
        }
      }
      return BillsListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return BillsListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Buy LUKU (Electricity) ───────────────────────────────────

  Future<BillsResult<BillPayment>> buyLuku({
    required int userId,
    required String meterNumber,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bills/luku'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'meter_number': meterNumber,
          'amount': amount,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final payment = BillPayment.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: amount,
              category: 'umeme_maji',
              description: 'LUKU: Meter $meterNumber',
              referenceId: 'bills_luku_${payment.id}',
              sourceModule: 'bills',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[BillsService] expenditure tracking skipped');
        });
        return BillsResult(success: true, data: payment);
      }
      return BillsResult(
          success: false, message: data['message'] ?? 'Imeshindwa kununua LUKU');
    } catch (e) {
      return BillsResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Buy Airtime ──────────────────────────────────────────────

  Future<BillsResult<BillPayment>> buyAirtime({
    required int userId,
    required String operator,
    required String phoneNumber,
    required double amount,
    required String paymentMethod,
    String? paymentPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bills/airtime'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'operator': operator,
          'phone_number': phoneNumber,
          'amount': amount,
          'payment_method': paymentMethod,
          if (paymentPhone != null) 'payment_phone': paymentPhone,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final payment = BillPayment.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: amount,
              category: 'simu_intaneti',
              description: 'Airtime: $operator $phoneNumber',
              referenceId: 'bills_airtime_${payment.id}',
              sourceModule: 'bills',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[BillsService] expenditure tracking skipped');
        });
        return BillsResult(success: true, data: payment);
      }
      return BillsResult(
          success: false,
          message: data['message'] ?? 'Imeshindwa kununua vocha');
    } catch (e) {
      return BillsResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Pay Water (DAWASCO) ──────────────────────────────────────

  Future<BillsResult<BillPayment>> payWater({
    required int userId,
    required String accountNumber,
    required double amount,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bills/water'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'account_number': accountNumber,
          'amount': amount,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final payment = BillPayment.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: amount,
              category: 'umeme_maji',
              description: 'Maji: Account $accountNumber',
              referenceId: 'bills_water_${payment.id}',
              sourceModule: 'bills',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[BillsService] expenditure tracking skipped');
        });
        return BillsResult(success: true, data: payment);
      }
      return BillsResult(
          success: false, message: data['message'] ?? 'Imeshindwa kulipa maji');
    } catch (e) {
      return BillsResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Pay TV ───────────────────────────────────────────────────

  Future<BillsResult<BillPayment>> payTv({
    required int userId,
    required String provider,
    required String smartcardNumber,
    required double amount,
    String? package,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bills/tv'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'provider': provider,
          'smartcard_number': smartcardNumber,
          'amount': amount,
          if (package != null) 'package': package,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final payment = BillPayment.fromJson(data['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: amount,
              category: 'burudani',
              description: 'TV: $provider',
              referenceId: 'bills_tv_${payment.id}',
              sourceModule: 'bills',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[BillsService] expenditure tracking skipped');
        });
        return BillsResult(success: true, data: payment);
      }
      return BillsResult(
          success: false, message: data['message'] ?? 'Imeshindwa kulipa TV');
    } catch (e) {
      return BillsResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Saved Accounts ──────────────────────────────────────────

  Future<BillsListResult<SavedAccount>> getSavedAccounts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/bills/saved-accounts?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => SavedAccount.fromJson(j))
              .toList();
          return BillsListResult(success: true, items: items);
        }
      }
      return BillsListResult(success: false);
    } catch (e) {
      return BillsListResult(success: false);
    }
  }

  Future<BillsResult<SavedAccount>> saveAccount({
    required int userId,
    required String type,
    required String label,
    required String accountNumber,
    String? provider,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bills/saved-accounts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'type': type,
          'label': label,
          'account_number': accountNumber,
          if (provider != null) 'provider': provider,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return BillsResult(
            success: true, data: SavedAccount.fromJson(data['data']));
      }
      return BillsResult(success: false, message: data['message']);
    } catch (e) {
      return BillsResult(success: false, message: 'Kosa: $e');
    }
  }
}
