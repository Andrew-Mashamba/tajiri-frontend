// lib/services/income_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../budget/models/budget_models.dart';

/// Central service for all income (money in) across the platform.
/// Static-method class — does not need instantiation.
///
/// Called by: BudgetService (summary, breakdown), BudgetHomeScreen (income total),
///           MonthlyReportScreen (income chart), ProfileScreen (earnings),
///           TeaService/Shangazi (AI budget insights).
class IncomeService {
  /// Record a new income event. Called by source modules when money comes in.
  ///
  /// Called from: WalletService.deposit(), SubscriptionService (tip/sub received),
  ///             ShopService (sale confirmed), TajirikaService (job completed),
  ///             ContributionService (withdrawal), LiveStreamService (gift received),
  ///             EventService (ticket sold), KikobaService (payout received).
  static Future<IncomeRecord?> recordIncome({
    required String token,
    required double amount,
    required String source,
    required String description,
    String? sourceModule,
    String? referenceId,
    Map<String, dynamic>? metadata,
    DateTime? date,
    bool isRecurring = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'source': source,
        'description': description,
      };
      if (sourceModule != null) body['source_module'] = sourceModule;
      if (referenceId != null) body['reference_id'] = referenceId;
      if (metadata != null) body['metadata'] = metadata;
      if (date != null) body['date'] = date.toIso8601String();
      if (isRecurring) body['is_recurring'] = true;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/income'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return IncomeRecord.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      debugPrint('[IncomeService] recordIncome failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[IncomeService] recordIncome error: $e');
      return null;
    }
  }

  /// Get paginated income records for the authenticated user.
  ///
  /// Called from: BudgetHomeScreen (income list), IncomeBreakdownScreen,
  ///             EnvelopeDetailScreen (income transactions).
  static Future<IncomeListResult> getIncome({
    required String token,
    String? source,
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
      if (source != null) params['source'] = source;
      if (sourceModule != null) params['source_module'] = sourceModule;
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();

      final uri = Uri.parse('${ApiConfig.baseUrl}/income')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>;
        final records = (data['records'] as List? ?? [])
            .map((r) => IncomeRecord.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        return IncomeListResult(
          success: true,
          records: records,
        );
      }

      return IncomeListResult(
        success: false,
        message: json['message'] as String?,
      );
    } catch (e) {
      debugPrint('[IncomeService] getIncome error: $e');
      return IncomeListResult(success: false, message: e.toString());
    }
  }

  /// Get income summary for a period (daily, weekly, monthly).
  ///
  /// Called from: BudgetHomeScreen (hero income number), BudgetService.getCurrentPeriod(),
  ///             MonthlyReportScreen, TeaService (Shangazi insights).
  static Future<IncomeSummary?> getIncomeSummary({
    required String token,
    required String period,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/income/summary')
          .replace(queryParameters: {'period': period});

      final response = await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return IncomeSummary.fromJson(
          Map<String, dynamic>.from(json['data'] as Map),
        );
      }
      return null;
    } catch (e) {
      debugPrint('[IncomeService] getIncomeSummary error: $e');
      return null;
    }
  }

  /// Get income grouped by source for a specific month.
  ///
  /// Called from: IncomeBreakdownScreen (pie chart), MonthlyReportScreen.
  static Future<Map<String, double>> getIncomeBySource({
    required String token,
    required int year,
    required int month,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/income/by-source')
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
      debugPrint('[IncomeService] getIncomeBySource error: $e');
      return {};
    }
  }

  /// Get recurring income patterns (auto-detected).
  ///
  /// Called from: CashFlowForecastScreen (predicted income), RecurringExpensesScreen.
  static Future<List<RecurringIncome>> getRecurringIncome({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/income/recurring'),
        headers: ApiConfig.authHeaders(token),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((r) => RecurringIncome.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[IncomeService] getRecurringIncome error: $e');
      return [];
    }
  }
}
