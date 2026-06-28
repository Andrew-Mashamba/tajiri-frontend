import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'http_retry.dart';
import 'graphql/graphql_onboarding_service.dart';
import '../models/secondary_models.dart';

class SecondarySchoolService {
  final String baseUrl;

  SecondarySchoolService({required this.baseUrl});

  Future<List<SecondaryRegion>> getRegions() async {
    try {
      final response = await httpGetWithRetry(
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
      final response = await httpGetWithRetry(
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

      final response = await httpGetWithRetry(uri);

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
    final rows = await GraphqlOnboardingService.searchInstitutions(
      level: 'secondary', query: query, regionCode: regionCode, limit: limit);
    return rows
        .map((g) => SecondarySchool.fromJson({
              'id': int.tryParse('${g['id']}') ?? 0,
              'code': g['code'],
              'name': g['name'],
              'type': g['type'],
              'region': g['regionName'],
              'district': g['districtName'],
            }))
        .toList();
  }
}

class AlevelSchoolService {
  final String baseUrl;

  AlevelSchoolService({required this.baseUrl});

  Future<List<SecondaryRegion>> getRegions() async {
    try {
      final response = await httpGetWithRetry(
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
      final response = await httpGetWithRetry(
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

      final response = await httpGetWithRetry(uri);

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
    final rows = await GraphqlOnboardingService.searchInstitutions(
      level: 'alevel', query: query, limit: limit);
    return rows
        .map((g) => AlevelSchool.fromJson({
              'id': int.tryParse('${g['id']}') ?? 0,
              'code': g['code'],
              'name': g['name'],
              'type': g['type'],
              'region': g['regionName'],
              'district': g['districtName'],
            }))
        .toList();
  }

  Future<List<AlevelCombination>> getCombinations() async {
    final rows = await GraphqlOnboardingService.alevelCombinations();
    return rows.map(_combinationFromGql).toList();
  }

  Future<List<AlevelCombination>> getSchoolCombinations(int schoolId) async {
    final rows = await GraphqlOnboardingService.schoolCombinations('$schoolId');
    return rows.map(_combinationFromGql).toList();
  }

  AlevelCombination _combinationFromGql(Map<String, dynamic> g) =>
      AlevelCombination.fromJson({
        'id': int.tryParse('${g['id']}') ?? 0,
        'code': g['code'],
        'name': g['name'],
        'category': g['category'],
        'subjects': g['subjects'],
        'careers': g['careers'],
      });
}
