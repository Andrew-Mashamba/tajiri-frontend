// lib/services/budget_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'budget_database.dart';
import 'wallet_service.dart';
import 'subscription_service.dart';
import 'shop_service.dart';
import 'contribution_service.dart';
import '../models/budget_models.dart';
import '../models/shop_models.dart';

class BudgetService {
  final BudgetDatabase _db = BudgetDatabase.instance;
  final WalletService _walletService = WalletService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ShopService _shopService = ShopService();
  final ContributionService _contributionService = ContributionService();

  static const _lastSyncKey = 'budget_last_sync';

  // ── Envelope Operations ───────────────────────────────────────────────

  Future<List<BudgetEnvelope>> getEnvelopes() => _db.getEnvelopes();

  Future<int> createEnvelope({
    required String name,
    required String icon,
    required double allocatedAmount,
    String color = '1A1A1A',
  }) async {
    final envelopes = await _db.getEnvelopes();
    return _db.insertEnvelope(BudgetEnvelope(
      name: name,
      icon: icon,
      allocatedAmount: allocatedAmount,
      color: color,
      order: envelopes.length,
    ));
  }

  Future<void> updateEnvelope(BudgetEnvelope envelope) =>
      _db.updateEnvelope(envelope);

  Future<void> deleteEnvelope(int id) => _db.deleteEnvelope(id);

  // ── Transaction Operations ────────────────────────────────────────────

  Future<List<BudgetTransaction>> getTransactions({
    int? envelopeId,
    BudgetTransactionType? type,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    int offset = 0,
  }) => _db.getTransactions(
    envelopeId: envelopeId,
    type: type,
    from: from,
    to: to,
    limit: limit,
    offset: offset,
  );

  Future<int> addTransaction({
    int? envelopeId,
    required double amount,
    required BudgetTransactionType type,
    BudgetSource source = BudgetSource.manual,
    required String description,
    DateTime? date,
    String? tajiriRefId,
  }) {
    return _db.insertTransaction(BudgetTransaction(
      envelopeId: envelopeId,
      amount: amount,
      type: type,
      source: source,
      description: description,
      date: date ?? DateTime.now(),
      tajiriRefId: tajiriRefId,
    ));
  }

  Future<void> deleteTransaction(int id) => _db.deleteTransaction(id);

  // ── Period Summary ────────────────────────────────────────────────────

  Future<BudgetPeriod> getCurrentPeriod() {
    final now = DateTime.now();
    return _db.getPeriodSummary(now.year, now.month);
  }

  Future<Map<BudgetSource, double>> getCurrentIncomeBreakdown() {
    final now = DateTime.now();
    return _db.getIncomeBySource(now.year, now.month);
  }

  // ── Goal Operations ───────────────────────────────────────────────────

  Future<List<BudgetGoal>> getGoals() => _db.getGoals();

  Future<int> createGoal({
    required String name,
    required String icon,
    required double targetAmount,
    DateTime? deadline,
  }) {
    return _db.insertGoal(BudgetGoal(
      name: name,
      icon: icon,
      targetAmount: targetAmount,
      deadline: deadline,
    ));
  }

  Future<void> updateGoal(BudgetGoal goal) => _db.updateGoal(goal);
  Future<void> deleteGoal(int id) => _db.deleteGoal(id);
  Future<void> addToGoal(int goalId, double amount) => _db.addToGoal(goalId, amount);

  // ── Auto-Sync from TAJIRI Services ────────────────────────────────────

  /// Sync income and expenses from all TAJIRI services.
  /// Deduplicates via tajiri_ref_id. Call on budget screen open.
  Future<int> syncFromTajiri(int userId) async {
    debugPrint('[BudgetService] syncFromTajiri started for userId=$userId');
    int synced = 0;

    try {
      synced += await _syncWalletTransactions(userId);
      synced += await _syncCreatorEarnings(userId);
      synced += await _syncShopSales(userId);
      synced += await _syncShopPurchases(userId);
      synced += await _syncMichangoReceived(userId);

      if (synced > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
        debugPrint('[BudgetService] Synced $synced new transactions');
      }
    } catch (e) {
      debugPrint('[BudgetService] syncFromTajiri error: $e');
    }

    return synced;
  }

