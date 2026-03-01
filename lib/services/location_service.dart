import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_models.dart';

class LocationService {
  final String baseUrl;

  LocationService({required this.baseUrl});

  Future<List<Region>> getRegions() async {
    final response = await http.get(Uri.parse('$baseUrl/api/locations/regions'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Region.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load regions');
  }

  Future<List<District>> getDistricts(int regionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/locations/regions/$regionId/districts'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => District.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load districts');
  }

  Future<List<Ward>> getWards(int districtId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/locations/districts/$districtId/wards'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Ward.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load wards');
  }

  Future<List<Street>> getStreets(int wardId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/locations/wards/$wardId/streets'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Street.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load streets');
  }

  Future<Map<String, dynamic>> searchLocations(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/locations/search?q=${Uri.encodeComponent(query)}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      }
    }
    throw Exception('Failed to search locations');
  }
}
