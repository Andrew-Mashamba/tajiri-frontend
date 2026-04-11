// lib/legal_gpt/services/legal_gpt_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/legal_gpt_models.dart';

class LegalGptService {
  Dio get _dio => AuthenticatedDio.instance;

  // ─── Ask Legal Question ───────────────────────────────────────
  Future<SingleResult<LegalMessage>> askQuestion(
    String message,
    List<Map<String, String>> history,
  ) async {
    try {
      final r = await _dio.post('/legal/ask', data: {
        'message': message,
        'history': history,
      });
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: LegalMessage.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Rights Cards ────────────────────────────────────────────
  Future<PaginatedResult<RightsCard>> getRightsCards({
    String? category,
  }) async {
    try {
      final r = await _dio.get('/legal/rights', queryParameters: {
        if (category != null) 'category': category,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => RightsCard.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Templates ────────────────────────────────────────────────
  Future<PaginatedResult<DocumentTemplate>> getTemplates({
    String? category,
  }) async {
    try {
      final r = await _dio.get('/legal/templates', queryParameters: {
        if (category != null) 'category': category,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => DocumentTemplate.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Lawyers ──────────────────────────────────────────────────
  Future<PaginatedResult<Lawyer>> searchLawyers({
    String? specialization,
    String? location,
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/legal/lawyers', queryParameters: {
        if (specialization != null) 'specialization': specialization,
        if (location != null) 'location': location,
        'page': page,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => Lawyer.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items, page: page);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Legal Aid Centers ────────────────────────────────────────
  Future<PaginatedResult<LegalAidCenter>> getLegalAidCenters({
    String? location,
  }) async {
    try {
      final r = await _dio.get('/legal/aid-centers', queryParameters: {
        if (location != null) 'location': location,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => LegalAidCenter.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }

  // ─── Document Review ──────────────────────────────────────────
  Future<SingleResult<DocumentReview>> reviewDocument(
    String filePath,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final r = await _dio.post('/legal/review', data: formData);
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: DocumentReview.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Case Tracker ────────────────────────────────────────────
  Future<SingleResult<CourtCase>> trackCase(
    String caseNumber, {
    String? court,
  }) async {
    try {
      final r = await _dio.get('/legal/cases/$caseNumber', queryParameters: {
        if (court != null) 'court': court,
      });
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: CourtCase.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Court Guide ──────────────────────────────────────────────
  Future<SingleResult<CourtGuide>> getCourtGuide(String courtType) async {
    try {
      final r = await _dio.get('/legal/court-guide', queryParameters: {
        'court_type': courtType,
      });
      final d = r.data;
      if (d['success'] == true && d['data'] != null) {
        return SingleResult(
          success: true,
          data: CourtGuide.fromJson(d['data']),
        );
      }
      return SingleResult(message: d['message'] ?? 'Not found');
    } catch (e) {
      return SingleResult(message: '$e');
    }
  }

  // ─── Dictionary ───────────────────────────────────────────────
  Future<PaginatedResult<LegalTerm>> getDictionary({String? term}) async {
    try {
      final r = await _dio.get('/legal/dictionary', queryParameters: {
        if (term != null) 'q': term,
      });
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List?)
                ?.map((e) => LegalTerm.fromJson(e))
                .toList() ??
            [];
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(message: d['message'] ?? 'Failed');
    } catch (e) {
      return PaginatedResult(message: '$e');
    }
  }
}
