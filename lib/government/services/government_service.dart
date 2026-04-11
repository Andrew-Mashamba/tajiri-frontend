// lib/government/services/government_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/government_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class GovernmentService {
  // ─── Service Categories ───────────────────────────────────────

  Future<GovtListResult<GovtService>> getServices({
    String? category,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{'page': '$page'};
      if (category != null) params['category'] = category;

      final uri = Uri.parse('$_baseUrl/government/services').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => GovtService.fromJson(j))
              .toList();
          return GovtListResult(success: true, items: items);
        }
      }
      return GovtListResult(success: false, message: 'Imeshindwa kupakia huduma');
    } catch (e) {
      return GovtListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Recent Queries ───────────────────────────────────────────

  Future<GovtListResult<GovtQuery>> getMyQueries({
    required int userId,
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/government/queries?user_id=$userId&page=$page'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => GovtQuery.fromJson(j))
              .toList();
          return GovtListResult(success: true, items: items);
        }
      }
      return GovtListResult(success: false, message: 'Imeshindwa kupakia maswali');
    } catch (e) {
      return GovtListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── NIDA Lookup ──────────────────────────────────────────────

  Future<GovtResult<NidaInfo>> lookupNida({
    required int userId,
    required String nidaNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/government/nida/lookup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'nida_number': nidaNumber}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return GovtResult(success: true, data: NidaInfo.fromJson(data['data']));
      }
      return GovtResult(success: false, message: data['message'] ?? 'Imeshindwa kuthibitisha NIDA');
    } catch (e) {
      return GovtResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── TRA / TIN Lookup ─────────────────────────────────────────

  Future<GovtResult<TinInfo>> lookupTin({
    required int userId,
    required String tinNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/government/tra/lookup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'tin_number': tinNumber}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return GovtResult(success: true, data: TinInfo.fromJson(data['data']));
      }
      return GovtResult(success: false, message: data['message'] ?? 'Imeshindwa kutafuta TIN');
    } catch (e) {
      return GovtResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── BRELA Business Search ────────────────────────────────────

  Future<GovtListResult<BrelaInfo>> searchBrela({
    required int userId,
    required String businessName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/government/brela/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'business_name': businessName}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => BrelaInfo.fromJson(j))
            .toList();
        return GovtListResult(success: true, items: items);
      }
      return GovtListResult(success: false, message: data['message'] ?? 'Imeshindwa kutafuta');
    } catch (e) {
      return GovtListResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── NSSF Lookup ──────────────────────────────────────────────

  Future<GovtResult<NssfInfo>> lookupNssf({
    required int userId,
    required String memberNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/government/nssf/lookup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'member_number': memberNumber}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return GovtResult(success: true, data: NssfInfo.fromJson(data['data']));
      }
      return GovtResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return GovtResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── NHIF Lookup ──────────────────────────────────────────────

  Future<GovtResult<NhifInfo>> lookupNhif({
    required int userId,
    required String memberNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/government/nhif/lookup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'member_number': memberNumber}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return GovtResult(success: true, data: NhifInfo.fromJson(data['data']));
      }
      return GovtResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return GovtResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── NSSF Contribution Calculator ─────────────────────────────

  Future<GovtResult<Map<String, dynamic>>> calculateNssfContribution({
    required double monthlySalary,
    required int years,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/government/nssf/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'monthly_salary': monthlySalary,
          'years': years,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return GovtResult(success: true, data: data['data']);
      }
      return GovtResult(success: false, message: data['message'] ?? 'Imeshindwa kuhesabu');
    } catch (e) {
      return GovtResult(success: false, message: 'Kosa: $e');
    }
  }
}
