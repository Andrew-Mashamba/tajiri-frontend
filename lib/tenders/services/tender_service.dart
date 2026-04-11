// TAJIRI Tenders Service
// Connects directly to the Tenders API at tenders.zimaservices.com
// Auth: Tenders API has its own JWT auth (register/login via /api/auth/*)
// TAJIRI auto-registers/logs in user on first access using their TAJIRI credentials.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../services/local_storage_service.dart';
import '../models/tender_models.dart';

const String _tendersBaseUrl = 'https://tenders.zimaservices.com/api';

void _log(String message) => debugPrint('[TenderService] $message');
void _logError(String method, dynamic error) => debugPrint('[TenderService] ERROR in $method: $error');

class TenderService {
  /// Get or create tenders API token.
  /// Uses TAJIRI user's email/phone to auto-register on tenders API.
  static Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    // Check for cached tenders token
    final cached = storage.getString('tenders_api_token');
    if (cached != null && cached.isNotEmpty) return cached;

    // Auto-register/login with TAJIRI user credentials
    final user = storage.getUser();
    if (user == null) return null;

    final email = '${user.phoneNumber ?? 'user'}@tajiri.co.tz';
    final password = 'tajiri-${user.userId ?? 0}-tenders';

    // Try login first
    try {
      final loginRes = await http.post(
        Uri.parse('$_tendersBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (loginRes.statusCode == 200) {
        final data = jsonDecode(loginRes.body);
        final token = data['access_token'] as String?;
        if (token != null) {
          await storage.setString('tenders_api_token', token);
          return token;
        }
      }
    } catch (_) {}

    // Login failed — register
    try {
      final regRes = await http.post(
        Uri.parse('$_tendersBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'company_name': user.fullName.isNotEmpty ? user.fullName : 'TAJIRI User',
        }),
      );
      if (regRes.statusCode == 200 || regRes.statusCode == 201) {
        final data = jsonDecode(regRes.body);
        final token = data['access_token'] as String?;
        if (token != null) {
          await storage.setString('tenders_api_token', token);
          return token;
        }
      }
    } catch (_) {}

    return null;
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // --------------------------------------------------------------------------
  // STATS
  // --------------------------------------------------------------------------

  static Future<TenderResult<TenderStats>> getStats() async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/stats');
      _log('GET $url');

