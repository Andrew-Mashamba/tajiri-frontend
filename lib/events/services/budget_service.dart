// lib/events/services/budget_service.dart
import 'package:dio/dio.dart';
import '../models/event.dart';
import '../models/budget.dart';
import '../../services/authenticated_dio.dart';

class BudgetService {
  Dio get _dio => AuthenticatedDio.instance;

  // ── Budget CRUD ──

  Future<SingleResult<EventBudget>> createBudget({
    required int eventId,
    required double totalBudget,
    String currency = 'TZS',
    required List<Map<String, dynamic>> categories,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/budget', data: {
        'total_budget': totalBudget,
        'currency': currency,
        'categories': categories,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventBudget.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<EventBudget>> getBudget({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/budget');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: EventBudget.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> updateCategory({required int categoryId, double? allocated, String? name}) async {
    try {
      final response = await _dio.put('/budget-categories/$categoryId', data: {
        if (allocated != null) 'allocated': allocated,
        if (name != null) 'name': name,
      });
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Expenses ──

  Future<PaginatedResult<Expense>> getExpenses({
    required int eventId,
    String? category,
    int? subCommitteeId,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (category != null) params['category'] = category;
      if (subCommitteeId != null) params['sub_committee_id'] = subCommitteeId;

      final response = await _dio.get('/events/$eventId/expenses', queryParameters: params);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List rawItems = data is List ? data : (data is Map && data['data'] is List ? data['data'] : []);
        final items = rawItems.map((e) => Expense.fromJson(e)).toList();
        final meta = response.data['meta'] as Map<String, dynamic>?;
        return PaginatedResult(
          success: true,
          items: items,
          currentPage: meta?['current_page'] ?? page,
          lastPage: meta?['last_page'] ?? 1,
          total: meta?['total'] ?? items.length,
        );
      }
      return PaginatedResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<Expense>> logExpense({
    required int eventId,
    required String categoryName,
    required double amount,
    required String description,
    int? budgetCategoryId,
    int? subCommitteeId,
    String? receiptPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'category_name': categoryName,
        'amount': amount,
        'description': description,
        if (budgetCategoryId != null) 'budget_category_id': budgetCategoryId,
        if (subCommitteeId != null) 'sub_committee_id': subCommitteeId,
      });
      if (receiptPath != null) {
        formData.files.add(MapEntry('receipt', await MultipartFile.fromFile(receiptPath)));
      }
      final response = await _dio.post('/events/$eventId/expenses', data: formData);
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Expense.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> approveExpense({required int expenseId}) async {
    try {
      final response = await _dio.post('/expenses/$expenseId/approve');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> rejectExpense({required int expenseId, String? reason}) async {
    try {
      final response = await _dio.post('/expenses/$expenseId/reject', data: {if (reason != null) 'reason': reason});
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  // ── Disbursement ──

  Future<SingleResult<Disbursement>> requestDisbursement({
    required int eventId,
    required int subCommitteeId,
    required double amount,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post('/events/$eventId/disbursements', data: {
        'sub_committee_id': subCommitteeId,
        'amount': amount,
        'purpose': purpose,
      });
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: Disbursement.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<SingleResult<void>> approveDisbursement({required int disbursementId}) async {
    try {
      final response = await _dio.post('/disbursements/$disbursementId/approve');
      return SingleResult(success: response.data['success'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  Future<List<Disbursement>> getDisbursements({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/disbursements');
      if (response.data['success'] == true) {
        return (response.data['data'] as List? ?? []).map((e) => Disbursement.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── Financial Report ──

  Future<SingleResult<FinancialReport>> generateReport({required int eventId}) async {
    try {
      final response = await _dio.get('/events/$eventId/financial-report');
      if (response.data['success'] == true) {
        return SingleResult(success: true, data: FinancialReport.fromJson(response.data['data']));
      }
      return SingleResult(success: false, message: response.data['message']?.toString());
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
