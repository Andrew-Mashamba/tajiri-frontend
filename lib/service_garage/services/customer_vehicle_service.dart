import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/customer_vehicle.dart';

String get _baseUrl => ApiConfig.baseUrl;

void _log(String m) => debugPrint('[CustomerVehicleService] $m');

class VehicleListResult {
  final bool success;
  final List<CustomerVehicle> items;
  final String? message;
  VehicleListResult({required this.success, this.items = const [], this.message});
}

class VehicleResult {
  final bool success;
  final CustomerVehicle? vehicle;
  final String? message;
  VehicleResult({required this.success, this.vehicle, this.message});
}

class ServiceHistoryResult {
  final bool success;
  final CustomerVehicle? vehicle;
  final List<VehicleServiceHistoryEntry> bookings;
  final String? message;
  ServiceHistoryResult({
    required this.success,
    this.vehicle,
    this.bookings = const [],
    this.message,
  });
}

class CustomerVehicleService {
  static Future<VehicleListResult> list({required int userId}) async {
    final uri = Uri.parse('$_baseUrl/customer-vehicles')
        .replace(queryParameters: {'user_id': '$userId'});
    _log('GET $uri');
    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          final items = (body['data'] as List)
              .whereType<Map>()
              .map((m) => CustomerVehicle.fromJson(m.cast<String, dynamic>()))
              .toList();
          return VehicleListResult(success: true, items: items);
        }
      }
      return VehicleListResult(success: false, message: 'HTTP ${res.statusCode}');
    } catch (e) {
      return VehicleListResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<VehicleResult> create({
    required int userId,
    required String plate,
    String? make,
    String? model,
    int? year,
    String? vin,
    int? mileageKm,
    String? photoUrl,
    String? color,
    bool isDefault = false,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'plate': plate,
      'is_default': isDefault,
    };
    if (make != null) body['make'] = make;
    if (model != null) body['model'] = model;
    if (year != null) body['year'] = year;
    if (vin != null) body['vin'] = vin;
    if (mileageKm != null) body['mileage_km'] = mileageKm;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    if (color != null) body['color'] = color;
    final uri = Uri.parse('$_baseUrl/customer-vehicles');
    _log('POST $uri');
    try {
      final res = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        return VehicleResult(
          success: true,
          vehicle: CustomerVehicle.fromJson(
              (r['data'] as Map).cast<String, dynamic>()),
        );
      }
      return VehicleResult(success: false, message: r['message']?.toString() ?? 'HTTP ${res.statusCode}');
    } catch (e) {
      return VehicleResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<VehicleResult> update({
    required int id,
    required int userId,
    String? plate,
    String? make,
    String? model,
    int? year,
    String? vin,
    int? mileageKm,
    String? photoUrl,
    String? color,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{'user_id': userId};
    if (plate != null) body['plate'] = plate;
    if (make != null) body['make'] = make;
    if (model != null) body['model'] = model;
    if (year != null) body['year'] = year;
    if (vin != null) body['vin'] = vin;
    if (mileageKm != null) body['mileage_km'] = mileageKm;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    if (color != null) body['color'] = color;
    if (isDefault != null) body['is_default'] = isDefault;
    final uri = Uri.parse('$_baseUrl/customer-vehicles/$id');
    try {
      final res = await http.patch(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        return VehicleResult(
          success: true,
          vehicle: CustomerVehicle.fromJson(
              (r['data'] as Map).cast<String, dynamic>()),
        );
      }
      return VehicleResult(success: false, message: r['message']?.toString() ?? 'HTTP ${res.statusCode}');
    } catch (e) {
      return VehicleResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<bool> delete({required int id, required int userId}) async {
    final uri = Uri.parse('$_baseUrl/customer-vehicles/$id');
    try {
      final res = await http.delete(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      final r = jsonDecode(res.body);
      return res.statusCode == 200 && r['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<ServiceHistoryResult> serviceHistory({
    required int vehicleId,
    required int userId,
  }) async {
    final uri = Uri.parse('$_baseUrl/customer-vehicles/$vehicleId/service-history')
        .replace(queryParameters: {'user_id': '$userId'});
    try {
      final res = await http.get(uri);
      final r = jsonDecode(res.body);
      if (res.statusCode == 200 && r['success'] == true) {
        final data = (r['data'] as Map).cast<String, dynamic>();
        final vehicle = CustomerVehicle.fromJson(
            (data['vehicle'] as Map).cast<String, dynamic>());
        final bookings = (data['bookings'] as List)
            .whereType<Map>()
            .map((m) => VehicleServiceHistoryEntry.fromJson(
                m.cast<String, dynamic>()))
            .toList();
        return ServiceHistoryResult(
          success: true,
          vehicle: vehicle,
          bookings: bookings,
        );
      }
      return ServiceHistoryResult(
        success: false,
        message: r['message']?.toString() ?? 'HTTP ${res.statusCode}',
      );
    } catch (e) {
      return ServiceHistoryResult(success: false, message: 'Kosa: $e');
    }
  }
}
