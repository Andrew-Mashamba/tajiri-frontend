import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/secondary_models.dart';

class SecondarySchoolService {
  final String baseUrl;

  SecondarySchoolService({required this.baseUrl});

  Future<List<SecondaryRegion>> getRegions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/secondary-schools/regions'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => SecondaryRegion.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching secondary school regions: $e');
      return [];
    }
  }

  Future<List<SecondaryDistrict>> getDistricts(String regionCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/secondary-schools/regions/$regionCode/districts'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => SecondaryDistrict.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching secondary school districts: $e');
      return [];
    }
  }

  Future<List<SecondarySchool>> getSchoolsInDistrict(String districtCode, {String? regionCode}) async {
    try {
      var uri = Uri.parse('$baseUrl/api/secondary-schools/districts/$districtCode/schools');

      // For "OTHER" district, pass region_code as query param
      if (districtCode == 'OTHER' && regionCode != null) {
        uri = uri.replace(queryParameters: {'region_code': regionCode});
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => SecondarySchool.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching secondary schools in district: $e');
      return [];
    }
  }

  /// Search by name, and optionally filter by region and/or district.
  /// Backend should support 5,500+ schools; search by region, district, name.
  Future<List<SecondarySchool>> searchSchools(
    String query, {
    int limit = 50,
    String? regionCode,
    String? districtCode,
  }) async {
    try {
      final params = <String, String>{
        'q': query,
        'limit': limit.toString(),
      };
      if (regionCode != null && regionCode.isNotEmpty) {
        params['region_code'] = regionCode;
      }
      if (districtCode != null && districtCode.isNotEmpty) {
        params['district_code'] = districtCode;
      }

      final uri = Uri.parse('$baseUrl/api/secondary-schools/search')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => SecondarySchool.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching secondary schools: $e');
      return [];
    }
  }
}

class AlevelSchoolService {
  final String baseUrl;

  AlevelSchoolService({required this.baseUrl});

  Future<List<SecondaryRegion>> getRegions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/alevel-schools/regions'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => SecondaryRegion.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching A-Level school regions: $e');
      return [];
    }
  }

  Future<List<SecondaryDistrict>> getDistricts(String regionCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/alevel-schools/regions/$regionCode/districts'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => SecondaryDistrict.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching A-Level school districts: $e');
      return [];
    }
  }

  Future<List<AlevelSchool>> getSchoolsInDistrict(String districtCode, {String? regionCode}) async {
    try {
      var uri = Uri.parse('$baseUrl/api/alevel-schools/districts/$districtCode/schools');

      // For "OTHER" district, pass region_code as query param
      if (districtCode == 'OTHER' && regionCode != null) {
        uri = uri.replace(queryParameters: {'region_code': regionCode});
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => AlevelSchool.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching A-Level schools in district: $e');
      return [];
    }
  }

  Future<List<AlevelSchool>> searchSchools(
    String query, {
    int limit = 20,
  }) async {
    try {
      final params = {
        'q': query,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/api/alevel-schools/search')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => AlevelSchool.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error searching A-Level schools: $e');
      return [];
    }
  }

  Future<List<AlevelCombination>> getCombinations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/alevel-schools/combinations'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => AlevelCombination.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching A-Level combinations: $e');
      return [];
    }
  }

  Future<List<AlevelCombination>> getSchoolCombinations(int schoolId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/alevel-schools/$schoolId/combinations'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => AlevelCombination.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching school combinations: $e');
      return [];
    }
  }
}
