import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/school_models.dart';

class SchoolService {
  final String baseUrl;

  SchoolService({required this.baseUrl});

  Future<List<SchoolRegion>> getRegions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schools/regions'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => SchoolRegion.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching school regions: $e');
      return [];
    }
  }

  Future<List<SchoolDistrict>> getDistricts(String regionCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schools/regions/$regionCode/districts'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => SchoolDistrict.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching school districts: $e');
      return [];
    }
  }

  Future<List<School>> getSchoolsInDistrict(String districtCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schools/districts/$districtCode/schools'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => School.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching schools in district: $e');
      return [];
    }
  }

  Future<List<School>> searchSchools(
    String query, {
    String? regionCode,
    String? districtCode,
    int limit = 20,
  }) async {
    try {
      final params = {
        'q': query,
        'limit': limit.toString(),
      };
      if (regionCode != null) params['region_code'] = regionCode;
      if (districtCode != null) params['district_code'] = districtCode;

      final uri = Uri.parse('$baseUrl/api/schools/search')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => School.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching schools: $e');
      return [];
    }
  }

  Future<SchoolStats?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schools/stats'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return SchoolStats.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching school stats: $e');
      return null;
    }
  }
}
