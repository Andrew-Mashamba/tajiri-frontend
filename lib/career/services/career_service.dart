// lib/career/services/career_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/career_models.dart';

class CareerService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<CareerListResult<JobListing>> getJobs({
    String? type,
    String? location,
    String? industry,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (type != null) params['type'] = type;
      if (location != null) params['location'] = location;
      if (industry != null) params['industry'] = industry;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res =
          await _dio.get('/career/jobs', queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => JobListing.fromJson(j))
            .toList();
        return CareerListResult(success: true, items: items);
      }
      return CareerListResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return CareerListResult(success: false, message: '$e');
    }
  }

  Future<CareerResult<JobListing>> getJob(int jobId) async {
    try {
      final res = await _dio.get('/career/jobs/$jobId');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return CareerResult(
          success: true,
          data: JobListing.fromJson(res.data['data']),
        );
      }
      return CareerResult(success: false, message: 'Kazi haipatikani');
    } catch (e) {
      return CareerResult(success: false, message: '$e');
    }
  }

  Future<CareerResult<void>> applyForJob({
    required int jobId,
    String? coverLetter,
    String? cvUrl,
  }) async {
    try {
      final res = await _dio.post('/career/jobs/$jobId/apply', data: {
        if (coverLetter != null) 'cover_letter': coverLetter,
        if (cvUrl != null) 'cv_url': cvUrl,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return CareerResult(success: true);
      }
      return CareerResult(success: false, message: 'Imeshindwa kutuma');
    } catch (e) {
      return CareerResult(success: false, message: '$e');
    }
  }

  Future<CareerResult<void>> saveJob(int jobId) async {
    try {
      final res = await _dio.post('/career/jobs/$jobId/save');
      return CareerResult(success: res.statusCode == 200);
    } catch (e) {
      return CareerResult(success: false, message: '$e');
    }
  }

  Future<CareerListResult<JobApplication>> getMyApplications() async {
    try {
      final res = await _dio.get('/career/applications');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => JobApplication.fromJson(j))
            .toList();
        return CareerListResult(success: true, items: items);
      }
      return CareerListResult(success: false);
    } catch (e) {
      return CareerListResult(success: false, message: '$e');
    }
  }

  Future<CareerListResult<CompanyProfile>> getCompanies({
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res =
          await _dio.get('/career/companies', queryParameters: params);
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => CompanyProfile.fromJson(j))
            .toList();
        return CareerListResult(success: true, items: items);
      }
      return CareerListResult(success: false);
    } catch (e) {
      return CareerListResult(success: false, message: '$e');
    }
  }

  Future<CareerResult<Map<String, dynamic>>> generateCV({
    required List<CVSection> sections,
  }) async {
    try {
      final res = await _dio.post('/career/cv/generate', data: {
        'sections': sections.map((s) => {
              'type': s.type,
              'fields': s.fields,
            }).toList(),
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        return CareerResult(success: true, data: res.data['data']);
      }
      return CareerResult(success: false, message: 'Imeshindwa kutengeneza CV');
    } catch (e) {
      return CareerResult(success: false, message: '$e');
    }
  }
}
