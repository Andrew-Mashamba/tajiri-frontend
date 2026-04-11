// lib/tanesco/services/tanesco_service.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/authenticated_dio.dart';
import '../../services/expenditure_service.dart';
import '../../services/local_storage_service.dart';
import '../models/tanesco_models.dart';

Dio get _dio => AuthenticatedDio.instance;

class TanescoService {
  static Future<SingleResult<TokenPurchase>> buyTokens(
      String meterNumber, double amount, String method) async {
    try {
      final r = await _dio.post('/tanesco/tokens', data: {
        'meter_number': meterNumber, 'amount': amount, 'method': method});
      final d = r.data;
      if (d['success'] == true) {
        final purchase = TokenPurchase.fromJson(d['data']);
        // Fire-and-forget: record expenditure for budget tracking
        LocalStorageService.getInstance().then((storage) {
          final token = storage.getAuthToken();
          if (token != null) {
            ExpenditureService.recordExpenditure(
              token: token,
              amount: amount,
              category: 'umeme_maji',
              description: 'TANESCO: Meter $meterNumber',
              referenceId: 'tanesco_token_${purchase.id}',
              sourceModule: 'tanesco',
            ).catchError((_) => null);
          }
        }).catchError((_) {
          debugPrint('[TanescoService] expenditure tracking skipped');
        });
        return SingleResult(success: true, data: purchase);
      }
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<TokenPurchase>> getTokenHistory(String meterNumber, {int page = 1}) async {
    try {
      final r = await _dio.get('/tanesco/tokens', queryParameters: {'meter_number': meterNumber, 'page': page});
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => TokenPurchase.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items,
          currentPage: d['meta']?['current_page'] ?? page, lastPage: d['meta']?['last_page'] ?? 1);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Meter>> getMyMeters() async {
    try {
      final r = await _dio.get('/tanesco/meters');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Meter.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Meter>> addMeter(String meterNumber, String? alias) async {
    try {
      final r = await _dio.post('/tanesco/meters', data: {'meter_number': meterNumber, 'alias': alias});
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: Meter.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Outage>> getOutages() async {
    try {
      final r = await _dio.get('/tanesco/outages');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Outage.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Outage>> reportOutage(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/tanesco/outages', data: body);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: Outage.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Bill>> getBills(String meterNumber) async {
    try {
      final r = await _dio.get('/tanesco/bills', queryParameters: {'meter_number': meterNumber});
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Bill.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> payBill(int billId, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/tanesco/bills/$billId/pay', data: body);
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
                description: 'TANESCO: Bill #$billId',
                referenceId: 'tanesco_bill_$billId',
                sourceModule: 'tanesco',
              ).catchError((_) => null);
            }
          }).catchError((_) {
            debugPrint('[TanescoService] expenditure tracking skipped');
          });
        }
        return SingleResult(success: true, data: d['data']);
      }
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Balance>> checkBalance(String meterNumber) async {
    try {
      final r = await _dio.get('/tanesco/meters/$meterNumber/balance');
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: Balance.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<ConsumptionRecord>> getConsumption(String meterNumber, String period) async {
    try {
      final r = await _dio.get('/tanesco/consumption', queryParameters: {
        'meter_number': meterNumber, 'period': period});
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => ConsumptionRecord.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<PlannedMaintenance>> getMaintenance({String? districtId}) async {
    try {
      final q = <String, dynamic>{};
      if (districtId != null) q['district_id'] = districtId;
      final r = await _dio.get('/tanesco/maintenance', queryParameters: q);
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => PlannedMaintenance.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> submitBillDispute(
      int billId, String description, String? photoPath) async {
    try {
      final formData = FormData.fromMap({
        'description': description,
        if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath),
      });
      final r = await _dio.post('/tanesco/bills/$billId/dispute', data: formData);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: d['data']);
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<ConnectionApplication>> applyConnection(Map<String, dynamic> data) async {
    try {
      final r = await _dio.post('/tanesco/connections', data: data);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: ConnectionApplication.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<ConnectionApplication>> getConnectionStatus(int applicationId) async {
    try {
      final r = await _dio.get('/tanesco/connections/$applicationId');
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: ConnectionApplication.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<ConnectionApplication>> getMyConnections() async {
    try {
      final r = await _dio.get('/tanesco/connections');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => ConnectionApplication.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<Map<String, dynamic>>> submitMeterReading(
      String meterNumber, double reading, String? photoPath) async {
    try {
      final formData = FormData.fromMap({
        'reading': reading,
        if (photoPath != null) 'photo': await MultipartFile.fromFile(photoPath),
      });
      final r = await _dio.post('/tanesco/meters/$meterNumber/reading', data: formData);
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: d['data']);
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<SingleResult<AutoRechargeConfig>> setAutoRecharge(
      String meterNumber, double threshold, double amount, bool enabled) async {
    try {
      final r = await _dio.post('/tanesco/auto-recharge', data: {
        'meter_number': meterNumber, 'threshold': threshold,
        'recharge_amount': amount, 'enabled': enabled});
      final d = r.data;
      if (d['success'] == true) return SingleResult(success: true, data: AutoRechargeConfig.fromJson(d['data']));
      return SingleResult(success: false, message: d['message']);
    } catch (e) { return SingleResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<ErrorCode>> getErrorCodes() async {
    try {
      final r = await _dio.get('/tanesco/error-codes');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => ErrorCode.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<EnergyTip>> getEnergyTips() async {
    try {
      final r = await _dio.get('/tanesco/tips');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => EnergyTip.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }

  static Future<PaginatedResult<Appliance>> getAppliances() async {
    try {
      final r = await _dio.get('/tanesco/appliances');
      final d = r.data;
      if (d['success'] == true) {
        final items = (d['data'] as List).map((j) => Appliance.fromJson(j)).toList();
        return PaginatedResult(success: true, items: items);
      }
      return PaginatedResult(success: false, message: d['message']);
    } catch (e) { return PaginatedResult(success: false, message: '$e'); }
  }
}
