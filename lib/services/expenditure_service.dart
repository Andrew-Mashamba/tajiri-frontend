// lib/services/expenditure_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../budget/models/budget_models.dart';

/// Central service for all expenditures (money out) across the platform.
/// Static-method class — does not need instantiation.
///
/// Called by: BudgetService (spending by category, pace), BudgetHomeScreen (per-envelope spending),
///           EnvelopeDetailScreen (transaction list), MonthlyReportScreen (spending charts),
///           CashFlowForecastScreen (upcoming expenses), TeaService/Shangazi (spending alerts),
///           Other modules for budget context (Food, Transport, Shop checkout, etc.).
class ExpenditureService {
  /// Record a new expenditure event. Called by source modules when money goes out.
  ///
  /// Called from: WalletService.withdraw(), WalletService.transfer() (sent),
  ///             Housing module (rent), Food module (orders), Transport module (fare),
  ///             Bills module (TANESCO/DAWASCO/airtime), Doctor/Pharmacy modules,
  ///             ShopService (purchase), SubscriptionService.subscribe()/sendTip(),
  ///             ContributionService.donateToCampaign(), Insurance module, etc.
  static Future<ExpenditureRecord?> recordExpenditure({
    required String token,
    required double amount,
    required String category,
    required String description,
    String? sourceModule,
    String? referenceId,
    String? envelopeTag,
    Map<String, dynamic>? metadata,
    DateTime? date,
    bool isRecurring = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'category': category,
        'description': description,
      };
      if (sourceModule != null) body['source_module'] = sourceModule;
      if (referenceId != null) body['reference_id'] = referenceId;
      if (envelopeTag != null) body['envelope_tag'] = envelopeTag;
      if (metadata != null) body['metadata'] = metadata;
      if (date != null) body['date'] = date.toIso8601String();
      if (isRecurring) body['is_recurring'] = true;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/expenditures'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return ExpenditureRecord.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      debugPrint('[ExpenditureService] recordExpenditure failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[ExpenditureService] recordExpenditure error: $e');
      return null;
    }
  }

  /// Get paginated expenditure records for the authenticated user.
  ///
  /// Called from: BudgetHomeScreen (recent transactions), EnvelopeDetailScreen (filtered by category),
  ///             AddTransactionScreen (recent for category suggestion).
  static Future<ExpenditureListResult> getExpenditures({
    required String token,
    String? category,
    String? sourceModule,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (category != null) params['category'] = category;
      if (sourceModule != null) params['source_module'] = sourceModule;
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}/expenditures')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>;
        final records = (data['records'] as List? ?? [])
            .map((r) => ExpenditureRecord.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        return ExpenditureListResult(
          success: true,
          records: records,
        );
      }

      return ExpenditureListResult(
        success: false,
        message: json['message'] as String?,
      );
    } catch (e) {
      debugPrint('[ExpenditureService] getExpenditures error: $e');
      return ExpenditureListResult(success: false, message: e.toString());
    }
  }

  /// Get expenditure summary for a period (daily, weekly, monthly).
  ///
  /// Called from: BudgetHomeScreen (hero spending number), BudgetService.getCurrentPeriod(),
  ///             MonthlyReportScreen, TeaService (Shangazi spending alerts).
  static Future<ExpenditureSummary?> getExpenditureSummary({
    required String token,
    required String period,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/expenditures/summary')
          .replace(queryParameters: {'period': period});

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return ExpenditureSummary.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[ExpenditureService] getExpenditureSummary error: $e');
      return null;
    }
  }

  /// Get expenditures grouped by category for a specific month.
  ///
  /// Called from: BudgetHomeScreen (per-envelope spent amounts), MonthlyReportScreen (breakdown chart).
  static Future<Map<String, double>> getExpenditureByCategory({
    required String token,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/expenditures/by-category')
          .replace(queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      });

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map;
        return data.map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        );
      }
      return {};
    } catch (e) {
      debugPrint('[ExpenditureService] getExpenditureByCategory error: $e');
      return {};
    }
  }

  /// Get recurring expenditure patterns (auto-detected + user-confirmed).
  ///
  /// Called from: RecurringExpensesScreen (list), CashFlowForecastScreen (upcoming bills),
  ///             BudgetHomeScreen (recurring expense summary).
  static Future<List<RecurringExpense>> getRecurringExpenses({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenditures/recurring'),
        headers: ApiConfig.authHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((r) => RecurringExpense.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExpenditureService] getRecurringExpenses error: $e');
      return [];
    }
  }

  /// Confirm a recurring expense (persist to backend).
  ///
  /// Called from: RecurringExpensesPage._confirmExpense()
  static Future<bool> confirmRecurringExpense(String token, int expenseId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/expenditures/recurring/$expenseId/confirm'),
        headers: ApiConfig.authHeaders(token),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['success'] == true;
    } catch (e) {
      debugPrint('[ExpenditureService] confirmRecurring error: $e');
      return false;
    }
  }

  /// Dismiss a recurring expense (persist to backend).
  ///
  /// Called from: RecurringExpensesPage._dismissExpense()
  static Future<bool> dismissRecurringExpense(String token, int expenseId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/expenditures/recurring/$expenseId/dismiss'),
        headers: ApiConfig.authHeaders(token),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['success'] == true;
    } catch (e) {
      debugPrint('[ExpenditureService] dismissRecurring error: $e');
      return false;
    }
  }

  /// Get predicted upcoming expenses based on recurring patterns.
  ///
  /// Called from: CashFlowForecastScreen (projection graph), BudgetHomeScreen (safe-to-spend calc).
  static Future<List<UpcomingExpense>> getUpcomingExpenses({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/expenditures/upcoming'),
        headers: ApiConfig.authHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((r) => UpcomingExpense.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ExpenditureService] getUpcomingExpenses error: $e');
      return [];
    }
  }

  /// Recategorize an expenditure record to a different envelope/category.
  ///
  /// Called from: EnvelopeDetailPage (transaction tap → reassign bottom sheet).
  static Future<bool> recategorizeExpenditure(
    String token,
    int expenditureId,
    String newCategory,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/expenditures/$expenditureId/recategorize'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'category': newCategory}),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['success'] == true;
    } catch (e) {
      debugPrint('[ExpenditureService] recategorize error: $e');
      return false;
    }
  }

  /// Get spending pace for a specific category in a month.
  ///
  /// Called from: EnvelopeDetailScreen (pace indicator), BudgetHomeScreen (envelope status badges),
  ///             Other modules for budget context at point of decision:
  ///             - Housing module: shows Kodi pace before rent payment
  ///             - Food module: shows Chakula pace when ordering
  ///             - Transport module: shows Usafiri pace after fare payment
  ///             - Shop: shows remaining budget at checkout
  ///             - Bills: shows if budget covers the bill
  ///             - Events: shows Burudani remaining before ticket purchase
  static Future<SpendingPace?> getSpendingPace({
    required String token,
    required String category,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/expenditures/spending-pace')
          .replace(queryParameters: {
        'category': category,
        'year': year.toString(),
        'month': month.toString(),
      });

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return SpendingPace.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[ExpenditureService] getSpendingPace error: $e');
      return null;
    }
  }
}
