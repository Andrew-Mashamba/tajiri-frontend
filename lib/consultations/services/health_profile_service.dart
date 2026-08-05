import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/http_retry.dart';
import '../../config/api_config.dart';

class HealthProfile {
  final int userId;
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<Map<String, dynamic>> pastPrescriptions;
  final List<Map<String, dynamic>> labUploads;
  final List<Map<String, dynamic>> insuranceCards;

  HealthProfile({
    required this.userId,
    required this.allergies,
    required this.chronicConditions,
    required this.pastPrescriptions,
    required this.labUploads,
    required this.insuranceCards,
  });

  factory HealthProfile.empty(int userId) => HealthProfile(
        userId: userId,
        allergies: const [],
        chronicConditions: const [],
        pastPrescriptions: const [],
        labUploads: const [],
        insuranceCards: const [],
      );

  factory HealthProfile.fromJson(int userId, Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(dynamic) cast) {
      if (raw is List) return raw.map(cast).toList();
      if (raw is String && raw.isNotEmpty) {
        try {
          final dec = jsonDecode(raw);
          if (dec is List) return dec.map(cast).toList();
        } catch (_) {}
      }
      return const <Never>[] as List<T>;
    }

    return HealthProfile(
      userId: userId,
      allergies: parseList(json['allergies'], (e) => e.toString()),
      chronicConditions: parseList(json['chronic_conditions'], (e) => e.toString()),
      pastPrescriptions: parseList(
        json['past_prescriptions'],
        (e) => (e is Map ? e.cast<String, dynamic>() : <String, dynamic>{'item': e.toString()}),
      ),
      labUploads: parseList(
        json['lab_uploads'],
        (e) => (e is Map ? e.cast<String, dynamic>() : <String, dynamic>{'url': e.toString()}),
      ),
      insuranceCards: parseList(
        json['insurance_cards'],
        (e) => (e is Map ? e.cast<String, dynamic>() : <String, dynamic>{'provider': e.toString()}),
      ),
    );
  }
}

class HealthProfileService {
  static Future<HealthProfile> show(int userId) async {
    try {
      final res = await httpGetWithRetry(
        Uri.parse('${ApiConfig.baseUrl}/customer-health-profiles/$userId'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        if (data is Map) {
          return HealthProfile.fromJson(userId, data.cast<String, dynamic>());
        }
      }
    } catch (_) {}
    return HealthProfile.empty(userId);
  }

  static Future<bool> upsert({
    required int userId,
    List<String>? allergies,
    List<String>? chronicConditions,
    List<Map<String, dynamic>>? pastPrescriptions,
    List<Map<String, dynamic>>? labUploads,
    List<Map<String, dynamic>>? insuranceCards,
  }) async {
    final body = <String, dynamic>{};
    if (allergies != null) body['allergies'] = allergies;
    if (chronicConditions != null) body['chronic_conditions'] = chronicConditions;
    if (pastPrescriptions != null) body['past_prescriptions'] = pastPrescriptions;
    if (labUploads != null) body['lab_uploads'] = labUploads;
    if (insuranceCards != null) body['insurance_cards'] = insuranceCards;
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/customer-health-profiles/$userId'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
