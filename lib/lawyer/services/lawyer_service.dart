// lib/lawyer/services/lawyer_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/lawyer_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class LawyerService {
  // ─── Find Lawyers ─────────────────────────────────────────────

  Future<LawyerListResult<Lawyer>> findLawyers({
    String? specialty,
    String? search,
    bool? onlineOnly,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
      };
      if (specialty != null) params['specialty'] = specialty;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (onlineOnly == true) params['online'] = '1';

      final uri = Uri.parse('$_baseUrl/lawyers').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => Lawyer.fromJson(j))
              .toList();
          return LawyerListResult(success: true, items: items);
        }
      }
      return LawyerListResult(success: false, message: 'Imeshindwa kupakia mawakili');
    } catch (e) {
      return LawyerListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<LawyerResult<Lawyer>> getLawyerProfile(int lawyerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lawyers/$lawyerId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return LawyerResult(success: true, data: Lawyer.fromJson(data['data']));
        }
      }
      return LawyerResult(success: false, message: 'Imeshindwa kupakia wakili');
    } catch (e) {
      return LawyerResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Lawyer Registration (Wakili Tajiri Program) ──────────────

  Future<LawyerResult<Lawyer>> registerAsLawyer({
    required int userId,
    required LawyerRegistrationRequest request,
    required File barCertificate,
    required File lawDegree,
    required File nationalId,
    File? practicePermit,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/lawyers/register');
      final multipart = http.MultipartRequest('POST', uri);

      multipart.fields['user_id'] = '$userId';
      multipart.fields.addAll(
        request.toJson().map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );

      multipart.files.add(await http.MultipartFile.fromPath('bar_certificate', barCertificate.path));
      multipart.files.add(await http.MultipartFile.fromPath('law_degree', lawDegree.path));
      multipart.files.add(await http.MultipartFile.fromPath('national_id', nationalId.path));
      if (practicePermit != null) {
        multipart.files.add(await http.MultipartFile.fromPath('practice_permit', practicePermit.path));
      }

      final streamedResponse = await multipart.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return LawyerResult(success: true, data: Lawyer.fromJson(data['data']));
      }
      return LawyerResult(success: false, message: data['message'] ?? 'Imeshindwa kusajili');
    } catch (e) {
      return LawyerResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<LawyerResult<Lawyer>> getMyLawyerProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lawyers/me?user_id=$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return LawyerResult(success: true, data: Lawyer.fromJson(data['data']));
        }
      }
      return LawyerResult(success: false);
    } catch (e) {
      return LawyerResult(success: false);
    }
  }

  // ─── Consultations ────────────────────────────────────────────

  Future<LawyerResult<LegalConsultation>> bookConsultation({
    required int clientId,
    required int lawyerId,
    required ConsultationType type,
    required DateTime scheduledAt,
    required String issue,
    String? notes,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/lawyers/consultations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_id': clientId,
          'lawyer_id': lawyerId,
          'type': type.name,
          'scheduled_at': scheduledAt.toIso8601String(),
          'issue': issue,
          if (notes != null) 'notes': notes,
          'payment_method': paymentMethod,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return LawyerResult(success: true, data: LegalConsultation.fromJson(data['data']));
      }
      return LawyerResult(success: false, message: data['message'] ?? 'Imeshindwa kuagiza');
    } catch (e) {
      return LawyerResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<LawyerListResult<LegalConsultation>> getMyConsultations({
    required int userId,
    String? status,
    int page = 1,
  }) async {
    try {
      String url = '$_baseUrl/lawyers/consultations?user_id=$userId&page=$page';
      if (status != null) url += '&status=$status';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => LegalConsultation.fromJson(j))
              .toList();
          return LawyerListResult(success: true, items: items);
        }
      }
      return LawyerListResult(success: false, message: 'Imeshindwa kupakia mashauriano');
    } catch (e) {
      return LawyerListResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<LawyerResult<void>> cancelConsultation(int consultationId, {String? reason}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/lawyers/consultations/$consultationId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({if (reason != null) 'reason': reason}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return LawyerResult(success: true);
      }
      return LawyerResult(success: false, message: data['message'] ?? 'Imeshindwa kughairi');
    } catch (e) {
      return LawyerResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Start consultation (call/chat) ───────────────────────────

  Future<LawyerResult<Map<String, dynamic>>> startConsultation(int consultationId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/lawyers/consultations/$consultationId/start'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return LawyerResult(success: true, data: data['data']);
      }
      return LawyerResult(success: false, message: data['message'] ?? 'Imeshindwa kuanza');
    } catch (e) {
      return LawyerResult(success: false, message: 'Kosa: $e');
    }
  }

  // ─── Reviews ──────────────────────────────────────────────────

  Future<LawyerResult<LawyerReview>> submitReview({
    required int consultationId,
    required int clientId,
    required int lawyerId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/lawyers/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'consultation_id': consultationId,
          'client_id': clientId,
          'lawyer_id': lawyerId,
          'rating': rating,
          if (comment != null) 'comment': comment,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return LawyerResult(success: true, data: LawyerReview.fromJson(data['data']));
      }
      return LawyerResult(success: false, message: data['message'] ?? 'Imeshindwa');
    } catch (e) {
      return LawyerResult(success: false, message: 'Kosa: $e');
    }
  }

  Future<LawyerListResult<LawyerReview>> getLawyerReviews(int lawyerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/lawyers/$lawyerId/reviews'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((j) => LawyerReview.fromJson(j))
              .toList();
          return LawyerListResult(success: true, items: items);
        }
      }
      return LawyerListResult(success: false);
    } catch (e) {
      return LawyerListResult(success: false);
    }
  }
}
