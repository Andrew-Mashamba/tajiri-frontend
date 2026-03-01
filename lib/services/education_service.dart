import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/education_models.dart';
import '../config/api_config.dart';

String get baseUrl => ApiConfig.baseUrl;

/// Service for Post-secondary institutions (VETA, TTC, Health, etc.)
class PostsecondaryService {
  Future<Map<String, String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/postsecondary/categories'));
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
    final response = await http.get(
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
    final response = await http.get(
      Uri.parse('$baseUrl/postsecondary/search?q=$query'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => PostsecondaryInstitution.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to search institutions');
  }

  Future<PostsecondaryInstitution?> getInstitution(String identifier) async {
    final response = await http.get(
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
    final response = await http.get(Uri.parse('$baseUrl/universities'));
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
    final response = await http.get(Uri.parse('$baseUrl/universities/categories'));
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
    final response = await http.get(
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
    final response = await http.get(
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
    final response = await http.get(
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
    final response = await http.get(uri);
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
    final response = await http.get(Uri.parse('$baseUrl/universities-detailed/types'));
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
    final encoded = Uri.encodeComponent(query);
    final response = await http.get(
      Uri.parse('$baseUrl/universities-detailed/search?q=$encoded'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => UniversityDetailed.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to search universities');
  }

  Future<List<UniversityCollege>> getColleges(int universityId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/universities-detailed/$universityId/colleges'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => UniversityCollege.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load colleges');
  }

  Future<List<UniversityDepartment>> getDepartments(int collegeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/universities-detailed/colleges/$collegeId/departments'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => UniversityDepartment.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to load departments');
  }

  Future<List<UniversityProgramme>> getProgrammesByDepartment(int departmentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/universities-detailed/departments/$departmentId/programmes'),
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

  Future<List<UniversityProgramme>> getProgrammesByUniversity(int universityId) async {
    final response = await http.get(
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
    final response = await http.get(uri);
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
    final response = await http.get(Uri.parse('$baseUrl/businesses'));
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
    final response = await http.get(Uri.parse('$baseUrl/businesses/sectors'));
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
    final response = await http.get(Uri.parse('$baseUrl/businesses/ownership-types'));
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
    final response = await http.get(
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
    final response = await http.get(
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
    final response = await http.get(
      Uri.parse('$baseUrl/businesses/search?q=$query'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((json) => Business.fromJson(json))
            .toList();
      }
    }
    throw Exception('Failed to search businesses');
  }

  Future<List<Business>> getParastatals() async {
    final response = await http.get(Uri.parse('$baseUrl/businesses/parastatals'));
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
    final response = await http.get(Uri.parse('$baseUrl/businesses/dse'));
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
    final response = await http.get(
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
