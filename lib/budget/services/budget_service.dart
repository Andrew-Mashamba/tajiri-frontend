// lib/budget/services/budget_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/budget_models.dart';
import '../../services/income_service.dart';
import '../../services/expenditure_service.dart';
import '../../services/wallet_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

// ---------------------------------------------------------------------------
// BudgetSnapshot — convenience aggregate returned by loadBudgetSnapshot
// ---------------------------------------------------------------------------

/// All budget data needed for the home screen, loaded in parallel.
class BudgetSnapshot {
  final double walletBalance;
  final List<BudgetEnvelope> envelopes;
  final IncomeSummary? incomeSummary;
  final ExpenditureSummary? expenditureSummary;
  final List<RecurringExpense> recurringExpenses;
  final List<UpcomingExpense> upcomingExpenses;

  BudgetSnapshot({
    this.walletBalance = 0,
    this.envelopes = const [],
    this.incomeSummary,
    this.expenditureSummary,
    this.recurringExpenses = const [],
    this.upcomingExpenses = const [],
  });

  /// Sum of all envelope allocations
  double get totalAllocated =>
      envelopes.fold(0.0, (sum, e) => sum + e.allocatedAmount);

  /// Wallet balance minus total allocated to envelopes
  double get unallocated => walletBalance - totalAllocated;

  /// Safe-to-spend: balance minus allocations minus upcoming obligations
  double get safeToSpend =>
      walletBalance -
      totalAllocated -
      upcomingExpenses.fold(0.0, (sum, u) => sum + u.amount);
}

// ---------------------------------------------------------------------------
// BudgetService — static-method API client for budget endpoints
// ---------------------------------------------------------------------------

/// Budget service — envelopes, periods, goals, and snapshot aggregation.
/// Static-method class — does not need instantiation.
///
/// Called by: BudgetHomeScreen, EnvelopeDetailScreen, GoalDetailScreen,
///           MonthlyReportScreen, CashFlowForecastScreen, TeaService/Shangazi.
class BudgetService {
  // ── Envelope Defaults ───────────────────────────────────────────────────

  /// Get the system-wide default envelope templates.
  ///
  /// Called from: OnboardingBudgetScreen (initial envelope picker),
  ///             EnvelopeSettingsScreen (add from defaults).
  static Future<List<EnvelopeDefault>> getEnvelopeDefaults(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/budget/envelope-defaults'),
        headers: ApiConfig.authHeaders(token),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((e) =>
                EnvelopeDefault.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      debugPrint(
          '[BudgetService] getEnvelopeDefaults failed: ${json['message']}');
      return [];
    } catch (e) {
      debugPrint('[BudgetService] getEnvelopeDefaults error: $e');
      return [];
    }
  }

  // ── User Envelopes ──────────────────────────────────────────────────────

