// lib/fee_status/services/fee_status_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/authenticated_dio.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/fee_status_models.dart';

class FeeStatusService {
  Dio get _dio => AuthenticatedDio.instance;

  Future<FeeResult<FeeBalance>> getBalance() async {
    try {
      final res = await _dio.get('/education/fees/balance');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return FeeResult(
          success: true,
          data: FeeBalance.fromJson(res.data['data']),
        );
      }
      return FeeResult(success: false, message: 'Imeshindwa kupakia');
    } catch (e) {
      return FeeResult(success: false, message: '$e');
    }
  }

  Future<FeeListResult<FeePayment>> getPaymentHistory() async {
    try {
      final res = await _dio.get('/education/fees/payments');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => FeePayment.fromJson(j))
            .toList();
        return FeeListResult(success: true, items: items);
      }
      return FeeListResult(success: false);
    } catch (e) {
      return FeeListResult(success: false, message: '$e');
    }
  }

  /// Initiate M-Pesa payment for fees.
  Future<FeeResult<void>> payViaMpesa({
    required double amount,
    required String phoneNumber,
    required String studentRef,
  }) async {
    try {
      final res = await _dio.post('/education/fees/pay/mpesa', data: {
        'amount': amount,
        'phone_number': phoneNumber,
        'student_ref': studentRef,
      });
      if (res.statusCode == 200 && res.data['success'] == true) {
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: amount,
              category: 'ada_shule',
              description: 'Ada ya Shule: $studentRef',
              referenceId: 'fee_mpesa_${studentRef}_${DateTime.now().millisecondsSinceEpoch}',
              sourceModule: 'fee_status',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[FeeStatusService] expenditure tracking skipped');
        });
        return FeeResult(success: true);
      }
      return FeeResult(success: false, message: 'Malipo yameshindwa');
    } catch (e) {
      return FeeResult(success: false, message: '$e');
    }
  }

  Future<FeeResult<HeslbStatus>> getHeslbStatus() async {
    try {
      final res = await _dio.get('/education/fees/heslb');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return FeeResult(
          success: true,
          data: HeslbStatus.fromJson(res.data['data']),
        );
      }
      return FeeResult(success: false, message: 'HESLB haipatikani');
    } catch (e) {
      return FeeResult(success: false, message: '$e');
    }
  }

  Future<FeeListResult<ClearanceItem>> getClearanceStatus() async {
    try {
      final res = await _dio.get('/education/fees/clearance');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final items = (res.data['data'] as List)
            .map((j) => ClearanceItem.fromJson(j))
            .toList();
        return FeeListResult(success: true, items: items);
      }
      return FeeListResult(success: false);
    } catch (e) {
      return FeeListResult(success: false, message: '$e');
    }
  }

  Future<FeeResult<String>> generateStatement() async {
    try {
      final res = await _dio.get('/education/fees/statement');
      if (res.statusCode == 200 && res.data['success'] == true) {
        return FeeResult(
          success: true,
          data: res.data['data']['url']?.toString(),
        );
      }
      return FeeResult(success: false, message: 'Imeshindwa kutengeneza');
    } catch (e) {
      return FeeResult(success: false, message: '$e');
    }
  }
}
