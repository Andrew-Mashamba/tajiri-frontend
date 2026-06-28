import 'dart:convert';
import 'http_retry.dart';
import '../models/education_models.dart';
import '../config/api_config.dart';
import 'graphql/graphql_onboarding_service.dart';

String get baseUrl => ApiConfig.baseUrl;

/// Service for Post-secondary institutions (VETA, TTC, Health, etc.)
class PostsecondaryService {
  Future<Map<String, String>> getCategories() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/postsecondary/categories'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final Map<String, dynamic> categories = data['data'];
        return categories.map((key, value) => MapEntry(key, value.toString()));
      }
    }
    throw Exception('Failed to load categories');
  }

  Future<List<PostsecondaryInstitution>> getByCategory(String category) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/postsecondary/category/$category'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => PostsecondaryInstitution.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load institutions');
  }

  Future<List<PostsecondaryInstitution>> search(String query) async {
    final rows = await GraphqlOnboardingService.searchInstitutions(
      level: 'postsecondary', query: query);
    return rows
        .map((g) => PostsecondaryInstitution.fromJson({
              'id': int.tryParse('${g['id']}') ?? 0,
              'code': g['code'],
              'name': g['name'],
              'type': g['type'],
              'category': g['category'],
              'region': g['regionName'],
            }))
        .toList();
  }

  Future<PostsecondaryInstitution?> getInstitution(String identifier) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/postsecondary/$identifier'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return PostsecondaryInstitution.fromJson(data['data']);
      }
    }
    return null;
  }
}

/// Service for Universities (TCU registered) - Simple API
class UniversityService {
  Future<List<University>> getAll() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/universities'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => University.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load universities');
  }

  Future<Map<String, String>> getCategories() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/universities/categories'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final Map<String, dynamic> categories = data['data'];
        return categories.map((key, value) => MapEntry(key, value.toString()));
      }
    }
    throw Exception('Failed to load categories');
  }

  Future<List<University>> getByCategory(String category) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/universities/category/$category'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => University.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load universities');
  }

  Future<List<University>> search(String query) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/universities/search?q=$query'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => University.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to search universities');
  }

  Future<University?> getUniversity(String identifier) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/universities/$identifier'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return University.fromJson(data['data']);
      }
    }
    return null;
  }
}

/// Service for Universities with full hierarchy (Detailed API)
class UniversityDetailedService {
  Future<List<UniversityDetailed>> getAll({String? type}) async {
    final uri = type != null
        ? Uri.parse('$baseUrl/universities-detailed?type=$type')
        : Uri.parse('$baseUrl/universities-detailed');
    final response = await httpGetWithRetry(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => UniversityDetailed.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load universities');
  }

  Future<Map<String, String>> getTypes() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/universities-detailed/types'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final Map<String, dynamic> types = data['data'];
        return types.map((key, value) => MapEntry(key, value.toString()));
      }
    }
    throw Exception('Failed to load types');
  }

  Future<List<UniversityDetailed>> search(String query) async {
    final rows = await GraphqlOnboardingService.searchInstitutions(
      level: 'university', query: query);
    return rows
        .map((g) => UniversityDetailed.fromJson({
              'id': int.tryParse('${g['id']}') ?? 0,
              'code': g['code'],
              'name': g['name'],
              'type': g['type'],
              'region': g['regionName'],
            }))
        .toList();
  }

  // College/department/programme hierarchy is not yet exposed via GraphQL
  // (only flat university institutions are loaded). Returns empty until a
  // backend query lands; the university step falls back to university-only.
  Future<List<UniversityCollege>> getColleges(int universityId) async =>
      <UniversityCollege>[];

  Future<List<UniversityDepartment>> getDepartments(int collegeId) async =>
      <UniversityDepartment>[];

  Future<List<UniversityProgramme>> getProgrammesByDepartment(int departmentId) async =>
      <UniversityProgramme>[];

  Future<List<UniversityProgramme>> getProgrammesByUniversity(int universityId) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/universities-detailed/$universityId/programmes'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => UniversityProgramme.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load programmes');
  }

  Future<List<UniversityProgramme>> searchProgrammes(String query, {String? level}) async {
    final encoded = Uri.encodeComponent(query);
    final uri = level != null
        ? Uri.parse('$baseUrl/universities-detailed/programmes/search?q=$encoded&level=$level')
        : Uri.parse('$baseUrl/universities-detailed/programmes/search?q=$encoded');
    final response = await httpGetWithRetry(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => UniversityProgramme.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to search programmes');
  }
}

/// Service for Businesses/Employers
class BusinessService {
  Future<List<Business>> getAll() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/businesses'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final businessData = data['data'];
        if (businessData is Map && businessData['data'] != null) {
          return (businessData['data'] as List)
              .map((json) => Business.fromJson(json))
              .toList();
        }
        return (businessData as List)
            .map((json) => Business.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load businesses');
  }

  Future<Map<String, String>> getSectors() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/businesses/sectors'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        // API returns array: [{"code": "agriculture", "label": "Agriculture", "count": 88}, ...]
        final List sectorsList = data['data'];
        return Map.fromEntries(
          sectorsList.map((s) => MapEntry(s['code'] as String, s['label'] as String)),
        );
      }
    }
    throw Exception('Failed to load sectors');
  }

  Future<Map<String, String>> getOwnershipTypes() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/businesses/ownership-types'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final Map<String, dynamic> types = data['data'];
        return types.map((key, value) => MapEntry(key, value.toString()));
      }
    }
    throw Exception('Failed to load ownership types');
  }

  Future<List<Business>> getBySector(String sector) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/businesses/sector/$sector'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Business.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load businesses');
  }

  Future<List<Business>> getByOwnership(String ownership) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/businesses/ownership/$ownership'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Business.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load businesses');
  }

  Future<List<Business>> search(String query) async {
    final rows = await GraphqlOnboardingService.searchBusinesses(query: query);
    return rows
        .map((g) => Business.fromJson({
              'id': int.tryParse('${g['id']}') ?? 0,
              'name': g['name'],
              'sector': g['sector'],
              'ownership': g['ownership'],
              'region': g['region'],
            }))
        .toList();
  }

  Future<List<Business>> getParastatals() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/businesses/parastatals'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Business.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load parastatals');
  }

  Future<List<Business>> getDseCompanies() async {
    final response = await httpGetWithRetry(Uri.parse('$baseUrl/businesses/dse'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Business.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load DSE companies');
  }

  Future<Business?> getBusiness(String identifier) async {
    final response = await httpGetWithRetry(
      Uri.parse('$baseUrl/businesses/$identifier'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return Business.fromJson(data['data']);
      }
    }
    return null;
  }
}
