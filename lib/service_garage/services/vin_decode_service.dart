import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec line 526 — VIN decode result. Wraps NHTSA + local cache lookup.
class VinDecode {
  final String vin;
  final String? make;
  final String? model;
  final int? year;
  final String? engine;
  final String? bodyClass;

  VinDecode({
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.engine,
    required this.bodyClass,
  });

  factory VinDecode.fromJson(Map<String, dynamic> json) {
    return VinDecode(
      vin: json['vin']?.toString() ?? '',
      make: json['make']?.toString(),
      model: json['model']?.toString(),
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse(json['year']?.toString() ?? ''),
      engine: json['engine']?.toString(),
      bodyClass: json['body_class']?.toString(),
    );
  }

  bool get hasUsefulData =>
      (make != null && make!.isNotEmpty) ||
      (model != null && model!.isNotEmpty) ||
      year != null;
}

class VinDecodeService {
  static Future<VinDecode?> decode(String vin) async {
    final cleaned = vin.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.length < 11 || cleaned.length > 17) return null;
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/vin/decode?vin=$cleaned'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final r = jsonDecode(res.body);
      if (r['success'] != true) return null;
      return VinDecode.fromJson((r['data'] as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('[VinDecodeService] error: $e');
      return null;
    }
  }
}