  /// Get all envelopes for a user (current month by default).
  ///
  /// Called from: BudgetHomeScreen (envelope grid), EnvelopeSettingsScreen,
  ///             loadBudgetSnapshot (parallel load).
  static Future<EnvelopeListResult> getUserEnvelopes(
      String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/budget/users/$userId/envelopes'),
        headers: ApiConfig.authHeaders(token),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        final envelopes = (json['data'] as List)
            .map((e) =>
                BudgetEnvelope.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return EnvelopeListResult(success: true, envelopes: envelopes);
      }

      return EnvelopeListResult(
        success: false,
        message: json['message'] as String?,
      );
    } catch (e) {
      debugPrint('[BudgetService] getUserEnvelopes error: $e');
      return EnvelopeListResult(success: false, message: e.toString());
    }
  }

  /// Create a new envelope for the user.
  ///
  /// Called from: AddEnvelopeScreen, OnboardingBudgetScreen.
  static Future<BudgetEnvelope?> createEnvelope(
      String token, int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/budget/users/$userId/envelopes'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return BudgetEnvelope.fromJson(
            Map<String, dynamic>.from(json['data'] as Map));
      }
      debugPrint('[BudgetService] createEnvelope failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] createEnvelope error: $e');
      return null;
    }
  }

  /// Update an existing envelope.
  ///
  /// Called from: EditEnvelopeScreen, EnvelopeDetailScreen (quick allocation edit).
  static Future<BudgetEnvelope?> updateEnvelope(
      String token, int userId, int envelopeId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/budget/users/$userId/envelopes/$envelopeId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return BudgetEnvelope.fromJson(
            Map<String, dynamic>.from(json['data'] as Map));
      }
      debugPrint('[BudgetService] updateEnvelope failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] updateEnvelope error: $e');
      return null;
    }
  }

  // ── Budget Period ───────────────────────────────────────────────────────

  /// Get the budget period summary for a user (defaults to current month).
  ///
  /// Called from: BudgetHomeScreen (period bar), MonthlyReportScreen.
  static Future<BudgetPeriod?> getPeriod(String token, int userId,
      {int? year, int? month}) async {
    try {
      final params = <String, String>{};
      if (year != null) params['year'] = year.toString();
      if (month != null) params['month'] = month.toString();

      final uri = Uri.parse('$_baseUrl/budget/users/$userId/period')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      final response =
          await http.get(uri, headers: ApiConfig.authHeaders(token));
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return BudgetPeriod.fromJson(
            Map<String, dynamic>.from(json['data'] as Map));
      }
      debugPrint('[BudgetService] getPeriod failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] getPeriod error: $e');
      return null;
    }
  }

  // ── Goals ───────────────────────────────────────────────────────────────

  /// Get all savings goals for a user.
  ///
  /// Called from: GoalsScreen (goal list), BudgetHomeScreen (goals summary).
  static Future<GoalListResult> getGoals(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/budget/users/$userId/goals'),
        headers: ApiConfig.authHeaders(token),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        final goals = (json['data'] as List)
            .map((e) =>
                BudgetGoal.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return GoalListResult(success: true, goals: goals);
      }

      return GoalListResult(
        success: false,
        message: json['message'] as String?,
      );
    } catch (e) {
      debugPrint('[BudgetService] getGoals error: $e');
      return GoalListResult(success: false, message: e.toString());
    }
  }

  /// Create a new savings goal.
  ///
  /// Called from: AddGoalScreen.
  static Future<BudgetGoal?> createGoal(
      String token, int userId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/budget/users/$userId/goals'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return BudgetGoal.fromJson(
            Map<String, dynamic>.from(json['data'] as Map));
      }
      debugPrint('[BudgetService] createGoal failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] createGoal error: $e');
      return null;
    }
  }

  /// Update an existing savings goal.
  ///
  /// Called from: EditGoalScreen, GoalDetailScreen (add savings).
  static Future<BudgetGoal?> updateGoal(
      String token, int userId, int goalId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/budget/users/$userId/goals/$goalId'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(data),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return BudgetGoal.fromJson(
            Map<String, dynamic>.from(json['data'] as Map));
      }
      debugPrint('[BudgetService] updateGoal failed: ${json['message']}');
      return null;
    } catch (e) {
      debugPrint('[BudgetService] updateGoal error: $e');
      return null;
    }
  }

  /// Delete a savings goal.
  ///
  /// Called from: GoalDetailScreen (delete action), GoalsScreen (swipe-to-delete).
  static Future<bool> deleteGoal(
      String token, int userId, int goalId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/budget/users/$userId/goals/$goalId'),
        headers: ApiConfig.authHeaders(token),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return true;
      }
      debugPrint('[BudgetService] deleteGoal failed: ${json['message']}');
      return false;
    } catch (e) {
      debugPrint('[BudgetService] deleteGoal error: $e');
      return false;
    }
  }

  // ── Shangazi AI Summary ─────────────────────────────────────────────────

  /// Returns structured budget data for Shangazi AI to interpret.
  ///
  /// Called from: TeaService / Shangazi orchestrator context injection.
  static Future<Map<String, dynamic>> getBudgetSummaryForAI(
      String token, int userId) async {
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        getEnvelopeDefaults(token), // 0: needed for name fallbacks
        getUserEnvelopes(token, userId), // 1: user envelopes
        IncomeService.getIncomeSummary(token: token, period: 'monthly'), // 2
        ExpenditureService.getExpenditureSummary(
            token: token, period: 'monthly'), // 3
      ]);

      final envelopes = (results[1] as EnvelopeListResult).envelopes;
      final income = results[2] as IncomeSummary?;
      final spending = results[3] as ExpenditureSummary?;

      final totalAllocated =
          envelopes.fold(0.0, (sum, e) => sum + e.allocatedAmount);
      final totalSpent = spending?.totalSpent ?? 0;
      final totalIncome = income?.totalIncome ?? 0;

      return {
        'month':
            '${now.year}-${now.month.toString().padLeft(2, '0')}',
        'total_income': totalIncome,
        'total_spent': totalSpent,
        'total_allocated': totalAllocated,
        'savings_rate': totalIncome > 0
            ? ((totalIncome - totalSpent) / totalIncome * 100).round()
            : 0,
        'spending_by_category': spending?.byCategory ?? {},
        'income_by_source': income?.bySource ?? {},
        'envelopes': envelopes
            .map((e) => {
                  'name': e.displayName(false),
                  'allocated': e.allocatedAmount,
                  'spent': e.spentAmount,
                  'remaining': e.remainingAmount,
                  'status': e.isOverBudget ? 'over_budget' : 'on_track',
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('[BudgetService] getBudgetSummaryForAI error: $e');
      return {'error': 'Failed to load budget data'};
    }
  }

  // ── Streak & Gamification ───────────────────────────────────────────────

  /// Get the current streak data for a user.
  ///
  /// Called from: BudgetHomePage (streak card display).
  static Future<BudgetStreak> getStreak(String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/budget/users/$userId/streak'),
        headers: ApiConfig.authHeaders(token),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return BudgetStreak.fromJson(
            Map<String, dynamic>.from(body['data'] as Map));
      }
      return BudgetStreak();
    } catch (e) {
      debugPrint('[BudgetService] getStreak error: $e');
      return BudgetStreak();
    }
  }

  /// Check in for today's streak. Pass whether all envelopes are within budget.
  ///
  /// Called from: BudgetHomePage (auto check-in after data load).
  static Future<BudgetStreak?> checkInStreak(
      String token, int userId, bool allWithinBudget) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/budget/users/$userId/streak/check-in'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({'all_within_budget': allWithinBudget}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return BudgetStreak.fromJson(
            Map<String, dynamic>.from(body['data'] as Map));
      }
      return null;
    } catch (e) {
      debugPrint('[BudgetService] checkInStreak error: $e');
      return null;
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────

  /// Trigger server-side budget notification checks for the user.
  /// Returns any newly triggered notifications. Fire-and-forget — don't block UI.
  ///
  /// Called from: BudgetHomePage._loadData (after main data loads).
  static Future<List<Map<String, dynamic>>> checkNotifications(
      String token, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/budget/users/$userId/check-notifications'),
        headers: ApiConfig.authHeaders(token),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return (body['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('[BudgetService] checkNotifications error: $e');
      return [];
    }
  }

  /// Get recent budget notifications for the user.
  ///
  /// Called from: BudgetNotificationsPage (if built).
  static Future<List<Map<String, dynamic>>> getNotifications(
      String token, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/budget/users/$userId/notifications'),
        headers: ApiConfig.authHeaders(token),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return (body['data'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('[BudgetService] getNotifications error: $e');
      return [];
    }
  }

  // ── Snapshot (parallel aggregate load) ──────────────────────────────────

  /// Load all budget data needed for the home screen in parallel.
  /// Returns a [BudgetSnapshot] with wallet balance, envelopes, income/expense
  /// summaries, recurring expenses, and upcoming expenses.
  ///
  /// Called from: BudgetHomeScreen.initState, pull-to-refresh.
  static Future<BudgetSnapshot> loadBudgetSnapshot(
      String token, int userId) async {
    try {
      final walletService = WalletService();

      final results = await Future.wait([
        // 0: wallet
        walletService.getWallet(userId),
        // 1: envelopes
        getUserEnvelopes(token, userId),
        // 2: income summary
        IncomeService.getIncomeSummary(token: token, period: 'monthly'),
        // 3: expenditure summary
        ExpenditureService.getExpenditureSummary(
            token: token, period: 'monthly'),
        // 4: recurring expenses
        ExpenditureService.getRecurringExpenses(token: token),
        // 5: upcoming expenses
        ExpenditureService.getUpcomingExpenses(token: token),
      ]);

      final walletResult = results[0] as WalletResult;
      final envelopeResult = results[1] as EnvelopeListResult;
      final incomeSummary = results[2] as IncomeSummary?;
      final expenditureSummary = results[3] as ExpenditureSummary?;
      final recurringExpenses = results[4] as List<RecurringExpense>;
      final upcomingExpenses = results[5] as List<UpcomingExpense>;

      final balance =
          walletResult.success ? (walletResult.wallet?.balance ?? 0.0) : 0.0;
      final envelopes =
          envelopeResult.success ? envelopeResult.envelopes : <BudgetEnvelope>[];

      // Fix 8: Merge confirmed recurring expenses into upcoming if not already present
      final mutableUpcoming = List<UpcomingExpense>.from(upcomingExpenses);
      final upcomingDescriptions =
          mutableUpcoming.map((u) => u.description).toSet();
      for (final recurring in recurringExpenses) {
        if (recurring.isConfirmed &&
            !upcomingDescriptions.contains(recurring.description)) {
          mutableUpcoming.add(UpcomingExpense(
            description: recurring.description,
            amount: recurring.amount,
            category: recurring.category,
            expectedDate: recurring.nextExpected ?? DateTime.now(),
            isRecurring: true,
          ));
        }
      }

      // Fix 10: Log warning if wallet balance and income diverge significantly
      if (incomeSummary != null && incomeSummary.totalIncome > 0) {
        final diff = (balance - incomeSummary.totalIncome).abs();
        if (diff > balance * 0.5) {
          debugPrint(
              '[BudgetService] Warning: wallet balance ($balance) and income total (${incomeSummary.totalIncome}) diverge significantly');
        }
      }

      return BudgetSnapshot(
        walletBalance: balance,
        envelopes: envelopes,
        incomeSummary: incomeSummary,
        expenditureSummary: expenditureSummary,
        recurringExpenses: recurringExpenses,
        upcomingExpenses: mutableUpcoming,
      );
    } catch (e) {
      debugPrint('[BudgetService] loadBudgetSnapshot error: $e');
      return BudgetSnapshot();
    }
  }
}
