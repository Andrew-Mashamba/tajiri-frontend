// lib/heslb/services/heslb_service.dart
import 'package:dio/dio.dart';
import '../../services/authenticated_dio.dart';
import '../models/heslb_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class HeslbService {
  static Future<SingleResult<LoanStatus>> getLoanStatus(
      String applicationNumber) async {
    try {
      final r = await _dio.get('/heslb/status',
          queryParameters: {'application_number': applicationNumber});
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: LoanStatus.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Disbursement>> getDisbursements({
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/heslb/disbursements',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => Disbursement.fromJson(j))
            .toList();
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<Repayment>> getRepayments({
    int page = 1,
  }) async {
    try {
      final r = await _dio.get('/heslb/repayments',
          queryParameters: {'page': page});
      final data = r.data;
      if (data['success'] == true) {
        final items = (data['data'] as List)
            .map((j) => Repayment.fromJson(j))
            .toList();
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: data['meta']?['current_page'] ?? page,
          lastPage: data['meta']?['last_page'] ?? 1,
        );
      }
      return PaginatedResult(success: false, message: data['message']);
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<Repayment>> initiateRepayment({
    required double amount,
    required String phone,
  }) async {
    try {
      final r = await _dio.post('/heslb/repayments', data: {
        'amount': amount,
        'phone': phone,
        'method': 'mpesa',
      });
      final data = r.data;
      if (data['success'] == true) {
        return SingleResult(
            success: true, data: Repayment.fromJson(data['data']));
      }
      return SingleResult(success: false, message: data['message']);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