      final response = await http.get(url, headers: _headers(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return TenderResult.ok(TenderStats.fromJson(data as Map<String, dynamic>));
      }
      return TenderResult.fail(data['detail']?.toString() ?? 'Imeshindwa kupata takwimu');
    } catch (e) {
      _logError('getStats', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }

  // --------------------------------------------------------------------------
  // TENDERS
  // --------------------------------------------------------------------------

  static Future<TenderListResult> getTenders({
    String? status,
    String? category,
    String? search,
    String? institutionSlug,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final token = await _getToken();
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (category != null) params['category'] = category;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (institutionSlug != null) params['institution'] = institutionSlug;

      final url = Uri.parse('$_tendersBaseUrl/tenders').replace(queryParameters: params.isNotEmpty ? params : null);
      _log('GET $url');

      final response = await http.get(url, headers: _headers(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final list = (data['tenders'] as List?) ?? [];
        final tenders = list.map((j) => Tender.fromJson(j as Map<String, dynamic>)).toList();
        return TenderListResult(tenders: tenders, total: tenders.length, success: true);
      }
      return TenderListResult(error: data['detail']?.toString() ?? 'Imeshindwa kupata zabuni', success: false);
    } catch (e) {
      _logError('getTenders', e);
      return const TenderListResult(error: 'Imeshindwa kuunganisha na seva', success: false);
    }
  }

  static Future<TenderResult<Tender>> getTenderDetail(String tenderId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/tenders/$tenderId');
      _log('GET $url');

      final response = await http.get(url, headers: _headers(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return TenderResult.ok(Tender.fromJson(data as Map<String, dynamic>));
      }
      return TenderResult.fail(data['detail']?.toString() ?? 'Zabuni haipatikani');
    } catch (e) {
      _logError('getTenderDetail', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }

  // --------------------------------------------------------------------------
  // INSTITUTIONS
  // --------------------------------------------------------------------------

  static Future<InstitutionListResult> getInstitutions({
    String? search,
    String? category,
  }) async {
    try {
      final token = await _getToken();
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (category != null) params['category'] = category;

      final url = Uri.parse('$_tendersBaseUrl/institutions').replace(
        queryParameters: params.isNotEmpty ? params : null,
      );
      _log('GET $url');

      final response = await http.get(url, headers: _headers(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final list = (data['institutions'] as List?) ?? [];
        final institutions = list.map((j) => Institution.fromJson(j as Map<String, dynamic>)).toList();
        return InstitutionListResult(institutions: institutions, success: true);
      }
      return InstitutionListResult(error: data['detail']?.toString() ?? 'Imeshindwa kupata taasisi', success: false);
    } catch (e) {
      _logError('getInstitutions', e);
      return const InstitutionListResult(error: 'Imeshindwa kuunganisha na seva', success: false);
    }
  }

  static Future<TenderResult<Institution>> getInstitutionDetail(String slug) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/institutions/$slug');
      _log('GET $url');

      final response = await http.get(url, headers: _headers(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return TenderResult.ok(Institution.fromJson(data as Map<String, dynamic>));
      }
      return TenderResult.fail(data['detail']?.toString() ?? 'Taasisi haipatikani');
    } catch (e) {
      _logError('getInstitutionDetail', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }

  static Future<TenderResult<bool>> followInstitution(String slug) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/me/institutions');
      _log('POST $url (follow $slug)');

      final response = await http.post(url, headers: _headers(token), body: jsonEncode({'slug': slug}));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TenderResult.ok(true);
      }
      final data = jsonDecode(response.body);
      return TenderResult.fail(data['detail']?.toString() ?? 'Imeshindwa kufuatilia');
    } catch (e) {
      _logError('followInstitution', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }

  static Future<TenderResult<bool>> unfollowInstitution(String slug) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/me/institutions/$slug');
      _log('DELETE $url');

      final response = await http.delete(url, headers: _headers(token));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return TenderResult.ok(true);
      }
      final data = jsonDecode(response.body);
      return TenderResult.fail(data['detail']?.toString() ?? 'Imeshindwa kuondoa ufuatiliaji');
    } catch (e) {
      _logError('unfollowInstitution', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }

  // --------------------------------------------------------------------------
  // APPLICATIONS
  // --------------------------------------------------------------------------

  static Future<ApplicationListResult> getMyApplications({String? status}) async {
    try {
      final token = await _getToken();
      final params = <String, String>{};
      if (status != null) params['status'] = status;

      final url = Uri.parse('$_tendersBaseUrl/me/applications').replace(
        queryParameters: params.isNotEmpty ? params : null,
      );
      _log('GET $url');

      final response = await http.get(url, headers: _headers(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final list = (data['applications'] as List?) ?? [];
        final apps = list.map((j) => TenderApplication.fromJson(j as Map<String, dynamic>)).toList();
        return ApplicationListResult(applications: apps, success: true);
      }
      return ApplicationListResult(error: data['detail']?.toString() ?? 'Imeshindwa kupata maombi', success: false);
    } catch (e) {
      _logError('getMyApplications', e);
      return const ApplicationListResult(error: 'Imeshindwa kuunganisha na seva', success: false);
    }
  }

  static Future<TenderResult<TenderApplication>> applyToTender({
    required String tenderId,
    String? tenderTitle,
    required String institutionSlug,
    String? notes,
    String? deadline,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/me/applications');
      final body = jsonEncode({
        'tender_id': tenderId,
        'institution_slug': institutionSlug,
        'status': 'interested',
        if (notes != null) 'notes': notes,
      });
      _log('POST $url');

      final response = await http.post(url, headers: _headers(token), body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // API returns {id, status: "created"} — build a minimal application object
        return TenderResult.ok(TenderApplication(
          id: (data['id'] as num?)?.toInt() ?? 0,
          tenderId: tenderId,
          tenderTitle: tenderTitle ?? '',
          institutionSlug: institutionSlug,
          status: ApplicationStatus.interested,
          notes: notes,
          deadline: deadline != null ? DateTime.tryParse(deadline) : null,
        ));
      }
      return TenderResult.fail(data['detail']?.toString() ?? 'Imeshindwa kuomba zabuni');
    } catch (e) {
      _logError('applyToTender', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }

  static Future<TenderResult<TenderApplication>> updateApplication({
    required int applicationId,
    required ApplicationStatus status,
    String? notes,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/me/applications/$applicationId');
      final body = jsonEncode({
        'status': status.value,
        if (notes != null) 'notes': notes,
      });
      _log('PUT $url');

      final response = await http.put(url, headers: _headers(token), body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final appData = data is Map<String, dynamic> ? data : <String, dynamic>{};
        return TenderResult.ok(TenderApplication.fromJson(appData));
      }
      return TenderResult.fail(data['detail']?.toString() ?? 'Imeshindwa kusasisha ombi');
    } catch (e) {
      _logError('updateApplication', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }

  static Future<TenderResult<bool>> deleteApplication(int applicationId) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/me/applications/$applicationId');
      _log('DELETE $url');

      final response = await http.delete(url, headers: _headers(token));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return TenderResult.ok(true);
      }
      final data = jsonDecode(response.body);
      return TenderResult.fail(data['detail']?.toString() ?? 'Imeshindwa kufuta ombi');
    } catch (e) {
      _logError('deleteApplication', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }

  // --------------------------------------------------------------------------
  // POST TENDER (user-created tenders — goes through TAJIRI backend)
  // --------------------------------------------------------------------------

  static Future<TenderResult<Tender>> postTender({
    required String title,
    required String description,
    String? referenceNumber,
    required String category,
    required String closingDate,
    String? closingTime,
    String? eligibility,
    Map<String, String>? contact,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('$_tendersBaseUrl/tenders');
      final body = jsonEncode({
        'title': title,
        'description': description,
        if (referenceNumber != null) 'reference_number': referenceNumber,
        'category': category,
        'closing_date': closingDate,
        if (closingTime != null) 'closing_time': closingTime,
        if (eligibility != null) 'eligibility': eligibility,
        if (contact != null) 'contact': contact,
      });
      _log('POST $url');

      final response = await http.post(url, headers: _headers(token), body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final tenderData = data is Map<String, dynamic> ? data : <String, dynamic>{};
        return TenderResult.ok(Tender.fromJson(tenderData));
      }
      return TenderResult.fail(data['detail']?.toString() ?? 'Imeshindwa kuchapisha zabuni');
    } catch (e) {
      _logError('postTender', e);
      return TenderResult.fail('Imeshindwa kuunganisha na seva');
    }
  }
}