  /// Sync wallet deposits (income) and payments/withdrawals (expense)
  Future<int> _syncWalletTransactions(int userId) async {
    int count = 0;
    try {
      final result = await _walletService.getTransactions(
        userId: userId,
        page: 1,
        perPage: 50,
      );
      if (!result.success) return 0;

      for (final txn in result.transactions) {
        final refId = 'wallet_${txn.id}';
        if (await _db.hasTransaction(refId)) continue;

        if (txn.isCredit) {
          await _db.insertTransaction(BudgetTransaction(
            amount: txn.amount,
            type: BudgetTransactionType.income,
            source: BudgetSource.wallet,
            description: '${txn.typeName}: ${txn.description ?? ''}',
            date: txn.createdAt,
            tajiriRefId: refId,
          ));
          count++;
        } else if (txn.isDebit) {
          await _db.insertTransaction(BudgetTransaction(
            amount: txn.total,
            type: BudgetTransactionType.expense,
            source: BudgetSource.wallet,
            description: '${txn.typeName}: ${txn.description ?? ''}',
            date: txn.createdAt,
            tajiriRefId: refId,
          ));
          count++;
        }
      }
    } catch (e) {
      debugPrint('[BudgetService] _syncWalletTransactions error: $e');
    }
    return count;
  }

  /// Sync creator earnings (subscriptions, tips, gifts)
  Future<int> _syncCreatorEarnings(int userId) async {
    int count = 0;
    try {
      final result = await _subscriptionService.getEarnings(userId: userId);
      if (!result.success) return 0;

      for (final earning in result.earnings) {
        final refId = 'earning_${earning.id}';
        if (await _db.hasTransaction(refId)) continue;

        final source = switch (earning.type) {
          'tip' => BudgetSource.tip,
          'gift' => BudgetSource.tip,
          _ => BudgetSource.subscription,
        };

        await _db.insertTransaction(BudgetTransaction(
          amount: earning.netAmount,
          type: BudgetTransactionType.income,
          source: source,
          description: '${earning.typeName} — TZS ${earning.netAmount.toStringAsFixed(0)}',
          date: earning.createdAt,
          tajiriRefId: refId,
        ));
        count++;
      }
    } catch (e) {
      debugPrint('[BudgetService] _syncCreatorEarnings error: $e');
    }
    return count;
  }

  /// Sync shop sales (seller income)
  Future<int> _syncShopSales(int userId) async {
    int count = 0;
    try {
      final result = await _shopService.getSellerOrders(
        userId,
        page: 1,
        perPage: 50,
      );
      if (!result.success) return 0;

      for (final order in result.orders) {
        if (order.status != OrderStatus.completed && order.status != OrderStatus.delivered) continue;
        final refId = 'shop_sale_${order.id}';
        if (await _db.hasTransaction(refId)) continue;

        await _db.insertTransaction(BudgetTransaction(
          amount: order.totalAmount,
          type: BudgetTransactionType.income,
          source: BudgetSource.shop,
          description: 'Mauzo: ${order.product?.title ?? 'Agizo #${order.id}'}',
          date: order.createdAt,
          tajiriRefId: refId,
        ));
        count++;
      }
    } catch (e) {
      debugPrint('[BudgetService] _syncShopSales error: $e');
    }
    return count;
  }

  /// Sync shop purchases (buyer expense)
  Future<int> _syncShopPurchases(int userId) async {
    int count = 0;
    try {
      final result = await _shopService.getBuyerOrders(userId, page: 1, perPage: 50);
      if (!result.success) return 0;

      for (final order in result.orders) {
        final refId = 'shop_buy_${order.id}';
        if (await _db.hasTransaction(refId)) continue;

        await _db.insertTransaction(BudgetTransaction(
          amount: order.totalAmount,
          type: BudgetTransactionType.expense,
          source: BudgetSource.shop,
          description: 'Ununuzi: ${order.product?.title ?? 'Agizo #${order.id}'}',
          date: order.createdAt,
          tajiriRefId: refId,
        ));
        count++;
      }
    } catch (e) {
      debugPrint('[BudgetService] _syncShopPurchases error: $e');
    }
    return count;
  }

  /// Sync michango campaign donations received (income)
  Future<int> _syncMichangoReceived(int userId) async {
    int count = 0;
    try {
      final result = await _contributionService.getUserCampaigns(userId, status: 'active');
      if (!result.success) return 0;

      for (final campaign in result.campaigns) {
        final refId = 'michango_${campaign.id}';
        if (await _db.hasTransaction(refId)) continue;
        if (campaign.raisedAmount <= 0) continue;

        await _db.insertTransaction(BudgetTransaction(
          amount: campaign.raisedAmount,
          type: BudgetTransactionType.income,
          source: BudgetSource.michango,
          description: 'Michango: ${campaign.title}',
          date: campaign.createdAt,
          tajiriRefId: refId,
        ));
        count++;
      }
    } catch (e) {
      debugPrint('[BudgetService] _syncMichangoReceived error: $e');
    }
    return count;
  }
}
