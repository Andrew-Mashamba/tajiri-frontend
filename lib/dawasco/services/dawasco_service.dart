// lib/dawasco/services/dawasco_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/authenticated_dio.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/dawasco_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class DawascoService {
  // ─── Account ──────────────────────────────────────────────────
  static Future<SingleResult<WaterAccount>> getAccount() async {
    try {
      final r = await _dio.get('/dawasco/account');
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: WaterAccount.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> getBalance(String accountNumber) async {
    try {
      final r = await _dio.get('/dawasco/accounts/$accountNumber/balance');
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: Map<String, dynamic>.from(d['data'] ?? {}));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<WaterAccount>> updateAccount(String accountNumber, Map<String, dynamic> fields) async {
    try {
      final r = await _dio.put('/dawasco/accounts/$accountNumber', data: fields);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: WaterAccount.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  // ─── Bills ────────────────────────────────────────────────────
  static Future<PaginatedResult<WaterBill>> getBills({int page = 1}) async {
    try {
      final r = await _dio.get('/dawasco/bills', queryParameters: {'page': page});
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => WaterBill.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items,
          currentPage: d['meta']?['current_page'] ?? page, lastPage: d['meta']?['last_page'] ?? 1);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> payBill(int billId, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/dawasco/bills/$billId/pay', data: body);
      final d = r.data;
      if (d['success'] == true) {
        // Fire-and-forget: record expenditure for budget tracking
        final billAmount = (body['amount'] as num?)?.toDouble() ?? 0;
        if (billAmount > 0) {
          LocalStorageService.getInstance().then((storage) {
            final token = storage.getAuthToken();
            if (token != null) {
              ExpenditureService.recordExpenditure(
                token: token,
                amount: billAmount,
                category: 'umeme_maji',
                description: 'DAWASCO: Bill #$billId',
                referenceId: 'dawasco_bill_$billId',
                sourceModule: 'dawasco',
              ).catchError((_) => null);
            }
          }).catchError((_) {
            debugPrint('[DawascoService] expenditure tracking skipped');
          });
        }
        return SingleResult(success: true, data: d['data']);
      }
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> submitBillDispute(int billId, String description, {String? photoPath}) async {
    try {
      final formData = FormData.fromMap({
        'bill_id': billId,
        'description': description,
        if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath, filename: 'dispute_photo.jpg'),
      });
      final r = await _dio.post('/dawasco/bills/$billId/dispute', data: formData);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: d['data']);
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  // ─── Meter Reading ────────────────────────────────────────────
  static Future<SingleResult<Map<String, dynamic>>> submitMeterReading(Map<String, dynamic> body, {String? photoPath}) async {
    try {
      final formData = FormData.fromMap({
        ...body,
        if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath, filename: 'meter_reading.jpg'),
      });
      final r = await _dio.post('/dawasco/meter-readings', data: formData);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: d['data']);
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  // ─── Consumption ──────────────────────────────────────────────
  static Future<PaginatedResult<ConsumptionRecord>> getConsumption(String accountNumber, {String period = '12months'}) async {
    try {
      final r = await _dio.get('/dawasco/accounts/$accountNumber/consumption', queryParameters: {'period': period});
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => ConsumptionRecord.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  // ─── Supply Schedule ──────────────────────────────────────────
  static Future<PaginatedResult<SupplySchedule>> getSupplySchedule({String? wardId}) async {
    try {
      final params = <String, dynamic>{};
      if (wardId != null) params['ward_id'] = wardId;
      final r = await _dio.get('/dawasco/supply-schedule', queryParameters: params);
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => SupplySchedule.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  // ─── Supply Status ────────────────────────────────────────────
  static Future<SingleResult<SupplyStatus>> getSupplyStatus({String? wardId}) async {
    try {
      final params = <String, dynamic>{};
      if (wardId != null) params['ward_id'] = wardId;
      final r = await _dio.get('/dawasco/supply-status', queryParameters: params);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: SupplyStatus.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<SupplyStatus>> reportSupplyStatus(String wardId, bool isAvailable) async {
    try {
      final r = await _dio.post('/dawasco/supply-status', data: {
        'ward_id': wardId, 'is_available': isAvailable,
      });
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: SupplyStatus.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  // ─── Issues / Reports ─────────────────────────────────────────
  static Future<SingleResult<WaterIssue>> reportIssue(Map<String, dynamic> body, {String? photoPath}) async {
    try {
      final formData = FormData.fromMap({
        ...body,
        if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath, filename: 'issue_photo.jpg'),
      });
      final r = await _dio.post('/dawasco/issues', data: formData);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: WaterIssue.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<WaterIssue>> getMyReports() async {
    try {
      final r = await _dio.get('/dawasco/issues/mine');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => WaterIssue.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  // ─── Connection Application ───────────────────────────────────
  static Future<SingleResult<ConnectionApplication>> applyConnection(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/dawasco/connections', data: body);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: ConnectionApplication.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<ConnectionApplication>> getConnectionStatus(int applicationId) async {
    try {
      final r = await _dio.get('/dawasco/connections/$applicationId');
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: ConnectionApplication.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> requestReconnection(String accountNumber, String paymentMethod) async {
    try {
      final r = await _dio.post('/dawasco/reconnection', data: {
        'account_number': accountNumber, 'payment_method': paymentMethod,
      });
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: d['data']);
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  // ─── Water Quality ─────────────────────────────────────────────
  static Future<PaginatedResult<WaterQualityReport>> getWaterQuality({String? wardId}) async {
    try {
      final params = <String, dynamic>{};
      if (wardId != null) params['ward_id'] = wardId;
      final r = await _dio.get('/dawasco/water-quality', queryParameters: params);
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => WaterQualityReport.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  // ─── Tariffs ──────────────────────────────────────────────────
  static Future<PaginatedResult<WaterTariff>> getTariffs() async {
    try {
      final r = await _dio.get('/dawasco/tariffs');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => WaterTariff.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  // ─── Water Tips ───────────────────────────────────────────────
  static Future<PaginatedResult<WaterTip>> getWaterTips() async {
    try {
      final r = await _dio.get('/dawasco/tips');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => WaterTip.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  // ─── Offices ──────────────────────────────────────────────────
  static Future<PaginatedResult<DawascoOffice>> getOffices() async {
    try {
      final r = await _dio.get('/dawasco/offices');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => DawascoOffice.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  // ─── Water Tankers ────────────────────────────────────────────
  static Future<PaginatedResult<WaterTanker>> getWaterTankers({String? districtId}) async {
    try {
      final params = <String, dynamic>{};
      if (districtId != null) params['district_id'] = districtId;
      final r = await _dio.get('/dawasco/tankers', queryParameters: params);
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => WaterTanker.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }
}
