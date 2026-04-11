// lib/zaka/services/zaka_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/zaka_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class ZakaService {
  // ─── Get Nisab Info ─────────────────────────────────────────
  Future<SingleResult<NisabInfo>> getNisabInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/zakat/nisab'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: NisabInfo.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kupakia nisab');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Calculate Zakat ────────────────────────────────────────
  Future<SingleResult<ZakatCalculation>> calculate({
    required String token,
    required List<AssetEntry> assets,
    required double totalDebts,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/zakat/calculate'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'assets': assets.map((a) => a.toJson()).toList(),
          'total_debts': totalDebts,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SingleResult(
            success: true,
            data: ZakatCalculation.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kuhesabu');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Pay Zakat ──────────────────────────────────────────────
  Future<SingleResult<ZakatPayment>> payZakat({
    required String token,
    required double amount,
    required String recipientName,
    required String recipientType,
    String paymentMethod = 'mpesa',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/zakat/pay'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'amount': amount,
          'recipient_name': recipientName,
          'recipient_type': recipientType,
          'payment_method': paymentMethod,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return SingleResult(
            success: true,
            data: ZakatPayment.fromJson(data['data']),
          );
        }
      }
      return SingleResult(success: false, message: 'Imeshindwa kulipa');
    } catch (e) {
      return SingleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Get Payment History ────────────────────────────────────
  Future<PaginatedResult<ZakatPayment>> getPaymentHistory({
    required String token,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/zakat/payments?page=$page'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List?)
                  ?.map((j) => ZakatPayment.fromJson(j))
                  .toList() ??
              [];
          return PaginatedResult(success: true, items: items, total: items.length);
        }
      }
      return PaginatedResult(
          success: false, message: 'Imeshindwa kupakia historia');
    } catch (e) {
      return PaginatedResult(success: false, message: 'Kosa: $e');
    }
  }
}
