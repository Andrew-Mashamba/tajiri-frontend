// lib/vehicle/services/vehicle_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/vehicle_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class VehicleService {
  // ─── Vehicles ─────────────────────────────────────────────────

  Future<VehicleListResult<Vehicle>> getMyVehicles(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/vehicles?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Vehicle.fromJson(j))
              .toList();
          return VehicleListResult(success: true, items: items);
        }
      }
      return VehicleListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return VehicleListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<VehicleResult<Vehicle>> getVehicleDetail(int vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/vehicles/$vehicleId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return VehicleResult(success: true, data: Vehicle.fromJson(data['data']));
        }
      }
      return VehicleResult(success: false);
    } catch (e) {
      return VehicleResult(success: false);
    }
  }

  Future<VehicleResult<Vehicle>> addVehicle({
    required int userId,
    required String make,
    required String model,
    required int year,
    required String plateNumber,
    String? color,
    String? engineSize,
    required String fuelType,
    double? mileage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/vehicles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'make': make,
          'model': model,
          'year': year,
          'plate_number': plateNumber,
          if (color != null) 'color': color,
          if (engineSize != null) 'engine_size': engineSize,
          'fuel_type': fuelType,
          if (mileage != null) 'mileage': mileage,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return VehicleResult(success: true, data: Vehicle.fromJson(data['data']));
      }
      return VehicleResult(
          success: false, message: data['message'] ?? 'Imeshindwa kuongeza gari');
    } catch (e) {
      return VehicleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Fuel Logs ────────────────────────────────────────────────

  Future<VehicleListResult<FuelLog>> getFuelLogs(int vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/vehicles/$vehicleId/fuel-logs'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => FuelLog.fromJson(j))
              .toList();
          return VehicleListResult(success: true, items: items);
        }
      }
      return VehicleListResult(success: false);
    } catch (e) {
      return VehicleListResult(success: false);
    }
  }

  Future<VehicleResult<FuelLog>> addFuelLog({
    required int vehicleId,
    required double liters,
    required double pricePerLiter,
    required double totalCost,
    double? mileage,
    String? station,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/vehicles/$vehicleId/fuel-logs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'liters': liters,
          'price_per_liter': pricePerLiter,
          'total_cost': totalCost,
          if (mileage != null) 'mileage': mileage,
          if (station != null) 'station': station,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return VehicleResult(success: true, data: FuelLog.fromJson(data['data']));
      }
      return VehicleResult(success: false, message: data['message']);
    } catch (e) {
      return VehicleResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Service Records ─────────────────────────────────────────

  Future<VehicleListResult<VehicleServiceRecord>> getServiceRecords(
      int vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/vehicles/$vehicleId/services'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => VehicleServiceRecord.fromJson(j))
              .toList();
          return VehicleListResult(success: true, items: items);
        }
      }
      return VehicleListResult(success: false);
    } catch (e) {
      return VehicleListResult(success: false);
    }
  }

  Future<VehicleResult<VehicleServiceRecord>> addServiceRecord({
    required int vehicleId,
    required String serviceType,
    required double cost,
    String? description,
    String? nextDue,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/vehicles/$vehicleId/services'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_type': serviceType,
          'cost': cost,
          if (description != null) 'description': description,
          if (nextDue != null) 'next_due': nextDue,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return VehicleResult(
            success: true, data: VehicleServiceRecord.fromJson(data['data']));
      }
      return VehicleResult(success: false, message: data['message']);
    } catch (e) {
      return VehicleResult(success: false, message: 'Kosa: $e');
    }
  }
}
